import '../../../pixels/pixel_mask.dart';
import '../../../util/math_utils.dart';
import '../../render_model.dart';
import 'atmosphere_masks.dart';

final class BackFlamesRenderer {
  const BackFlamesRenderer();

  AtmosphereMasks build(AvatarRenderContext c) {
    final style = c.string('v4.backFlames');
    final height = c.integer('v4.flameHeight');
    final intensity = c.integer('v4.flameIntensity');
    final flicker = c.integer('v4.flameFlicker');
    final dark = PixelMask();
    final base = PixelMask();
    final light = PixelMask();
    if (style == 'none' || height == 0 || intensity == 0) {
      return AtmosphereMasks(dark, base, light);
    }
    final phase = c.rendering.animateBackground ? c.phase : 0;
    final spacing = style == 'wideFlames' || style == 'hellfire' ? 4 : 7;
    for (var x = -2; x < 52; x += spacing) {
      final wave = positiveMod(x * 3 + phase * clampInt(flicker, 1, 6), 7);
      final tip = clampInt(47 - height * 3 - wave, 10, 45);
      base.fillTriangle(
        (x: x - 3, y: 48),
        (x: x + 4, y: 48),
        (x: x, y: tip),
      );
      light.fillTriangle(
        (x: x - 1, y: 48),
        (x: x + 2, y: 48),
        (x: x, y: tip + 5 + intensity ~/ 2),
      );
      if (style == 'smokeAndFire') dark.fillEllipse(x, tip - 4, 3, 2);
    }
    if (style == 'ritualFire') {
      dark.fillEllipse(24, 44, 17, 3);
      base.fillEllipse(24, 43, 12, 2);
    }
    if (style == 'torchGlow') light.fillEllipse(24, 31, 18, 15);
    return AtmosphereMasks(dark, base, light);
  }
}
