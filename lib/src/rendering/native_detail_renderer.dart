import '../api/avatar_request.dart';
import '../palette/avatar_palette.dart';
import '../pixels/indexed_image.dart';
import 'regional_detail_budget.dart';
import 'render_model.dart';
import 'resolution_profile.dart';

/// Adds semantic information that only becomes legible above the canonical
/// 48×48 grid. Identity-defining silhouettes remain stable; interiors gain
/// material-aware, region-budgeted information on the destination grid.
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

    final regional = RegionalDetailBudget.forProfile(profile);
    final output = image.clone();
    final owners = _sourceOwners(layers, source.width, source.height);
    for (var y = 1; y < output.height - 1; y++) {
      final sy = (y * source.height ~/ output.height)
          .clamp(0, source.height - 1)
          .toInt();
      for (var x = 1; x < output.width - 1; x++) {
        final sx = (x * source.width ~/ output.width)
            .clamp(0, source.width - 1)
            .toInt();
        final owner = owners[sy * source.width + sx] ?? '';
        final ownerBudget = regional.forOwner(owner);
        if (ownerBudget == 0) continue;
        final color = output.get(x, y);
        if (color == output.transparentIndex) continue;
        final replacement = _semanticColor(
          owner: owner,
          ownerBudget: ownerBudget,
          color: color,
          x: x,
          y: y,
          phase: phase,
          palette: palette,
          image: output,
          lighting: settings.lightingDirection,
        );
        if (replacement != null) output.setPixel(x, y, replacement);
      }
    }
    return output;
  }

  int? _semanticColor({
    required String owner,
    required int ownerBudget,
    required int color,
    required int x,
    required int y,
    required int phase,
    required AvatarPalette palette,
    required IndexedImage image,
    required AvatarLightingDirection lighting,
  }) {
    final roles = palette.roles;
    final left = image.get(x - 1, y);
    final right = image.get(x + 1, y);
    final up = image.get(x, y - 1);
    final down = image.get(x, y + 1);
    final boundary = left != color || right != color || up != color || down != color;
    final lightFromRight = lighting == AvatarLightingDirection.upperRight;
    final frontal = lighting == AvatarLightingDirection.frontal;
    final lightNeighbour = lightFromRight ? right : left;
    final shadowNeighbour = lightFromRight ? left : right;
    final lightFacing = up != color || (!frontal && lightNeighbour != color);
    final shadowFacing = down != color || (!frontal && shadowNeighbour != color);

    if (owner == 'eyes') {
      if (color == roles['irisBase']) {
        if (ownerBudget >= 1 && lightFacing && (x + y) % 3 == 0) {
          return roles['irisLight'];
        }
        if (ownerBudget >= 2 && shadowFacing && (x * 3 + y) % 5 == 0) {
          return roles['irisDark'];
        }
      }
      if (ownerBudget >= 2 && boundary && up != color && y.isOdd) {
        return roles['outline'];
      }
      if (ownerBudget >= 3 && !boundary && (x + y * 2) % 11 == 0) {
        return roles['white'];
      }
    }

    if (owner == 'mouth') {
      if (color == roles['mouthBase'] && ownerBudget >= 1 && lightFacing) {
        return roles['mouthLight'];
      }
      if (ownerBudget >= 2 && boundary && shadowFacing) {
        return roles['mouthDark'];
      }
      if (ownerBudget >= 3 && !boundary && (x + y) % 9 == 0) {
        return roles['white'];
      }
    }

    if (owner == 'head' || owner == 'face' || owner == 'skin' || owner == 'chest') {
      if (ownerBudget >= 2 && !boundary && lightFacing && (x * 5 + y * 3) % 31 == 0) {
        return roles['skinLight'];
      }
      if (ownerBudget >= 2 && !boundary && shadowFacing && (x * 3 + y * 5) % 37 == 0) {
        return roles['skinShadow'];
      }
      if (ownerBudget >= 3 && !boundary && (x * 7 + y * 11) % 79 == 0) {
        return roles['skinShadow'];
      }
    }

    if (owner == 'hair' || owner.startsWith('hair')) {
      final strandPeriod = ownerBudget >= 3 ? 4 : ownerBudget >= 2 ? 6 : 8;
      final directional = lightFromRight ? x - y : x + y;
      if (!boundary && directional.abs() % strandPeriod == 0) {
        return lightFacing ? roles['hairLight'] : roles['hairShadow'];
      }
      if (ownerBudget >= 2 && shadowFacing && y % 5 == 0) {
        return roles['hairShadow'];
      }
    }

    if (owner == 'clothing' || owner == 'cloth') {
      if (ownerBudget >= 1 && !boundary && y % 8 == 0 && x % 3 != 0) {
        return roles['clothDark'];
      }
      if (ownerBudget >= 2 && !boundary && x % 11 == 0) {
        return lightFacing ? roles['clothLight'] : roles['clothDark'];
      }
      if (ownerBudget >= 3 && boundary && (x + y) % 7 == 0) {
        return roles['clothAccent'];
      }
    }

    final metal = owner == 'armor' ||
        owner == 'jewelry' ||
        owner == 'cyber' ||
        owner == 'eyewear' ||
        owner.contains('Wearable');
    if (metal) {
      if (boundary && lightFacing && (x + y + phase ~/ 12) % 4 == 0) {
        return roles['white'];
      }
      if (ownerBudget >= 2 && !boundary && (x - y).abs() % 9 == 0) {
        return lightFacing ? roles['fantasyLight'] : roles['fantasyDark'];
      }
      if (ownerBudget >= 3 && shadowFacing && (x * 2 + y) % 13 == 0) {
        return roles['outline'];
      }
    }

    if (owner == 'background' && ownerBudget >= 1) {
      if ((x * 3 + y * 5) % 29 == 0) return roles['bgLight'];
      if ((x * 5 + y * 3) % 31 == 0) return roles['bgDark'];
    }

    if (owner.contains('companion') && ownerBudget >= 2 && !boundary) {
      if ((x + y + phase ~/ 8) % 17 == 0) return roles['fantasyLight'];
    }

    return null;
  }

  List<String?> _sourceOwners(List<RenderLayer> layers, int width, int height) {
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
