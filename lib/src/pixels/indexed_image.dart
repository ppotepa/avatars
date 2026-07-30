import 'dart:typed_data';

import '../util/math_utils.dart';
import 'pixel_mask.dart';

final class IndexedImage {
  IndexedImage({this.width = 48, this.height = 48, this.transparentIndex = 255})
      : indices = Uint8List(width * height) {
    indices.fillRange(0, indices.length, transparentIndex);
  }

  IndexedImage.fromIndices({
    required this.width,
    required this.height,
    required Uint8List indices,
    this.transparentIndex = 255,
  }) : indices = Uint8List.fromList(indices) {
    if (this.indices.length != width * height) {
      throw ArgumentError.value(this.indices.length, 'indices.length');
    }
  }

  final int width;
  final int height;
  final int transparentIndex;
  final Uint8List indices;

  IndexedImage clone() => IndexedImage.fromIndices(
        width: width,
        height: height,
        indices: indices,
        transparentIndex: transparentIndex,
      );

  IndexedImage crop(int x, int y, int cropWidth, int cropHeight) {
    final output = IndexedImage(
      width: cropWidth,
      height: cropHeight,
      transparentIndex: transparentIndex,
    );
    for (var yy = 0; yy < cropHeight; yy++) {
      for (var xx = 0; xx < cropWidth; xx++) {
        output.setPixel(xx, yy, get(x + xx, y + yy));
      }
    }
    return output;
  }

  int get(int x, int y) => x >= 0 && x < width && y >= 0 && y < height
      ? indices[y * width + x]
      : transparentIndex;

  Map<String, Object> toJson() => <String, Object>{
        'width': width,
        'height': height,
        'transparentIndex': transparentIndex,
        'indices': indices.toList(growable: false),
      };

  void setPixel(int x, int y, int paletteIndex) {
    if (x >= 0 && x < width && y >= 0 && y < height) {
      indices[y * width + x] = paletteIndex;
    }
  }

  void applyMask(PixelMask mask, int paletteIndex) {
    if (mask.width != width || mask.height != height) {
      throw ArgumentError('Mask dimensions differ from image dimensions.');
    }
    for (var i = 0; i < indices.length; i++) {
      if (mask.data[i] != 0) indices[i] = paletteIndex;
    }
  }

  String get hash {
    var value = 0x811c9dc5;
    for (final pixel in indices) {
      value ^= pixel;
      value = multiply32(value, 0x01000193);
    }
    return hex32(value);
  }

  int get usedColorCount {
    final values = <int>{};
    for (final index in indices) {
      if (index != transparentIndex) values.add(index);
    }
    return values.length;
  }
}
