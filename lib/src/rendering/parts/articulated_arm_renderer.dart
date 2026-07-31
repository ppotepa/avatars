import '../../pixels/pixel_mask.dart';
import '../../util/math_utils.dart';
import '../render_model.dart';
import '../rig_model.dart';

/// Splits side geometry from torso/clothing/armor layers into real arm nodes.
///
/// The anatomy renderer historically unions visible arms into the torso mask.
/// This post-process keeps the generated silhouette but gives arm pixels an
/// independent owner and shoulder pivot for animation.
final class ArticulatedArmRenderer implements AvatarPartRenderer {
  const ArticulatedArmRenderer();

  @override
  void render(AvatarRenderContext context, AvatarRenderState state) {
    if (context.integer('body.armVisibility') <= 0) return;
    final torso = state.mask('torso');
    final bounds = torso.bounds;
    if (bounds == null) return;

    final top = context.integer('torso.topY', bounds.top);
    final centerX = bounds.center.x;
    final topWidth = clampInt(context.integer('torso.widthTop', 30), 18, 48);
    final bottomWidth = clampInt(context.integer('torso.widthBottom', 34), 18, 48);
    final armBottom = clampInt(
      top + 5 + context.integer('body.armVisibility') * 2,
      top + 3,
      bounds.bottom,
    );

    bool armPixel(int x, int y, {required bool left}) {
      if (y < top + 2 || y > armBottom) return false;
      final t = (y - top) / (bounds.bottom - top).clamp(1, 99);
      final coreWidth =
          (topWidth + (bottomWidth - topWidth) * t).round();
      final leftCore = centerX - coreWidth ~/ 2;
      final rightCore = centerX + coreWidth ~/ 2;
      return left ? x < leftCore : x > rightCore;
    }

    final leftZone = PixelMask(width: torso.width, height: torso.height);
    final rightZone = PixelMask(width: torso.width, height: torso.height);
    for (var y = 0; y < torso.height; y++) {
      for (var x = 0; x < torso.width; x++) {
        if (armPixel(x, y, left: true)) leftZone.set(x, y);
        if (armPixel(x, y, left: false)) rightZone.set(x, y);
      }
    }

    // Extremely broad torsos can cover the generated arm extension completely.
    // Reserve the outer edge of each occupied row so animation never targets an
    // empty arm node.
    if (torso.intersect(leftZone).count == 0 ||
        torso.intersect(rightZone).count == 0) {
      for (var y = top + 2; y <= armBottom; y++) {
        final row = _rowBounds(torso, y);
        if (row == null) continue;
        leftZone
          ..set(row.$1, y)
          ..set(row.$1 + 1, y);
        rightZone
          ..set(row.$2, y)
          ..set(row.$2 - 1, y);
      }
    }

    final replacement = <RenderLayer>[];
    final leftCombined = PixelMask(width: torso.width, height: torso.height);
    final rightCombined = PixelMask(width: torso.width, height: torso.height);

    for (final layer in state.layers) {
      final splittable = <String>{'torso', 'clothing', 'armor', 'chest'}
          .contains(layer.nodeId);
      if (!splittable) {
        replacement.add(layer);
        continue;
      }
      final left = layer.mask.intersect(leftZone);
      final right = layer.mask.intersect(rightZone);
      final core = layer.mask.subtract(left.union(right));
      if (core.count > 0) replacement.add(layer.copyWith(mask: core));
      if (left.count > 0) {
        leftCombined.data.setAll(0, leftCombined.union(left).data);
        replacement.add(layer.copyWith(
          mask: left,
          nodeId: 'leftArm',
          slot: RenderSlot.frontArms,
          meta: <String, Object?>{
            ...layer.meta,
            'sourceNodeId': layer.nodeId,
            'rigSegment': 'leftArm',
          },
        ));
      }
      if (right.count > 0) {
        rightCombined.data.setAll(0, rightCombined.union(right).data);
        replacement.add(layer.copyWith(
          mask: right,
          nodeId: 'rightArm',
          slot: RenderSlot.frontArms,
          meta: <String, Object?>{
            ...layer.meta,
            'sourceNodeId': layer.nodeId,
            'rigSegment': 'rightArm',
          },
        ));
      }
    }

    state.layers
      ..clear()
      ..addAll(replacement);

    PixelMask handFrom(PixelMask arm) {
      final armBounds = arm.bounds;
      if (armBounds == null) return PixelMask(width: arm.width, height: arm.height);
      final handZone = PixelMask(width: arm.width, height: arm.height)
        ..fillRect(
          armBounds.left,
          clampInt(armBounds.bottom - 1, armBounds.top, armBounds.bottom),
          armBounds.width,
          2,
        );
      return arm.intersect(handZone);
    }

    final leftHand = handFrom(leftCombined);
    final rightHand = handFrom(rightCombined);
    state
      ..putMask('leftArm', leftCombined)
      ..putMask('rightArm', rightCombined)
      ..putMask('leftHand', leftHand)
      ..putMask('rightHand', rightHand)
      ..parentNode('leftArm', 'leftShoulder')
      ..parentNode('rightArm', 'rightShoulder')
      ..parentNode('leftHand', 'leftArm')
      ..parentNode('rightHand', 'rightArm');

    state.metadata['armRig'] = <String, Object>{
      'leftPixels': leftCombined.count,
      'rightPixels': rightCombined.count,
      'leftHandPixels': leftHand.count,
      'rightHandPixels': rightHand.count,
      'armBottom': armBottom,
    };
  }

  (int, int)? _rowBounds(PixelMask mask, int y) {
    var left = mask.width;
    var right = -1;
    for (var x = 0; x < mask.width; x++) {
      if (mask.get(x, y) == 0) continue;
      if (x < left) left = x;
      if (x > right) right = x;
    }
    return right < left ? null : (left, right);
  }
}
