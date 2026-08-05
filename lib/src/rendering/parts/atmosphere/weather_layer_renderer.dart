import '../../../pixels/pixel_mask.dart';
import '../../../util/math_utils.dart';
import '../../render_model.dart';
import 'atmosphere_masks.dart';

final class WeatherLayerRenderer {
  const WeatherLayerRenderer();

  AtmosphereMasks build(AvatarRenderContext c, {required bool back}) {
    final style = c.string('v4.weather');
    final density = c.integer('v4.weatherDensity');
    final depth = c.integer('v4.weatherDepth');
    final dark = PixelMask();
    final base = PixelMask();
    final light = PixelMask();
    if (style == 'none' || density == 0) {
      return AtmosphereMasks(dark, base, light);
    }
    if (back && depth <= 1) return AtmosphereMasks(dark, base, light);
    if (!back && depth >= 4) return AtmosphereMasks(dark, base, light);
    final rng = c.random('v42.weather.$style.${back ? 'back' : 'front'}');
    final phase = c.rendering.animateBackground ? c.phase : 0;
    final drift = c.integer('v4.weatherDrift');
    final count = 4 + density * (back ? 2 : 3);
    for (var i = 0; i < count; i++) {
      var x = rng.nextInt(0, 47);
      var y = rng.nextInt(0, 47);
      x = positiveMod(x + drift * phase ~/ 4, 48);
      y = positiveMod(y + phase * (1 + i % 2), 48);
      if (style == 'rain' || style == 'heavyRain' || style == 'lightDrizzle') {
        final length = style == 'heavyRain'
            ? 6
            : style == 'lightDrizzle'
                ? 2
                : 4;
        base.line(
          x,
          y,
          x - 1,
          y + length,
          thickness: style == 'heavyRain' && i.isEven ? 2 : 1,
        );
      } else if (style == 'snow' || style == 'blizzard') {
        light.set(x, y).set(x - 1, y).set(x, y - 1);
        if (style == 'blizzard') light.line(x - 3, y, x + 3, y);
      } else if (style == 'embers' ||
          style == 'sparks' ||
          style == 'magicDust') {
        light.set(x, y).set(x, y - 1);
        if (style != 'magicDust') base.set(x, y + 1);
      } else if (style == 'ash' || style == 'dust' || style == 'pollen') {
        (i.isEven ? dark : base).fillRect(x, y, 2, 2);
      } else if (style == 'fog' || style == 'mist') {
        (style == 'fog' ? dark : light).hLine(0, 47, y);
      } else if (style == 'fallingLeaves' || style == 'petals') {
        base.set(x, y).set(x + 1, y + 1).set(x + 2, y);
      } else if (style == 'bubbles') {
        light.fillEllipse(x, y, 1 + i % 2, 1 + i % 2);
      } else if (style == 'sandstorm') {
        base.line(x - 3, y, x + 4, y);
      } else if (style == 'meteorShower') {
        light.line(x, y, x - 5, y + 4);
      } else if (style == 'fireflies') {
        light.fillEllipse(x, y, 1, 1);
      } else if (style == 'glitchNoise') {
        base.hLine(x - 2, x + 3, y);
      }
    }
    return AtmosphereMasks(dark, base, light);
  }
}
