import 'animation_controller.dart';
import 'render_helpers.dart';
import 'render_model.dart';
import 'rig_model.dart';

/// Adds deterministic hand and forearm gestures on top of the emotion profile.
/// Gestures target semantic regions (mouth, cheeks, hips or guard position)
/// instead of merely increasing the rotation of the complete arm.
final class SemanticGesturePolicy {
  const SemanticGesturePolicy();

  MotionSample augment(AvatarRenderContext context, MotionSample base) {
    final transforms = <String, RigTransform>{...base.transforms};
    final events = <String>{...base.events};
    final weights = <String, double>{...base.channelWeights};
    final profile = _profile(context);
    final phase = base.phase;
    final random = context.random('rig.gesture.$profile');
    final variant = random.nextInt(0, 4);
    final pulse = cyclicOffset(phase, animationPeriod(3, slow: 18, fast: 8), 1);

    void merge(String nodeId, {int dx = 0, int dy = 0, int rotation = 0}) {
      final current = transforms[nodeId] ?? RigTransform.identity;
      transforms[nodeId] = RigTransform(
        dx: current.dx + dx,
        dy: current.dy + dy,
        rotationDegrees: current.rotationDegrees + rotation,
        pivotX: current.pivotX,
        pivotY: current.pivotY,
      );
    }

    switch (profile) {
      case 'laugh':
        if (variant == 0 && context.string('v4.mouthProp') == 'none') {
          merge('leftArm', rotation: -18);
          merge('leftForearm', rotation: -48 + pulse * 4);
          merge('leftHand', dx: 3, dy: -8, rotation: 12);
          events.addAll(<String>{'gestureCoverMouth', 'handShapeCovering'});
        } else if (variant == 1) {
          merge('leftArm', rotation: 12);
          merge('rightArm', rotation: -12);
          merge('leftForearm', rotation: 32);
          merge('rightForearm', rotation: -32);
          merge('leftHand', dx: 2, dy: 2);
          merge('rightHand', dx: -2, dy: 2);
          events.addAll(<String>{'gestureBellyLaugh', 'handShapeOpen'});
        } else {
          merge('leftForearm', rotation: 10 + pulse * 5);
          merge('rightForearm', rotation: -10 - pulse * 5);
          events.add('handShapeOpen');
        }
        break;
      case 'angry':
        if (variant <= 1) {
          merge('leftArm', rotation: -26);
          merge('rightArm', rotation: 26);
          merge('leftForearm', rotation: -58 + pulse * 3);
          merge('rightForearm', rotation: 58 - pulse * 3);
          merge('leftHand', dx: 4, dy: -6);
          merge('rightHand', dx: -4, dy: -6);
          events.addAll(<String>{'gestureBoxerGuard', 'handShapeFist'});
        } else if (variant == 2) {
          merge('leftForearm', rotation: -8);
          merge('rightForearm', rotation: 8);
          merge('leftHand', dy: 1);
          merge('rightHand', dy: 1);
          events.addAll(<String>{'gestureFistsDown', 'handShapeFist'});
        } else {
          merge('rightArm', rotation: -24);
          merge('rightForearm', rotation: -48);
          merge('rightHand', dx: -4, dy: -2, rotation: -8);
          events.addAll(<String>{'gesturePoint', 'handShapePoint'});
        }
        break;
      case 'surprised':
        merge('leftArm', rotation: -24);
        merge('rightArm', rotation: 24);
        merge('leftForearm', rotation: -62);
        merge('rightForearm', rotation: 62);
        merge('leftHand', dx: 3, dy: -8);
        merge('rightHand', dx: -3, dy: -8);
        events.addAll(<String>{'gestureHandsToFace', 'handShapeOpen'});
        break;
      case 'proud':
        merge('leftArm', rotation: 24);
        merge('rightArm', rotation: -24);
        merge('leftForearm', rotation: 38);
        merge('rightForearm', rotation: -38);
        merge('leftHand', dx: 2, dy: 3);
        merge('rightHand', dx: -2, dy: 3);
        events.addAll(<String>{'gestureHandsOnHips', 'handShapeGrip'});
        break;
      case 'sad':
        if (variant.isEven) {
          merge('leftArm', rotation: -18);
          merge('rightArm', rotation: 18);
          merge('leftForearm', rotation: -30);
          merge('rightForearm', rotation: 30);
          merge('leftHand', dx: 5, dy: -1);
          merge('rightHand', dx: -5, dy: -1);
          events.addAll(<String>{'gestureSelfHug', 'handShapeGrip'});
        } else {
          events.add('handShapeRelaxed');
        }
        break;
      case 'bashful':
        merge('leftArm', rotation: -14);
        merge('leftForearm', rotation: -52);
        merge('leftHand', dx: 4, dy: -7, rotation: 8);
        events.addAll(<String>{'gestureHandToCheek', 'handShapeRelaxed'});
        break;
      case 'talk':
        if (variant == 0) {
          merge('rightForearm', rotation: -24 + pulse * 5);
          merge('rightHand', dx: -2, dy: -2, rotation: pulse * 4);
          events.add('handShapeOpen');
        }
        break;
    }

    return MotionSample(
      phase: base.phase,
      transforms: Map.unmodifiable(transforms),
      channelWeights: Map.unmodifiable(weights),
      events: Set.unmodifiable(events),
    );
  }

  String _profile(AvatarRenderContext context) {
    final face = context.string('v4.faceAnimation');
    if (face != 'none') return face;
    final expression = context.string('v4.expression');
    if (<String>{'laugh', 'openLaugh', 'manic'}.contains(expression)) {
      return 'laugh';
    }
    if (<String>{'angry', 'furious', 'determined'}.contains(expression)) {
      return 'angry';
    }
    if (<String>{'sad', 'crying', 'worried'}.contains(expression)) {
      return 'sad';
    }
    if (<String>{'surprised', 'shocked'}.contains(expression)) {
      return 'surprised';
    }
    final pose = context.string('v4.poseMotion');
    if (pose == 'proudPose') return 'proud';
    if (pose == 'shyLookAway') return 'bashful';
    return context.string('v4.animation');
  }
}
