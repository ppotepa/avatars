import 'package:avatar_genome/avatar_genome.dart';
import 'package:test/test.dart';

void main() {
  final catalog = ParameterCatalog.v41;
  final generator = AvatarGenerator();

  test('automatic generation reaches every catalog background', () {
    final observed = <String>{};
    for (var index = 0; index < 4096; index++) {
      final result = generator.generate(AvatarRequest(
        seed: 'background-reachability-$index',
        overrides: const <String, Object>{
          'v4.worldStyle': 'mixed',
          'v4.archetype': 'auto',
        },
      ));
      observed.add(result.genome.string('v4.background'));
    }
    final expected = catalog.fieldById['v4.background']!.options
        .map((option) => option.value)
        .toSet();
    expect(observed, containsAll(expected));
  });

  test('zero complexity permits an avatar without optional V4 features', () {
    final result = generator.generate(AvatarRequest(
      seed: 'minimal-complexity-contract',
      overrides: <String, Object>{
        'v4.complexity': 0,
        'v4.randomMode': 'minimal',
      },
    ));
    for (final id in const <String>{
      'v4.headwear',
      'v4.eyewear',
      'v4.faceMask',
      'v4.earJewelry',
      'v4.facePiercing',
      'v4.neckJewelry',
      'v4.armor',
      'v4.cape',
      'v4.mouthProp',
      'v4.shoulderProp',
      'v4.cybernetics',
      'v4.scar',
      'v4.marking',
      'v4.effect',
      'v4.aura',
    }) {
      expect(result.genome.string(id), 'none', reason: id);
    }
  });

  test('text seed hashing uses values beyond the 32-bit range', () {
    final values = <int>{
      for (var index = 0; index < 256; index++)
        RandomStream(index * 0x100000001 + 0x123456789abc).seed,
    };
    expect(values.any((value) => value > 0xffffffff), isTrue);
    expect(values.length, 256);
  });

  test('disabled diagnostics do not disable safety correction', () {
    final guard = ConstraintEngine(enabled: false);
    expect(guard.correct('test', 9, 4, 'normalize'), 4);
    expect(guard.entries, isEmpty);
  });

  test('weighted picks reject a fully invalid weight set', () {
    final random = RandomStream(123);
    expect(
      () => random.weightedPick(const <WeightedValue<String>>[
        WeightedValue<String>('zero', 0),
        WeightedValue<String>('negative', -1),
      ]),
      throwsArgumentError,
    );
  });
}
