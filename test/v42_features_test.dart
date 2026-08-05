import 'package:avatar_genome/avatar_genome.dart';
import 'package:test/test.dart';

void main() {
  final generator = AvatarGenerator();

  test('server registry exposes the complete V4.2 catalog', () {
    final registry = AvatarPropertyRegistry();
    for (final id in const <String>[
      'v4.expression',
      'v4.faceAnimation',
      'v4.halo',
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

  test('adornments are attached to semantic rig nodes', () {
    final result = generator.generate(AvatarRequest(
      seed: 'v42-rig-adornments',
      settings: const GenomeSettings(fantasy: FantasyLevel.strong),
      overrides: <String, Object>{
        'v4.halo': 'runicHalo',
        'v4.headAdornment': 'foreheadGem',
        'v4.creatureTrait': 'fangs',
        'v4.backAdornment': 'wingsFeatherRoyal',
        'v4.extraShoulderProp': 'owl',
        'v4.relic': 'crystalPendant',
      },
    ));
    final nodes = result.layers.map((layer) => layer.nodeId).toSet();
    expect(nodes, contains('halo'));
    expect(nodes, contains('headAdornment'));
    expect(nodes, contains('creatureTraits'));
    expect(nodes, contains('leftWingTip'));
    expect(nodes, contains('rightWingTip'));
    expect(nodes, contains('companionHead'));
    expect(nodes, contains('pendant'));
  });

  test('storm fire and cosmic effects animate deterministically', () {
    final request = AvatarRequest(
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
      },
    );
    final first = generator.generate(request.copyWith(phase: 0));
    final repeated = generator.generate(request.copyWith(phase: 0));
    final later = generator.generate(request.copyWith(phase: 5));
    expect(repeated.imageHash, first.imageHash);
    expect(later.imageHash, isNot(first.imageHash));
    expect(later.genome.values, first.genome.values);
  });

  test('expressions coordinate face and body rig motion', () {
    final animation = generator.generateAnimation(
      AvatarRequest(
        seed: 'v42-expression-rig',
        overrides: <String, Object>{
          'v4.expression': 'laugh',
          'v4.eyeExpression': 'laughing',
          'v4.mouthExpression': 'laughOpen',
          'v4.faceAnimation': 'laugh',
          'v4.mouthMotionStyle': 'laughLoop',
          'v4.expressionIntensity': 4,
          'v4.motionIntensity': 4,
        },
      ),
      frameCount: 16,
    );
    expect(animation.frames.map((frame) => frame.imageHash).toSet().length,
        greaterThan(3));
    final headValues = animation.frames
        .map((frame) => frame.layout.graph.nodes['rig.head']?.value.toString())
        .toSet();
    expect(headValues.length, greaterThan(1));
  });
}
