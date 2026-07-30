import '../api/avatar_request.dart';
import '../constraints/validation.dart';
import '../genome/avatar_genome_model.dart';
import '../geometry/avatar_layout.dart';
import '../palette/avatar_palette.dart';
import '../pixels/indexed_image.dart';
import '../pixels/pixel_mask.dart';
import '../random/random_stream.dart';
import '../util/math_utils.dart';

final class RenderLayer {
  const RenderLayer({
    required this.id,
    required this.z,
    required this.mask,
    required this.colorIndex,
    this.meta = const <String, Object?>{},
  });

  final String id;
  final int z;
  final PixelMask mask;
  final int colorIndex;
  final Map<String, Object?> meta;

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'z': z,
        'colorIndex': colorIndex,
        'pixelCount': mask.count,
        'bounds': mask.bounds?.toJson(),
        'meta': meta,
      };
}

final class AvatarRenderContext {
  AvatarRenderContext({
    required this.genome,
    required this.layout,
    required this.palette,
    required this.guard,
    required this.phase,
    this.rendering = const AvatarRenderSettings(),
  });

  final AvatarGenome genome;
  final AvatarLayout layout;
  final AvatarPalette palette;
  final ConstraintEngine guard;
  final int phase;
  final AvatarRenderSettings rendering;

  int integer(String id, [int fallback = 0]) => layout.integer(id, fallback);
  String string(String id, [String fallback = 'none']) =>
      layout.string(id, fallback);
  int color(String role) => palette.role(role);
  RandomStream random(String namespace) =>
      RandomStream(layout.values['seedHash'] is int
              ? layout.values['seedHash']! as int
              : fnv1a32('${genome.generatorVersion}:${genome.seed}'))
          .fork(namespace);
}

final class AvatarRenderState {
  final Map<String, PixelMask> masks = <String, PixelMask>{};
  final List<RenderLayer> layers = <RenderLayer>[];
  final Map<String, Object?> metadata = <String, Object?>{};

  PixelMask mask(String id) => masks[id] ?? PixelMask();

  void putMask(String id, PixelMask mask) {
    masks[id] = mask;
  }

  void addLayer(
    String id,
    int z,
    PixelMask mask,
    int colorIndex, {
    Map<String, Object?> meta = const <String, Object?>{},
  }) {
    if (mask.count == 0) return;
    layers.add(RenderLayer(
      id: id,
      z: z,
      mask: mask,
      colorIndex: colorIndex,
      meta: meta,
    ));
  }

  /// Applies a deterministic spatial transform to selected masks and layers.
  ///
  /// This is intentionally implemented at render-state level so animation
  /// channels can move a composed avatar without mutating its genome or layout.
  void translateWhere({
    required int dx,
    required int dy,
    required bool Function(String id) includeMask,
    required bool Function(RenderLayer layer) includeLayer,
  }) {
    if (dx == 0 && dy == 0) return;

    final maskEntries = masks.entries.toList(growable: false);
    for (final entry in maskEntries) {
      if (includeMask(entry.key)) {
        masks[entry.key] = entry.value.translated(dx, dy);
      }
    }

    for (var index = 0; index < layers.length; index++) {
      final layer = layers[index];
      if (!includeLayer(layer)) continue;
      layers[index] = RenderLayer(
        id: layer.id,
        z: layer.z,
        mask: layer.mask.translated(dx, dy),
        colorIndex: layer.colorIndex,
        meta: layer.meta,
      );
    }
  }
}

final class RenderVisibility {
  const RenderVisibility({
    required this.visiblePixels,
    required this.sourcePixels,
  });

  final Map<String, int> visiblePixels;
  final Map<String, int> sourcePixels;

  double visibleRatio(String part) {
    final source = sourcePixels[part] ?? 0;
    if (source == 0) return 1;
    return (visiblePixels[part] ?? 0) / source;
  }

  Map<String, Object> toJson() => <String, Object>{
        'visiblePixels': visiblePixels,
        'sourcePixels': sourcePixels,
        'visibleRatios': <String, double>{
          for (final part in sourcePixels.keys) part: visibleRatio(part),
        },
      };
}

RenderVisibility analyzeRenderVisibility(List<RenderLayer> layers) {
  final sorted = List<RenderLayer>.from(layers)
    ..sort((a, b) {
      final byZ = a.z.compareTo(b.z);
      return byZ != 0 ? byZ : a.id.compareTo(b.id);
    });
  final sourceMasks = <String, PixelMask>{};
  final owners = List<String?>.filled(48 * 48, null);
  for (final layer in sorted) {
    final part = layer.meta['part'] is String
        ? layer.meta['part']! as String
        : layer.id.split('.').first;
    sourceMasks[part] = (sourceMasks[part] ?? PixelMask()).union(layer.mask);
    for (var y = 0; y < 48; y++) {
      for (var x = 0; x < 48; x++) {
        if (layer.mask.get(x, y) != 0) owners[y * 48 + x] = part;
      }
    }
  }
  final visible = <String, int>{};
  for (final owner in owners) {
    if (owner != null) visible[owner] = (visible[owner] ?? 0) + 1;
  }
  return RenderVisibility(
    visiblePixels: Map.unmodifiable(visible),
    sourcePixels: Map.unmodifiable(<String, int>{
      for (final entry in sourceMasks.entries) entry.key: entry.value.count,
    }),
  );
}

abstract interface class AvatarPartRenderer {
  void render(AvatarRenderContext context, AvatarRenderState state);
}

abstract interface class AvatarCompositor {
  IndexedImage compose(List<RenderLayer> layers);
}

final class IndexedAvatarCompositor implements AvatarCompositor {
  const IndexedAvatarCompositor();

  @override
  IndexedImage compose(List<RenderLayer> layers) {
    final sorted = List<RenderLayer>.from(layers)
      ..sort((a, b) {
        final byZ = a.z.compareTo(b.z);
        return byZ != 0 ? byZ : a.id.compareTo(b.id);
      });
    final image = IndexedImage();
    for (final layer in sorted) {
      image.applyMask(layer.mask, layer.colorIndex);
    }
    return image;
  }
}
