import 'package:avatar_genome/avatar_genome.dart';
import 'package:test/test.dart';

void main() {
  test('48 64 and 96 preserve identity but produce native output detail', () {
    final generator = AvatarGenerator();
    const seed = 'native-resolution-e2e';
    const base = AvatarRequest(seed: seed);

    final result48 = generator.generate(base);
    final result64 = generator.generate(AvatarRequest(
      seed: seed,
      rendering: const AvatarRenderSettings(
        size: 64,
        detailLevel: AvatarDetailLevel.rich,
        shadingStrength: 2,
      ),
    ));
    final result96 = generator.generate(AvatarRequest(
      seed: seed,
      rendering: const AvatarRenderSettings(
        size: 96,
        detailLevel: AvatarDetailLevel.rich,
        shadingStrength: 2,
      ),
    ));

    expect(result48.genome.values, result64.genome.values);
    expect(result48.genome.values, result96.genome.values);
    expect(result48.image.width, 48);
    expect(result64.image.width, 64);
    expect(result96.image.width, 96);
    expect(result64.imageHash, isNot(result48.imageHash));
    expect(result96.imageHash, isNot(result64.imageHash));

    final naive64 = _nearest(result48.image, 64);
    final naive96 = _nearest(result48.image, 96);
    expect(_differentPixels(result64.image, naive64), greaterThan(0));
    expect(_differentPixels(result96.image, naive96), greaterThan(0));

    expect(
      result48.nativeGeometryDiagnostics['geometryProfile'],
      'canonical48',
    );
    expect(
      result64.nativeGeometryDiagnostics['nativeGeometryPixelCount'],
      greaterThan(0),
    );
    expect(
      result96.nativeGeometryDiagnostics['nativeGeometryPixelCount'],
      greaterThan(0),
    );
    expect(
      result64.nativeGeometryDiagnostics['geometryProfile'],
      startsWith('native64.'),
    );
    expect(
      result96.nativeGeometryDiagnostics['geometryProfile'],
      startsWith('native96.'),
    );

    final repeated64 = generator.generate(AvatarRequest(
      seed: seed,
      rendering: const AvatarRenderSettings(
        size: 64,
        detailLevel: AvatarDetailLevel.rich,
        shadingStrength: 2,
      ),
    ));
    expect(repeated64.imageHash, result64.imageHash);
    expect(
      repeated64.nativeGeometryDiagnostics,
      result64.nativeGeometryDiagnostics,
    );
  });
}

IndexedImage _nearest(IndexedImage source, int size) {
  final output = IndexedImage(
    width: size,
    height: size,
    transparentIndex: source.transparentIndex,
  );
  for (var y = 0; y < size; y++) {
    final sy = y * source.height ~/ size;
    for (var x = 0; x < size; x++) {
      final sx = x * source.width ~/ size;
      final value = source.get(sx, sy);
      if (value != source.transparentIndex) output.setPixel(x, y, value);
    }
  }
  return output;
}

int _differentPixels(IndexedImage first, IndexedImage second) {
  expect(first.width, second.width);
  expect(first.height, second.height);
  var count = 0;
  for (var index = 0; index < first.indices.length; index++) {
    if (first.indices[index] != second.indices[index]) count++;
  }
  return count;
}
