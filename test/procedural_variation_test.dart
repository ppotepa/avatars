import 'package:avatar_genome/avatar_genome.dart';
import 'package:test/test.dart';

void main() {
  final generator = AvatarGenerator();

  String proceduralSignature(AvatarResult result) {
    final layers = result.layers
        .where((layer) => layer.id.startsWith('faceMask.procedural.'))
        .toList(growable: false)
      ..sort((a, b) => a.id.compareTo(b.id));
    return layers
        .map((layer) => '${layer.id}:${layer.mask.data.join()}')
        .join('|');
  }

  String particleSignature(AvatarResult result) {
    final layers = result.layers
        .where((layer) => layer.id.startsWith('particle.v2.'))
        .toList(growable: false)
      ..sort((a, b) => a.id.compareTo(b.id));
    return layers
        .map((layer) => '${layer.id}:${layer.mask.data.join()}')
        .join('|');
  }

  test('hockey mask produces many deterministic seed variants', () {
    final signatures = <String>{};
    for (var index = 0; index < 100; index++) {
      final result = generator.generate(AvatarRequest(
        seed: 'hockey-variation-$index',
        settings: const GenomeSettings(
          fantasy: FantasyLevel.strong,
          symmetry: false,
        ),
        overrides: const <String, Object>{
          'v4.faceMask': 'hockeyMask',
          'v4.maskCoverage': 3,
          'v4.maskDamage': 2,
          'v4.headwear': 'none',
          'v4.eyewear': 'none',
        },
      ));
      final signature = proceduralSignature(result);
      expect(signature, isNotEmpty, reason: 'seed $index');
      signatures.add(signature);
    }
    expect(signatures.length, greaterThanOrEqualTo(30));
  });

  test('procedural mask details remain deterministic', () {
    const request = AvatarRequest(
      seed: 'hockey-deterministic',
      overrides: <String, Object>{
        'v4.faceMask': 'hockeyMask',
        'v4.maskCoverage': 4,
        'v4.maskDamage': 3,
      },
    );
    expect(
      proceduralSignature(generator.generate(request)),
      proceduralSignature(generator.generate(request)),
    );
  });

  test('natural particles replace legacy weather and effect layers', () {
    const request = AvatarRequest(
      seed: 'natural-particle-replacement',
      overrides: <String, Object>{
        'v4.weather': 'heavyRain',
        'v4.weatherDensity': 6,
        'v4.weatherDepth': 2,
        'v4.weatherDrift': 2,
        'v4.effect': 'sparks',
        'v4.particleDensity': 5,
      },
    );
    final result = generator.generate(request);
    final ids = result.layers.map((layer) => layer.id).toList();
    expect(ids.any((id) => id.startsWith('particle.v2.')), isTrue);
    expect(ids.any((id) => id.startsWith('weather.v42.')), isFalse);
    expect(ids.any((id) => id.startsWith('effect.back')), isFalse);
    expect(ids.any((id) => id.startsWith('effect.front')), isFalse);
  });

  test('particle motion is deterministic and changes across phases', () {
    const request = AvatarRequest(
      seed: 'natural-particle-motion',
      overrides: <String, Object>{
        'v4.weather': 'snow',
        'v4.weatherDensity': 6,
        'v4.weatherDepth': 3,
        'v4.weatherDrift': 1,
        'v4.effect': 'none',
      },
    );
    final first = generator.generate(request.copyWith(phase: 4));
    final repeated = generator.generate(request.copyWith(phase: 4));
    final next = generator.generate(request.copyWith(phase: 5));
    expect(particleSignature(repeated), particleSignature(first));
    expect(particleSignature(next), isNot(particleSignature(first)));
  });

  test('fog uses patches rather than full-width scan lines', () {
    const request = AvatarRequest(
      seed: 'natural-fog-patches',
      overrides: <String, Object>{
        'v4.weather': 'fog',
        'v4.weatherDensity': 6,
        'v4.weatherDepth': 3,
        'v4.effect': 'none',
      },
    );
    final result = generator.generate(request.copyWith(phase: 12));
    final masks = result.layers
        .where((layer) => layer.id.startsWith('particle.v2.'))
        .map((layer) => layer.mask)
        .toList(growable: false);
    expect(masks, isNotEmpty);
    for (var y = 0; y < 48; y++) {
      var occupied = 0;
      for (var x = 0; x < 48; x++) {
        if (masks.any((mask) => mask.get(x, y) != 0)) occupied++;
      }
      expect(occupied, lessThan(48), reason: 'row $y');
    }
  });
}
