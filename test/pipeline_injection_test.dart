import 'package:avatar_genome/avatar_genome.dart';
import 'package:test/test.dart';

void main() {
  test('complete pipeline cannot be combined with owned services', () {
    final base = AvatarGenerator();

    expect(
      () => AvatarGenerator(
        pipeline: base.pipeline,
        genomeService: base.genomeService,
      ),
      throwsArgumentError,
    );
    expect(
      () => AvatarGenerator(
        pipeline: base.pipeline,
        validator: base.validator,
      ),
      throwsArgumentError,
    );
  });

  test('complete pipeline remains a supported injection boundary', () {
    final base = AvatarGenerator();
    final injected = AvatarGenerator(pipeline: base.pipeline);

    expect(identical(injected.pipeline, base.pipeline), isTrue);
    expect(identical(injected.genomeService, base.pipeline.genomeGenerator), isTrue);
  });
}
