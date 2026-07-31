import '../util/math_utils.dart';
import 'animation_controller.dart';
import 'render_helpers.dart';
import 'render_model.dart';
import 'rig_model.dart';

/// Adds actor-specific articulation and secondary inertia to the generic sample.
final class ExpressiveMotionPolicy {
  const ExpressiveMotionPolicy();

  MotionSample augment(AvatarRenderContext context, MotionSample base) {
    final transforms = <String, RigTransform>{...base.transforms};
    final events = <String>{...base.events};
    final weights = <String, double>{...base.channelWeights};
    final profile = _profile(context);
    final speed = clampInt(
      context.integer('v4.motionSpeed', context.integer('v4.animationSpeed', 3)),
      1,
      6,
    );
    final period = animationPeriod(speed, slow: 22, fast: 8);
    final phase = base.phase;
    final pulse = positiveMod(phase, period);
    final fastSwing = cyclicOffset(phase, clampInt(period ~/ 2, 4, period), 1);
    final slowSwing = cyclicOffset(phase - 3, period, 1);
    final inertia = cyclicOffset(phase - 5, period, 2);

    void merge(
      String nodeId, {
      int dx = 0,
      int dy = 0,
      int rotation = 0,
    }) {
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
        merge('torso', dy: fastSwing > 0 ? -1 : 0);
        merge('neck', dy: fastSwing < 0 ? 1 : 0);
        merge('head',
            dx: slowSwing,
            dy: fastSwing,
            rotation: cyclicOffset(phase - 2, period, 4));
        merge('leftShoulder', dy: fastSwing, rotation: 5 + fastSwing * 3);
        merge('rightShoulder', dy: -fastSwing, rotation: -5 - fastSwing * 3);
        merge('leftArm', rotation: 20 + pulse % 3 * 5);
        merge('rightArm', rotation: -20 - pulse % 3 * 5);
        merge('hairBackMiddle', dx: slowSwing);
        merge('hairBackTips', dx: inertia, dy: inertia.abs() ~/ 2);
        merge('hairSideLeftTip', dx: inertia);
        merge('hairSideRightTip', dx: inertia);
        merge('necklace', dx: inertia);
        merge('pendant', dx: inertia, dy: fastSwing.abs());
        merge('leftEarJewelry', dx: inertia);
        merge('rightEarJewelry', dx: inertia);
        merge('shoulderCompanion', dy: fastSwing.abs());
        merge('companionHead', rotation: slowSwing * 5);
        merge('companionWings', rotation: fastSwing * 12);
        merge('companionTail', rotation: inertia * 8);
        merge('capeMidLeft', dx: -slowSwing);
        merge('capeMidRight', dx: -slowSwing);
        merge('capeTipLeft', dx: -inertia);
        merge('capeTipRight', dx: -inertia);
        events.addAll(<String>{'shoulderBounce', 'secondaryInertia'});
        break;
      case 'angry':
        merge('torso', dy: -1);
        merge('neck', dx: 1, dy: -1);
        merge('head',
            dx: fastSwing,
            dy: -1,
            rotation: cyclicOffset(phase, period, 2));
        merge('leftShoulder', dy: -1, rotation: -4);
        merge('rightShoulder', dy: -1, rotation: 4);
        merge('leftArm', rotation: -18 - fastSwing * 3);
        merge('rightArm', rotation: 18 + fastSwing * 3);
        merge('leftHand', dx: 1);
        merge('rightHand', dx: -1);
        merge('hairBackTips', dx: -fastSwing);
        merge('necklace', dx: fastSwing);
        merge('pendant', dx: fastSwing * 2);
        merge('shoulderCompanion', dx: -fastSwing, dy: -1);
        merge('companionEars', dy: -fastSwing.abs());
        events.addAll(<String>{'tension', 'microTremor'});
        break;
      case 'talk':
        merge('torso', dy: slowSwing > 0 ? 1 : 0);
        merge('head',
            dx: cyclicOffset(phase - 2, period * 2, 1),
            dy: fastSwing,
            rotation: slowSwing);
        merge('rightShoulder', rotation: -fastSwing * 3);
        merge('rightArm', rotation: -8 - pulse % 4 * 3);
        merge('rightHand', rotation: pulse.isEven ? 4 : -4);
        merge('hairBackTips', dx: slowSwing);
        merge('necklace', dx: slowSwing);
        merge('pendant', dx: inertia);
        merge('shoulderCompanion', dy: fastSwing.abs());
        merge('companionHead', rotation: slowSwing * 4);
        merge('companionBeak', dy: positiveMod(phase, 2));
        events.addAll(<String>{'mouthPhoneme', 'browPunctuation'});
        break;
      case 'sad':
        merge('torso', dy: 1);
        merge('neck', dy: 1);
        merge('head', dy: 1, rotation: -3);
        merge('leftShoulder', dy: 1, rotation: -3);
        merge('rightShoulder', dy: 1, rotation: 3);
        merge('leftArm', rotation: -8);
        merge('rightArm', rotation: 8);
        merge('hairBackTips', dx: slowSwing ~/ 2);
        merge('necklace', dx: slowSwing ~/ 2);
        merge('shoulderCompanion', dy: 1);
        merge('companionHead', rotation: -2);
        weights['secondary'] = (weights['secondary'] ?? 1) * .45;
        events.add('slowBlink');
        break;
      case 'surprised':
        final hit = pulse < 3;
        if (hit) {
          merge('torso', dy: 1);
          merge('neck', dy: -1);
          merge('head', dy: -2, rotation: 3);
          merge('leftShoulder', dy: -1);
          merge('rightShoulder', dy: -1);
          merge('leftArm', rotation: -45);
          merge('rightArm', rotation: 45);
          merge('hairBackMiddle', dx: -slowSwing);
          merge('hairBackTips', dx: -inertia, dy: -1);
          merge('necklace', dx: -inertia);
          merge('pendant', dx: -inertia, dy: 1);
          merge('shoulderCompanion', dy: -1);
          merge('companionWings', rotation: 18);
          merge('capeTipLeft', dx: inertia);
          merge('capeTipRight', dx: inertia);
        }
        events.addAll(<String>{'wideEyes', 'recoil'});
        break;
      case 'happy':
        merge('torso', dy: fastSwing > 0 ? -1 : 0);
        merge('head', dy: fastSwing < 0 ? -1 : 0, rotation: slowSwing);
        merge('hairBackTips', dx: slowSwing);
        merge('necklace', dx: slowSwing);
        merge('shoulderCompanion', dy: fastSwing.abs());
        merge('companionTail', rotation: inertia * 5);
        events.add('happyEyes');
        break;
      case 'sleepy':
        merge('torso', dy: slowSwing > 0 ? 1 : 0);
        merge('head', dy: 1, rotation: slowSwing);
        merge('hairBackTips', dx: slowSwing ~/ 2);
        merge('necklace', dx: slowSwing ~/ 2);
        merge('shoulderCompanion', dy: 1);
        events.add('slowBlink');
        break;
      case 'confused':
        merge('head', dx: fastSwing, rotation: slowSwing * 3);
        merge('leftShoulder', dy: fastSwing > 0 ? -1 : 0);
        merge('rightShoulder', dy: fastSwing < 0 ? -1 : 0);
        merge('leftArm', rotation: 15 + slowSwing * 3);
        merge('rightArm', rotation: -10 + slowSwing * 3);
        merge('hairBackTips', dx: inertia);
        merge('necklace', dx: inertia);
        merge('companionHead', rotation: -slowSwing * 5);
        events.add('browQuestion');
        break;
      case 'proud':
        merge('torso', dy: -1);
        merge('head', dy: -1, rotation: 2);
        merge('leftShoulder', dy: -1);
        merge('rightShoulder', dy: -1);
        merge('capeTipLeft', dx: -slowSwing);
        merge('capeTipRight', dx: -slowSwing);
        break;
      case 'bashful':
        merge('head', dx: -1, dy: 1, rotation: -3);
        merge('leftShoulder', dy: 1);
        merge('rightShoulder', dy: 1);
        merge('hairBackTips', dx: slowSwing);
        merge('companionHead', rotation: 2);
        events.add('blush');
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
    if (<String>{'smile', 'bigSmile', 'blushingHappy'}.contains(expression)) {
      return 'happy';
    }
    return context.string('v4.animation');
  }
}
