import '../api/avatar_request.dart';
import '../palette/avatar_palette.dart';
import '../pixels/indexed_image.dart';
import 'render_model.dart';

/// Expands the canonical 48×48 composition into a resolution-aware pixel
/// render. The legacy canvas is returned byte-for-byte; larger profiles add
/// deterministic sub-pixel bevels, material highlights and ordered dithering.
final class ResolutionAwareRenderer {
  const ResolutionAwareRenderer();

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
    final size = settings.size;
    final output = IndexedImage(width: size, height: size);
    final owners = _owners(layers, source.width, source.height);
    for (var y = 0; y < size; y++) {
      final sy = y * source.height ~/ size;
      for (var x = 0; x < size; x++) {
        final sx = x * source.width ~/ size;
        final color = source.get(sx, sy);
        if (color == source.transparentIndex) continue;
        output.setPixel(
          x,
          y,
          _detailColor(
            source: source,
            palette: palette,
            settings: settings,
            owners: owners,
            sx: sx,
            sy: sy,
            x: x,
            y: y,
            phase: phase,
          ),
        );
      }
    }
    return output;
  }

  int _detailColor({
    required IndexedImage source,
    required AvatarPalette palette,
    required AvatarRenderSettings settings,
    required List<String?> owners,
    required int sx,
    required int sy,
    required int x,
    required int y,
    required int phase,
  }) {
    final original = source.get(sx, sy);
    if (settings.detailLevel == AvatarDetailLevel.basic ||
        settings.shadingStrength == 0) {
      return original;
    }

    final size = settings.size;
    final cellLeft = (sx * size + source.width - 1) ~/ source.width;
    final cellRight = (((sx + 1) * size + source.width - 1) ~/ source.width) - 1;
    final cellTop = (sy * size + source.height - 1) ~/ source.height;
    final cellBottom =
        (((sy + 1) * size + source.height - 1) ~/ source.height) - 1;
    final owner = owners[sy * source.width + sx] ?? '';
    final frontal =
        settings.lightingDirection == AvatarLightingDirection.frontal;
    final lightFromRight =
        settings.lightingDirection == AvatarLightingDirection.upperRight;
    final lightEdge = y == cellTop ||
        (!frontal && (lightFromRight ? x == cellRight : x == cellLeft));
    final shadowEdge = y == cellBottom ||
        (!frontal && (lightFromRight ? x == cellLeft : x == cellRight));
    final lightNeighbourX = lightFromRight ? sx + 1 : sx - 1;
    final shadowNeighbourX = lightFromRight ? sx - 1 : sx + 1;
    final exposedToLight =
        (!frontal && source.get(lightNeighbourX, sy) != original) ||
        source.get(sx, sy - 1) != original;
    final exposedToShadow =
        (!frontal && source.get(shadowNeighbourX, sy) != original) ||
        source.get(sx, sy + 1) != original;

    if (lightEdge && exposedToLight) {
      return _ramp(original, palette, lighter: true, owner: owner);
    }
    if (settings.shadingStrength >= 2 && shadowEdge && exposedToShadow) {
      return _ramp(original, palette, lighter: false, owner: owner);
    }

    if (settings.detailLevel == AvatarDetailLevel.rich) {
      final roles = palette.roles;
      if (owner == 'eyes' &&
          original == roles['irisBase'] &&
          (x + y * 2) % 5 == 0) {
        return roles['irisLight']!;
      }
      if (owner == 'mouth' &&
          original == roles['mouthBase'] &&
          y.isEven &&
          x % 3 == 0) {
        return roles['mouthLight']!;
      }
      final material = owner == 'jewelry' ||
          owner == 'armor' ||
          owner == 'eyewear' ||
          owner == 'cyber';
      if (material && (x + y + phase ~/ 8) % 7 == 0) {
        return _ramp(original, palette, lighter: true, owner: owner);
      }
      if (owner == 'background' &&
          settings.shadingStrength >= 2 &&
          (x + y * 3) % 11 == 0) {
        return _ramp(
          original,
          palette,
          lighter: ((x + y) ~/ 3).isEven,
          owner: owner,
        );
      }
      if ((owner == 'hair' || owner == 'clothing') &&
          (x * 3 + y + phase ~/ 16) % 13 == 0) {
        return _ramp(original, palette, lighter: y < size ~/ 2, owner: owner);
      }
      if (owner == 'clothing' &&
          y > size * 2 ~/ 3 &&
          (x - size ~/ 2).abs() % 11 == 0) {
        return _ramp(original, palette, lighter: x < size ~/ 2, owner: owner);
      }
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
        (owner == 'jewelry' || owner == 'armor' || owner == 'eyewear') &&
        (color == roles['clothAccent'] ||
            color == roles['fantasyLight'] ||
            color == roles['irisLight'])) {
      return roles['white']!;
    }
    return color;
  }

  List<String?> _owners(List<RenderLayer> layers, int width, int height) {
    final owners = List<String?>.filled(width * height, null);
    final sorted = List<RenderLayer>.from(layers)
      ..sort((a, b) {
        final byZ = a.z.compareTo(b.z);
        return byZ != 0 ? byZ : a.id.compareTo(b.id);
      });
    for (final layer in sorted) {
      final owner = layer.meta['part'] is String
          ? layer.meta['part']! as String
          : layer.id.split('.').first;
      for (var y = 0; y < height; y++) {
        for (var x = 0; x < width; x++) {
          if (layer.mask.get(x, y) != 0) owners[y * width + x] = owner;
        }
      }
    }
    return owners;
  }
}
