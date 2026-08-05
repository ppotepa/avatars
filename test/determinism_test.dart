import 'package:avatar_genome/avatar_genome.dart';
import 'package:test/test.dart';

void main() {
  final generator = AvatarGenerator();

  test('the same request produces the same genome and image', () {
    final request = AvatarRequest(seed: 'deterministic-user-1');
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
    final result = generator.generate(AvatarRequest(seed: 'dimensions'));
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

  test('result reports final semantic visibility', () {
    final result = generator.generate(AvatarRequest(
      seed: 'visibility-contract',
      overrides: <String, Object>{
        'eyes.shape': 'round',
        'eyes.width': 5,
        'eyes.height': 3,
      },
    ));
    expect(result.metrics.visibility.sourcePixels['eyes'], greaterThan(0));
    expect(result.metrics.visibility.visiblePixels['eyes'], greaterThan(0));
    expect(result.metrics.faceReadabilityScore, inInclusiveRange(0, 100));
  });

  test('all four render sizes preserve the genome and render natively', () {
    const sizes = AvatarRenderSettings.supportedSizes;
    final results = <AvatarResult>[
      for (final size in sizes)
        generator.generate(AvatarRequest(
          seed: 'multi-resolution',
          rendering: AvatarRenderSettings(
            size: size,
            detailLevel: AvatarDetailLevel.rich,
          ),
        )),
    ];
    for (var index = 0; index < sizes.length; index++) {
      expect(results[index].image.width, sizes[index]);
      expect(results[index].image.height, sizes[index]);
      expect(results[index].metrics.canvasWidth, sizes[index]);
      expect(results[index].image.indices.length, sizes[index] * sizes[index]);
      expect(results[index].genome.values, results.first.genome.values);
    }
    expect(results.map((result) => result.imageHash).toSet(), hasLength(4));
  });

  test('enhanced 96x96 render adds deterministic detail over basic scaling', () {
    final basic = AvatarRequest(
      seed: 'detail-profile',
      rendering: const AvatarRenderSettings(
        size: 96,
        detailLevel: AvatarDetailLevel.basic,
      ),
    );
    final rich = AvatarRequest(
      seed: 'detail-profile',
      rendering: const AvatarRenderSettings(
        size: 96,
        detailLevel: AvatarDetailLevel.rich,
        shadingStrength: 3,
      ),
    );
    final basicResult = generator.generate(basic);
    final richResult = generator.generate(rich);
    expect(richResult.genome.values, basicResult.genome.values);
    expect(richResult.imageHash, isNot(basicResult.imageHash));
    expect(generator.generate(rich).imageHash, richResult.imageHash);
  });

  test('48x48 compatibility render ignores presentation-only detail controls', () {
    final base = AvatarRequest(seed: 'legacy-48');
    final rich = AvatarRequest(
      seed: 'legacy-48',
      rendering: const AvatarRenderSettings(
        detailLevel: AvatarDetailLevel.rich,
        lightingDirection: AvatarLightingDirection.upperRight,
        shadingStrength: 3,
      ),
    );
    expect(
      generator.generate(rich).image.indices,
      generator.generate(base).image.indices,
    );
  });

  test('unsupported render sizes fail explicitly', () {
    expect(
      () => generator.generate(
        AvatarRequest(
          seed: 'invalid-size',
          rendering: const AvatarRenderSettings(size: 72),
        ),
      ),
      throwsArgumentError,
    );
  });

  test('category nonce rerolls only the requested category at genome level', () {
    final request = AvatarRequest(seed: 'category-reroll');
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
