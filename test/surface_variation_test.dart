import 'package:avatar_genome/avatar_genome.dart';
import 'package:test/test.dart';

void main() {
  final generator = AvatarGenerator();

  String signature(AvatarResult result, String prefix) {
    final layers = result.layers
        .where((layer) => layer.id.startsWith(prefix))
        .toList(growable: false)
      ..sort((a, b) => a.id.compareTo(b.id));
    return layers
        .map((layer) => '${layer.id}:${layer.mask.data.join()}')
        .join('|');
  }

  test('plate armor produces multiple procedural constructions', () {
    final signatures = <String>{};
    for (var index = 0; index < 60; index++) {
      final result = generator.generate(AvatarRequest(
        seed: 'armor-surface-$index',
        overrides: const <String, Object>{
          'v4.armor': 'plateArmor',
          'v4.armorBulk': 3,
          'v4.pauldronSize': 2,
          'v4.armorDamage': 2,
        },
      ));
      final value = signature(result, 'armor.procedural.');
      expect(value, isNotEmpty);
      signatures.add(value);
    }
    expect(signatures.length, greaterThanOrEqualTo(16));
  });

  test('hockey and headwear surface signatures remain deterministic', () {
    const request = AvatarRequest(
      seed: 'surface-deterministic',
      overrides: <String, Object>{
        'v4.headwear': 'tacticalHelmet',
        'v4.headwearDamage': 3,
        'v4.faceMask': 'hockeyMask',
      },
    );
    final first = generator.generate(request);
    final second = generator.generate(request);
    expect(
      signature(first, 'headwear.procedural.'),
      signature(second, 'headwear.procedural.'),
    );
    expect(
      signature(first, 'faceMask.procedural.'),
      signature(second, 'faceMask.procedural.'),
    );
  });
}
