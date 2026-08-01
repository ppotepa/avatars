import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../api/avatar_result.dart';
import '../palette/avatar_palette.dart';
import '../pixels/indexed_image.dart';
import 'avatar_codec.dart';

/// PNG adapter for Android, iOS and desktop Dart/Flutter targets.
///
/// Only this adapter imports `dart:io`; the generator core remains portable.
final class AvatarPngCodec implements AvatarCodec<Uint8List> {
  const AvatarPngCodec({this.scale = 1});

  final int scale;

  @override
  Uint8List encode(AvatarResult result) => encodeImage(
        result.image,
        result.palette,
        scale: scale,
      );

  Uint8List encodeImage(
    IndexedImage source,
    AvatarPalette palette, {
    int scale = 1,
  }) {
    final safeScale = scale < 1 ? 1 : scale;
    final width = source.width * safeScale;
    final height = source.height * safeScale;
    final rgba = const AvatarRgbaCodec().encodeImage(
      source,
      palette,
      scale: safeScale,
    );
    return encodeRgba(rgba, width: width, height: height);
  }

  /// Encodes a packed RGBA buffer into a PNG without constructing an avatar.
  static Uint8List encodeRgba(
    Uint8List rgba, {
    required int width,
    required int height,
  }) {
    if (width < 1 || height < 1 || rgba.length != width * height * 4) {
      throw ArgumentError('RGBA buffer dimensions are invalid.');
    }
    final raw = BytesBuilder(copy: false);
    final rowLength = width * 4;
    for (var y = 0; y < height; y++) {
      raw.addByte(0); // PNG filter: None.
      raw.add(Uint8List.sublistView(rgba, y * rowLength, (y + 1) * rowLength));
    }
    final compressed = ZLibCodec(level: 6).encode(raw.takeBytes());
    final output = BytesBuilder(copy: false)
      ..add(const <int>[137, 80, 78, 71, 13, 10, 26, 10])
      ..add(_chunk('IHDR', _ihdr(width, height)))
      ..add(_chunk('IDAT', Uint8List.fromList(compressed)))
      ..add(_chunk('IEND', Uint8List(0)));
    return output.takeBytes();
  }

  static Uint8List _ihdr(int width, int height) {
    final data = ByteData(13)
      ..setUint32(0, width)
      ..setUint32(4, height)
      ..setUint8(8, 8)
      ..setUint8(9, 6)
      ..setUint8(10, 0)
      ..setUint8(11, 0)
      ..setUint8(12, 0);
    return data.buffer.asUint8List();
  }

  static Uint8List _chunk(String type, Uint8List data) {
    final typeBytes = ascii.encode(type);
    final bytes = BytesBuilder(copy: false)
      ..add(_uint32(data.length))
      ..add(typeBytes)
      ..add(data)
      ..add(_uint32(_crc32(<int>[...typeBytes, ...data])));
    return bytes.takeBytes();
  }

  static Uint8List _uint32(int value) {
    final data = ByteData(4)..setUint32(0, value & 0xffffffff);
    return data.buffer.asUint8List();
  }

  static int _crc32(List<int> bytes) {
    var crc = 0xffffffff;
    for (final byte in bytes) {
      crc ^= byte;
      for (var bit = 0; bit < 8; bit++) {
        crc = (crc & 1) != 0 ? (crc >> 1) ^ 0xedb88320 : crc >> 1;
      }
    }
    return (crc ^ 0xffffffff) & 0xffffffff;
  }
}

/// Encodes animation frames into a PNG sprite sheet plus separate metadata.
final class AvatarSpriteSheetCodec {
  const AvatarSpriteSheetCodec({this.columns = 4, this.scale = 1});

  final int columns;
  final int scale;

  Uint8List encode(AvatarAnimation animation) {
    if (animation.frames.isEmpty) return Uint8List(0);
    final cols = columns < 1 ? 1 : columns;
    final rows = (animation.frames.length / cols).ceil();
    final first = animation.frames.first;
    final frameWidth = first.image.width;
    final frameHeight = first.image.height;
    final sheet = IndexedImage(
      width: frameWidth * cols,
      height: frameHeight * rows,
    );
    for (var frameIndex = 0;
        frameIndex < animation.frames.length;
        frameIndex++) {
      final frame = animation.frames[frameIndex].image;
      final column = frameIndex % cols;
      final row = frameIndex ~/ cols;
      for (var y = 0; y < frame.height; y++) {
        for (var x = 0; x < frame.width; x++) {
          sheet.setPixel(
            column * frameWidth + x,
            row * frameHeight + y,
            frame.get(x, y),
          );
        }
      }
    }
    return const AvatarPngCodec().encodeImage(
      sheet,
      first.palette,
      scale: scale,
    );
  }

  Map<String, Object> metadata(AvatarAnimation animation) => <String, Object>{
        'frameCount': animation.frames.length,
        'frameDurationMs': animation.frameDuration.inMilliseconds,
        'loop': animation.loop,
        'columns': columns,
        'frameWidth':
            animation.frames.isEmpty ? 0 : animation.frames.first.image.width,
        'frameHeight':
            animation.frames.isEmpty ? 0 : animation.frames.first.image.height,
      };
}
