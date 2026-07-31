import '../util/math_utils.dart';
import 'render_helpers.dart';
import 'render_model.dart';
import 'rig_model.dart';

final class MotionSample {
  const MotionSample({
    required this.phase,
    required this.transforms,
    required this.channelWeights,
    required this.events,
  });

  final int phase;
  final Map<String, RigTransform> transforms;
  final Map<String, double> channelWeights;
  final Set<String> events;

  RigTransform transformFor(String nodeId) =>
      transforms[nodeId] ?? RigTransform.identity;

  Map<String, Object> toJson() => <String, Object>{
        'phase': phase,
        'transforms': <String, Object>{
          for (final entry in transforms.entries)
            entry.key: entry.value.toJson(),
        },
        'channelWeights': channelWeights,
        'events': events.toList(growable: false)..sort(),
      };
}

final class AnimationProfile {
  const AnimationProfile({
    required this.id,
    required this.basePeriod,
    this.bodyAmplitude = 1,
    this.headAmplitude = 1,
    this.secondaryAmplitude = 1,
    this.irregularity = 0,
  });

  final String id;
  final int basePeriod;
  final int bodyAmplitude;
  final int headAmplitude;
  final int secondaryAmplitude;
  final int irregularity;
}

final class RigAnimationController {
  const RigAnimationController();

  static const Map<String, AnimationProfile> profiles =
      <String, AnimationProfile>{
    'none': AnimationProfile(id: 'none', basePeriod: 24, bodyAmplitude: 0, headAmplitude: 0, secondaryAmplitude: 0),
    'idle': AnimationProfile(id: 'idle', basePeriod: 24, bodyAmplitude: 1, headAmplitude: 1, secondaryAmplitude: 1, irregularity: 2),
    'blink': AnimationProfile(id: 'blink', basePeriod: 20, bodyAmplitude: 0, headAmplitude: 0, secondaryAmplitude: 0, irregularity: 2),
    'lookAround': AnimationProfile(id: 'lookAround', basePeriod: 22, bodyAmplitude: 0, headAmplitude: 1, secondaryAmplitude: 1, irregularity: 2),
    'talk': AnimationProfile(id: 'talk', basePeriod: 12, bodyAmplitude: 1, headAmplitude: 1, secondaryAmplitude: 1),
    'laugh': AnimationProfile(id: 'laugh', basePeriod: 8, bodyAmplitude: 2, headAmplitude: 2, secondaryAmplitude: 2),
    'angry': AnimationProfile(id: 'angry', basePeriod: 10, bodyAmplitude: 1, headAmplitude: 1, secondaryAmplitude: 2),
    'sad': AnimationProfile(id: 'sad', basePeriod: 28, bodyAmplitude: 1, headAmplitude: 1, secondaryAmplitude: 1),
    'happy': AnimationProfile(id: 'happy', basePeriod: 16, bodyAmplitude: 1, headAmplitude: 1, secondaryAmplitude: 1),
    'sleepy': AnimationProfile(id: 'sleepy', basePeriod: 32, bodyAmplitude: 1, headAmplitude: 1, secondaryAmplitude: 1),
    'surprised': AnimationProfile(id: 'surprised', basePeriod: 18, bodyAmplitude: 2, headAmplitude: 2, secondaryAmplitude: 2),
    'curious': AnimationProfile(id: 'curious', basePeriod: 20, bodyAmplitude: 0, headAmplitude: 1, secondaryAmplitude: 1),
    'proud': AnimationProfile(id: 'proud', basePeriod: 24, bodyAmplitude: 1, headAmplitude: 1, secondaryAmplitude: 1),
    'evil': AnimationProfile(id: 'evil', basePeriod: 16, bodyAmplitude: 1, headAmplitude: 1, secondaryAmplitude: 2),
    'bashful': AnimationProfile(id: 'bashful', basePeriod: 24, bodyAmplitude: 1, headAmplitude: 1, secondaryAmplitude: 1),
    'confused': AnimationProfile(id: 'confused', basePeriod: 13, bodyAmplitude: 1, headAmplitude: 2, secondaryAmplitude: 2),
    'hairWind': AnimationProfile(id: 'hairWind', basePeriod: 18, bodyAmplitude: 0, headAmplitude: 0, secondaryAmplitude: 3),
    'jewelrySwing': AnimationProfile(id: 'jewelrySwing', basePeriod: 16, bodyAmplitude: 0, headAmplitude: 0, secondaryAmplitude: 3),
    'smoke': AnimationProfile(id: 'smoke', basePeriod: 18, bodyAmplitude: 0, headAmplitude: 0, secondaryAmplitude: 1),
    'auraPulse': AnimationProfile(id: 'auraPulse', basePeriod: 20, bodyAmplitude: 0, headAmplitude: 0, secondaryAmplitude: 2),
    'glowPulse': AnimationProfile(id: 'glowPulse', basePeriod: 18, bodyAmplitude: 0, headAmplitude: 0, secondaryAmplitude: 2),
    'particles': AnimationProfile(id: 'particles', basePeriod: 20, bodyAmplitude: 0, headAmplitude: 0, secondaryAmplitude: 1),
  };

  MotionSample sample(AvatarRenderContext context) {
    final id = _effectiveId(context);
    final profile = profiles[id] ?? profiles['idle']!;
    final speed = clampInt(
      context.integer('v4.motionSpeed', context.integer('v4.animationSpeed', 3)),
      1,
      6,
    );
    final intensity = clampInt(
      context.integer('v4.motionIntensity', context.integer('v4.animationAmplitude', 2)),
      0,
      5,
    );
    final phase = context.phase + context.integer('v4.motionPhaseOffset');
    final period = animationPeriod(
      speed,
      slow: clampInt(profile.basePeriod + 6, 8, 40),
      fast: clampInt(profile.basePeriod - 4, 4, 32),
    );
    final seedJitter = context.random('rig.motion.$id.${phase ~/ period}');
    final jitter = profile.irregularity == 0
        ? 0
        : seedJitter.nextInt(-profile.irregularity, profile.irregularity);
    final localPhase = phase + jitter;

    final transforms = <String, RigTransform>{};
    final weights = <String, double>{
      'body': profile.bodyAmplitude * intensity / 5,
      'head': profile.headAmplitude * intensity / 5,
      'secondary': profile.secondaryAmplitude * intensity / 5,
      'face': context.string('v4.faceAnimation') == 'none' ? 0 : 1,
    };
    final events = <String>{};

    void set(String nodeId, {int dx = 0, int dy = 0, int rotation = 0}) {
      if (dx == 0 && dy == 0 && rotation == 0) return;
      transforms[nodeId] = RigTransform(
        dx: dx,
        dy: dy,
        rotationDegrees: rotation,
      );
    }

    final breath = cyclicOffset(localPhase, period, clampInt(profile.bodyAmplitude, 0, 2));
    final delayed = cyclicOffset(localPhase - 2, period, clampInt(profile.headAmplitude, 0, 2));
    final secondary = cyclicOffset(
      localPhase - 4,
      period,
      clampInt(profile.secondaryAmplitude, 0, 3),
    );

    switch (id) {
      case 'idle':
        set('torso', dy: breath > 0 ? 1 : 0);
        set('neck', dy: delayed > 0 ? 1 : 0);
        set('head',
            dx: cyclicOffset(localPhase - 7, period * 3, 1),
            dy: delayed > 0 ? 1 : 0,
            rotation: cyclicOffset(localPhase - 11, period * 4, 1));
        set('leftShoulder', dy: breath > 0 ? 1 : 0);
        set('rightShoulder', dy: breath > 0 ? 1 : 0);
        if (positiveMod(localPhase, period * 3) == period * 2) {
          events.add('microLook');
        }
        break;
      case 'lookAround':
      case 'curious':
        set('head',
            dx: cyclicOffset(localPhase, period, 1),
            rotation: cyclicOffset(localPhase - 3, period * 2, 2));
        events.add('gaze');
        break;
      case 'talk':
        set('torso', dy: breath > 0 ? 1 : 0);
        set('head',
            dx: cyclicOffset(localPhase - 2, period * 2, 1),
            dy: cyclicOffset(localPhase, period, 1),
            rotation: cyclicOffset(localPhase - 1, period * 2, 1));
        set('rightArm', rotation: -8 - positiveMod(localPhase, 3) * 3);
        events.add('mouthPhoneme');
        break;
      case 'laugh':
        set('torso', dy: -cyclicOffset(localPhase - 1, period, 1).abs());
        set('head',
            dx: cyclicOffset(localPhase - 2, period, 1),
            dy: cyclicOffset(localPhase, period, 2),
            rotation: cyclicOffset(localPhase - 2, period, 3));
        set('leftShoulder', dy: cyclicOffset(localPhase, period, 1));
        set('rightShoulder', dy: cyclicOffset(localPhase + 1, period, 1));
        set('leftArm', rotation: 12 + positiveMod(localPhase, 3) * 4);
        set('rightArm', rotation: -12 - positiveMod(localPhase, 3) * 4);
        events.addAll(<String>{'mouthPhoneme', 'happyEyes'});
        break;
      case 'angry':
        set('torso', dy: -1);
        set('neck', dx: cyclicOffset(localPhase, period ~/ 2, 1));
        set('head',
            dx: cyclicOffset(localPhase, clampInt(period ~/ 3, 4, period), 1),
            dy: -1,
            rotation: cyclicOffset(localPhase, period, 1));
        set('leftShoulder', dy: -1);
        set('rightShoulder', dy: -1);
        set('leftArm', rotation: -12);
        set('rightArm', rotation: 12);
        events.add('tension');
        break;
      case 'sad':
        set('torso', dy: 1);
        set('head', dy: 1, rotation: -2);
        set('leftShoulder', dy: 1);
        set('rightShoulder', dy: 1);
        events.add('slowBlink');
        break;
      case 'happy':
        set('torso', dy: breath > 0 ? -1 : 0);
        set('head', dy: delayed > 0 ? -1 : 0, rotation: secondary);
        events.add('happyEyes');
        break;
      case 'sleepy':
        set('torso', dy: breath > 0 ? 1 : 0);
        set('head', dy: 1, rotation: cyclicOffset(localPhase, period * 2, 1));
        events.add('slowBlink');
        break;
      case 'surprised':
        final hit = positiveMod(localPhase, period) < 3;
        set('torso', dy: hit ? 1 : 0);
        set('head', dy: hit ? -2 : 0, rotation: hit ? 2 : 0);
        set('leftShoulder', dy: hit ? -1 : 0);
        set('rightShoulder', dy: hit ? -1 : 0);
        set('leftArm', rotation: hit ? -35 : 0);
        set('rightArm', rotation: hit ? 35 : 0);
        events.add('wideEyes');
        break;
      case 'proud':
        set('torso', dy: -1);
        set('head', dy: -1, rotation: 1);
        break;
      case 'bashful':
        set('head', dx: -1, dy: 1, rotation: -2);
        events.add('blush');
        break;
      case 'confused':
        set('head',
            dx: cyclicOffset(localPhase, period, 1),
            rotation: cyclicOffset(localPhase - 2, period, 3));
        set('leftShoulder', dy: secondary > 0 ? -1 : 0);
        events.add('browQuestion');
        break;
      case 'evil':
        set('head', dy: -1, rotation: cyclicOffset(localPhase, period, 1));
        events.add('evilEyes');
        break;
      case 'hairWind':
        set('hairBackMiddle', dx: secondary);
        set('hairBackTips', dx: cyclicOffset(localPhase - 3, period, 3));
        set('hairSideLeftTip', dx: secondary);
        set('hairSideRightTip', dx: secondary);
        break;
      case 'jewelrySwing':
        set('necklace', dx: secondary);
        set('leftEarJewelry', dx: secondary);
        set('rightEarJewelry', dx: secondary);
        break;
      case 'auraPulse':
      case 'glowPulse':
        events.add('pulse');
        break;
      case 'smoke':
        events.add('emitSmoke');
        break;
      case 'particles':
        events.add('animateParticles');
        break;
    }

    // Secondary nodes inherit delayed inertial response in every body-driven
    // profile. Dedicated channel transforms above override these defaults.
    if (profile.bodyAmplitude > 0) {
      transforms.putIfAbsent(
        'hairBackTips',
        () => RigTransform(dx: cyclicOffset(localPhase - 4, period, 1)),
      );
      transforms.putIfAbsent(
        'necklace',
        () => RigTransform(dx: cyclicOffset(localPhase - 3, period, 1)),
      );
      transforms.putIfAbsent(
        'shoulderCompanion',
        () => RigTransform(
          dx: cyclicOffset(localPhase - 2, period, 1),
          dy: delayed > 0 ? 1 : 0,
        ),
      );
    }

    return MotionSample(
      phase: localPhase,
      transforms: Map.unmodifiable(transforms),
      channelWeights: Map.unmodifiable(weights),
      events: Set.unmodifiable(events),
    );
  }

  String _effectiveId(AvatarRenderContext context) {
    final face = context.string('v4.faceAnimation');
    if (face != 'none') return face;
    final pose = context.string('v4.poseMotion');
    if (pose == 'proudPose') return 'proud';
    if (pose == 'shyLookAway') return 'bashful';
    if (pose == 'tinyShake') return 'angry';
    if (pose == 'headTilt') return 'confused';
    return context.string('v4.animation');
  }
}
