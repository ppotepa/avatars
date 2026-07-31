import '../geometry/pixel_rect.dart';
import '../pixels/indexed_image.dart';
import '../pixels/pixel_mask.dart';
import '../util/math_utils.dart';
import 'render_model.dart';
import 'rig_model.dart';

final class OverscanCanvas {
  const OverscanCanvas({
    this.width = 72,
    this.height = 72,
    this.sourceWidth = 48,
    this.sourceHeight = 48,
    this.offsetX = 12,
    this.offsetY = 12,
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

enum ClipCameraProfile { portrait, expressive, wide }

final class ClipFrameBounds {
  const ClipFrameBounds({
    required this.core,
    required this.safety,
    this.critical,
  });

  final PixelRect? core;
  final PixelRect? safety;
  final PixelRect? critical;
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
    this.criticalCoverage = 1,
    this.profile = ClipCameraProfile.portrait,
  });

  final double x;
  final double y;
  final int width;
  final int height;
  final int baseline;
  final double scale;
  final double actorOccupancy;
  final double safetyCoverage;
  final double criticalCoverage;
  final ClipCameraProfile profile;

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
        'criticalCoverage': criticalCoverage,
        'profile': profile.name,
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
        actorBounds.map((bounds) =>
            ClipFrameBounds(core: bounds, safety: bounds, critical: bounds)),
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
    PixelRect? critical;
    for (final frame in frames) {
      if (frame.core != null) core = core == null ? frame.core : _union(core, frame.core!);
      if (frame.safety != null) {
        safety = safety == null ? frame.safety : _union(safety, frame.safety!);
      }
      if (frame.critical != null) {
        critical = critical == null
            ? frame.critical
            : _union(critical, frame.critical!);
      }
    }
    core ??= safety;
    safety ??= core;
    critical ??= core;
    if (core == null) {
      return const ClipCamera(x: 12, y: 12, baseline: 59, scale: 1);
    }

    final profile = _profile(core, safety, critical);
    final settings = switch (profile) {
      ClipCameraProfile.portrait => (
          targetWidth: targetWidth,
          targetHeight: targetHeight,
          minScale: .88,
          maxScale: 1.65,
          minimumSafety: .55,
          maximumNudge: 5.0,
        ),
      ClipCameraProfile.expressive => (
          targetWidth: 44,
          targetHeight: 43,
          minScale: .82,
          maxScale: 1.40,
          minimumSafety: .72,
          maximumNudge: 8.0,
        ),
      ClipCameraProfile.wide => (
          targetWidth: 42,
          targetHeight: 41,
          minScale: .70,
          maxScale: 1.20,
          minimumSafety: .82,
          maximumNudge: 12.0,
        ),
    };

    final widthScale = settings.targetWidth / core.width;
    final heightScale = settings.targetHeight / core.height;
    var scale = clampDouble(
      widthScale < heightScale ? widthScale : heightScale,
      settings.minScale,
      settings.maxScale,
    );

    ({double x, double y, double sourceWidth, double sourceHeight}) positionFor(
      double candidateScale,
    ) {
      final sourceWidth = viewportWidth / candidateScale;
      final sourceHeight = viewportHeight / candidateScale;
      final focus = critical ?? core!;
      final centeredX = focus.center.x - sourceWidth / 2;
      final bottomAlignedY = core!.bottom - sourceHeight + 2;
      final maximumX =
          (canvasWidth - sourceWidth).clamp(0, canvasWidth).toDouble();
      final maximumY =
          (canvasHeight - sourceHeight).clamp(0, canvasHeight).toDouble();
      var x = clampDouble(centeredX, 0, maximumX);
      var y = clampDouble(bottomAlignedY, 0, maximumY);
      if (safety != null) {
        x = _nudgeAxis(
          position: x,
          size: sourceWidth,
          minimum: safety!.left.toDouble(),
          maximum: safety!.right.toDouble(),
          lowerBound: 0,
          upperBound: maximumX,
          maximumNudge: settings.maximumNudge,
        );
        y = _nudgeAxis(
          position: y,
          size: sourceHeight,
          minimum: safety!.top.toDouble(),
          maximum: safety!.bottom.toDouble(),
          lowerBound: 0,
          upperBound: maximumY,
          maximumNudge: settings.maximumNudge,
        );
      }
      return (x: x, y: y, sourceWidth: sourceWidth, sourceHeight: sourceHeight);
    }

    var position = positionFor(scale);
    var coverage = safety == null
        ? 1.0
        : _coverage(
            safety!,
            x: position.x,
            y: position.y,
            width: position.sourceWidth,
            height: position.sourceHeight,
          );
    while (coverage < settings.minimumSafety && scale > settings.minScale) {
      scale = clampDouble(scale - .04, settings.minScale, settings.maxScale);
      position = positionFor(scale);
      coverage = safety == null
          ? 1.0
          : _coverage(
              safety!,
              x: position.x,
              y: position.y,
              width: position.sourceWidth,
              height: position.sourceHeight,
            );
    }

    final occupancy = clampDouble(core.height * scale / viewportHeight, 0, 1);
    final criticalCoverage = critical == null
        ? 1.0
        : _coverage(
            critical!,
            x: position.x,
            y: position.y,
            width: position.sourceWidth,
            height: position.sourceHeight,
          );
    return ClipCamera(
      x: position.x,
      y: position.y,
      width: viewportWidth,
      height: viewportHeight,
      baseline: baseline,
      scale: scale,
      actorOccupancy: occupancy,
      safetyCoverage: coverage,
      criticalCoverage: criticalCoverage,
      profile: profile,
    );
  }

  static ClipFrameBounds frameBounds(List<RenderLayer> layers) {
    PixelRect? core;
    PixelRect? safety;
    PixelRect? critical;
    for (final layer in layers) {
      final bounds = layer.mask.bounds;
      if (bounds == null) continue;
      if (_isSafetyActor(layer)) safety = safety == null ? bounds : _union(safety, bounds);
      if (_isCameraCore(layer)) core = core == null ? bounds : _union(core, bounds);
      if (_isCriticalActor(layer)) {
        critical = critical == null ? bounds : _union(critical, bounds);
      }
    }
    return ClipFrameBounds(
      core: core ?? safety,
      safety: safety ?? core,
      critical: critical ?? core,
    );
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

  static bool _isCriticalActor(RenderLayer layer) => <String>{
        'head',
        'face',
        'eyes',
        'mouth',
        'leftForearm',
        'rightForearm',
        'leftWrist',
        'rightWrist',
        'leftHand',
        'rightHand',
        'shoulderCompanion',
        'companionBody',
      }.contains(layer.nodeId);

  static bool _isSafetyActor(RenderLayer layer) {
    if (<RenderSlot>{
      RenderSlot.background,
      RenderSlot.backgroundDetail,
      RenderSlot.atmosphereBack,
      RenderSlot.foreground,
      RenderSlot.auraBack,
      RenderSlot.emotionEffects,
    }.contains(layer.slot)) {
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

  static ClipCameraProfile _profile(
    PixelRect core,
    PixelRect? safety,
    PixelRect? critical,
  ) {
    if (safety != null &&
        (safety.width > core.width * 1.45 || safety.height > core.height * 1.25)) {
      return ClipCameraProfile.wide;
    }
    if (critical != null &&
        (critical.width > core.width * 1.12 || critical.height > core.height)) {
      return ClipCameraProfile.expressive;
    }
    return ClipCameraProfile.portrait;
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
