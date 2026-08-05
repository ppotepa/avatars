import '../api/avatar_request.dart';
import '../api/avatar_result.dart';
import '../palette/avatar_palette.dart';
import '../pixels/indexed_image.dart';
import '../pixels/pixel_mask.dart';
import '../rendering/render_model.dart';
import '../util/math_utils.dart';

final class AvatarMetricsAnalyzer {
  const AvatarMetricsAnalyzer();

  AvatarMetrics analyze(
    IndexedImage image,
    AvatarRenderState state,
    AvatarPalette palette,
    AvatarRenderSettings rendering,
  ) {
    final metricLayers = state.layers
        .map((layer) =>
            layer.copyWith(mask: _scaleMask(layer.mask, image.width)))
        .toList(growable: false);
    final scene = PixelMask(width: image.width, height: image.height);
    for (var y = 0; y < image.height; y++) {
      for (var x = 0; x < image.width; x++) {
        if (image.get(x, y) != image.transparentIndex) scene.set(x, y);
      }
    }
    final sceneComponents = scene.connectedComponents();
    final sceneIsolated =
        sceneComponents.where((component) => component.length == 1).length;

    final actor = _unionLayers(metricLayers.where(_isActorLayer));
    final effects = _unionLayers(metricLayers.where(_isSceneEffectLayer));
    final face = _unionLayers(metricLayers.where(_isFaceLayer));
    final actorComponents = actor.connectedComponents();
    final actorIsolated =
        actorComponents.where((component) => component.length == 1).length;
    final actorBounds = actor.bounds;
    final faceBounds = face.bounds;
    final actorCanvasArea = actor.width * actor.height;

    final visibility = analyzeRenderVisibility(metricLayers);
    final eyeRatio = visibility.visibleRatio('eyes');
    final mouthRatio = visibility.visibleRatio('mouth');
    final eyeContrast = _contrastScore(
      palette.colors[palette.role('skinBase')],
      palette.colors[palette.role('irisBase')],
    );
    final scleraContrast = _contrastScore(
      palette.colors[palette.role('skinBase')],
      palette.colors[palette.role('sclera')],
    );
    final eyeScore =
        eyeContrast > scleraContrast ? eyeContrast : scleraContrast;
    final eyePixelContrast = _maskPixelContrast(
      image,
      _unionLayers(metricLayers.where((layer) => layer.nodeId == 'eyes')),
      palette,
    );
    final mouthPixelContrast = _maskPixelContrast(
      image,
      _unionLayers(metricLayers.where((layer) => layer.nodeId == 'mouth')),
      palette,
    );
    final finalEyeScore = ((eyeScore + eyePixelContrast) / 2).round();
    final silhouetteScore = _contrastScore(
      palette.colors[palette.role('outline')],
      palette.colors[palette.role('bg')],
    );
    final densityScore =
        _visualDensityScore(image, actor, actorComponents.length);
    final faceScore = clampInt(
      (((eyeRatio * .7 + mouthRatio * .3) * 100) * .65 +
              finalEyeScore * .2 +
              mouthPixelContrast * .15)
          .round(),
      0,
      100,
    );
    return AvatarMetrics(
      usedColorCount: _usedRenderedColorCount(image, palette),
      occupiedPixelCount: scene.count,
      isolatedPixelCount: sceneIsolated,
      connectedComponentCount: sceneComponents.length,
      actorOccupiedPixelCount: actor.count,
      actorIsolatedPixelCount: actorIsolated,
      actorConnectedComponentCount: actorComponents.length,
      actorWidthOccupancy:
          actorBounds == null ? 0 : actorBounds.width / actor.width,
      actorHeightOccupancy:
          actorBounds == null ? 0 : actorBounds.height / actor.height,
      actorAreaOccupancy:
          actorCanvasArea == 0 ? 0 : actor.count / actorCanvasArea,
      faceHeightOccupancy:
          faceBounds == null ? 0 : faceBounds.height / face.height,
      sceneEffectPixelRatio:
          actorCanvasArea == 0 ? 0 : effects.count / actorCanvasArea,
      layerCount: state.layers.length,
      visibility: visibility,
      faceReadabilityScore: faceScore,
      canvasWidth: image.width,
      canvasHeight: image.height,
      detailLevel: rendering.detailLevel.name,
      eyeContrastScore: finalEyeScore,
      silhouetteContrastScore: silhouetteScore,
      visualDensityScore: densityScore,
    );
  }

  PixelMask _unionLayers(Iterable<RenderLayer> layers) {
    PixelMask? result;
    for (final layer in layers) {
      result = result == null ? layer.mask.clone() : result.union(layer.mask);
    }
    return result ?? PixelMask();
  }

  int _usedRenderedColorCount(IndexedImage image, AvatarPalette palette) {
    final colors = <int>{};
    for (final index in image.indices) {
      if (index == image.transparentIndex || index >= palette.colors.length) {
        continue;
      }
      colors.add(palette.colors[index]);
    }
    return colors.length;
  }

  PixelMask _scaleMask(PixelMask source, int size) {
    if (source.width == size && source.height == size) return source.clone();
    final output = PixelMask(width: size, height: size);
    for (var y = 0; y < size; y++) {
      final sy = ((y + .5) * source.height / size - .5).round().clamp(
            0,
            source.height - 1,
          );
      for (var x = 0; x < size; x++) {
        final sx = ((x + .5) * source.width / size - .5).round().clamp(
              0,
              source.width - 1,
            );
        if (source.get(sx, sy) != 0) output.set(x, y);
      }
    }
    return output;
  }

  int _visualDensityScore(
    IndexedImage image,
    PixelMask actor,
    int componentCount,
  ) {
    if (actor.count == 0) return 0;
    var transitions = 0;
    for (var y = 0; y < actor.height; y++) {
      for (var x = 0; x < actor.width; x++) {
        if (actor.get(x, y) == 0) continue;
        final color = image.get(x, y);
        if (x + 1 < actor.width &&
            actor.get(x + 1, y) != 0 &&
            image.get(x + 1, y) != color) {
          transitions++;
        }
        if (y + 1 < actor.height &&
            actor.get(x, y + 1) != 0 &&
            image.get(x, y + 1) != color) {
          transitions++;
        }
      }
    }
    final transitionPressure = transitions * 100 ~/ (actor.count * 2);
    return clampInt(
      transitionPressure * 2 + (componentCount - 1) * 4,
      0,
      100,
    );
  }

  bool _isActorLayer(RenderLayer layer) =>
      !<RenderSlot>{
        RenderSlot.background,
        RenderSlot.auraBack,
        RenderSlot.emotionEffects,
        RenderSlot.foreground,
      }.contains(layer.slot) &&
      layer.nodeId != 'atmosphere' &&
      layer.nodeId != 'foreground' &&
      layer.nodeId != 'sceneSymbols';

  bool _isSceneEffectLayer(RenderLayer layer) =>
      <RenderSlot>{
        RenderSlot.auraBack,
        RenderSlot.emotionEffects,
        RenderSlot.foreground,
      }.contains(layer.slot) ||
      layer.nodeId == 'atmosphere' ||
      layer.nodeId == 'foreground' ||
      layer.nodeId == 'sceneSymbols';

  bool _isFaceLayer(RenderLayer layer) => <String>{
        'head',
        'face',
        'eyes',
        'brows',
        'mouth',
        'leftEar',
        'rightEar',
        'facialHair',
        'hairFront',
        'eyewear',
        'faceMask',
      }.contains(layer.nodeId);

  int _contrastScore(int first, int second) {
    double luma(int rgba) {
      final red = (rgba >> 24) & 0xff;
      final green = (rgba >> 16) & 0xff;
      final blue = (rgba >> 8) & 0xff;
      return red * .2126 + green * .7152 + blue * .0722;
    }

    return clampInt(
      ((luma(first) - luma(second)).abs() / 1.8).round(),
      0,
      100,
    );
  }

  int _maskPixelContrast(
    IndexedImage image,
    PixelMask mask,
    AvatarPalette palette,
  ) {
    if (mask.count == 0) return 0;
    double luma(int rgba) {
      final red = (rgba >> 24) & 0xff;
      final green = (rgba >> 16) & 0xff;
      final blue = (rgba >> 8) & 0xff;
      return red * .2126 + green * .7152 + blue * .0722;
    }

    var total = 0.0;
    var samples = 0;
    for (var y = 0; y < mask.height; y++) {
      for (var x = 0; x < mask.width; x++) {
        if (mask.get(x, y) == 0) continue;
        final source = palette.colors[image.get(x, y)];
        for (final (dx, dy) in const <(int, int)>[
          (-1, 0),
          (1, 0),
          (0, -1),
          (0, 1),
        ]) {
          final nx = x + dx;
          final ny = y + dy;
          if (nx < 0 || ny < 0 || nx >= mask.width || ny >= mask.height) {
            continue;
          }
          if (mask.get(nx, ny) != 0) continue;
          total +=
              (luma(source) - luma(palette.colors[image.get(nx, ny)])).abs();
          samples++;
        }
      }
    }
    return clampInt(
      samples == 0 ? 0 : (total / samples / 1.8).round(),
      0,
      100,
    );
  }
}
