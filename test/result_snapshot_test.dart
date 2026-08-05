import 'package:avatar_genome/avatar_genome.dart';
import 'package:test/test.dart';

void main() {
  test('result owns independent frozen image and layer snapshots', () {
    final generator = AvatarGenerator();
    final result = generator.generate(
      const AvatarRequest(seed: 'result-snapshot'),
    );
    final originalHash = result.imageHash;
    final originalPixel = result.image.get(0, 0);
    final originalMaskCount = result.layers.first.mask.count;

    expect(result.image.isFrozen, isTrue);
    expect(result.layers.first.mask.isFrozen, isTrue);
    expect(() => result.image.setPixel(0, 0, 0), throwsStateError);
    expect(() => result.layers.first.mask.clear(), throwsStateError);

    final exposedMaskData = result.layers.first.mask.data;
    exposedMaskData.fillRange(0, exposedMaskData.length, 0);

    final copiedImage = result.image.clone();
    copiedImage.setPixel(0, 0, 0);
    final copiedMask = result.layers.first.mask.clone()..clear();

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
