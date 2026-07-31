import '../palette/avatar_palette.dart';
import '../pixels/indexed_image.dart';
import '../pixels/pixel_mask.dart';
import 'render_model.dart';
import 'resolution_profile.dart';

/// Rasterizes semantic layers independently on the requested output grid.
///
/// Unlike final-image enlargement, this preserves layer ownership and paint
/// order while allowing selected contours to gain destination-grid geometry.
final class NativeGeometryRenderer {
  const NativeGeometryRenderer();

  IndexedImage rasterize({
    required List<RenderLayer> layers,
    required AvatarPalette palette,
    required int sourceWidth,
    required int sourceHeight,
    required ResolutionProfile profile,
  }) {
    final output = IndexedImage(width: profile.size, height: profile.size);
    final sorted = List<RenderLayer>.from(layers)
      ..sort((a, b) {
        final bySlot = a.slot.index.compareTo(b.slot.index);
        if (bySlot != 0) return bySlot;
        final byLocal = a.localOrder.compareTo(b.localOrder);
        return byLocal != 0 ? byLocal : a.id.compareTo(b.id);
      });

    for (final layer in sorted) {
      final mask = _scaleMask(
        layer.mask,
        width: profile.size,
        height: profile.size,
        refine: profile.detailBudget > 0 && _refinesContour(layer),
      );
      output.applyMask(mask, layer.colorIndex);
    }
    return output;
  }

  PixelMask _scaleMask(
    PixelMask source, {
    required int width,
    required int height,
    required bool refine,
  }) {
    final output = PixelMask(width: width, height: height);
    for (var sy = 0; sy < source.height; sy++) {
      final top = sy * height ~/ source.height;
      final bottom = ((sy + 1) * height ~/ source.height).clamp(top + 1, height).toInt();
      for (var sx = 0; sx < source.width; sx++) {
        if (source.get(sx, sy) == 0) continue;
        final left = sx * width ~/ source.width;
        final right = ((sx + 1) * width ~/ source.width).clamp(left + 1, width).toInt();
        output.fillRect(left, top, right - left, bottom - top);
      }
    }
    if (!refine) return output;
    return _refineDiagonals(output);
  }

  PixelMask _refineDiagonals(PixelMask source) {
    final output = source.clone();
    for (var y = 1; y < source.height - 1; y++) {
      for (var x = 1; x < source.width - 1; x++) {
        if (source.get(x, y) != 0) continue;
        final diagonal = source.get(x - 1, y - 1) != 0 &&
                source.get(x + 1, y + 1) != 0 ||
            source.get(x + 1, y - 1) != 0 &&
                source.get(x - 1, y + 1) != 0;
        final bridge = source.get(x - 1, y) != 0 &&
                source.get(x, y - 1) != 0 ||
            source.get(x + 1, y) != 0 && source.get(x, y - 1) != 0 ||
            source.get(x - 1, y) != 0 && source.get(x, y + 1) != 0 ||
            source.get(x + 1, y) != 0 && source.get(x, y + 1) != 0;
        if (diagonal || bridge) output.set(x, y);
      }
    }
    return output;
  }

  bool _refinesContour(RenderLayer layer) => <String>{
        'head',
        'face',
        'eyes',
        'brows',
        'mouth',
        'hairBack',
        'hairFront',
        'leftArm',
        'rightArm',
        'leftForearm',
        'rightForearm',
        'leftHand',
        'rightHand',
        'clothing',
        'armor',
        'headwear',
        'eyewear',
        'faceMask',
      }.contains(layer.nodeId);
}
