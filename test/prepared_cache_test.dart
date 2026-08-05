import 'package:avatar_genome/avatar_genome.dart';
import 'package:avatar_genome/src/genome/cached_genome_generator.dart';
import 'package:avatar_genome/src/geometry/cached_layout_resolver.dart';
import 'package:test/test.dart';

void main() {
  test('default dependencies cache genomes and layouts', () {
    final generator = AvatarGenerator(cacheCapacity: 0);
    expect(generator.genomeService, isA<CachedGenomeGenerator>());
    expect(generator.layoutResolver, isA<CachedLayoutResolver>());

    final first = generator.generate(
      const AvatarRequest(seed: 'prepared-cache'),
    );
    final second = generator.generate(
      const AvatarRequest(seed: 'prepared-cache'),
    );

    expect(second.imageHash, first.imageHash);
    expect(second.validation.toJson(), first.validation.toJson());
    expect(
      (generator.genomeService as CachedGenomeGenerator).length,
      greaterThan(0),
    );
    expect(
      (generator.layoutResolver as CachedLayoutResolver).length,
      greaterThan(0),
    );
  });
}
