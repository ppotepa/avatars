import '../api/avatar_request.dart';
import '../palette/avatar_palette.dart';
import '../pixels/indexed_image.dart';
import 'render_model.dart';
import 'resolution_profile.dart';

/// Adds semantic information that only becomes legible above the canonical
/// 48×48 grid. It never changes the identity-defining silhouette; it enriches
/// interiors of already visible parts using their render ownership.
final class NativeDetailRenderer {
  const NativeDetailRenderer();

  IndexedImage enhance({
    required IndexedImage image,
    required IndexedImage source,
    required List<RenderLayer> layers,
    required AvatarPalette palette,
    required AvatarRenderSettings settings,
    required int phase,
  }) {
    final profile = ResolutionProfile.forSettings(settings);
    if (!profile.nativeGeometry || profile.detailBudget == 0) return image;

    final output = image.clone();
    final owners = _sourceOwners(layers, source.width, source.height);
    for (var y = 1; y < output.height - 1; y++) {
      final sy = (y * source.height ~/ output.height).clamp(0, source.height - 1);
      for (var x = 1; x < output.width - 1; x++) {
        final sx = (x * source.width ~/ output.width).clamp(0, source.width - 1);
        final owner = owners[sy * source.width + sx] ?? '';
        final color = output.get(x, y);
        if (color == output.transparentIndex) continue;
        final replacement = _semanticColor(
          owner: owner,
          color: color,
          x: x,
          y: y,
          phase: phase,
          profile: profile,
          palette: palette,
          image: output,
        );
        if (replacement != null) output.setPixel(x, y, replacement);
      }
    }
    return output;
  }

  int? _semanticColor({
    required String owner,
    required int color,
    required int x,
    required int y,
    required int phase,
    required ResolutionProfile profile,
    required AvatarPalette palette,
    required IndexedImage image,
  }) {
    final roles = palette.roles;
    final boundary = image.get(x - 1, y) != color ||
        image.get(x + 1, y) != color ||
        image.get(x, y - 1) != color ||
        image.get(x, y + 1) != color;

    if (owner == 'eyes') {
      if (profile.detailBudget >= 1 && color == roles['irisBase']) {
        if ((x + y) % 4 == 0) return roles['irisLight'];
        if (profile.detailBudget >= 2 && (x * 3 + y) % 7 == 0) {
          return roles['irisDark'];
        }
      }
      if (profile.detailBudget >= 2 && boundary && y.isOdd) {
        return roles['outline'];
      }
    }

    if (owner == 'mouth') {
      if (profile.detailBudget >= 1 && color == roles['mouthBase'] && y.isEven) {
        return roles['mouthLight'];
      }
      if (profile.detailBudget >= 2 && boundary && y.isOdd) {
        return roles['mouthDark'];
      }
    }

    if (owner == 'hair') {
      final strandPeriod = profile.detailBudget >= 3 ? 5 : 7;
      if (!boundary && (x * 2 + y + phase ~/ 16) % strandPeriod == 0) {
        return y < image.height ~/ 2 ? roles['hairLight'] : roles['hairShadow'];
      }
    }

    if (owner == 'clothing') {
      if (profile.detailBudget >= 2 && !boundary && y % 8 == 0 && x % 3 != 0) {
        return roles['clothDark'];
      }
      if (profile.detailBudget >= 3 && !boundary && x % 11 == 0) {
        return roles['clothLight'];
      }
    }

    if (owner == 'armor' || owner == 'jewelry' || owner == 'cyber') {
      if (boundary && (x + y + phase ~/ 12) % 5 == 0) {
        return roles['white'];
      }
      if (profile.detailBudget >= 2 && !boundary && (x - y).abs() % 13 == 0) {
        return roles['fantasyLight'];
      }
    }

    if (owner == 'head' && profile.detailBudget >= 3 && !boundary) {
      if ((x * 5 + y * 3) % 37 == 0) return roles['skinShadow'];
    }
    return null;
  }

  List<String?> _sourceOwners(List<RenderLayer> layers, int width, int height) {
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
