import '../api/avatar_request.dart';
import '../palette/avatar_palette.dart';
import '../pixels/indexed_image.dart';
import 'native_detail_renderer.dart';
import 'render_model.dart';

/// Expands the canonical 48×48 composition into a resolution-aware pixel
/// render. Destination sampling is centered and mirrored around the canvas axis
/// so non-integer profiles such as 64×64 and 80×80 do not accumulate all narrow
/// source cells on one side of the face.
final class ResolutionAwareRenderer {
  const ResolutionAwareRenderer({
    this.nativeDetails = const NativeDetailRenderer(),
  });

  final NativeDetailRenderer nativeDetails;

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
      final sy = _sourceCoordinate(y, size, source.height);
      for (var x = 0; x < size; x++) {
        final sx = _sourceCoordinate(x, size, source.width);
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
    return nativeDetails.enhance(
      image: output,
      source: source,
      layers: layers,
      palette: palette,
      settings: settings,
      phase: phase,
    );
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
    final leftEdge =
        x == 0 || _sourceCoordinate(x - 1, size, source.width) != sx;
    final rightEdge = x == size - 1 ||
        _sourceCoordinate(x + 1, size, source.width) != sx;
    final topEdge =
        y == 0 || _sourceCoordinate(y - 1, size, source.height) != sy;
    final bottomEdge = y == size - 1 ||
        _sourceCoordinate(y + 1, size, source.height) != sy;

    final owner = owners[sy * source.width + sx] ?? '';
    final frontal =
        settings.lightingDirection == AvatarLightingDirection.frontal;
    final lightFromRight =
        settings.lightingDirection == AvatarLightingDirection.upperRight;
    final lightEdge =
        topEdge || (!frontal && (lightFromRight ? rightEdge : leftEdge));
    final shadowEdge =
        bottomEdge || (!frontal && (lightFromRight ? leftEdge : rightEdge));
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
        return _ramp(
          original,
          palette,
          lighter: y < size ~/ 2,
          owner: owner,
        );
      }
      if (owner == 'clothing' &&
          y > size * 2 ~/ 3 &&
          (x - size ~/ 2).abs() % 11 == 0) {
        return _ramp(
          original,
          palette,
          lighter: x < size ~/ 2,
          owner: owner,
        );
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
