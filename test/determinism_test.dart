import 'package:avatar_genome/avatar_genome.dart';
import 'package:test/test.dart';

void main() {
  final generator = AvatarGenerator();

  test('the same request produces the same genome and image', () {
    const request = AvatarRequest(seed: 'deterministic-user-1');
    final first = generator.generate(request);
    final second = generator.generate(request);

    expect(second.imageHash, first.imageHash);
    expect(second.genome.values, first.genome.values);
    expect(second.image.indices, first.image.indices);
  });

  test('different seeds explore different genomes', () {
    final hashes = <String>{};
    for (var index = 0; index < 64; index++) {
      final result = generator.generate(AvatarRequest(seed: 'seed-$index'));
      hashes.add(result.imageHash);
    }
    expect(hashes.length, greaterThan(56));
  });

  test('result uses a 48x48 indexed buffer and at most 32 colors', () {
    final result = generator.generate(const AvatarRequest(seed: 'dimensions'));
    expect(result.image.width, 48);
    expect(result.image.height, 48);
    expect(result.image.indices.length, 48 * 48);
    expect(result.image.usedColorCount, lessThanOrEqualTo(32));
    expect(
      result.image.indices.every(
        (index) => index == result.image.transparentIndex || index < 32,
      ),
      isTrue,
    );
  });

  test('category nonce rerolls only the requested category at genome level',
      () {
    const request = AvatarRequest(seed: 'category-reroll');
    final base = generator.generate(request);
    final rerolled = generator.generate(
      AvatarPresetService().rerollCategory(request, 'hair'),
    );
    final hairIds = ParameterCatalog.v41.categoryById['hair']!.fields
        .map((field) => field.id)
        .toSet();

    expect(
      hairIds.any(
        (id) => base.genome.values[id] != rerolled.genome.values[id],
      ),
      isTrue,
    );
    for (final field in ParameterCatalog.v41.fields) {
      if (!hairIds.contains(field.id) &&
          !field.id.startsWith('v4.') &&
          base.genome.sources[field.id]?.source == 'auto') {
        expect(
          rerolled.genome.values[field.id],
          base.genome.values[field.id],
          reason: field.id,
        );
      }
    }
  });
}
