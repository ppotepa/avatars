import 'package:avatar_genome/avatar_genome.dart';
import 'package:test/test.dart';

void main() {
  final generator = AvatarGenerator();

  test('server property registry exposes all V4.2 controls', () {
    final registry = AvatarPropertyRegistry();
    for (final id in const <String>[
      'v4.expression',
      'v4.eyeExpression',
      'v4.mouthExpression',
      'v4.faceAnimation',
      'v4.halo',
      'v4.headAdornment',
      'v4.creatureTrait',
      'v4.symbolOverlay',
      'v4.weather',
      'v4.backgroundEvent',
      'v4.cosmicLayer',
      'v4.backFlames',
      'v4.poseMotion',
    ]) {
      expect(registry.bindingById, contains(id), reason: id);
    }
    expect(registry.catalogBindings, hasLength(ParameterCatalog.v41.fieldCount));
  });

  test('halo adornments companions and relics add visible layers', () {
    const request = AvatarRequest(
      seed: 'v42-adornments',
      settings: GenomeSettings(
        fantasy: FantasyLevel.strong,
        symmetry: false,
      ),
      overrides: <String, Object>{
        'v4.halo': 'runicHalo',
        'v4.haloGlow': 5,
        'v4.headAdornment': 'foreheadGem',
        'v4.sideHeadFeature': 'finFrill',
        'v4.creatureTrait': 'fangs',
        'v4.symbolOverlay': 'magicCircle',
        'v4.symbolDensity': 5,
        'v4.backAdornment': 'wingsFeatherRoyal',
        'v4.extraShoulderProp': 'owl',
        'v4.relic': 'crystalPendant',
      },
    );
    final result = generator.generate(request);
    final layerIds = result.layers.map((layer) => layer.id).toSet();

    expect(layerIds.any((id) => id.startsWith('halo.v42')), isTrue);
    expect(layerIds.any((id) => id.startsWith('headAdornment.v42')), isTrue);
    expect(layerIds.any((id) => id.startsWith('creature.v42')), isTrue);
    expect(layerIds.any((id) => id.startsWith('symbols.v42')), isTrue);
    expect(layerIds.any((id) => id.startsWith('backAdornment.v42')), isTrue);
    expect(layerIds.any((id) => id.startsWith('companion.v42')), isTrue);
    expect(layerIds.any((id) => id.startsWith('relic.v42')), isTrue);
  });

  test('storm fire and cosmic effects animate deterministically', () {
    const request = AvatarRequest(
      seed: 'v42-atmosphere',
      overrides: <String, Object>{
        'v4.background': 'bloodMoon',
        'v4.weather': 'heavyRain',
        'v4.weatherDensity': 6,
        'v4.weatherDepth': 2,
        'v4.backgroundEvent': 'lightningBranch',
        'v4.eventFrequency': 2,
        'v4.eventIntensity': 5,
        'v4.cosmicLayer': 'starsDense',
        'v4.cosmicDensity': 5,
        'v4.backFlames': 'hellfire',
        'v4.flameHeight': 7,
        'v4.flameIntensity': 6,
        'v4.flameFlicker': 5,
        'v4.ambientOverlay': 'stormClouds',
        'v4.ambientDensity': 5,
      },
    );
    final first = generator.generate(request.copyWith(phase: 0));
    final repeated = generator.generate(request.copyWith(phase: 0));
    final later = generator.generate(request.copyWith(phase: 5));

    expect(repeated.imageHash, first.imageHash);
    expect(later.imageHash, isNot(first.imageHash));
    expect(later.genome.values, first.genome.values);
    expect(first.layers.any((layer) => layer.id.startsWith('weather.v42')), isTrue);
    expect(first.layers.any((layer) => layer.id.startsWith('flames.v42')), isTrue);
    expect(first.layers.any((layer) => layer.id.startsWith('cosmic.v42')), isTrue);
    expect(
      first.layers.any((layer) => layer.id.startsWith('backgroundEvent.v42')),
      isTrue,
    );
  });

  test('talk and laugh animate the mouth while body framing stays stable', () {
    const request = AvatarRequest(
      seed: 'v42-expression-animation',
      overrides: <String, Object>{
        'v4.expression': 'laugh',
        'v4.eyeExpression': 'laughing',
        'v4.browExpression': 'relaxed',
        'v4.mouthExpression': 'laughOpen',
        'v4.faceAnimation': 'talk',
        'v4.mouthMotionStyle': 'talkNormal',
        'v4.expressionIntensity': 4,
        'v4.expressionSpeed': 4,
      },
    );
    final animation = generator.generateAnimation(request, frameCount: 16);
    final hashes = animation.frames.map((frame) => frame.imageHash).toSet();
    expect(hashes.length, greaterThan(2));

    List<int> layerPixels(AvatarResult frame, String id) => frame.layers
        .firstWhere((layer) => layer.id == id)
        .mask
        .data
        .toList(growable: false);

    for (final id in const <String>[
      'head.base',
      'neck.base',
      'torso.outline',
      'clothing.base',
    ]) {
      final reference = layerPixels(animation.frames.first, id);
      for (final frame in animation.frames.skip(1)) {
        expect(layerPixels(frame, id), reference, reason: id);
      }
    }
  });

  test('manual expression controls create distinct face output', () {
    const base = AvatarRequest(
      seed: 'v42-expression-difference',
      overrides: <String, Object>{
        'v4.expression': 'neutral',
        'v4.eyeExpression': 'neutral',
        'v4.browExpression': 'relaxed',
        'v4.mouthExpression': 'neutral',
        'v4.faceAnimation': 'none',
        'v4.mouthMotionStyle': 'none',
      },
    );
    final neutral = generator.generate(base);
    final angry = generator.generate(base.copyWith(
      overrides: <String, Object>{
        ...base.overrides,
        'v4.expression': 'furious',
        'v4.eyeExpression': 'angry',
        'v4.browExpression': 'angryDown',
        'v4.mouthExpression': 'snarl',
        'v4.emotionMark': 'angerMark',
        'v4.expressionIntensity': 5,
      },
    ));
    final happy = generator.generate(base.copyWith(
      overrides: <String, Object>{
        ...base.overrides,
        'v4.expression': 'bigSmile',
        'v4.eyeExpression': 'happy',
        'v4.browExpression': 'relaxed',
        'v4.mouthExpression': 'wideSmile',
        'v4.emotionMark': 'blush',
        'v4.expressionIntensity': 4,
      },
    ));

    expect(angry.imageHash, isNot(neutral.imageHash));
    expect(happy.imageHash, isNot(neutral.imageHash));
    expect(happy.imageHash, isNot(angry.imageHash));
  });
}
