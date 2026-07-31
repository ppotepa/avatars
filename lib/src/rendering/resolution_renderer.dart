import '../api/avatar_request.dart';
import '../palette/avatar_palette.dart';
import '../pixels/indexed_image.dart';
import 'native_detail_renderer.dart';
import 'render_model.dart';
import 'resolution_render_cache.dart';

/// Expands the canonical composition to the requested pixel grid, applies
/// material-aware semantic detail and caches the immutable final image.
final class ResolutionAwareRenderer {
  const ResolutionAwareRenderer({
    this.nativeDetails = const NativeDetailRenderer(),
  });

  final NativeDetailRenderer nativeDetails;
  static final ResolutionRenderCache _cache = ResolutionRenderCache();

  IndexedImage render({
    required IndexedImage source,
    required List<RenderLayer> layers,
    required AvatarPalette palette,
    required AvatarRenderSettings settings,
    required int phase,
  }) {
    if (settings.size == source.width && settings.size == source.height) {
      return source;
    }

    final key = _cacheKey(source, layers, palette, settings, phase);
    final cached = _cache.get(key);
    if (cached != null) return cached;

    final owners = _owners(layers, source.width, source.height);
    final output = IndexedImage(width: settings.size, height: settings.size);
    for (var y = 0; y < output.height; y++) {
      final sy = _sourceCoordinate(y, output.height, source.height);
      for (var x = 0; x < output.width; x++) {
        final sx = _sourceCoordinate(x, output.width, source.width);
        final original = source.get(sx, sy);
        if (original == source.transparentIndex) continue;
        output.setPixel(
          x,
          y,
          _shade(
            source: source,
            palette: palette,
            settings: settings,
            owner: owners[sy * source.width + sx] ?? '',
            original: original,
            sx: sx,
            sy: sy,
            x: x,
            y: y,
          ),
        );
      }
    }

    final enhanced = nativeDetails.enhance(
      image: output,
      source: source,
      layers: layers,
      palette: palette,
      settings: settings,
      phase: phase,
    );
    _cache.put(key, enhanced);
    return enhanced;
  }

  String _cacheKey(
    IndexedImage source,
    List<RenderLayer> layers,
    AvatarPalette palette,
    AvatarRenderSettings settings,
    int phase,
  ) {
    final layerSignature = layers
        .map((layer) =>
            '${layer.id}:${layer.nodeId}:${layer.slot.index}:${layer.localOrder}:${layer.mask.count}')
        .join('|');
    return '${source.hashWithPalette(palette.colors)}:'
        '${settings.size}:${settings.detailLevel.name}:'
        '${settings.lightingDirection.name}:${settings.shadingStrength}:'
        '$phase:$layerSignature';
  }

  int _sourceCoordinate(int destination, int destinationSize, int sourceSize) {
    final mirrored = destination >= destinationSize ~/ 2;
    final localDestination =
        mirrored ? destinationSize - 1 - destination : destination;
    final halfDestination = destinationSize ~/ 2;
    final halfSource = sourceSize ~/ 2;
    final localSource =
        ((2 * localDestination + 1) * halfSource) ~/ (2 * halfDestination);
    return mirrored ? sourceSize - 1 - localSource : localSource;
  }

  int _shade({
    required IndexedImage source,
    required AvatarPalette palette,
    required AvatarRenderSettings settings,
    required String owner,
    required int original,
    required int sx,
    required int sy,
    required int x,
    required int y,
  }) {
    if (settings.detailLevel == AvatarDetailLevel.basic ||
        settings.shadingStrength == 0) {
      return original;
    }

    final size = settings.size;
    final leftEdge = x == 0 ||
        _sourceCoordinate(x - 1, size, source.width) != sx;
    final rightEdge = x == size - 1 ||
        _sourceCoordinate(x + 1, size, source.width) != sx;
    final topEdge = y == 0 ||
        _sourceCoordinate(y - 1, size, source.height) != sy;
    final bottomEdge = y == size - 1 ||
        _sourceCoordinate(y + 1, size, source.height) != sy;
    final frontal =
        settings.lightingDirection == AvatarLightingDirection.frontal;
    final fromRight =
        settings.lightingDirection == AvatarLightingDirection.upperRight;
    final lightEdge = topEdge || (!frontal && (fromRight ? rightEdge : leftEdge));
    final shadowEdge =
        bottomEdge || (!frontal && (fromRight ? leftEdge : rightEdge));

    if (lightEdge) return _ramp(original, palette, lighter: true, owner: owner);
    if (settings.shadingStrength >= 2 && shadowEdge) {
      return _ramp(original, palette, lighter: false, owner: owner);
    }
    return original;
  }

  int _ramp(
    int color,
    AvatarPalette palette, {
    required bool lighter,
    required String owner,
  }) {
    final roles = palette.roles;
    final ramps = <(int, int, int)>[
      (roles['skinShadow']!, roles['skinBase']!, roles['skinLight']!),
      (roles['hairShadow']!, roles['hairBase']!, roles['hairLight']!),
      (roles['irisDark']!, roles['irisBase']!, roles['irisLight']!),
      (roles['mouthDark']!, roles['mouthBase']!, roles['mouthLight']!),
      (roles['clothDark']!, roles['clothBase']!, roles['clothLight']!),
      (roles['bgDark']!, roles['bg']!, roles['bgLight']!),
      (roles['fantasyDark']!, roles['fantasyBase']!, roles['fantasyLight']!),
    ];
    for (final ramp in ramps) {
      if (color == ramp.$1) return lighter ? ramp.$2 : ramp.$1;
      if (color == ramp.$2) return lighter ? ramp.$3 : ramp.$1;
      if (color == ramp.$3) return lighter ? ramp.$3 : ramp.$2;
    }
    if (lighter &&
        (owner == 'jewelry' || owner == 'armor' || owner == 'eyewear')) {
      return roles['white']!;
    }
    return color;
  }

  List<String?> _owners(List<RenderLayer> layers, int width, int height) {
    final owners = List<String?>.filled(width * height, null);
    final sorted = List<RenderLayer>.from(layers)
      ..sort((a, b) {
        final bySlot = a.slot.index.compareTo(b.slot.index);
        if (bySlot != 0) return bySlot;
        final byLocal = a.localOrder.compareTo(b.localOrder);
        return byLocal != 0 ? byLocal : a.id.compareTo(b.id);
      });
    for (final layer in sorted) {
      final owner = layer.meta['part'] is String
          ? layer.meta['part']! as String
          : layer.nodeId;
      for (var y = 0; y < height; y++) {
        for (var x = 0; x < width; x++) {
          if (layer.mask.get(x, y) != 0) owners[y * width + x] = owner;
        }
      }
    }
    return owners;
  }
}
