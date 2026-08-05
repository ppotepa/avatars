import '../../../pixels/pixel_mask.dart';
import '../../../util/math_utils.dart';
import '../../render_helpers.dart';
import '../../render_model.dart';
import 'atmosphere_masks.dart';

final class BackgroundEventRenderer {
  const BackgroundEventRenderer();

  AtmosphereMasks build(AvatarRenderContext c) {
    final style = c.string('v4.backgroundEvent');
    final frequency = c.integer('v4.eventFrequency');
    final intensity = c.integer('v4.eventIntensity');
    final dark = PixelMask();
    final base = PixelMask();
    final light = PixelMask();
    if (style == 'none' || intensity == 0 || !c.rendering.animateBackground) {
      return AtmosphereMasks(dark, base, light);
    }
    final background = c.string('v4.background');
    final technicalBackground =
        <String>{'terminal', 'laboratory', 'spaceship'}.contains(background);
    final nightBackground = <String>{'night', 'neonCity', 'rainCity', 'dungeon'}
        .contains(background);
    if ((style == 'screenScan' && !technicalBackground) ||
        (style == 'shadowSweep' && !nightBackground) ||
        (style == 'neonFlicker' && !technicalBackground && !nightBackground)) {
      return AtmosphereMasks(dark, base, light);
    }
    final period = clampInt(10 + frequency * 7, 12, 72);
    final step =
        positiveMod(c.phase + c.integer('v4.motionPhaseOffset'), period);
    if (step > 1 && !(style == 'screenScan' || style == 'shadowSweep')) {
      return AtmosphereMasks(dark, base, light);
    }
    if (style == 'lightningFlash' ||
        style == 'alarmFlash' ||
        style == 'sunPulse') {
      light.replaceData(
        orderedDither(PixelMask.filled(), 2 + intensity).data,
      );
    } else if (style == 'lightningBranch') {
      final x = 24 + positiveMod(c.phase * 5, 15) - 7;
      light.line(x, 0, x - 3, 12, thickness: 2);
      light.line(x - 3, 12, x + 2, 23, thickness: 2);
      light.line(x + 2, 23, x - 4, 37, thickness: 2);
      light.line(x - 2, 17, x - 10, 25);
    } else if (style == 'moonGlow' || style == 'eclipsePulse') {
      base.fillEllipse(38, 9, 5 + intensity, 5 + intensity);
      if (style == 'eclipsePulse') {
        dark.fillEllipse(38, 9, 3 + intensity, 3 + intensity);
      }
    } else if (style == 'fireBurst' || style == 'lavaPulse') {
      for (var x = 0; x < 48; x += 5) {
        light.line(
          x,
          47,
          x + 1,
          30 - positiveMod(x + c.phase, 10),
          thickness: 2,
        );
      }
    } else if (style == 'portalPulse') {
      final outer = PixelMask()
        ..fillEllipse(24, 24, 18 + intensity, 22 + intensity);
      final inner = PixelMask()
        ..fillEllipse(24, 24, 15 + intensity, 19 + intensity);
      base.replaceData(outer.subtract(inner).data);
    } else if (style == 'neonFlicker') {
      dark.replaceData(orderedDither(PixelMask.filled(), 3).data);
    } else if (style == 'screenScan') {
      final y = positiveMod(c.phase * 2, 48);
      light.hLine(4, 17, y);
    } else if (style == 'cometPass') {
      final x = 52 - positiveMod(c.phase * 4, 64);
      light.line(x, 5, x - 12, 12, thickness: 2);
    } else if (style == 'starTwinkleBurst') {
      for (var i = 0; i < 9; i++) {
        final x = 4 + positiveMod(i * 13, 40);
        final y = 4 + positiveMod(i * 9, 26);
        light
            .set(x, y)
            .set(x - 1, y)
            .set(x + 1, y)
            .set(x, y - 1)
            .set(x, y + 1);
      }
    } else if (style == 'ghostPass') {
      base.fillEllipse(positiveMod(c.phase * 3, 60) - 6, 22, 5, 9);
    } else if (style == 'shadowSweep') {
      final x = positiveMod(c.phase * 2, 56) - 8;
      dark.fillRect(x, 0, 3 + clampInt(intensity, 0, 2), 48);
    }
    return AtmosphereMasks(dark, base, light);
  }
}
