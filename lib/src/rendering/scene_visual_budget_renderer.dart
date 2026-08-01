import '../pixels/pixel_mask.dart';
import '../quality/scene_visual_noise.dart';
import '../random/random_stream.dart';
import '../util/math_utils.dart';
import 'render_model.dart';

/// Final scene-layer gate and structural visual-noise diagnostics.
final class SceneVisualBudgetRenderer implements AvatarPartRenderer {
  const SceneVisualBudgetRenderer();

  @override
  void render(AvatarRenderContext context, AvatarRenderState state) {
    final active = SceneVisualNoise.activeChannels(context.genome.values);
    final winner = active.firstOrNull;
    final removed = <String>[];

    state.layers.removeWhere((layer) {
      final channel = _channelFor(layer);
      final remove = channel != null && channel != winner;
      if (remove) removed.add(layer.id);
      return remove;
    });

    final effectLayers = state.layers
        .where((layer) => _channelFor(layer) != null)
        .toList(growable: false);
    final effectPixelLimit = effectLayers.isEmpty
        ? 0
        : (effectLayers.first.mask.width * effectLayers.first.mask.height * .12)
            .floor();
    final trimmedPixels = _trimEffectLayers(
      state,
      effectPixelLimit,
    );
    var union = PixelMask();
    var componentCount = 0;
    for (final layer in effectLayers) {
      if (layer.mask.width != union.width ||
          layer.mask.height != union.height) {
        union = PixelMask(width: layer.mask.width, height: layer.mask.height);
      }
      union = union.union(layer.mask);
      componentCount += layer.mask.connectedComponents().length;
    }
    final edgePixels =
        union.count == 0 ? 0 : union.outline(diagonal: true).count;
    final edgeDensity = union.width * union.height == 0
        ? 0.0
        : edgePixels / (union.width * union.height);
    final configured = SceneVisualNoise.score(context.genome.values);
    final structuralPressure = clampInt(
      clampInt(componentCount ~/ 12, 0, 8) + (edgeDensity * 10).round(),
      0,
      16,
    );
    final target = SceneVisualNoise.probabilisticTarget(
      context.genome.values,
      RandomStream(
        fnv1a32(
          '${context.genome.generatorVersion}:${context.genome.seed}:scene-budget',
        ),
      ).fork('target'),
    );

    state.metadata['visualNoise'] = <String, Object?>{
      'targetScore': target,
      'hardLimit': SceneVisualNoise.hardLimit,
      'configuredScore': configured,
      'finalScore': configured,
      'structuralPressure': structuralPressure,
      'activeChannel': winner,
      'configuredChannelCount': active.length,
      'activeChannelCount': winner == null ? 0 : 1,
      'effectLayerCount': effectLayers.length,
      'componentCount': componentCount,
      'edgeDensity': edgeDensity,
      'removedLayers': removed,
      'effectPixelLimit': effectPixelLimit,
      'trimmedPixels': trimmedPixels,
    };
  }

  int _trimEffectLayers(AvatarRenderState state, int limit) {
    var kept = 0;
    var removed = 0;
    for (var index = 0; index < state.layers.length; index++) {
      final layer = state.layers[index];
      if (_channelFor(layer) == null) continue;
      final available = limit - kept;
      if (available <= 0) {
        removed += layer.mask.count;
        state.layers[index] = layer.copyWith(
            mask: PixelMask(
          width: layer.mask.width,
          height: layer.mask.height,
        ));
        continue;
      }
      if (layer.mask.count <= available) {
        kept += layer.mask.count;
        continue;
      }
      final trimmed = PixelMask(
        width: layer.mask.width,
        height: layer.mask.height,
      );
      var remaining = available;
      for (var y = 0; y < layer.mask.height && remaining > 0; y++) {
        for (var x = 0; x < layer.mask.width && remaining > 0; x++) {
          if (layer.mask.get(x, y) == 0) continue;
          trimmed.set(x, y);
          remaining--;
        }
      }
      kept += trimmed.count;
      removed += layer.mask.count - trimmed.count;
      state.layers[index] = layer.copyWith(mask: trimmed);
    }
    return removed;
  }

  String? _channelFor(RenderLayer layer) {
    final id = layer.id;
    final part = layer.meta['part']?.toString();
    if (id.startsWith('cosmic.v42') || part == 'cosmic') {
      return 'v4.cosmicLayer';
    }
    if (id.startsWith('ambient.v42') || part == 'ambient') {
      return 'v4.ambientOverlay';
    }
    if (id.startsWith('flames.v42') || part == 'flames') {
      return 'v4.backFlames';
    }
    if (id.startsWith('backgroundEvent.v42') || part == 'backgroundEvent') {
      return 'v4.backgroundEvent';
    }
    if (id.startsWith('particle.v3.weather.') || part == 'weatherParticle') {
      return 'v4.weather';
    }
    if (id.startsWith('particle.v3.effect.') || part == 'effectParticle') {
      return 'v4.effect';
    }
    if (id.startsWith('rain.field') ||
        id.startsWith('weather.v42') ||
        part == 'weather' ||
        part == 'rain' ||
        part == 'rainSplash') {
      return 'v4.weather';
    }
    if (id.startsWith('effect.back') || id.startsWith('effect.front')) {
      return 'v4.effect';
    }
    return null;
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }
}
