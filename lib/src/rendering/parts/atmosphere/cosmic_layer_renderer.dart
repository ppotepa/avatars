import '../../../pixels/pixel_mask.dart';
import '../../../util/math_utils.dart';
import '../../render_model.dart';
import 'atmosphere_masks.dart';

final class CosmicLayerRenderer {
  const CosmicLayerRenderer();

  AtmosphereMasks build(AvatarRenderContext c) {
    final style = c.string('v4.cosmicLayer');
    final density = c.integer('v4.cosmicDensity');
    final dark = PixelMask();
    final base = PixelMask();
    final light = PixelMask();
    if (style == 'none' || density == 0) {
      return AtmosphereMasks(dark, base, light);
    }
    final rng = c.random('v42.cosmic.$style');
    final phase = c.rendering.animateBackground ? c.phase : 0;
    final count = 5 + density * 5;
    for (var i = 0; i < count; i++) {
      final x = rng.nextInt(1, 46);
      final y = rng.nextInt(1, 35);
      (i % 5 == 0 ? base : light).set(x, y);
    }
    if (style == 'starsDense' ||
        style == 'cosmicDust' ||
        style == 'holographicStars') {
      for (var i = 0; i < count; i++) {
        base.set(rng.nextInt(0, 47), rng.nextInt(0, 47));
      }
    }
    if (style == 'nebula' || style == 'galaxySwirl') {
      base.fillEllipse(15, 15, 13, 5);
      dark.fillEllipse(32, 30, 15, 6);
      light.line(6, 24, 42, 18, thickness: 2);
    }
    if (style == 'planets' || style == 'ringPlanet') {
      base.fillEllipse(37, 11, 6, 6);
      if (style == 'ringPlanet') light.line(28, 13, 46, 9, thickness: 2);
    }
    if (style == 'moonAndStars') base.fillEllipse(38, 9, 5, 5);
    if (style == 'blackHole') {
      dark.fillEllipse(24, 20, 10, 10);
      final ring = PixelMask()..fillEllipse(24, 20, 14, 6);
      light.replaceData(light.union(ring.subtract(dark)).data);
    }
    if (style == 'constellation') {
      for (var i = 0; i < 6; i++) {
        final x1 = 6 + i * 7;
        final y1 = 8 + positiveMod(i * 11, 20);
        light.set(x1, y1);
        if (i > 0) {
          light.line(
            x1 - 7,
            8 + positiveMod((i - 1) * 11, 20),
            x1,
            y1,
          );
        }
      }
    }
    if (style == 'auroraSky') {
      for (var x = 0; x < 48; x++) {
        final y = 8 + positiveMod(x ~/ 3 + phase ~/ 2, 8);
        base.set(x, y).set(x, y + 1);
      }
    }
    if (style == 'shootingStars' || style == 'comets') {
      final x = 47 - positiveMod(phase * 3, 58);
      light.line(x, 5, x - 8, 11, thickness: style == 'comets' ? 2 : 1);
    }
    if (style == 'asteroidField') {
      for (var i = 0; i < 7; i++) {
        dark.fillEllipse(
          rng.nextInt(2, 45),
          rng.nextInt(4, 35),
          1 + i % 3,
          1 + i % 2,
        );
      }
    }
    return AtmosphereMasks(dark, base, light);
  }
}
