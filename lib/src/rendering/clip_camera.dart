import '../geometry/pixel_rect.dart';
import '../pixels/indexed_image.dart';
import '../pixels/pixel_mask.dart';
import '../util/math_utils.dart';
import 'render_model.dart';

final class OverscanCanvas {
  const OverscanCanvas({
    this.width = 56,
    this.height = 60,
    this.sourceWidth = 48,
    this.sourceHeight = 48,
    this.offsetX = 4,
    this.offsetY = 6,
  });

  final int width;
  final int height;
  final int sourceWidth;
  final int sourceHeight;
  final int offsetX;
  final int offsetY;

  PixelMask embedMask(PixelMask source) {
    if (source.width == width && source.height == height) return source.clone();
    final output = PixelMask(width: width, height: height);
    for (var y = 0; y < source.height; y++) {
      for (var x = 0; x < source.width; x++) {
        if (source.get(x, y) != 0) output.set(x + offsetX, y + offsetY);
      }
    }
    return output;
  }

  IndexedImage embedImage(IndexedImage source) {
    if (source.width == width && source.height == height) return source.clone();
    final output = IndexedImage(
      width: width,
      height: height,
      transparentIndex: source.transparentIndex,
    );
    for (var y = 0; y < source.height; y++) {
      for (var x = 0; x < source.width; x++) {
        final value = source.get(x, y);
        if (value != source.transparentIndex) {
          output.setPixel(x + offsetX, y + offsetY, value);
        }
      }
    }
    return output;
  }

  void embedState(AvatarRenderState state) {
    for (final entry in state.masks.entries.toList(growable: false)) {
      state.masks[entry.key] = embedMask(entry.value);
    }
    for (var index = 0; index < state.layers.length; index++) {
      final layer = state.layers[index];
      state.layers[index] = layer.copyWith(mask: embedMask(layer.mask));
    }
    state.metadata['overscan'] = <String, int>{
      'width': width,
      'height': height,
      'offsetX': offsetX,
      'offsetY': offsetY,
    };
  }
}

final class ClipCamera {
  const ClipCamera({
    required this.x,
    required this.y,
    this.width = 48,
    this.height = 48,
    this.baseline = 53,
  });

  final int x;
  final int y;
  final int width;
  final int height;
  final int baseline;

  PixelMask cropMask(PixelMask source) {
    final output = PixelMask(width: width, height: height);
    for (var yy = 0; yy < height; yy++) {
      for (var xx = 0; xx < width; xx++) {
        if (source.get(x + xx, y + yy) != 0) output.set(xx, yy);
      }
    }
    return output;
  }

  IndexedImage cropImage(IndexedImage source) {
    final output = IndexedImage(
      width: width,
      height: height,
      transparentIndex: source.transparentIndex,
    );
    for (var yy = 0; yy < height; yy++) {
      for (var xx = 0; xx < width; xx++) {
        final value = source.get(x + xx, y + yy);
        if (value != source.transparentIndex) output.setPixel(xx, yy, value);
      }
    }
    return output;
  }

  List<RenderLayer> cropLayers(List<RenderLayer> layers) => <RenderLayer>[
        for (final layer in layers) layer.copyWith(mask: cropMask(layer.mask)),
      ];

  Map<String, Object> toJson() => <String, Object>{
        'x': x,
        'y': y,
        'width': width,
        'height': height,
        'baseline': baseline,
      };
}

abstract final class ClipCameraFitter {
  static ClipCamera fit(
    Iterable<PixelRect?> actorBounds, {
    required int canvasWidth,
    required int canvasHeight,
    int viewportWidth = 48,
    int viewportHeight = 48,
    int preferredX = 4,
    int preferredY = 6,
    int baseline = 53,
  }) {
    PixelRect? union;
    for (final bounds in actorBounds) {
      if (bounds == null) continue;
      union = union == null ? bounds : _union(union, bounds);
    }
    if (union == null) {
      return ClipCamera(
        x: preferredX,
        y: preferredY,
        width: viewportWidth,
        height: viewportHeight,
        baseline: baseline,
      );
    }

    final minimumX = clampInt(union.right - viewportWidth + 1, 0,
        clampInt(canvasWidth - viewportWidth, 0, canvasWidth));
    final maximumX = clampInt(union.left, minimumX,
        clampInt(canvasWidth - viewportWidth, 0, canvasWidth));
    final minimumY = clampInt(union.bottom - viewportHeight + 1, 0,
        clampInt(canvasHeight - viewportHeight, 0, canvasHeight));
    final maximumY = clampInt(union.top, minimumY,
        clampInt(canvasHeight - viewportHeight, 0, canvasHeight));

    return ClipCamera(
      x: clampInt(preferredX, minimumX, maximumX),
      y: clampInt(preferredY, minimumY, maximumY),
      width: viewportWidth,
      height: viewportHeight,
      baseline: baseline,
    );
  }

  static PixelRect? actorBounds(List<RenderLayer> layers) {
    PixelRect? result;
    for (final layer in layers) {
      if (_isSceneLayer(layer)) continue;
      final bounds = layer.mask.bounds;
      if (bounds == null) continue;
      result = result == null ? bounds : _union(result, bounds);
    }
    return result;
  }

  static bool _isSceneLayer(RenderLayer layer) =>
      layer.nodeId == 'background' ||
      layer.nodeId == 'foreground' ||
      layer.slot == RenderSlot.background ||
      layer.meta['part'] == 'weather' ||
      layer.meta['part'] == 'ambient' ||
      layer.meta['part'] == 'cosmic';
}

PixelRect _union(PixelRect first, PixelRect second) {
  final left = first.left < second.left ? first.left : second.left;
  final top = first.top < second.top ? first.top : second.top;
  final right = first.right > second.right ? first.right : second.right;
  final bottom = first.bottom > second.bottom ? first.bottom : second.bottom;
  return PixelRect(left, top, right - left + 1, bottom - top + 1);
}
