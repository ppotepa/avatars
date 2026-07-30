import 'package:avatar_genome/src/pixels/pixel_mask.dart';
import 'package:test/test.dart';

void main() {
  test('hLine ignores fully off-canvas horizontal segments', () {
    final mask = PixelMask(width: 8, height: 8)
      ..hLine(-5, -1, 3)
      ..hLine(8, 12, 4);

    expect(mask.count, 0);
  });

  test('vLine ignores fully off-canvas vertical segments', () {
    final mask = PixelMask(width: 8, height: 8)
      ..vLine(-1, 0, 7)
      ..vLine(8, 0, 7)
      ..vLine(2, -4, -1)
      ..vLine(5, 8, 10);

    expect(mask.count, 0);
  });
}
