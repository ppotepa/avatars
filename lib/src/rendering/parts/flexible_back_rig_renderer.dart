import '../../pixels/pixel_mask.dart';
import '../../util/math_utils.dart';
import '../render_helpers.dart';
import '../render_model.dart';
import '../rig_anchor_resolver.dart';
import '../rig_model.dart';

/// Routes back wearables to rigid, cloth-chain or articulated-wing strategies.
final class FlexibleBackRigRenderer implements AvatarPartRenderer {
  const FlexibleBackRigRenderer({
    this.anchorResolver = const RigAnchorResolver(),
  });

  static const Set<String> _softCapeStyles = <String>{
    'shortCape',
    'longCape',
    'scarfBack',
  };
  static const Set<String> _wingCapeStyles = <String>{
    'angelWings',
    'demonWings',
    'dragonWings',
    'mechanicalWings',
  };
  static const Set<String> _softBackStyles = <String>{
    'spiritRibbon',
    'prayerScrollBack',
    'capeTorn',
    'capeRoyal',
    'cloakStarry',
  };

  final RigAnchorResolver anchorResolver;

  @override
  void render(AvatarRenderContext context, AvatarRenderState state) {
    final capeStyle = context.string('v4.cape');
    final backStyle = context.string('v4.backAdornment');
    if (capeStyle == 'none' && backStyle == 'none') return;

    final anchors = anchorResolver.resolve(context.layout, state);
    for (final anchor in anchors.where((item) => item.id.startsWith('cape.'))) {
      state.anchorNode(anchor.nodeId, anchor.id);
    }
    state
      ..parentNode('cape', 'torso')
      ..parentNode('rigidBackWearable', 'torso')
      ..parentNode('capeLeftRoot', 'leftShoulder')
      ..parentNode('capeRightRoot', 'rightShoulder')
      ..parentNode('capeCenter', 'torso')
      ..parentNode('capeMidLeft', 'capeLeftRoot')
      ..parentNode('capeMidRight', 'capeRightRoot')
      ..parentNode('capeTipLeft', 'capeMidLeft')
      ..parentNode('capeTipRight', 'capeMidRight')
      ..parentNode('leftWingRoot', 'torso')
      ..parentNode('leftWingMid', 'leftWingRoot')
      ..parentNode('leftWingTip', 'leftWingMid')
      ..parentNode('rightWingRoot', 'torso')
      ..parentNode('rightWingMid', 'rightWingRoot')
      ..parentNode('rightWingTip', 'rightWingMid');

    final combined = <RenderLayer>[];
    for (final layer in state.layers) {
      if (layer.id.startsWith('cape.')) {
        if (_softCapeStyles.contains(capeStyle)) {
          combined.addAll(_splitCloth(context, layer));
        } else if (_wingCapeStyles.contains(capeStyle)) {
          combined.addAll(_splitWings(context, layer));
        } else {
          combined.add(_rigid(layer, capeStyle));
        }
      } else if (layer.id.startsWith('backAdornment.v42')) {
        final winged = backStyle.contains('wings') || backStyle.contains('Wings');
        if (winged) {
          combined.addAll(_splitWings(context, layer));
        } else if (_softBackStyles.contains(backStyle)) {
          combined.addAll(_splitCloth(context, layer));
        } else {
          combined.add(_rigid(layer, backStyle));
        }
      } else {
        combined.add(layer);
      }
    }
    state.layers
      ..clear()
      ..addAll(combined);

    state.metadata['backRig'] = <String, Object>{
      'capeStyle': capeStyle,
      'capeStrategy': _strategy(capeStyle),
      'backStyle': backStyle,
      'backStrategy': _strategy(backStyle),
      'anchors': <String, Object>{
        for (final anchor in anchors.where((item) => item.id.startsWith('cape.')))
          anchor.id: anchor.localPosition.toJson(),
      },
    };
  }

  String _strategy(String style) {
    if (style == 'none') return 'none';
    if (_softCapeStyles.contains(style) || _softBackStyles.contains(style)) {
      return 'clothChain';
    }
    if (_wingCapeStyles.contains(style) ||
        style.contains('wings') ||
        style.contains('Wings')) {
      return 'articulatedWings';
    }
    return 'rigidBackWearable';
  }

  RenderLayer _rigid(RenderLayer source, String style) => source.copyWith(
        nodeId: 'rigidBackWearable',
        slot: RenderSlot.capeHairBack,
        meta: <String, Object?>{
          ...source.meta,
          'attachmentKind': 'rigidBackWearable',
          'backStyle': style,
        },
      );

  List<RenderLayer> _splitCloth(
    AvatarRenderContext context,
    RenderLayer source,
  ) {
    final bounds = source.mask.bounds;
    if (bounds == null) return <RenderLayer>[];
    final centerX = bounds.center.x;
    final rootY = clampInt(bounds.top + 3, bounds.top, bounds.bottom);
    final middleY = clampInt(
      bounds.top + bounds.height * 2 ~/ 3,
      rootY,
      bounds.bottom,
    );
    final left = _zone(source.mask, (x, y) => x < centerX);
    final right = _zone(source.mask, (x, y) => x >= centerX);
    final center = _zone(
      source.mask,
      (x, y) => (x - centerX).abs() <= 2 && y <= rootY + 4,
    );

    final leftRoot = _zone(left, (x, y) => y <= rootY);
    final leftMid = _zone(left, (x, y) => y > rootY && y <= middleY);
    final leftTip = _zone(left, (x, y) => y > middleY);
    final rightRoot = _zone(right, (x, y) => y <= rootY);
    final rightMid = _zone(right, (x, y) => y > rootY && y <= middleY);
    final rightTip = _zone(right, (x, y) => y > middleY);

    final speed = clampInt(context.integer('v4.animationSpeed', 3), 1, 6);
    final period = animationPeriod(speed, slow: 24, fast: 11);
    final active = context.string('v4.animation') != 'none' ||
        context.string('v4.faceAnimation') != 'none';
    final middleSwing = active ? cyclicOffset(context.phase - 2, period, 1) : 0;
    final tipSwing = active ? cyclicOffset(context.phase - 5, period, 2) : 0;

    return _pieces(
      source,
      <(String, PixelMask)>[
        ('capeCenter', center),
        ('capeLeftRoot', leftRoot),
        ('capeMidLeft', leftMid.translated(middleSwing, 0)),
        ('capeTipLeft', leftTip.translated(tipSwing, 0)),
        ('capeRightRoot', rightRoot),
        ('capeMidRight', rightMid.translated(middleSwing, 0)),
        ('capeTipRight', rightTip.translated(tipSwing, 0)),
      ],
    );
  }

  List<RenderLayer> _splitWings(
    AvatarRenderContext context,
    RenderLayer source,
  ) {
    final bounds = source.mask.bounds;
    if (bounds == null) return <RenderLayer>[];
    final centerX = bounds.center.x;
    final left = _zone(source.mask, (x, y) => x < centerX);
    final right = _zone(source.mask, (x, y) => x >= centerX);
    final leftWidth = clampInt(left.bounds?.width ?? 1, 1, 48);
    final rightWidth = clampInt(right.bounds?.width ?? 1, 1, 48);
    final leftRootLimit = centerX - leftWidth ~/ 3;
    final leftTipLimit = centerX - leftWidth * 2 ~/ 3;
    final rightRootLimit = centerX + rightWidth ~/ 3;
    final rightTipLimit = centerX + rightWidth * 2 ~/ 3;

    final leftRoot = _zone(left, (x, y) => x >= leftRootLimit);
    final leftMid = _zone(left, (x, y) => x < leftRootLimit && x >= leftTipLimit);
    final leftTip = _zone(left, (x, y) => x < leftTipLimit);
    final rightRoot = _zone(right, (x, y) => x <= rightRootLimit);
    final rightMid = _zone(right, (x, y) => x > rightRootLimit && x <= rightTipLimit);
    final rightTip = _zone(right, (x, y) => x > rightTipLimit);

    final speed = clampInt(context.integer('v4.animationSpeed', 3), 1, 6);
    final period = animationPeriod(speed, slow: 18, fast: 8);
    final active = context.string('v4.animation') != 'none' ||
        context.string('v4.faceAnimation') != 'none';
    final flap = active ? cyclicOffset(context.phase, period, 1) : 0;
    final tip = active ? cyclicOffset(context.phase - 3, period, 2) : 0;

    return _pieces(
      source,
      <(String, PixelMask)>[
        ('leftWingRoot', leftRoot),
        ('leftWingMid', leftMid.translated(-flap, flap.abs())),
        ('leftWingTip', leftTip.translated(-tip, tip.abs())),
        ('rightWingRoot', rightRoot),
        ('rightWingMid', rightMid.translated(flap, flap.abs())),
        ('rightWingTip', rightTip.translated(tip, tip.abs())),
      ],
    );
  }

  List<RenderLayer> _pieces(
    RenderLayer source,
    List<(String, PixelMask)> pieces,
  ) {
    final output = <RenderLayer>[];
    var index = 0;
    for (final piece in pieces) {
      if (piece.$2.count == 0) continue;
      output.add(RenderLayer(
        id: '${source.id}.rig$index',
        z: source.z,
        mask: piece.$2,
        colorIndex: source.colorIndex,
        nodeId: piece.$1,
        slot: source.slot,
        localOrder: source.localOrder + index,
        meta: <String, Object?>{
          ...source.meta,
          'sourceLayerId': source.id,
          'rigSegment': piece.$1,
        },
      ));
      index++;
    }
    return output;
  }

  PixelMask _zone(PixelMask source, bool Function(int x, int y) predicate) {
    final output = PixelMask(width: source.width, height: source.height);
    for (var y = 0; y < source.height; y++) {
      for (var x = 0; x < source.width; x++) {
        if (source.get(x, y) != 0 && predicate(x, y)) output.set(x, y);
      }
    }
    return output;
  }
}
