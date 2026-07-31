import '../animation_controller.dart';
import '../render_model.dart';
import '../rig_model.dart';

/// Applies the centralized animation sample to the hierarchical rig.
final class AvatarMotionRenderer implements AvatarPartRenderer {
  const AvatarMotionRenderer({
    this.controller = const RigAnimationController(),
  });

  final RigAnimationController controller;

  @override
  void render(AvatarRenderContext context, AvatarRenderState state) {
    final sample = controller.sample(context);
    if (sample.transforms.isEmpty && sample.events.isEmpty) return;

    final graph = state.buildRigGraph();
    final order = graph.topologicalOrder();
    for (final nodeId in order) {
      final transform = sample.transformFor(nodeId);
      if (transform.isIdentity) continue;
      final dx = _safeDx(state, nodeId, transform.dx);
      final dy = _safeDy(state, nodeId, transform.dy);
      state.translateNode(nodeId, dx: dx, dy: dy);
      if (transform.rotationDegrees != 0) {
        // Rotation becomes an explicit pose property now. Pixel masks are
        // rotated by the clip pipeline after overscan is applied, avoiding
        // destructive edge clipping on the canonical 48x48 geometry.
        state.setNodeTransform(
          nodeId,
          RigTransform(
            dx: dx,
            dy: dy,
            rotationDegrees: transform.rotationDegrees,
            pivotX: transform.pivotX,
            pivotY: transform.pivotY,
          ),
        );
      }
    }

    state.metadata['motionSample'] = sample.toJson();
    state.metadata['idleRigChannels'] = <String, Object>{
      'breathing': sample.channelWeights['body'] ?? 0,
      'headMicroMotion': sample.channelWeights['head'] ?? 0,
      'secondaryMotion': sample.channelWeights['secondary'] ?? 0,
      'events': sample.events.toList(growable: false),
    };
  }

  int _safeDx(AvatarRenderState state, String nodeId, int requested) {
    if (requested == 0) return 0;
    final ids = state.nodeAndDescendants(nodeId);
    var left = 1 << 30;
    var right = -1;
    var width = 48;
    for (final layer in state.layers) {
      if (!ids.contains(layer.nodeId)) continue;
      width = layer.mask.width;
      final bounds = layer.mask.bounds;
      if (bounds == null) continue;
      if (bounds.left < left) left = bounds.left;
      if (bounds.right > right) right = bounds.right;
    }
    if (right < left) return 0;
    return requested.clamp(-left, width - 1 - right).toInt();
  }

  int _safeDy(AvatarRenderState state, String nodeId, int requested) {
    if (requested == 0) return 0;
    final ids = state.nodeAndDescendants(nodeId);
    var top = 1 << 30;
    var bottom = -1;
    var height = 48;
    for (final layer in state.layers) {
      if (!ids.contains(layer.nodeId)) continue;
      height = layer.mask.height;
      final bounds = layer.mask.bounds;
      if (bounds == null) continue;
      if (bounds.top < top) top = bounds.top;
      if (bounds.bottom > bottom) bottom = bounds.bottom;
    }
    if (bottom < top) return 0;
    return requested.clamp(-top, height - 1 - bottom).toInt();
  }
}
