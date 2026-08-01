import 'dart:convert';

import 'package:avatar_genome/avatar_genome.dart';
import 'package:avatar_genome/src/constraints/validation.dart';
import 'package:avatar_genome/src/genome/budgeted_genome_generator.dart';
import 'package:avatar_genome/src/quality/scene_visual_noise.dart';
import 'package:avatar_genome/src/random/random_stream.dart';
import 'package:test/test.dart';

void main() {
  test('automatic generation keeps one channel with probabilistic targets', () {
    final generator = BudgetedGenomeGenerator();
    final targets = <int>{};

    for (var index = 0; index < 120; index++) {
      final genome = generator.generate(
        AvatarRequest(seed: 'scene-budget-$index'),
        ConstraintEngine(enabled: true),
      );
      final active = SceneVisualNoise.activeChannels(genome.values);
      expect(active.length, lessThanOrEqualTo(1), reason: genome.seed);
      expect(
        SceneVisualNoise.score(genome.values),
        lessThanOrEqualTo(SceneVisualNoise.hardLimit),
        reason: genome.seed,
      );
      targets.add(SceneVisualNoise.probabilisticTarget(
        genome.values,
        RandomStream(index + 17),
      ));
    }

    expect(targets.length, greaterThanOrEqualTo(4));
    expect(targets.every((value) => value >= 24 && value <= 40), isTrue);
  });

  test('conflicting explicit scene effects keep the semantic primary channel',
      () {
    final result = AvatarGenerator().generate(const AvatarRequest(
      seed: 'explicit-scene-conflict',
      overrides: <String, Object>{
        'v4.background': 'voidStatic',
        'v4.weather': 'heavyRain',
        'v4.weatherDensity': 6,
        'v4.weatherDepth': 4,
        'v4.cosmicLayer': 'nebula',
        'v4.cosmicDensity': 6,
        'v4.backFlames': 'hellfire',
        'v4.flameIntensity': 6,
        'v4.flameHeight': 8,
        'v4.ambientOverlay': 'stormClouds',
        'v4.ambientDensity': 6,
        'v4.backgroundEvent': 'lightningBranch',
        'v4.eventIntensity': 5,
        'v4.eventFrequency': 8,
        'v4.effect': 'snow',
        'v4.particleDensity': 6,
        'v4.symbolOverlay': 'warningTriangles',
        'v4.symbolDensity': 6,
        'v4.aura': 'magic',
        'v4.halo': 'electricHalo',
      },
    ));

    final active = SceneVisualNoise.activeChannels(result.genome.values);
    expect(active, <String>['v4.weather']);
    expect(
      SceneVisualNoise.score(result.genome.values),
      lessThanOrEqualTo(SceneVisualNoise.hardLimit),
    );
    final diagnostics =
        result.layout.graph.nodes['rig.visualNoise']!.value as Map;
    expect(diagnostics['activeChannel'], 'v4.weather');
    expect(diagnostics['activeChannelCount'], lessThanOrEqualTo(1));
    expect(diagnostics['configuredScore'], lessThanOrEqualTo(42));
    expect(diagnostics['finalPixelScore'], isA<num>());
    expect(diagnostics['finalEffectPixelRatio'], isA<num>());
  });

  test('core framing fills the viewport despite large soft attachments', () {
    final generator = AvatarGenerator();
    for (final bodyType in const <String>[
      'petite',
      'verySlim',
      'standard',
      'broad',
    ]) {
      final request = AvatarRequest(
        seed: 'core-framing-$bodyType',
        overrides: <String, Object>{
          'body.type': bodyType,
          'v4.animation': 'idle',
          'v4.halo': 'holySpikes',
          'fantasy.hornStyle': 'mooseFlat',
          'v4.backAdornment': 'wingsFeatherRoyal',
          'v4.shoulderProp': 'cosmicJellyfish',
          'hair.lengthStyle': 'belowShoulder',
          'hair.length': 15,
        },
      );
      final still = generator.generate(request);
      final clip = generator.generateAnimation(request, frameCount: 16);
      final stillCamera = still.layout.graph.nodes['rig.camera']!.value as Map;
      final clipCamera =
          clip.frames.first.layout.graph.nodes['rig.camera']!.value as Map;

      expect(jsonEncode(stillCamera), jsonEncode(clipCamera), reason: bodyType);
      expect(
        (stillCamera['actorOccupancy']! as num).toDouble(),
        greaterThanOrEqualTo(.75),
        reason: bodyType,
      );
      expect(
        (stillCamera['scale']! as num).toDouble(),
        lessThanOrEqualTo(1.65),
      );
      expect(
        (stillCamera['safetyCoverage']! as num).toDouble(),
        greaterThanOrEqualTo(.72),
        reason: bodyType,
      );
      expect(
        (stillCamera['criticalCoverage']! as num).toDouble(),
        greaterThanOrEqualTo(.999),
        reason: bodyType,
      );
    }
  });
}
