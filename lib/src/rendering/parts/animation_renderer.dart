import '../../util/math_utils.dart';
import '../render_helpers.dart';
import '../render_model.dart';

/// Applies animation channels that affect the already composed avatar body.
///
/// Local channels such as blinking, eye movement, hair wind and jewelry swing
/// are owned by their respective part renderers. This renderer handles only
/// whole-avatar transforms, preserving single responsibility and allowing it
/// to be replaced by an application-specific animation policy.
final class AvatarMotionRenderer implements AvatarPartRenderer {
  const AvatarMotionRenderer();

  @override
  void render(AvatarRenderContext context, AvatarRenderState state) {
    if (!animationChannelEnabled(
      context.string('v4.animation'),
      'idle',
    )) {
      return;
    }

    final amplitude = context.rendering.reducedMotion
        ? 1
        : clampInt(context.integer('v4.animationAmplitude'), 1, 4);
    final speed = clampInt(context.integer('v4.animationSpeed'), 1, 6);
    final motionPhase =
        context.rendering.reducedMotion ? context.phase ~/ 2 : context.phase;
    final dy = cyclicOffset(
      motionPhase,
      animationPeriod(speed, slow: 20, fast: 12),
      clampInt((amplitude + 1) ~/ 2, 1, 2),
    );
    if (dy == 0) return;

    state.translateWhere(
      dx: 0,
      dy: dy,
      includeMask: (id) => !_isWorldSpace(id),
      includeLayer: (layer) => !_isWorldSpace(layer.id),
    );
  }

  bool _isWorldSpace(String id) {
    return id.startsWith('background') ||
        id.startsWith('effect.') ||
        id.startsWith('aura.');
  }
}
