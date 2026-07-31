import '../../pixels/pixel_mask.dart';
import '../../util/math_utils.dart';
import '../render_helpers.dart';
import '../render_model.dart';

/// Replaces the legacy wrap-around particles with deterministic particles that
/// spawn off-canvas, live for a bounded number of phases and disappear outside
/// the viewport. Each particle has independent speed, drift, size and shape.
final class NaturalParticleFieldRenderer implements AvatarPartRenderer {
  const NaturalParticleFieldRenderer();

  @override
  void render(AvatarRenderContext context, AvatarRenderState state) {
    state.layers.removeWhere(
      (layer) => layer.id.startsWith('effect.back') ||
          layer.id.startsWith('effect.front') ||
          layer.id.startsWith('weather.v42.'),
    );

    final back = _ParticleMasks();
    final front = _ParticleMasks();
    _renderChannel(
      context,
      back,
      front,
      style: context.string('v4.effect'),
      density: context.integer('v4.particleDensity'),
      namespace: 'effect',
      depth: 3,
      drift: 0,
    );
    _renderChannel(
      context,
      back,
      front,
      style: context.string('v4.weather'),
      density: context.integer('v4.weatherDensity'),
      namespace: 'weather',
      depth: context.integer('v4.weatherDepth'),
      drift: context.integer('v4.weatherDrift'),
    );

    state
      ..addLayer('particle.v2.back.dark', 6, back.dark, context.color('bgDark'),
          meta: const {'part': 'particle'})
      ..addLayer('particle.v2.back', 7, back.base,
          context.color('fantasyBase'), meta: const {'part': 'particle'})
      ..addLayer('particle.v2.back.light', 8, back.light,
          context.color('fantasyLight'), meta: const {'part': 'particle'})
      ..addLayer('particle.v2.front.dark', 233, front.dark,
          context.color('bgDark'), meta: const {'part': 'particle'})
      ..addLayer('particle.v2.front', 234, front.base,
          context.color('fantasyBase'), meta: const {'part': 'particle'})
      ..addLayer('particle.v2.front.light', 235, front.light,
          context.color('fantasyLight'), meta: const {'part': 'particle'});
  }

  void _renderChannel(
    AvatarRenderContext context,
    _ParticleMasks back,
    _ParticleMasks front, {
    required String style,
    required int density,
    required String namespace,
    required int depth,
    required int drift,
  }) {
    if (style == 'none' || density <= 0) return;
    final count = clampInt(4 + density * 3, 4, 28);
    for (var index = 0; index < count; index++) {
      final random = context.random('particle.v2.$namespace.$style.$index');
      final isFront = index % 5 < clampInt(5 - depth, 1, 4);
      final target = isFront ? front : back;
      final lifetime = _lifetime(style, random.nextInt(0, 7));
      final offset = random.nextInt(0, lifetime - 1);
      final age = positiveMod(context.phase + offset, lifetime);
      final size = random.nextInt(1, isFront ? 3 : 2);
      final sway = random.nextInt(0, isFront ? 3 : 2);
      final startX = random.nextInt(-6, 53);
      final phaseOffset = random.nextInt(0, lifetime - 1);
      final wind = drift + random.nextInt(-2, 2);
      _drawParticle(
        target,
        style: style,
        age: age,
        lifetime: lifetime,
        startX: startX,
        wind: wind,
        sway: sway,
        size: size,
        variant: random.nextInt(0, 3),
        phaseOffset: phaseOffset,
      );
    }
  }

  int _lifetime(String style, int variation) {
    if (_isRain(style) || style == 'meteorShower') return 12 + variation;
    if (style == 'sparks' || style == 'electricity') return 10 + variation;
    if (style == 'embers' || style == 'fire' || style == 'ash') {
      return 22 + variation * 2;
    }
    if (style == 'fog' || style == 'mist' || style == 'smoke' ||
        style == 'steam') {
      return 36 + variation * 3;
    }
    return 28 + variation * 2;
  }

  bool _isRain(String style) =>
      style == 'rain' || style == 'heavyRain' || style == 'lightDrizzle';

  void _drawParticle(
    _ParticleMasks target, {
    required String style,
    required int age,
    required int lifetime,
    required int startX,
    required int wind,
    required int sway,
    required int size,
    required int variant,
    required int phaseOffset,
  }) {
    final oscillation = cyclicOffset(age + phaseOffset, lifetime, sway);
    if (_isRain(style)) {
      final speed = style == 'heavyRain' ? 5 : style == 'lightDrizzle' ? 2 : 4;
      final length = style == 'heavyRain' ? 6 : style == 'lightDrizzle' ? 2 : 4;
      final y = -length + age * speed;
      final x = startX + wind * age ~/ 3 + oscillation;
      if (y < -length || y >= 48) return;
      target.base.line(x, y, x - 1 - wind.sign, y + length,
          thickness: style == 'heavyRain' && variant == 0 ? 2 : 1);
      return;
    }

    if (style == 'snow' || style == 'blizzard') {
      final y = -3 + age * (style == 'blizzard' ? 2 : 1);
      final x = startX + wind * age ~/ 5 + oscillation * 2;
      if (y < -2 || y >= 48) return;
      target.light.set(x, y).set(x - 1, y);
      if (size > 1) target.light.set(x, y - 1).set(x + 1, y);
      if (style == 'blizzard') target.light.line(x - 2, y, x + 2, y);
      return;
    }

    if (style == 'embers' || style == 'fire' || style == 'sparks' ||
        style == 'electricity' || style == 'ash') {
      final speed = style == 'sparks' || style == 'electricity' ? 3 : 1;
      final y = 50 - age * speed;
      final x = startX + wind * age ~/ 5 + oscillation;
      if (y < -3 || y >= 50) return;
      if (style == 'ash') {
        target.dark.fillRect(x, y, size, 1);
      } else if (style == 'sparks' || style == 'electricity') {
        target.light.line(x, y, x + wind.sign * (2 + variant), y - 2 - variant);
      } else {
        target.light.set(x, y).set(x, y - 1);
        if (size > 1) target.base.set(x + 1, y);
      }
      return;
    }

    if (style == 'fog' || style == 'mist' || style == 'smoke' ||
        style == 'steam') {
      final rising = style == 'smoke' || style == 'steam';
      final y = rising ? 49 - age : 5 + positiveMod(startX * 3, 36);
      final x = -10 + age * 2 + startX ~/ 4 + wind * age ~/ 7 + oscillation;
      if (x < -10 || x > 57 || y < -4 || y > 51) return;
      final width = 3 + size + age * 3 ~/ lifetime;
      final height = 1 + (variant == 0 ? 1 : 0);
      final mask = style == 'fog' || style == 'smoke' ? target.dark : target.light;
      mask.fillEllipse(x, y, width, height);
      return;
    }

    if (style == 'fallingLeaves' || style == 'leaves' || style == 'petals') {
      final y = -3 + age * 2;
      final x = startX + wind * age ~/ 5 + oscillation * 2;
      if (y < -2 || y >= 48) return;
      target.base.set(x, y).set(x + 1, y + (variant.isEven ? 1 : -1));
      if (size > 1) target.light.set(x - 1, y);
      return;
    }

    if (style == 'dust' || style == 'pollen' || style == 'magicDust' ||
        style == 'sandstorm') {
      final y = 4 + positiveMod(startX * 5 + variant * 7, 40);
      final x = -6 + age * (style == 'sandstorm' ? 4 : 2) + wind * age ~/ 5;
      if (x < -5 || x > 52) return;
      if (style == 'sandstorm') {
        target.base.line(x - 2, y, x + 3 + size, y);
      } else {
        (style == 'magicDust' ? target.light : target.base).set(x, y);
      }
      return;
    }

    if (style == 'bubbles') {
      final y = 50 - age * 2;
      final x = startX + oscillation * 2;
      if (y < -3 || y >= 50) return;
      target.light.fillEllipse(x, y, size, size);
      target.dark.set(x, y);
      return;
    }

    if (style == 'meteorShower') {
      final y = -5 + age * 4;
      final x = startX - age * 3 + wind;
      if (y < -4 || y >= 48) return;
      target.light.line(x, y, x - 5, y + 4, thickness: size > 1 ? 2 : 1);
      return;
    }

    if (style == 'fireflies') {
      final y = 8 + positiveMod(startX * 7, 31) + oscillation;
      final x = startX + cyclicOffset(age + phaseOffset, lifetime, 3);
      if (x < 0 || x >= 48 || y < 0 || y >= 48) return;
      target.light.fillEllipse(x, y, variant == 0 ? 1 : 0, variant == 0 ? 1 : 0);
      return;
    }

    if (style == 'glitch' || style == 'hologram' || style == 'glitchNoise') {
      if (age % 4 != variant) return;
      final y = positiveMod(startX * 11 + age * 3, 48);
      final x = positiveMod(startX + age * 5, 48);
      target.base.hLine(x - 2, x + 2 + size, y);
      return;
    }

    final y = -2 + age * 2;
    final x = startX + wind * age ~/ 5 + oscillation;
    if (y >= 0 && y < 48) target.base.fillRect(x, y, size, size);
  }
}

final class _ParticleMasks {
  final PixelMask dark = PixelMask();
  final PixelMask base = PixelMask();
  final PixelMask light = PixelMask();
}
