import 'package:avatar_genome/avatar_genome.dart';
import 'package:test/test.dart';

void main() {
  test('larger rich renders add semantic palette detail', () {
    final generator = AvatarGenerator();
    final base = AvatarRequest(
      seed: 'native-resolution-detail',
      overrides: <String, Object>{
        'v4.background': 'solid',
        'v4.weather': 'none',
        'v4.effect': 'none',
        'v4.faceAnimation': 'none',
      },
    );

    final image48 = generator.generate(base).image;
    final image64 = generator.generate(AvatarRequest(
      seed: base.seed,
      overrides: base.overrides,
      rendering: const AvatarRenderSettings(
        size: 64,
        detailLevel: AvatarDetailLevel.rich,
        shadingStrength: 3,
      ),
    )).image;
    final image96 = generator.generate(AvatarRequest(
      seed: base.seed,
      overrides: base.overrides,
      rendering: const AvatarRenderSettings(
        size: 96,
        detailLevel: AvatarDetailLevel.rich,
        shadingStrength: 3,
      ),
    )).image;

    expect(image64.width, 64);
    expect(image96.width, 96);
    expect(image64.hash, isNot(image48.hash));
    expect(image96.hash, isNot(image64.hash));
    expect(image96.usedColorCount, greaterThanOrEqualTo(image64.usedColorCount));
  });
}
