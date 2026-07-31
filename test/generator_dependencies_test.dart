import 'package:avatar_genome/avatar_genome.dart';
import 'package:test/test.dart';

void main() {
  test('generator fields and pipeline share resolved services', () {
    final generator = AvatarGenerator();

    expect(identical(generator.genomeService, generator.pipeline.genomeGenerator), isTrue);
    expect(identical(generator.layoutResolver, generator.pipeline.layoutResolver), isTrue);
    expect(identical(generator.paletteFactory, generator.pipeline.paletteFactory), isTrue);
    expect(identical(generator.compositor, generator.pipeline.compositor), isTrue);
    expect(identical(generator.validator, generator.pipeline.validator), isTrue);
    expect(identical(generator.catalog, ParameterCatalog.current), isTrue);
  });
}
