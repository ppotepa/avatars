import 'dart:typed_data';

import '../util/math_utils.dart';
import 'pixel_mask.dart';

final class IndexedImage {
  IndexedImage({this.width = 48, this.height = 48, this.transparentIndex = 255})
      : _indices = Uint8List(width * height) {
    _indices.fillRange(0, _indices.length, transparentIndex);
  }

  IndexedImage.fromIndices({
    required this.width,
    required this.height,
    required Uint8List indices,
    this.transparentIndex = 255,
  }) : _indices = Uint8List.fromList(indices) {
    if (_indices.length != width * height) {
      throw ArgumentError.value(_indices.length, 'indices.length');
    }
  }

  final int width;
  final int height;
  final int transparentIndex;
  final Uint8List _indices;

  /// Returns an independent copy so callers cannot mutate image storage.
  Uint8List get indices => Uint8List.fromList(_indices);

  IndexedImage clone() => IndexedImage.fromIndices(
        width: width,
        height: height,
        indices: _indices,
        transparentIndex: transparentIndex,
      );

  int get(int x, int y) =>
      x >= 0 && x < width && y >= 0 && y < height
          ? _indices[y * width + x]
          : transparentIndex;

  Map<String, Object> toJson() => <String, Object>{
        'width': width,
        'height': height,
        'transparentIndex': transparentIndex,
        'indices': _indices.toList(growable: false),
      };

  void setPixel(int x, int y, int paletteIndex) {
    if (x >= 0 && x < width && y >= 0 && y < height) {
      _indices[y * width + x] = paletteIndex;
    }
  }

  void applyMask(PixelMask mask, int paletteIndex) {
    if (mask.width != width || mask.height != height) {
      throw ArgumentError('Mask dimensions differ from image dimensions.');
    }
    for (var i = 0; i < _indices.length; i++) {
      if (mask.data[i] != 0) _indices[i] = paletteIndex;
    }
  }

  /// A deterministic 48-bit hash of the indexed buffer and its dimensions.
  String get hash => hash48(_indices, prefix: _hashPrefix());

  /// A deterministic 48-bit hash of the complete rendered appearance.
  ///
  /// Indexed pixels alone do not identify an image because the same indices can
  /// be rendered through different palettes. The result-level image hash uses
  /// this method so color-only avatar variants receive distinct identifiers.
  String hashWithPalette(Iterable<int> rgbaColors) =>
      hash48(_indices, prefix: _hashPrefix(rgbaColors));

  List<int> _hashPrefix([Iterable<int> rgbaColors = const <int>[]]) {
    final bytes = <int>[
      width & 0xff,
      (width >> 8) & 0xff,
      height & 0xff,
      (height >> 8) & 0xff,
      transparentIndex & 0xff,
    ];
    for (final rgba in rgbaColors) {
      bytes
        ..add((rgba >> 24) & 0xff)
        ..add((rgba >> 16) & 0xff)
        ..add((rgba >> 8) & 0xff)
        ..add(rgba & 0xff);
    }
    return bytes;
  }

  int get usedColorCount {
    final values = <int>{};
    for (final index in _indices) {
      if (index != transparentIndex) values.add(index);
    }
    return values.length;
  }
}
