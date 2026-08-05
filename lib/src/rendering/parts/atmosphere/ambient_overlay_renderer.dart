import '../../../pixels/pixel_mask.dart';
import '../../../util/math_utils.dart';
import '../../render_helpers.dart';
import '../../render_model.dart';
import 'atmosphere_masks.dart';

final class AmbientOverlayRenderer {
  const AmbientOverlayRenderer();

  AtmosphereMasks build(AvatarRenderContext c) {
    final style = c.string('v4.ambientOverlay');
    final density = c.integer('v4.ambientDensity');
    final dark = PixelMask();
    final light = PixelMask();
    if (style == 'none' || density == 0) {
      return AtmosphereMasks(dark, PixelMask(), light);
    }
    final phase = c.rendering.animateBackground ? c.phase : 0;
    if (style == 'softFog' ||
        style == 'deepFog' ||
        style == 'dreamHaze' ||
        style == 'neonMist' ||
        style == 'toxicCloud') {
      final step = clampInt(8 - density, 2, 8);
      for (var y = 8 + positiveMod(phase ~/ 3, step); y < 48; y += step) {
        (style == 'deepFog' || style == 'toxicCloud' ? dark : light)
            .hLine(0, 47, y);
      }
    } else if (style == 'stormClouds') {
      for (var x = -2; x < 52; x += 7) {
        dark.fillEllipse(x, 7 + positiveMod(x, 5), 6, 3);
      }
    } else if (style == 'heatHaze') {
      for (var x = 2; x < 47; x += 5) {
        light.line(x, 47, x + positiveMod(phase, 3) - 1, 32);
      }
    } else if (style == 'voidVeil') {
      dark.replaceData(
        orderedDither(PixelMask.filled(), clampInt(density, 1, 6)).data,
      );
    } else if (style == 'holyLight') {
      for (var x = 0; x < 48; x += 7) light.line(24, 0, x, 47);
    } else if (style == 'dustVeil') {
      light.replaceData(
        orderedDither(
          PixelMask.filled(),
          clampInt(density, 1, 4),
          phase: phase,
        ).data,
      );
    } else if (style == 'underwaterLight') {
      for (var x = 0; x < 48; x += 8) light.line(x, 0, x + 12, 47);
    }
    return AtmosphereMasks(dark, PixelMask(), light);
  }
}
