import '../../pixels/pixel_mask.dart';
import '../render_model.dart';
import '../rig_model.dart';

/// Refines the existing articulated arm output into upper-arm, forearm and hand
/// segments. Segmentation follows the current generated geometry, so it does not
/// change the rest silhouette but gives gestures an elbow and wrist pivot.
final class ForearmSegmentationRenderer implements AvatarPartRenderer {
  const ForearmSegmentationRenderer();

  @override
  void render(AvatarRenderContext context, AvatarRenderState state) {
    final output = <RenderLayer>[];
    final segments = <String, Object>{};

    for (final side in const <String>['left', 'right']) {
      final armNode = '${side}Arm';
      final forearmNode = '${side}Forearm';
      final handNode = '${side}Hand';
      final sideLayers = state.layers.where((layer) => layer.nodeId == armNode).toList();
      final combined = _union(sideLayers.map((layer) => layer.mask));
      final bounds = combined.bounds;
      if (bounds == null) continue;
      final elbowY = bounds.top + (bounds.height * .48).round();
      final forearmZone = PixelMask(width: combined.width, height: combined.height)
        ..fillRect(0, elbowY, combined.width, combined.height - elbowY);

      for (final layer in state.layers) {
        if (layer.nodeId != armNode) continue;
        final forearm = layer.mask.intersect(forearmZone);
        final upper = layer.mask.subtract(forearm);
        if (upper.count > 0) output.add(layer.copyWith(mask: upper));
        if (forearm.count > 0) {
          output.add(layer.copyWith(
            mask: forearm,
            nodeId: forearmNode,
            slot: RenderSlot.frontArms,
            localOrder: layer.localOrder + 1,
            meta: <String, Object?>{
              ...layer.meta,
              'rigSegment': forearmNode,
              'sourceArmNode': armNode,
            },
          ));
        }
      }

      state
        ..parentNode(forearmNode, armNode)
        ..parentNode(handNode, forearmNode)
        ..putMask(armNode, combined.subtract(combined.intersect(forearmZone)))
        ..putMask(forearmNode, combined.intersect(forearmZone));
      segments[side] = <String, Object>{
        'elbowY': elbowY,
        'upperPixels': state.mask(armNode).count,
        'forearmPixels': state.mask(forearmNode).count,
      };
    }

    if (segments.isEmpty) return;
    final retained = state.layers.where((layer) => layer.nodeId != 'leftArm' && layer.nodeId != 'rightArm').toList();
    state.layers
      ..clear()
      ..addAll(retained)
      ..addAll(output);
    state.metadata['forearmRig'] = segments;
  }

  PixelMask _union(Iterable<PixelMask> masks) {
    PixelMask? result;
    for (final mask in masks) {
      result = result == null ? mask.clone() : result.union(mask);
    }
    return result ?? PixelMask();
  }
}
