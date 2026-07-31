import '../geometry/pixel_rect.dart';
import '../pixels/indexed_image.dart';
import '../pixels/pixel_mask.dart';
import '../util/math_utils.dart';
import 'render_model.dart';
import 'rig_model.dart';

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
    this.scale = 1,
    this.actorOccupancy = 0,
  });

  final double x;
  final double y;
  final int width;
  final int height;
  final int baseline;
  final double scale;
  final double actorOccupancy;

  PixelMask cropMask(PixelMask source) {
    final output = PixelMask(width: width, height: height);
    for (var yy = 0; yy < height; yy++) {
      for (var xx = 0; xx < width; xx++) {
        final sx = x + xx / scale;
        final sy = y + yy / scale;
        if (source.get(sx.round(), sy.round()) != 0) output.set(xx, yy);
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
        final sx = x + xx / scale;
        final sy = y + yy / scale;
        final value = source.get(sx.round(), sy.round());
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
        'scale': scale,
        'actorOccupancy': actorOccupancy,
      };
}

abstract final class ClipCameraFitter {
  static ClipCamera fit(
    Iterable<PixelRect?> actorBounds, {
    required int canvasWidth,
    required int canvasHeight,
    int viewportWidth = 48,
    int viewportHeight = 48,
    int baseline = 53,
    int targetWidth = 44,
    int targetHeight = 44,
  }) {
    PixelRect? union;
    for (final bounds in actorBounds) {
      if (bounds == null) continue;
      union = union == null ? bounds : _union(union, bounds);
    }
    if (union == null) {
      return const ClipCamera(
        x: 4,
        y: 6,
        baseline: 53,
        scale: 1,
      );
    }

    final widthScale = targetWidth / union.width;
    final heightScale = targetHeight / union.height;
    final scale = clampDouble(
      widthScale < heightScale ? widthScale : heightScale,
      .9,
      1.25,
    );
    final sourceWidth = viewportWidth / scale;
    final sourceHeight = viewportHeight / scale;
    final centeredX = union.center.x - sourceWidth / 2;
    final bottomAlignedY = union.bottom - sourceHeight + 2;
    final maximumX = (canvasWidth - sourceWidth).clamp(0, canvasWidth).toDouble();
    final maximumY = (canvasHeight - sourceHeight).clamp(0, canvasHeight).toDouble();
    final x = clampDouble(centeredX, 0, maximumX);
    final y = clampDouble(bottomAlignedY, 0, maximumY);
    final occupancy = clampDouble(
      union.height * scale / viewportHeight,
      0,
      1,
    );

    return ClipCamera(
      x: x,
      y: y,
      width: viewportWidth,
      height: viewportHeight,
      baseline: baseline,
      scale: scale,
      actorOccupancy: occupancy,
    );
  }

  /// Bounds used for framing the readable avatar core.
  ///
  /// Large halos, wings, capes, companions and screen-space effects are soft
  /// bounds: they may approach an edge but never force the face and torso to
  /// shrink inside the preview.
  static PixelRect? actorBounds(List<RenderLayer> layers) {
    PixelRect? result;
    for (final layer in layers) {
      if (!_isCameraCore(layer)) continue;
      final bounds = layer.mask.bounds;
      if (bounds == null) continue;
      result = result == null ? bounds : _union(result, bounds);
    }
    return result;
  }

  static bool _isCameraCore(RenderLayer layer) {
    if (layer.slot == RenderSlot.background ||
        layer.slot == RenderSlot.foreground ||
        layer.slot == RenderSlot.auraBack ||
        layer.slot == RenderSlot.emotionEffects ||
        layer.slot == RenderSlot.shoulderCompanion ||
        layer.slot == RenderSlot.capeHairBack) {
      return false;
    }
    if (<String>{
      'halo',
      'aura',
      'cape',
      'backAdornment',
      'shoulderCompanion',
      'foreground',
      'atmosphere',
    }.contains(layer.nodeId)) {
      return false;
    }
    return true;
  }
}

PixelRect _union(PixelRect first, PixelRect second) {
  final left = first.left < second.left ? first.left : second.left;
  final top = first.top < second.top ? first.top : second.top;
  final right = first.right > second.right ? first.right : second.right;
  final bottom = first.bottom > second.bottom ? first.bottom : second.bottom;
  return PixelRect(left, top, right - left + 1, bottom - top + 1);
}
