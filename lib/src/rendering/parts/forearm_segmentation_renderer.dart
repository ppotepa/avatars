import '../../geometry/point.dart';
import '../../pixels/pixel_mask.dart';
import '../render_model.dart';
import '../rig_model.dart';

/// Refines generated arm geometry into upper-arm and forearm segments.
///
/// Segmentation is derived from the shoulder-to-wrist axis instead of a global
/// horizontal cut. Every color layer uses the same ownership map and the two
/// segments overlap around the elbow, preventing animated seams.
final class ForearmSegmentationRenderer implements AvatarPartRenderer {
  const ForearmSegmentationRenderer();

  @override
  void render(AvatarRenderContext context, AvatarRenderState state) {
    final output = <RenderLayer>[];
    final segments = <String, Object>{};
    final runtimeAnchors = <Map<String, Object?>>[];

    for (final side in const <String>['left', 'right']) {
      final armNode = '${side}Arm';
      final forearmNode = '${side}Forearm';
      final wristNode = '${side}Wrist';
      final handNode = '${side}Hand';
      final sideLayers = state.layers
          .where((layer) => layer.nodeId == armNode)
          .toList(growable: false);
      final combined = _union(sideLayers.map((layer) => layer.mask));
      final bounds = combined.bounds;
      if (bounds == null) continue;

      final shoulder = PixelPoint(
        side == 'left' ? bounds.right : bounds.left,
        bounds.top,
      );
      final wrist = PixelPoint(bounds.center.x, bounds.bottom);
      final elbow = PixelPoint(
        (shoulder.x + wrist.x) ~/ 2,
        (shoulder.y + wrist.y) ~/ 2,
      );
      final ownership = _ownershipMap(combined, shoulder, wrist);

      for (final layer in sideLayers) {
        final upper = layer.mask.intersect(ownership.upper);
        final forearm = layer.mask.intersect(ownership.forearm);
        if (upper.count > 0) {
          output.add(layer.copyWith(
            mask: upper,
            meta: <String, Object?>{
              ...layer.meta,
              'rigSegment': armNode,
              'segmentAxis': 'shoulder-elbow',
            },
          ));
        }
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
              'segmentAxis': 'elbow-wrist',
            },
          ));
        }
      }

      state
        ..parentNode(forearmNode, armNode)
        ..parentNode(wristNode, forearmNode)
        ..parentNode(handNode, wristNode)
        ..putMask(armNode, combined.intersect(ownership.upper))
        ..putMask(forearmNode, combined.intersect(ownership.forearm))
        ..anchorNode(forearmNode, '$forearmNode.elbow')
        ..anchorNode(wristNode, '$wristNode.center')
        ..anchorNode(handNode, '$wristNode.center');

      runtimeAnchors
        ..add(<String, Object?>{
          'id': '$forearmNode.elbow',
          'nodeId': forearmNode,
          'x': elbow.x,
          'y': elbow.y,
        })
        ..add(<String, Object?>{
          'id': '$wristNode.center',
          'nodeId': wristNode,
          'x': wrist.x,
          'y': wrist.y,
        });

      segments[side] = <String, Object>{
        'shoulder': <String, int>{'x': shoulder.x, 'y': shoulder.y},
        'elbow': <String, int>{'x': elbow.x, 'y': elbow.y},
        'wrist': <String, int>{'x': wrist.x, 'y': wrist.y},
        'upperPixels': state.mask(armNode).count,
        'forearmPixels': state.mask(forearmNode).count,
        'seamPixels': ownership.upper.intersect(ownership.forearm).count,
      };
    }

    if (segments.isEmpty) return;
    final retained = state.layers
        .where((layer) =>
            layer.nodeId != 'leftArm' && layer.nodeId != 'rightArm')
        .toList(growable: false);
    state.layers
      ..clear()
      ..addAll(retained)
      ..addAll(output);

    final existing = state.metadata['runtimeAnchors'];
    state.metadata
      ..['runtimeAnchors'] = <Object?>[
        if (existing is List) ...existing,
        ...runtimeAnchors,
      ]
      ..['forearmRig'] = segments;
  }

  ({PixelMask upper, PixelMask forearm}) _ownershipMap(
    PixelMask arm,
    PixelPoint shoulder,
    PixelPoint wrist,
  ) {
    final upper = PixelMask(width: arm.width, height: arm.height);
    final forearm = PixelMask(width: arm.width, height: arm.height);
    final axisX = wrist.x - shoulder.x;
    final axisY = wrist.y - shoulder.y;
    final lengthSquared = axisX * axisX + axisY * axisY;
    if (lengthSquared == 0) {
      return (upper: arm.clone(), forearm: PixelMask(width: arm.width, height: arm.height));
    }

    for (var y = 0; y < arm.height; y++) {
      for (var x = 0; x < arm.width; x++) {
        if (arm.get(x, y) == 0) continue;
        final relativeX = x - shoulder.x;
        final relativeY = y - shoulder.y;
        final projection =
            (relativeX * axisX + relativeY * axisY) / lengthSquared;
        if (projection <= .58) upper.set(x, y);
        if (projection >= .42) forearm.set(x, y);
      }
    }
    return (upper: upper, forearm: forearm);
  }

  PixelMask _union(Iterable<PixelMask> masks) {
    PixelMask? result;
    for (final mask in masks) {
      result = result == null ? mask.clone() : result.union(mask);
    }
    return result ?? PixelMask();
  }
}
