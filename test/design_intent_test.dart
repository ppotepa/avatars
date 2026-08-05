import 'package:avatar_genome/avatar_genome.dart';
import 'package:test/test.dart';

void main() {
  test('design intent is deterministic for automatic values', () {
    final generator = AvatarGenerator();
    final request = AvatarRequest(seed: 'design-intent-deterministic');

    final first = generator.generate(request).genome;
    final second = generator.generate(request).genome;

    expect(first.values, equals(second.values));
    expect(first.sources, hasLength(second.sources.length));
    expect(
      first.sources.values.any((source) => source.source.startsWith('designIntent.')),
      isTrue,
    );
  });

  test('design intent never overwrites manual proportions', () {
    final result = AvatarGenerator().generate(AvatarRequest(
      seed: 'design-intent-manual',
      overrides: <String, Object>{
        'head.width': 23,
        'shoulders.width': 31,
        'torso.height': 12,
      },
    ));

    expect(result.genome.integer('head.width'), 23);
    expect(result.genome.integer('shoulders.width'), 31);
    expect(result.genome.integer('torso.height'), 12);
    expect(result.genome.sources['head.width']?.source, 'manual');
  });
}
