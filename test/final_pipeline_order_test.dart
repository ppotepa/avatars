import 'package:avatar_genome/avatar_genome.dart';
import 'package:test/test.dart';

void main() {
  test('weather and effect particles use separate rendered namespaces', () {
    final weather = AvatarGenerator().generate(
      AvatarRequest(
        seed: 'pipeline-weather',
        overrides: <String, Object>{
          'v4.weather': 'heavyRain',
          'v4.effect': 'none',
        },
      ),
    );
    final ids = weather.layers.map((layer) => layer.id).toSet();
    expect(ids.any((id) => id.startsWith('rain.field')), isTrue);
    expect(ids.any((id) => id.startsWith('particle.v3.effect.')), isFalse);
    expect(
      (weather.layout.graph.nodes['rig.visualNoise']!.value
          as Map)['activeChannel'],
      'v4.weather',
    );
  });

  test('final scene diagnostics are produced after posing and composition', () {
    final result = AvatarGenerator().generate(
      AvatarRequest(
        seed: 'pipeline-order',
        overrides: <String, Object>{
          'v4.effect': 'glitch',
          'v4.weather': 'none',
        },
      ),
    );
    final graph = result.layout.graph.nodes;
    final motion = graph['rig.motion']!.value as Map;
    final noise = graph['rig.visualNoise']!.value as Map;
    expect(motion['solvedTransforms'], isNotNull);
    expect(noise['finalPixelScore'], isA<num>());
    expect(noise['finalEffectPixelRatio'], isA<num>());
  });
}
