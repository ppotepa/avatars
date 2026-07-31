import 'package:avatar_genome/avatar_genome.dart';
import 'package:test/test.dart';

void main() {
  test('camera samples image and masks through the same pixel centers', () {
    final mask = PixelMask(width: 8, height: 8)..set(3, 3);
    final image = IndexedImage(width: 8, height: 8)..setPixel(3, 3, 7);
    const camera = ClipCamera(
      x: 1.25,
      y: 1.25,
      width: 6,
      height: 6,
      scale: 1.5,
    );

    final croppedMask = camera.cropMask(mask);
    final croppedImage = camera.cropImage(image);
    for (var y = 0; y < croppedMask.height; y++) {
      for (var x = 0; x < croppedMask.width; x++) {
        expect(
          croppedMask.get(x, y) != 0,
          croppedImage.get(x, y) == 7,
          reason: 'mismatch at $x,$y',
        );
      }
    }
  });
}
