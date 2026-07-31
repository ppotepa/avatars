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

final class ClipFrameBounds {
  const ClipFrameBounds({required this.core, required this.safety});

  final PixelRect? core;
  final PixelRect? safety;
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
    this.safetyCoverage = 1,
  });

  final double x;
  final double y;
  final int width;
  final int height;
  final int baseline;
  final double scale;
  final double actorOccupancy;
  final double safetyCoverage;

  PixelMask cropMask(PixelMask source) {
    final output = PixelMask(width: width, height: height);
    for (var yy = 0; yy < height; yy++) {
      for (var xx = 0; xx < width; xx++) {
        final sx = _sourceCoordinate(x, xx);
        final sy = _sourceCoordinate(y, yy);
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
        final sx = _sourceCoordinate(x, xx);
        final sy = _sourceCoordinate(y, yy);
        final value = source.get(sx.round(), sy.round());
        if (value != source.transparentIndex) output.setPixel(xx, yy, value);
      }
    }
    return output;
  }

  double _sourceCoordinate(double origin, int destination) =>
      origin + (destination + .5) / scale - .5;

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
        'safetyCoverage': safetyCoverage,
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
    int targetWidth = 47,
    int targetHeight = 45,
  }) =>
      fitFrames(
        actorBounds.map((bounds) => ClipFrameBounds(core: bounds, safety: bounds)),
        canvasWidth: canvasWidth,
        canvasHeight: canvasHeight,
        viewportWidth: viewportWidth,
        viewportHeight: viewportHeight,
        baseline: baseline,
        targetWidth: targetWidth,
        targetHeight: targetHeight,
      );

  static ClipCamera fitFrames(
    Iterable<ClipFrameBounds> frames, {
    required int canvasWidth,
    required int canvasHeight,
    int viewportWidth = 48,
    int viewportHeight = 48,
    int baseline = 53,
    int targetWidth = 47,
    int targetHeight = 45,
  }) {
    PixelRect? core;
    PixelRect? safety;
    for (final frame in frames) {
      if (frame.core != null) {
        core = core == null ? frame.core : _union(core, frame.core!);
      }
      if (frame.safety != null) {
        safety = safety == null ? frame.safety : _union(safety, frame.safety!);
      }
    }
    core ??= safety;
    safety ??= core;
    if (core == null) {
      return const ClipCamera(x: 4, y: 6, baseline: 53, scale: 1);
    }

    final widthScale = targetWidth / core.width;
    final heightScale = targetHeight / core.height;
    final scale = clampDouble(
      widthScale < heightScale ? widthScale : heightScale,
      .88,
      1.65,
    );
    final sourceWidth = viewportWidth / scale;
    final sourceHeight = viewportHeight / scale;
    final centeredX = core.center.x - sourceWidth / 2;
    final bottomAlignedY = core.bottom - sourceHeight + 2;
    final maximumX = (canvasWidth - sourceWidth).clamp(0, canvasWidth).toDouble();
    final maximumY = (canvasHeight - sourceHeight).clamp(0, canvasHeight).toDouble();

    var x = clampDouble(centeredX, 0, maximumX);
    var y = clampDouble(bottomAlignedY, 0, maximumY);
    if (safety != null) {
      x = _nudgeAxis(
        position: x,
        size: sourceWidth,
        minimum: safety.left.toDouble(),
        maximum: safety.right.toDouble(),
        lowerBound: 0,
        upperBound: maximumX,
        maximumNudge: 3,
      );
      y = _nudgeAxis(
        position: y,
        size: sourceHeight,
        minimum: safety.top.toDouble(),
        maximum: safety.bottom.toDouble(),
        lowerBound: 0,
        upperBound: maximumY,
        maximumNudge: 3,
      );
    }

    final occupancy = clampDouble(core.height * scale / viewportHeight, 0, 1);
    final coverage = safety == null
        ? 1.0
        : _coverage(
            safety,
            x: x,
            y: y,
            width: sourceWidth,
            height: sourceHeight,
          );
    return ClipCamera(
      x: x,
      y: y,
      width: viewportWidth,
      height: viewportHeight,
      baseline: baseline,
      scale: scale,
      actorOccupancy: occupancy,
      safetyCoverage: coverage,
    );
  }

  static ClipFrameBounds frameBounds(List<RenderLayer> layers) {
    PixelRect? core;
    PixelRect? safety;
    for (final layer in layers) {
      final bounds = layer.mask.bounds;
      if (bounds == null) continue;
      if (_isSafetyActor(layer)) {
        safety = safety == null ? bounds : _union(safety, bounds);
      }
      if (_isCameraCore(layer)) {
        core = core == null ? bounds : _union(core, bounds);
      }
    }
    return ClipFrameBounds(core: core ?? safety, safety: safety ?? core);
  }

  static PixelRect? actorBounds(List<RenderLayer> layers) =>
      frameBounds(layers).core;

  static bool _isCameraCore(RenderLayer layer) => <String>{
        'torso',
        'chest',
        'clothing',
        'armor',
        'neck',
        'head',
        'face',
        'eyes',
        'brows',
        'mouth',
        'facialHair',
        'hairFront',
        'ears',
        'leftEar',
        'rightEar',
      }.contains(layer.nodeId);

  static bool _isSafetyActor(RenderLayer layer) {
    if (layer.slot == RenderSlot.background ||
        layer.slot == RenderSlot.foreground ||
        layer.slot == RenderSlot.auraBack ||
        layer.slot == RenderSlot.emotionEffects) {
      return false;
    }
    return !<String>{
      'scene',
      'background',
      'foreground',
      'atmosphere',
      'sceneSymbols',
      'actorSymbols',
    }.contains(layer.nodeId);
  }

  static double _nudgeAxis({
    required double position,
    required double size,
    required double minimum,
    required double maximum,
    required double lowerBound,
    required double upperBound,
    required double maximumNudge,
  }) {
    var output = position;
    if (minimum < output) {
      output -= clampDouble(output - minimum, 0, maximumNudge);
    }
    if (maximum > output + size - 1) {
      output += clampDouble(maximum - (output + size - 1), 0, maximumNudge);
    }
    return clampDouble(output, lowerBound, upperBound);
  }

  static double _coverage(
    PixelRect bounds, {
    required double x,
    required double y,
    required double width,
    required double height,
  }) {
    final left = bounds.left > x ? bounds.left.toDouble() : x;
    final top = bounds.top > y ? bounds.top.toDouble() : y;
    final rightLimit = x + width - 1;
    final bottomLimit = y + height - 1;
    final right = bounds.right < rightLimit ? bounds.right.toDouble() : rightLimit;
    final bottom = bounds.bottom < bottomLimit ? bounds.bottom.toDouble() : bottomLimit;
    if (right < left || bottom < top) return 0;
    final visibleArea = (right - left + 1) * (bottom - top + 1);
    final totalArea = bounds.width * bounds.height;
    return clampDouble(visibleArea / totalArea, 0, 1);
  }
}

PixelRect _union(PixelRect first, PixelRect second) {
  final left = first.left < second.left ? first.left : second.left;
  final top = first.top < second.top ? first.top : second.top;
  final right = first.right > second.right ? first.right : second.right;
  final bottom = first.bottom > second.bottom ? first.bottom : second.bottom;
  return PixelRect(left, top, right - left + 1, bottom - top + 1);
}
