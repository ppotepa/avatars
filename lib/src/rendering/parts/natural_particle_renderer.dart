import '../../pixels/pixel_mask.dart';
import '../../util/math_utils.dart';
import '../render_helpers.dart';
import '../render_model.dart';

/// Deterministic force-field particles for non-rain weather and effects.
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
      globalWind: 0,
    );
    final weather = context.string('v4.weather');
    if (!_isRain(weather)) {
      _renderChannel(
        context,
        back,
        front,
        style: weather,
        density: context.integer('v4.weatherDensity'),
        namespace: 'weather',
        depth: context.integer('v4.weatherDepth'),
        globalWind: context.integer('v4.weatherDrift'),
      );
    }

    state
      ..addLayer('particle.v3.back.dark', 6, back.dark,
          context.color('bgDark'),
          nodeId: 'atmosphere',
          meta: const {'part': 'particle', 'depth': 'back'})
      ..addLayer('particle.v3.back', 7, back.base,
          context.color('bgLight'),
          nodeId: 'atmosphere',
          meta: const {'part': 'particle', 'depth': 'back'})
      ..addLayer('particle.v3.back.light', 8, back.light,
          context.color('fantasyLight'),
          nodeId: 'atmosphere',
          meta: const {'part': 'particle', 'depth': 'back'})
      ..addLayer('particle.v3.front.dark', 233, front.dark,
          context.color('bgDark'),
          nodeId: 'foreground',
          meta: const {'part': 'particle', 'depth': 'front'})
      ..addLayer('particle.v3.front', 234, front.base,
          context.color('fantasyBase'),
          nodeId: 'foreground',
          meta: const {'part': 'particle', 'depth': 'front'})
      ..addLayer('particle.v3.front.light', 235, front.light,
          context.color('fantasyLight'),
          nodeId: 'foreground',
          meta: const {'part': 'particle', 'depth': 'front'});
  }

  void _renderChannel(
    AvatarRenderContext context,
    _ParticleMasks back,
    _ParticleMasks front, {
    required String style,
    required int density,
    required String namespace,
    required int depth,
    required int globalWind,
  }) {
    if (style == 'none' || density <= 0) return;
    final count = clampInt(5 + density * 4, 5, 34);
    for (var index = 0; index < count; index++) {
      final random = context.random('particle.v3.$namespace.$style.$index');
      final layerDepth = index % 3;
      final isFront = layerDepth >= clampInt(depth - 1, 0, 2);
      final target = isFront ? front : back;
      final lifetime = _lifetime(style, random.nextInt(0, 8));
      final spawn = random.nextInt(0, lifetime - 1);
      final cycle = (context.phase - spawn) ~/ lifetime;
      final age = positiveMod(context.phase - spawn, lifetime);
      final cycleRandom =
          context.random('particle.v3.$namespace.$style.$index.$cycle');
      final depthScale = layerDepth + 1;
      final size = clampInt(cycleRandom.nextInt(1, 2) + layerDepth ~/ 2, 1, 3);
      final startX = cycleRandom.nextInt(-8, 55);
      final startY = cycleRandom.nextInt(-8, 50);
      final wind = globalWind + cycleRandom.nextInt(-1, 1);
      final turbulence = cycleRandom.nextInt(0, 2);
      _drawParticle(
        target,
        style: style,
        age: age,
        lifetime: lifetime,
        startX: startX,
        startY: startY,
        wind: wind,
        turbulence: turbulence,
        size: size,
        depthScale: depthScale,
        variant: cycleRandom.nextInt(0, 4),
      );
    }
  }

  int _lifetime(String style, int variation) {
    if (style == 'sparks' || style == 'electricity') return 9 + variation;
    if (style == 'embers' || style == 'fire') return 18 + variation * 2;
    if (style == 'ash') return 32 + variation * 3;
    if (style == 'fog' || style == 'mist') return 50 + variation * 4;
    if (style == 'smoke' || style == 'steam') return 40 + variation * 3;
    if (style == 'snow' || style == 'blizzard') return 34 + variation * 3;
    return 28 + variation * 2;
  }

  static bool _isRain(String style) =>
      style == 'rain' || style == 'heavyRain' || style == 'lightDrizzle';

  void _drawParticle(
    _ParticleMasks target, {
    required String style,
    required int age,
    required int lifetime,
    required int startX,
    required int startY,
    required int wind,
    required int turbulence,
    required int size,
    required int depthScale,
    required int variant,
  }) {
    final lifeRatio = age / lifetime;
    final sway = cyclicOffset(age + variant * 3, lifetime, turbulence + 1);

    if (style == 'snow' || style == 'blizzard') {
      final velocityY = style == 'blizzard' ? depthScale + 1 : 1;
      final x = startX + wind * age ~/ 7 + sway * (style == 'blizzard' ? 3 : 2);
      final y = -4 + age * velocityY;
      if (!_inside(x, y, margin: 4)) return;
      final mask = lifeRatio < .15 || lifeRatio > .9 ? target.base : target.light;
      mask.set(x, y).set(x - 1, y);
      if (size > 1) mask.set(x, y - 1).set(x + 1, y);
      if (style == 'blizzard') mask.line(x - 2, y, x + 2, y - wind.sign);
      return;
    }

    if (style == 'embers' || style == 'fire') {
      final velocityY = 1 + depthScale ~/ 2;
      final dragX = wind * age ~/ (8 + depthScale);
      final x = startX + dragX + sway;
      final y = 50 - age * velocityY - (age * age ~/ (lifetime * 2));
      if (!_inside(x, y, margin: 4)) return;
      final mask = lifeRatio > .8 ? target.base : target.light;
      mask.set(x, y).set(x, y + 1);
      if (size > 1 && lifeRatio < .7) target.base.set(x + wind.sign, y + 1);
      return;
    }

    if (style == 'sparks' || style == 'electricity') {
      final velocityX = wind == 0 ? (variant.isEven ? -2 : 2) : wind;
      final x = startX + velocityX * age;
      final y = startY - age * depthScale + age * age ~/ 5;
      if (!_inside(x, y, margin: 6)) return;
      target.light.line(
        x,
        y,
        x - velocityX.sign * (2 + depthScale),
        y + depthScale,
      );
      return;
    }

    if (style == 'ash') {
      final x = startX + wind * age ~/ 10 + sway * 2;
      final y = -3 + age;
      if (!_inside(x, y, margin: 4)) return;
      final mask = lifeRatio < .2 || lifeRatio > .85 ? target.dark : target.base;
      mask.fillRect(x, y, size, 1);
      return;
    }

    if (style == 'fog' || style == 'mist') {
      final bandY = 10 + positiveMod(startY * 5 + variant * 11, 34);
      final x = -14 + age * (1 + depthScale ~/ 2) + wind * age ~/ 12;
      if (x < -14 || x > 62) return;
      final width = 4 + size * 2 + (lifeRatio * 5).round();
      final mask = style == 'fog' ? target.dark : target.base;
      mask
        ..fillEllipse(x, bandY + sway, width, 1 + depthScale ~/ 2)
        ..fillEllipse(x + width ~/ 2, bandY + sway - 1, width ~/ 2, 1);
      return;
    }

    if (style == 'smoke' || style == 'steam') {
      final buoyancy = 1 + depthScale ~/ 2;
      final x = startX + wind * age ~/ 9 + sway * 2;
      final y = 51 - age * buoyancy;
      if (!_inside(x, y, margin: 7)) return;
      final radius = 1 + size + (lifeRatio * 3).round();
      final mask = style == 'smoke' ? target.dark : target.base;
      mask.fillEllipse(x, y, radius, clampInt(radius ~/ 2, 1, 3));
      return;
    }

    if (style == 'fallingLeaves' || style == 'leaves' || style == 'petals') {
      final x = startX + wind * age ~/ 6 + sway * 3;
      final y = -3 + age * (1 + depthScale ~/ 2);
      if (!_inside(x, y, margin: 4)) return;
      target.base.set(x, y).set(x + (variant.isEven ? 1 : -1), y + 1);
      if (size > 1) target.light.set(x - 1, y);
      return;
    }

    if (style == 'dust' || style == 'pollen' || style == 'magicDust' ||
        style == 'sandstorm') {
      final velocityX = style == 'sandstorm' ? 3 + depthScale : 1 + depthScale;
      final x = -7 + age * velocityX + wind * age ~/ 8;
      final y = 5 + positiveMod(startY * 7 + variant * 13, 39) + sway;
      if (!_inside(x, y, margin: 7)) return;
      if (style == 'sandstorm') {
        target.base.line(x - 2, y, x + 2 + size, y - wind.sign);
      } else {
        (style == 'magicDust' ? target.light : target.base).set(x, y);
      }
      return;
    }

    if (style == 'bubbles') {
      final x = startX + sway * 2;
      final y = 50 - age * (1 + depthScale ~/ 2);
      if (!_inside(x, y, margin: 4)) return;
      target.light.fillEllipse(x, y, size, size);
      target.dark.set(x, y);
      return;
    }

    if (style == 'meteorShower') {
      final x = 55 - age * (2 + depthScale) + startX ~/ 5;
      final y = -5 + age * (2 + depthScale);
      if (!_inside(x, y, margin: 8)) return;
      target.light.line(x, y, x + 4 + depthScale, y - 4 - depthScale);
      return;
    }

    if (style == 'fireflies') {
      final x = startX + cyclicOffset(age + variant, lifetime, 3);
      final y = 8 + positiveMod(startY * 7, 31) + sway;
      if (!_inside(x, y)) return;
      if (positiveMod(age + variant, 5) < 3) target.light.set(x, y);
      return;
    }

    if (style == 'glitch' || style == 'hologram' || style == 'glitchNoise') {
      if (age % 4 != variant % 4) return;
      final y = positiveMod(startY + age * 3, 48);
      final x = positiveMod(startX + age * 5, 48);
      target.base.hLine(x - 2, x + 2 + size, y);
      return;
    }

    final x = startX + wind * age ~/ 8 + sway;
    final y = -2 + age * depthScale;
    if (_inside(x, y)) target.base.fillRect(x, y, size, size);
  }

  bool _inside(int x, int y, {int margin = 0}) =>
      x >= -margin && x < 48 + margin && y >= -margin && y < 48 + margin;
}

final class _ParticleMasks {
  final PixelMask dark = PixelMask();
  final PixelMask base = PixelMask();
  final PixelMask light = PixelMask();
}
