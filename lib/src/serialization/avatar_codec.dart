import 'dart:convert';
import 'dart:typed_data';

import '../api/avatar_result.dart';
import '../palette/avatar_palette.dart';
import '../pixels/indexed_image.dart';

/// Converts a generated avatar into an application-facing representation.
abstract interface class AvatarCodec<T> {
  T encode(AvatarResult result);
}

/// Serializes the full deterministic result, including the genome and graph.
final class AvatarJsonCodec implements AvatarCodec<String> {
  const AvatarJsonCodec({this.pretty = true, this.includePixels = true});

  final bool pretty;
  final bool includePixels;

  @override
  String encode(AvatarResult result) {
    final value = result.toJson(includePixels: includePixels);
    return pretty
        ? const JsonEncoder.withIndent('  ').convert(value)
        : jsonEncode(value);
  }
}

/// Exports the indexed buffer as crisp vector rectangles.
final class AvatarSvgCodec implements AvatarCodec<String> {
  const AvatarSvgCodec({this.scale = 1, this.includeMetadata = false});

  final int scale;
  final bool includeMetadata;

  @override
  String encode(AvatarResult result) {
    final image = result.image;
    final safeScale = scale < 1 ? 1 : scale;
    final buffer = StringBuffer()
      ..writeln('<?xml version="1.0" encoding="UTF-8"?>')
      ..writeln('<svg xmlns="http://www.w3.org/2000/svg" '
          'width="${image.width * safeScale}" height="${image.height * safeScale}" '
          'viewBox="0 0 ${image.width} ${image.height}" '
          'shape-rendering="crispEdges">');
    if (includeMetadata) {
      final metadata =
          const JsonEncoder().convert(result.toJson(includePixels: false));
      buffer.writeln(
        '<metadata>${const HtmlEscape().convert(metadata)}</metadata>',
      );
    }
    for (var y = 0; y < image.height; y++) {
      var x = 0;
      while (x < image.width) {
        final color = image.get(x, y);
        if (color == image.transparentIndex) {
          x++;
          continue;
        }
        var end = x + 1;
        while (end < image.width && image.get(end, y) == color) {
          end++;
        }
        buffer.writeln(
          '<rect x="$x" y="$y" width="${end - x}" height="1" '
          'fill="${result.palette.hexAt(color)}"/>',
        );
        x = end;
      }
    }
    buffer.writeln('</svg>');
    return buffer.toString();
  }
}

/// Converts an indexed avatar to a tightly packed RGBA byte buffer.
///
/// Flutter adapters can pass these bytes to `decodeImageFromPixels` without
/// making the core package depend on `dart:ui`.
final class AvatarRgbaCodec implements AvatarCodec<Uint8List> {
  const AvatarRgbaCodec({this.scale = 1});

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
    final output = Uint8List(width * height * 4);
    var cursor = 0;
    for (var y = 0; y < height; y++) {
      final sourceY = y ~/ safeScale;
      for (var x = 0; x < width; x++) {
        final index = source.get(x ~/ safeScale, sourceY);
        if (index == source.transparentIndex) {
          output[cursor++] = 0;
          output[cursor++] = 0;
          output[cursor++] = 0;
          output[cursor++] = 0;
          continue;
        }
        final rgba = palette.colors[index];
        output[cursor++] = (rgba >> 24) & 0xff;
        output[cursor++] = (rgba >> 16) & 0xff;
        output[cursor++] = (rgba >> 8) & 0xff;
        output[cursor++] = rgba & 0xff;
      }
    }
    return output;
  }
}
