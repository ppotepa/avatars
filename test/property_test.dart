import 'package:avatar_genome/avatar_genome.dart';
import 'package:test/test.dart';

void main() {
  test('a broad deterministic seed sample stays within core invariants', () {
    final generator = AvatarGenerator();
    final hashes = <String>{};
    for (var index = 0; index < 256; index++) {
      final result = generator.generate(
        AvatarRequest(
          seed: 'property-$index',
          settings: GenomeSettings(
            fantasy: FantasyLevel.values[index % FantasyLevel.values.length],
            symmetry: index.isEven,
          ),
        ),
      );
      hashes.add(result.imageHash);
      expect(result.image.usedColorCount, lessThanOrEqualTo(32));
      expect(result.image.indices.length, 2304);
      expect(result.layout.landmarks, isNotEmpty);
      expect(result.layers, isNotEmpty);
    }
    expect(hashes.length, greaterThan(240));
  });
}
