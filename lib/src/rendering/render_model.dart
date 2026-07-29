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
  });

  final AvatarGenome genome;
  final AvatarLayout layout;
  final AvatarPalette palette;
  final ConstraintEngine guard;
  final int phase;

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
