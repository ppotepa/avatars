import '../../util/math_utils.dart';
import '../render_helpers.dart';
import '../render_model.dart';

/// Applies primary body motion through the hierarchical rig.
///
/// The renderer runs after actor geometry has been created, so translating a
/// node moves every attached child: clothing, armor, neck, head equipment and
/// other descendants remain connected automatically.
final class AvatarMotionRenderer implements AvatarPartRenderer {
  const AvatarMotionRenderer();

  @override
  void render(AvatarRenderContext context, AvatarRenderState state) {
    final animation = context.string('v4.animation');
    final faceAnimation = context.string('v4.faceAnimation');
    final pose = context.string('v4.poseMotion');
    final speed = clampInt(
      context.integer('v4.motionSpeed', context.integer('v4.animationSpeed', 3)),
      1,
      6,
    );
    final amplitude = clampInt(
      context.integer(
        'v4.motionIntensity',
        context.integer('v4.animationAmplitude', 2),
      ),
      0,
      5,
    );
    if (amplitude == 0) return;

    final period = animationPeriod(speed, slow: 24, fast: 10);
    final phase = context.phase + context.integer('v4.motionPhaseOffset');
    final active = animation != 'none' ||
        faceAnimation != 'none' ||
        pose != 'none';
    if (!active) return;

    var torsoDy = 0;
    var headDy = 0;
    var headDx = 0;

    if (animation == 'idle' || pose == 'breathe') {
      final breath = cyclicOffset(
        phase,
        period,
        clampInt((amplitude + 1) ~/ 2, 1, 2),
      );
      torsoDy = breath > 0 ? 1 : 0;
      headDy = cyclicOffset(phase - 2, period, 1) > 0 ? 1 : 0;
      headDx = cyclicOffset(phase - 5, period * 3, 1);
    }

    if (animation == 'lookAround') {
      headDx = cyclicOffset(phase, period, clampInt(amplitude, 1, 2));
    }

    if (faceAnimation == 'talk') {
      headDy += cyclicOffset(phase, clampInt(period ~/ 2, 5, period), 1);
      torsoDy += cyclicOffset(phase - 2, period, 1) > 0 ? 1 : 0;
    } else if (faceAnimation == 'laugh') {
      headDy += cyclicOffset(phase, clampInt(period ~/ 2, 4, period), 2);
      torsoDy += cyclicOffset(phase - 1, clampInt(period ~/ 2, 4, period), 1);
      headDx += cyclicOffset(phase - 2, period, 1);
    } else if (faceAnimation == 'angry') {
      headDy -= cyclicOffset(phase, period, 1).abs();
      headDx += cyclicOffset(phase, clampInt(period ~/ 3, 4, period), 1);
    } else if (faceAnimation == 'sad') {
      headDy += 1;
      torsoDy += cyclicOffset(phase, period * 2, 1) > 0 ? 1 : 0;
    } else if (faceAnimation == 'surprised') {
      headDy -= positiveMod(phase, period) < 3 ? 2 : 0;
      torsoDy += positiveMod(phase, period) < 3 ? 1 : 0;
    } else if (faceAnimation == 'sleepy') {
      headDy += cyclicOffset(phase, period * 2, 1) >= 0 ? 1 : 0;
    }

    if (pose == 'headNod') {
      headDy += cyclicOffset(phase, period, 1);
    } else if (pose == 'headTilt') {
      headDx += cyclicOffset(phase, period * 2, 1);
    } else if (pose == 'tinyShake') {
      headDx += cyclicOffset(phase, clampInt(period ~/ 3, 4, period), 1);
    } else if (pose == 'proudPose') {
      headDy -= 1;
      torsoDy -= 1;
    } else if (pose == 'shyLookAway') {
      headDx += cyclicOffset(phase, period * 2, 1);
      headDy += 1;
    }

    torsoDy = _safeDy(state, 'torso', torsoDy);
    state.translateNode('torso', dx: 0, dy: torsoDy);

    // Neck receives a smaller delayed correction before the head, preserving a
    // readable joint while avoiding the previous rigid single-block motion.
    final neckDy = _safeDy(
      state,
      'neck',
      torsoDy == 0 ? 0 : (cyclicOffset(phase - 1, period, 1) > 0 ? 1 : 0),
    );
    state.translateNode('neck', dx: 0, dy: neckDy);

    headDx = _safeDx(state, 'head', headDx);
    headDy = _safeDy(state, 'head', headDy);
    state.translateNode('head', dx: headDx, dy: headDy);

    state.metadata['primaryRigMotion'] = <String, Object>{
      'phase': phase,
      'animation': animation,
      'faceAnimation': faceAnimation,
      'pose': pose,
      'torso': <String, int>{'dx': 0, 'dy': torsoDy},
      'neck': <String, int>{'dx': 0, 'dy': neckDy},
      'head': <String, int>{'dx': headDx, 'dy': headDy},
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
    return clampInt(requested, -left, width - 1 - right);
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
    return clampInt(requested, -top, height - 1 - bottom);
  }
}
