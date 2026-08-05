import 'package:avatar_genome/avatar_genome.dart';
import 'package:test/test.dart';

void main() {
  test('result owns independent image and layer snapshots', () {
    final generator = AvatarGenerator();
    final result = generator.generate(
      const AvatarRequest(seed: 'result-snapshot'),
    );
    final originalHash = result.imageHash;
    final originalPixel = result.image.get(0, 0);
    final originalMaskCount = result.layers.first.mask.count;

    final copiedImage = result.image.clone();
    copiedImage.setPixel(0, 0, 0);
    final copiedMask = result.layers.first.mask.clone();
    copiedMask.data.fillRange(0, copiedMask.data.length, 0);

    expect(result.imageHash, originalHash);
    expect(result.image.get(0, 0), originalPixel);
    expect(result.layers.first.mask.count, originalMaskCount);
    expect(copiedMask.count, 0);
  });

  test('animation frames are exposed through an immutable list', () {
    final animation = AvatarGenerator().generateAnimation(
      const AvatarRequest(seed: 'animation-snapshot'),
      frameCount: 2,
    );

    expect(() => animation.frames.clear(), throwsUnsupportedError);
  });
}
