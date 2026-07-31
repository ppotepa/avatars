import 'animation_controller.dart';
import 'render_helpers.dart';
import 'render_model.dart';

/// Removes central transforms for parts whose geometry renderer already emitted
/// phase-dependent articulation.
///
/// This is a migration boundary: inherited parent motion remains intact, but a
/// flexible child is never moved once by its renderer and a second time by the
/// central pose. That prevents gaps at hair, chain, cape and companion joints.
final class MotionOwnershipPolicy {
  const MotionOwnershipPolicy();

  MotionSample apply(AvatarRenderContext context, MotionSample sample) {
    final transforms = <String, dynamic>{...sample.transforms};
    final animation = context.string('v4.animation');
    final faceAnimation = context.string('v4.faceAnimation');

    final localHair = animationChannelEnabled(animation, 'hairWind');
    final localJewelry =
        animationChannelEnabled(animation, 'jewelrySwing') ||
            faceAnimation != 'none';
    final localCompanion = animation != 'none' || faceAnimation != 'none';
    final localBackRig = animation != 'none' || faceAnimation != 'none';

    void remove(Iterable<String> ids) {
      for (final id in ids) transforms.remove(id);
    }

    if (localHair) {
      remove(const <String>[
        'hairBackMiddle',
        'hairBackTips',
        'hairSideLeftRoot',
        'hairSideLeftTip',
        'hairSideRightRoot',
        'hairSideRightTip',
      ]);
    }
    if (localJewelry) {
      remove(const <String>[
        'necklace',
        'necklaceLeft',
        'necklaceRight',
        'pendant',
        'leftEarJewelry',
        'rightEarJewelry',
      ]);
    }
    if (localCompanion) {
      remove(const <String>[
        'shoulderCompanion',
        'companionBody',
        'companionHead',
        'companionWings',
        'companionTail',
        'companionEars',
        'companionEyes',
        'companionBeak',
      ]);
    }
    if (localBackRig) {
      remove(const <String>[
        'capeMidLeft',
        'capeMidRight',
        'capeTipLeft',
        'capeTipRight',
        'leftWingMid',
        'leftWingTip',
        'rightWingMid',
        'rightWingTip',
      ]);
    }

    return MotionSample(
      phase: sample.phase,
      transforms: Map.unmodifiable(
        transforms.cast<String, dynamic>().map(
              (key, value) => MapEntry(key, value),
            ),
      ).cast(),
      channelWeights: sample.channelWeights,
      events: sample.events,
    );
  }
}
