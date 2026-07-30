import 'dart:typed_data';

import 'package:image/image.dart' as img;

import '../api/avatar_result.dart';
import 'avatar_png_codec.dart';

final class AvatarGifCodec {
  const AvatarGifCodec({this.scale = 1});

  final int scale;

  Uint8List encode(AvatarAnimation animation) {
    if (animation.frames.isEmpty) return Uint8List(0);

    final encoder = img.GifEncoder();
    final frameDelay = _frameDelay(animation.safeFrameDuration);
    final pngCodec = AvatarPngCodec(scale: scale);

    for (final frame in animation.frames) {
      final pngBytes = pngCodec.encode(frame);
      final image = img.decodePng(pngBytes);
      if (image == null) {
        throw StateError('Failed to decode PNG frame for GIF encoding.');
      }
      encoder.addFrame(image, duration: frameDelay);
    }

    final bytes = encoder.finish();
    return bytes == null ? Uint8List(0) : Uint8List.fromList(bytes);
  }

  int _frameDelay(Duration duration) {
    final hundredths = (duration.inMilliseconds / 10).round();
    return hundredths < 13 ? 13 : hundredths;
  }
}
