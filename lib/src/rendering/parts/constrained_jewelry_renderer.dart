import 'dart:math' as math;

import '../../geometry/point.dart';
import '../../pixels/pixel_mask.dart';
import '../../util/math_utils.dart';
import '../render_helpers.dart';
import '../render_model.dart';
import '../rig_anchor_resolver.dart';
import '../rig_model.dart';

/// Replaces flat jewelry masks with anchored ear pieces and a two-anchor chain.
final class ConstrainedJewelryRenderer implements AvatarPartRenderer {
  const ConstrainedJewelryRenderer({
    this.anchorResolver = const RigAnchorResolver(),
  });

  final RigAnchorResolver anchorResolver;

  @override
  void render(AvatarRenderContext context, AvatarRenderState state) {
    final neckStyle = context.string('v4.neckJewelry');
    final relicStyle = context.string('v4.relic');
    final earStyle = context.string('v4.earJewelry');
    if (neckStyle == 'none' && relicStyle == 'none' && earStyle == 'none') {
      return;
    }

    final anchors = <String, PixelPoint>{
      for (final anchor in anchorResolver.resolve(context.layout, state))
        anchor.id: anchor.localPosition,
    };
    final leftEar = anchors['leftEar.center'];
    final rightEar = anchors['rightEar.center'];
    final leftClavicle = anchors['leftClavicle'];
    final rightClavicle = anchors['rightClavicle'];
    if (leftClavicle == null || rightClavicle == null) return;

    state
      ..parentNode('leftEarJewelry', 'leftEar')
      ..parentNode('rightEarJewelry', 'rightEar')
      ..parentNode('necklace', 'torso')
      ..parentNode('necklaceLeft', 'necklace')
      ..parentNode('necklaceRight', 'necklace')
      ..parentNode('pendant', 'necklace')
      ..anchorNode('leftEarJewelry', 'leftEar.center')
      ..anchorNode('rightEarJewelry', 'rightEar.center')
      ..anchorNode('necklaceLeft', 'leftClavicle')
      ..anchorNode('necklaceRight', 'rightClavicle');

    // Remove flat jewelry/relic layers. Their visual content is reconstructed
    // below from explicit anchors and constraints.
    state.layers.removeWhere((layer) =>
        layer.id.startsWith('jewelry.') || layer.id.startsWith('relic.v42'));

    final earDark = PixelMask();
    final earBase = PixelMask();
    final earLight = PixelMask();
    if (earStyle != 'none') {
      if (leftEar != null) {
        _drawEarPiece(
          context,
          earStyle,
          leftEar,
          -1,
          earDark,
          earBase,
          earLight,
        );
      }
      if (rightEar != null) {
        _drawEarPiece(
          context,
          earStyle,
          rightEar,
          1,
          earDark,
          earBase,
          earLight,
        );
      }
    }

    final leftEarZone = PixelMask()
      ..fillRect(0, 0, 24, 48);
    final rightEarZone = PixelMask()
      ..fillRect(24, 0, 24, 48);
    _addJewelryLayers(
      context,
      state,
      prefix: 'jewelry.rig.leftEar',
      nodeId: 'leftEarJewelry',
      dark: earDark.intersect(leftEarZone),
      base: earBase.intersect(leftEarZone),
      light: earLight.intersect(leftEarZone),
      order: 186,
    );
    _addJewelryLayers(
      context,
      state,
      prefix: 'jewelry.rig.rightEar',
      nodeId: 'rightEarJewelry',
      dark: earDark.intersect(rightEarZone),
      base: earBase.intersect(rightEarZone),
      light: earLight.intersect(rightEarZone),
      order: 186,
    );

    if (neckStyle == 'none' && relicStyle == 'none') return;

    final size = clampInt(context.integer('v4.jewelrySize', 2), 1, 5);
    final chainStyle = relicStyle != 'none' ? relicStyle : neckStyle;
    final drop = _dropFor(chainStyle, size);
    final centerX = (leftClavicle.x + rightClavicle.x) ~/ 2;
    final baseY = (leftClavicle.y + rightClavicle.y) ~/ 2;
    final animated = animationChannelEnabled(
          context.string('v4.animation'),
          'jewelrySwing',
        ) ||
        context.string('v4.faceAnimation') != 'none';
    final speed = clampInt(context.integer('v4.animationSpeed', 3), 1, 6);
    final amplitude = clampInt(context.integer('v4.animationAmplitude', 2), 1, 3);
    final swing = animated
        ? cyclicOffset(
            context.phase - 2,
            animationPeriod(speed, slow: 22, fast: 10),
            amplitude,
          )
        : 0;
    var pendant = PixelPoint(centerX + swing, baseY + drop);
    final leftLength = _distance(leftClavicle, PixelPoint(centerX, baseY + drop));
    final rightLength = _distance(rightClavicle, PixelPoint(centerX, baseY + drop));
    for (var iteration = 0; iteration < 5; iteration++) {
      pendant = _project(pendant, leftClavicle, leftLength);
      pendant = _project(pendant, rightClavicle, rightLength);
    }

    final leftChain = PixelMask()
      ..line(leftClavicle.x, leftClavicle.y, pendant.x, pendant.y);
    final rightChain = PixelMask()
      ..line(rightClavicle.x, rightClavicle.y, pendant.x, pendant.y);
    final pendantBase = PixelMask();
    final pendantDark = PixelMask();
    final pendantLight = PixelMask();
    _drawPendant(
      chainStyle,
      pendant,
      size,
      pendantDark,
      pendantBase,
      pendantLight,
    );

    state
      ..putMask('necklace.left', leftChain)
      ..putMask('necklace.right', rightChain)
      ..putMask('necklace.pendant', pendantBase);

    state
      ..addLayer(
        'jewelry.rig.leftChain',
        186,
        leftChain,
        context.color('clothDark'),
        nodeId: 'necklaceLeft',
        slot: RenderSlot.frontArms,
        meta: const <String, Object?>{
          'part': 'jewelry',
          'constraint': 'left-chain-length',
        },
      )
      ..addLayer(
        'jewelry.rig.rightChain',
        186,
        rightChain,
        context.color('clothDark'),
        nodeId: 'necklaceRight',
        slot: RenderSlot.frontArms,
        meta: const <String, Object?>{
          'part': 'jewelry',
          'constraint': 'right-chain-length',
        },
      );
    _addJewelryLayers(
      context,
      state,
      prefix: 'jewelry.rig.pendant',
      nodeId: 'pendant',
      dark: pendantDark,
      base: pendantBase,
      light: pendantLight,
      order: 188,
    );

    state.metadata['jewelryRig'] = <String, Object>{
      'leftAnchor': leftClavicle.toJson(),
      'rightAnchor': rightClavicle.toJson(),
      'pendant': pendant.toJson(),
      'leftLength': leftLength,
      'rightLength': rightLength,
      'swing': swing,
      'solverIterations': 5,
    };
  }

  void _drawEarPiece(
    AvatarRenderContext context,
    String style,
    PixelPoint anchor,
    int side,
    PixelMask dark,
    PixelMask base,
    PixelMask light,
  ) {
    final size = clampInt(context.integer('v4.jewelrySize', 2), 1, 5);
    final animated = animationChannelEnabled(
          context.string('v4.animation'),
          'jewelrySwing',
        ) ||
        context.string('v4.faceAnimation') != 'none';
    final swing = animated
        ? cyclicOffset(
            context.phase - (side < 0 ? 1 : 3),
            animationPeriod(
              context.integer('v4.animationSpeed', 3),
              slow: 20,
              fast: 9,
            ),
            clampInt(context.integer('v4.animationAmplitude', 2), 1, 2),
          )
        : 0;
    if (style == 'stud' || style == 'pearl') {
      base.fillEllipse(anchor.x, anchor.y, 1, 1);
      light.set(anchor.x - 1, anchor.y - 1);
    } else if (style.contains('Hoop') || style == 'tunnel') {
      final outer = PixelMask()..fillEllipse(anchor.x, anchor.y + size, size, size);
      final inner = PixelMask()
        ..fillEllipse(anchor.x, anchor.y + size, clampInt(size - 1, 0, 4), clampInt(size - 1, 0, 4));
      base.data.setAll(0, base.union(outer.subtract(inner)).data);
    } else {
      final joint = PixelPoint(anchor.x + swing, anchor.y + size + 2);
      base.line(anchor.x, anchor.y, joint.x, joint.y);
      dark.set(anchor.x, anchor.y);
      light.fillEllipse(joint.x, joint.y, 1 + size ~/ 3, 1 + size ~/ 3);
    }
  }

  void _drawPendant(
    String style,
    PixelPoint point,
    int size,
    PixelMask dark,
    PixelMask base,
    PixelMask light,
  ) {
    if (style.contains('dogTag') || style == 'dogTags') {
      base.fillRect(point.x - 2, point.y - 1, 4, 6);
      dark.hLine(point.x - 2, point.x + 1, point.y + 4);
    } else if (style.contains('crystal') || style.contains('Crystal')) {
      base.fillTriangle(
        (x: point.x - size, y: point.y),
        (x: point.x + size, y: point.y),
        (x: point.x, y: point.y + size + 4),
      );
      light.line(point.x, point.y, point.x - 1, point.y + size + 2);
    } else if (style.contains('fang') || style.contains('bone')) {
      base.fillTriangle(
        (x: point.x - 2, y: point.y),
        (x: point.x + 2, y: point.y),
        (x: point.x, y: point.y + size + 4),
      );
      dark.set(point.x, point.y + size + 3);
    } else {
      base.fillEllipse(point.x, point.y + size, size + 1, size + 1);
      dark.data.setAll(0, base.outline(diagonal: true).data);
      light.set(point.x - 1, point.y + size - 1);
    }
  }

  void _addJewelryLayers(
    AvatarRenderContext context,
    AvatarRenderState state, {
    required String prefix,
    required String nodeId,
    required PixelMask dark,
    required PixelMask base,
    required PixelMask light,
    required int order,
  }) {
    state
      ..addLayer(
        '$prefix.dark',
        order,
        dark,
        context.color('clothDark'),
        nodeId: nodeId,
        slot: RenderSlot.frontArms,
        meta: const <String, Object?>{'part': 'jewelry'},
      )
      ..addLayer(
        '$prefix.base',
        order + 1,
        base,
        context.color('fantasyLight'),
        nodeId: nodeId,
        slot: RenderSlot.frontArms,
        meta: const <String, Object?>{'part': 'jewelry'},
      )
      ..addLayer(
        '$prefix.light',
        order + 2,
        light,
        context.color('white'),
        nodeId: nodeId,
        slot: RenderSlot.frontArms,
        meta: const <String, Object?>{'part': 'jewelry'},
      );
  }

  int _dropFor(String style, int size) {
    if (style == 'choker') return 3;
    if (style == 'thinChain' || style == 'thickChain') return 5 + size;
    if (style.contains('Large') || style.contains('royal') || style.contains('sacred')) {
      return 10 + size;
    }
    return 7 + size;
  }

  double _distance(PixelPoint first, PixelPoint second) {
    final dx = (first.x - second.x).toDouble();
    final dy = (first.y - second.y).toDouble();
    return math.sqrt(dx * dx + dy * dy);
  }

  PixelPoint _project(PixelPoint point, PixelPoint anchor, double length) {
    final dx = point.x - anchor.x;
    final dy = point.y - anchor.y;
    final distance = math.sqrt((dx * dx + dy * dy).toDouble());
    if (distance == 0) return PixelPoint(anchor.x, anchor.y + length.round());
    final scale = length / distance;
    return PixelPoint(
      anchor.x + (dx * scale).round(),
      anchor.y + (dy * scale).round(),
    );
  }
}
