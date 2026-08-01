import '../../pixels/pixel_mask.dart';
import '../../util/math_utils.dart';
import '../render_helpers.dart';
import '../render_model.dart';

/// Adds the V4.2 scenic, weather, event, cosmic and flame layers.
final class ExtendedAtmosphereRenderer implements AvatarPartRenderer {
  const ExtendedAtmosphereRenderer();

  @override
  void render(AvatarRenderContext context, AvatarRenderState state) {
    final scenic = _scenic(context);
    final cosmic = _cosmic(context);
    final ambient = _ambient(context);
    final flames = _flames(context);
    final event = _event(context);
    final weatherBack = _weather(context, back: true);
    final weatherFront = _weather(context, back: false);

    state
      ..addLayer('background.v42.dark', 2, scenic.dark, context.color('bgDark'),
          meta: const {'part': 'background'})
      ..addLayer(
          'background.v42.light', 3, scenic.light, context.color('bgLight'),
          meta: const {'part': 'background'})
      ..addLayer('background.v42.accent', 4, scenic.accent,
          context.color('clothAccent'),
          meta: const {'part': 'background'})
      ..addLayer(
          'cosmic.v42.dark', 3, cosmic.dark, context.color('fantasyDark'),
          meta: const {'part': 'cosmic'})
      ..addLayer(
          'cosmic.v42.base', 4, cosmic.base, context.color('fantasyBase'),
          meta: const {'part': 'cosmic'})
      ..addLayer(
          'cosmic.v42.light', 5, cosmic.light, context.color('fantasyLight'),
          meta: const {'part': 'cosmic'})
      ..addLayer('ambient.v42.dark', 5, ambient.dark, context.color('bgDark'),
          meta: const {'part': 'ambient'})
      ..addLayer(
          'ambient.v42.light', 6, ambient.light, context.color('bgLight'),
          meta: const {'part': 'ambient'})
      ..addLayer(
          'weather.v42.back.dark', 7, weatherBack.dark, context.color('bgDark'),
          meta: const {'part': 'weather'})
      ..addLayer(
          'weather.v42.back', 8, weatherBack.base, context.color('fantasyBase'),
          meta: const {'part': 'weather'})
      ..addLayer('weather.v42.back.light', 9, weatherBack.light,
          context.color('fantasyLight'),
          meta: const {'part': 'weather'})
      ..addLayer(
          'flames.v42.dark', 8, flames.dark, context.color('fantasyDark'),
          meta: const {'part': 'flames'})
      ..addLayer(
          'flames.v42.base', 9, flames.base, context.color('fantasyBase'),
          meta: const {'part': 'flames'})
      ..addLayer(
          'flames.v42.light', 9, flames.light, context.color('fantasyLight'),
          meta: const {'part': 'flames'})
      ..addLayer(
          'backgroundEvent.v42.dark', 6, event.dark, context.color('bgDark'),
          meta: const {'part': 'backgroundEvent'})
      ..addLayer('backgroundEvent.v42.base', 7, event.base,
          context.color('clothAccent'),
          meta: const {'part': 'backgroundEvent'})
      ..addLayer(
          'backgroundEvent.v42.light', 8, event.light, context.color('white'),
          meta: const {'part': 'backgroundEvent'})
      ..addLayer('weather.v42.front.dark', 233, weatherFront.dark,
          context.color('bgDark'),
          meta: const {'part': 'weather'})
      ..addLayer('weather.v42.front', 234, weatherFront.base,
          context.color('fantasyBase'),
          meta: const {'part': 'weather'})
      ..addLayer('weather.v42.front.light', 235, weatherFront.light,
          context.color('fantasyLight'),
          meta: const {'part': 'weather'});
  }

  _TripleMask _scenic(AvatarRenderContext c) {
    final style = c.string('v4.background');
    final dark = PixelMask();
    final light = PixelMask();
    final accent = PixelMask();
    if (style == 'sunrise' || style == 'sunsetMountains') {
      light.fillRect(0, 0, 48, 25);
      accent.fillEllipse(style == 'sunrise' ? 12 : 36, 14, 5, 5);
      for (var x = -5; x < 53; x += 10) {
        dark.fillTriangle((x: x, y: 39), (x: x + 13, y: 39),
            (x: x + 6, y: 22 + positiveMod(x, 7)));
      }
    } else if (style == 'moonlitForest' ||
        style == 'foggyForest' ||
        style == 'deadForest') {
      dark.fillRect(0, 0, 48, 48);
      accent.fillEllipse(38, 9, 4, 4);
      for (var x = 1; x < 48; x += 7) {
        dark.fillRect(x, 17 + positiveMod(x, 7), 2, 31);
        light.line(x + 1, 20, x - 3, 10 + positiveMod(x, 6));
      }
      if (style == 'foggyForest') {
        for (var y = 22; y < 45; y += 6) light.hLine(0, 47, y);
      }
    } else if (style == 'desertDunes' || style == 'alienPlanet') {
      light.fillRect(0, 0, 48, 27);
      dark.fillEllipse(10, 45, 30, 12);
      accent.fillEllipse(41, 8, style == 'alienPlanet' ? 6 : 4, 4);
      if (style == 'alienPlanet') accent.fillEllipse(7, 13, 2, 2);
    } else if (style == 'oceanHorizon') {
      light.fillRect(0, 0, 48, 24);
      dark.fillRect(0, 25, 48, 23);
      for (var y = 28; y < 48; y += 4) {
        accent.hLine(positiveMod(y, 5), 47 - positiveMod(y, 7), y);
      }
    } else if (style == 'snowMountains') {
      light.fillRect(0, 0, 48, 48);
      for (var x = -8; x < 55; x += 14) {
        dark.fillTriangle((x: x, y: 42), (x: x + 18, y: 42),
            (x: x + 9, y: 15 + positiveMod(x, 8)));
        accent.fillTriangle((x: x + 4, y: 29), (x: x + 14, y: 29),
            (x: x + 9, y: 16 + positiveMod(x, 8)));
      }
    } else if (style == 'volcanicSky' || style == 'demonicGate') {
      dark.fillRect(0, 0, 48, 48);
      accent.fillEllipse(24, 31, 17, 22);
      dark.fillEllipse(24, 31, 11, 17);
      for (var x = 0; x < 48; x += 6) {
        light.line(x, 47, x + 2, 35 - positiveMod(x, 8));
      }
    } else if (style == 'caveGlow' || style == 'crystalCave') {
      dark.fillRect(0, 0, 48, 48);
      for (var x = 2; x < 48; x += 7) {
        accent.fillTriangle((x: x, y: 47), (x: x + 5, y: 47),
            (x: x + 2, y: 28 - positiveMod(x, 10)));
        light.set(x + 2, 31 - positiveMod(x, 10));
      }
    } else if (style == 'citySkyline' || style == 'factorySmoke') {
      dark.fillRect(0, 0, 48, 48);
      for (var x = 0; x < 48; x += 6) {
        final height = 10 + positiveMod(x * 3, 24);
        light.fillRect(x, 48 - height, 5, height);
        for (var y = 48 - height + 3; y < 47; y += 5) accent.set(x + 2, y);
      }
      if (style == 'factorySmoke') {
        for (var i = 0; i < 5; i++) {
          accent.fillEllipse(8 + i * 8, 12 - i, 3 + i % 2, 2);
        }
      }
    } else if (style == 'castleWall' ||
        style == 'throneRoom' ||
        style == 'cathedralWindow') {
      dark.fillRect(0, 0, 48, 48);
      for (var y = 3; y < 48; y += 6) {
        for (var x = (y ~/ 6).isEven ? 0 : -4; x < 48; x += 9) {
          light.hLine(x, x + 7, y);
        }
      }
      if (style == 'throneRoom') {
        accent.fillRect(18, 10, 12, 28);
        accent.fillTriangle((x: 18, y: 10), (x: 30, y: 10), (x: 24, y: 3));
      } else if (style == 'cathedralWindow') {
        accent.fillEllipse(24, 15, 10, 13);
        dark.vLine(24, 3, 28).hLine(14, 34, 15);
      }
    } else if (style == 'libraryShelves') {
      dark.fillRect(0, 0, 48, 48);
      for (var y = 5; y < 48; y += 10) {
        light.hLine(1, 46, y);
        for (var x = 3; x < 45; x += 4) accent.fillRect(x, y + 1, 2, 7);
      }
    } else if (style == 'runeCircle' ||
        style == 'portalRift' ||
        style == 'astralPlane') {
      dark.fillRect(0, 0, 48, 48);
      final outer = PixelMask()..fillEllipse(24, 24, 21, 21);
      final inner = PixelMask()..fillEllipse(24, 24, 17, 17);
      accent.data.setAll(0, outer.subtract(inner).data);
      for (var i = 0; i < 12; i++) {
        light.set(5 + positiveMod(i * 13, 38), 5 + positiveMod(i * 7, 38));
      }
      if (style == 'portalRift') light.vLine(24, 5, 43);
    } else if (style == 'floatingIslands') {
      light.fillRect(0, 0, 48, 48);
      for (var i = 0; i < 4; i++) {
        final x = 5 + i * 12;
        final y = 12 + positiveMod(i * 7, 20);
        dark.fillEllipse(x, y, 7, 3);
        accent.fillTriangle(
            (x: x - 5, y: y + 1), (x: x + 5, y: y + 1), (x: x, y: y + 8));
      }
    } else if (style == 'celestialHall') {
      light.fillRect(0, 0, 48, 48);
      for (var x = 4; x < 48; x += 10) dark.fillRect(x, 6, 4, 42);
      accent.fillEllipse(24, 8, 7, 3);
    } else if (style == 'spaceStation' || style == 'starshipBridge') {
      dark.fillRect(0, 0, 48, 48);
      light.fillRect(4, 4, 40, 30);
      dark.fillRect(7, 7, 34, 24);
      accent.hLine(8, 40, 34).vLine(24, 7, 31);
    } else if (style == 'dataGrid' ||
        style == 'warpTunnel' ||
        style == 'voidStatic') {
      dark.fillRect(0, 0, 48, 48);
      for (var x = 0; x < 48; x += 5) accent.vLine(x, 0, 47);
      for (var y = 0; y < 48; y += 5) light.hLine(0, 47, y);
      if (style == 'warpTunnel') {
        for (var i = 0; i < 8; i++)
          light.line(24, 24, i * 7, i.isEven ? 0 : 47);
      }
    } else if (style == 'graveyard' ||
        style == 'bloodMoon' ||
        style == 'mistSwamp') {
      dark.fillRect(0, 0, 48, 48);
      accent.fillEllipse(37, 9, style == 'bloodMoon' ? 7 : 4, 7);
      for (var x = 4; x < 46; x += 8) {
        light.fillRect(x, 32 + positiveMod(x, 5), 4, 12);
        light.hLine(x - 2, x + 5, 35 + positiveMod(x, 5));
      }
    }
    return _TripleMask(dark, light, accent);
  }

  _TripleMask _cosmic(AvatarRenderContext c) {
    final style = c.string('v4.cosmicLayer');
    final density = c.integer('v4.cosmicDensity');
    final dark = PixelMask();
    final base = PixelMask();
    final light = PixelMask();
    if (style == 'none' || density == 0) return _TripleMask(dark, base, light);
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
      light.data.setAll(0, light.union(ring.subtract(dark)).data);
    }
    if (style == 'constellation') {
      for (var i = 0; i < 6; i++) {
        final x1 = 6 + i * 7;
        final y1 = 8 + positiveMod(i * 11, 20);
        light.set(x1, y1);
        if (i > 0)
          light.line(x1 - 7, 8 + positiveMod((i - 1) * 11, 20), x1, y1);
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
            rng.nextInt(2, 45), rng.nextInt(4, 35), 1 + i % 3, 1 + i % 2);
      }
    }
    return _TripleMask(dark, base, light);
  }

  _TripleMask _ambient(AvatarRenderContext c) {
    final style = c.string('v4.ambientOverlay');
    final density = c.integer('v4.ambientDensity');
    final dark = PixelMask();
    final light = PixelMask();
    if (style == 'none' || density == 0)
      return _TripleMask(dark, PixelMask(), light);
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
      for (var x = -2; x < 52; x += 7)
        dark.fillEllipse(x, 7 + positiveMod(x, 5), 6, 3);
    } else if (style == 'heatHaze') {
      for (var x = 2; x < 47; x += 5)
        light.line(x, 47, x + positiveMod(phase, 3) - 1, 32);
    } else if (style == 'voidVeil') {
      dark.data.setAll(
          0, orderedDither(PixelMask.filled(), clampInt(density, 1, 6)).data);
    } else if (style == 'holyLight') {
      for (var x = 0; x < 48; x += 7) light.line(24, 0, x, 47);
    } else if (style == 'dustVeil') {
      light.data.setAll(
          0,
          orderedDither(PixelMask.filled(), clampInt(density, 1, 4),
                  phase: phase)
              .data);
    } else if (style == 'underwaterLight') {
      for (var x = 0; x < 48; x += 8) light.line(x, 0, x + 12, 47);
    }
    return _TripleMask(dark, PixelMask(), light);
  }

  _TripleMask _flames(AvatarRenderContext c) {
    final style = c.string('v4.backFlames');
    final height = c.integer('v4.flameHeight');
    final intensity = c.integer('v4.flameIntensity');
    final flicker = c.integer('v4.flameFlicker');
    final dark = PixelMask();
    final base = PixelMask();
    final light = PixelMask();
    if (style == 'none' || height == 0 || intensity == 0) {
      return _TripleMask(dark, base, light);
    }
    final phase = c.rendering.animateBackground ? c.phase : 0;
    final spacing = style == 'wideFlames' || style == 'hellfire' ? 4 : 7;
    for (var x = -2; x < 52; x += spacing) {
      final wave = positiveMod(x * 3 + phase * clampInt(flicker, 1, 6), 7);
      final tip = clampInt(47 - height * 3 - wave, 10, 45);
      base.fillTriangle((x: x - 3, y: 48), (x: x + 4, y: 48), (x: x, y: tip));
      light.fillTriangle((x: x - 1, y: 48), (x: x + 2, y: 48),
          (x: x, y: tip + 5 + intensity ~/ 2));
      if (style == 'smokeAndFire') dark.fillEllipse(x, tip - 4, 3, 2);
    }
    if (style == 'ritualFire') {
      dark.fillEllipse(24, 44, 17, 3);
      base.fillEllipse(24, 43, 12, 2);
    }
    if (style == 'torchGlow') light.fillEllipse(24, 31, 18, 15);
    return _TripleMask(dark, base, light);
  }

  _TripleMask _weather(AvatarRenderContext c, {required bool back}) {
    final style = c.string('v4.weather');
    final density = c.integer('v4.weatherDensity');
    final depth = c.integer('v4.weatherDepth');
    final dark = PixelMask();
    final base = PixelMask();
    final light = PixelMask();
    if (style == 'none' || density == 0) return _TripleMask(dark, base, light);
    if (back && depth <= 1) return _TripleMask(dark, base, light);
    if (!back && depth >= 4) return _TripleMask(dark, base, light);
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
        base.line(x, y, x - 1, y + length,
            thickness: style == 'heavyRain' && i.isEven ? 2 : 1);
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
    return _TripleMask(dark, base, light);
  }

  _TripleMask _event(AvatarRenderContext c) {
    final style = c.string('v4.backgroundEvent');
    final frequency = c.integer('v4.eventFrequency');
    final intensity = c.integer('v4.eventIntensity');
    final dark = PixelMask();
    final base = PixelMask();
    final light = PixelMask();
    if (style == 'none' || intensity == 0 || !c.rendering.animateBackground) {
      return _TripleMask(dark, base, light);
    }
    final background = c.string('v4.background');
    final technicalBackground =
        <String>{'terminal', 'laboratory', 'spaceship'}.contains(background);
    final nightBackground = <String>{'night', 'neonCity', 'rainCity', 'dungeon'}
        .contains(background);
    if ((style == 'screenScan' && !technicalBackground) ||
        (style == 'shadowSweep' && !nightBackground) ||
        (style == 'neonFlicker' && !technicalBackground && !nightBackground)) {
      return _TripleMask(dark, base, light);
    }
    final period = clampInt(10 + frequency * 7, 12, 72);
    final step =
        positiveMod(c.phase + c.integer('v4.motionPhaseOffset'), period);
    if (step > 1 && !(style == 'screenScan' || style == 'shadowSweep')) {
      return _TripleMask(dark, base, light);
    }
    if (style == 'lightningFlash' ||
        style == 'alarmFlash' ||
        style == 'sunPulse') {
      light.data
          .setAll(0, orderedDither(PixelMask.filled(), 2 + intensity).data);
    } else if (style == 'lightningBranch') {
      var x = 24 + positiveMod(c.phase * 5, 15) - 7;
      light.line(x, 0, x - 3, 12, thickness: 2);
      light.line(x - 3, 12, x + 2, 23, thickness: 2);
      light.line(x + 2, 23, x - 4, 37, thickness: 2);
      light.line(x - 2, 17, x - 10, 25);
    } else if (style == 'moonGlow' || style == 'eclipsePulse') {
      base.fillEllipse(38, 9, 5 + intensity, 5 + intensity);
      if (style == 'eclipsePulse')
        dark.fillEllipse(38, 9, 3 + intensity, 3 + intensity);
    } else if (style == 'fireBurst' || style == 'lavaPulse') {
      for (var x = 0; x < 48; x += 5) {
        light.line(x, 47, x + 1, 30 - positiveMod(x + c.phase, 10),
            thickness: 2);
      }
    } else if (style == 'portalPulse') {
      final outer = PixelMask()
        ..fillEllipse(24, 24, 18 + intensity, 22 + intensity);
      final inner = PixelMask()
        ..fillEllipse(24, 24, 15 + intensity, 19 + intensity);
      base.data.setAll(0, outer.subtract(inner).data);
    } else if (style == 'neonFlicker') {
      dark.data.setAll(0, orderedDither(PixelMask.filled(), 3).data);
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
        light.set(x, y).set(x - 1, y).set(x + 1, y).set(x, y - 1).set(x, y + 1);
      }
    } else if (style == 'ghostPass') {
      base.fillEllipse(positiveMod(c.phase * 3, 60) - 6, 22, 5, 9);
    } else if (style == 'shadowSweep') {
      final x = positiveMod(c.phase * 2, 56) - 8;
      dark.fillRect(x, 0, 3 + clampInt(intensity, 0, 2), 48);
    }
    return _TripleMask(dark, base, light);
  }
}

/// Adds halos, symbolic rings, creature traits, relics and companion props.
final class ExtendedAdornmentRenderer implements AvatarPartRenderer {
  const ExtendedAdornmentRenderer();

  @override
  void render(AvatarRenderContext context, AvatarRenderState state) {
    final halo = _halo(context);
    final symbols = _symbols(context);
    final back = _backAdornment(context);
    final head = _headDetails(context, state);
    final creature = _creature(context, state);
    final relic = _relic(context);
    final companion = _companion(context);
    final hornAccent = _hornAccent(context, state);

    state
      ..addLayer(
          'backAdornment.v42.dark', 8, back.dark, context.color('outline'),
          meta: const {'part': 'backAdornment'})
      ..addLayer('backAdornment.v42', 9, back.base, context.color('clothBase'),
          meta: const {'part': 'backAdornment'})
      ..addLayer('backAdornment.v42.light', 9, back.light,
          context.color('fantasyLight'),
          meta: const {'part': 'backAdornment'})
      ..addLayer(
          'symbols.v42.back', 9, symbols.back, context.color('fantasyBase'),
          meta: const {'part': 'symbols'})
      ..addLayer('halo.v42.back', 9, halo.back, context.color('fantasyBase'),
          meta: const {'part': 'halo'})
      ..addLayer('halo.v42.glow', 9, halo.glow, context.color('fantasyLight'),
          meta: const {'part': 'halo'})
      ..addLayer('headAdornment.v42.dark', 152, head.dark,
          context.color('outlineSoft'),
          meta: const {'part': 'headAdornment'})
      ..addLayer(
          'headAdornment.v42', 153, head.base, context.color('clothAccent'),
          meta: const {'part': 'headAdornment'})
      ..addLayer('headAdornment.v42.light', 154, head.light,
          context.color('fantasyLight'),
          meta: const {'part': 'headAdornment'})
      ..addLayer(
          'creature.v42.dark', 152, creature.dark, context.color('skinDeep'),
          meta: const {'part': 'creatureTrait'})
      ..addLayer(
          'creature.v42', 153, creature.base, context.color('skinAccent'),
          meta: const {'part': 'creatureTrait'})
      ..addLayer('creature.v42.light', 154, creature.light,
          context.color('fantasyLight'),
          meta: const {'part': 'creatureTrait'})
      ..addLayer(
          'hornAccent.v42', 152, hornAccent.base, context.color('fantasyDark'),
          meta: const {'part': 'fantasy'})
      ..addLayer('hornAccent.v42.light', 153, hornAccent.light,
          context.color('fantasyLight'),
          meta: const {'part': 'fantasy'})
      ..addLayer(
          'halo.v42.front', 155, halo.front, context.color('fantasyLight'),
          meta: const {'part': 'halo'})
      ..addLayer('symbols.v42.front', 190, symbols.front,
          context.color('fantasyLight'),
          meta: const {'part': 'symbols'})
      ..addLayer('relic.v42.dark', 189, relic.dark, context.color('clothDark'),
          meta: const {'part': 'relic'})
      ..addLayer('relic.v42', 190, relic.base, context.color('clothAccent'),
          meta: const {'part': 'relic'})
      ..addLayer(
          'relic.v42.light', 191, relic.light, context.color('fantasyLight'),
          meta: const {'part': 'relic'})
      ..addLayer(
          'companion.v42.dark', 198, companion.dark, context.color('outline'),
          meta: const {'part': 'companion'})
      ..addLayer(
          'companion.v42', 199, companion.base, context.color('clothAccent'),
          meta: const {'part': 'companion'})
      ..addLayer('companion.v42.light', 200, companion.light,
          context.color('fantasyLight'),
          meta: const {'part': 'companion'});
  }

  _HaloResult _halo(AvatarRenderContext c) {
    final style = c.string('v4.halo');
    final back = PixelMask();
    final front = PixelMask();
    final glow = PixelMask();
    if (style == 'none') return _HaloResult(back, front, glow);
    final size = c.integer('v4.haloSize');
    final centerY = clampInt(
        c.integer('head.topY') - 4 + c.integer('v4.haloHeight'), 1, 28);
    final tilt = c.integer('v4.haloTilt');
    final pulse = (c.string('v4.eventMotion') == 'haloPulse' ||
            c.string('v4.eventMotion') == 'haloOrbit')
        ? cyclicOffset(
            c.phase,
            animationPeriod(c.integer('v4.haloOrbitSpeed'), slow: 24, fast: 12),
            1)
        : 0;
    final outer = PixelMask()
      ..fillEllipse(
          24 + tilt, centerY, size + pulse, clampInt(size ~/ 3 + pulse, 2, 9));
    final inner = PixelMask()
      ..fillEllipse(24 + tilt, centerY, clampInt(size - 2, 2, 22),
          clampInt(size ~/ 3 - 1 + pulse, 1, 8));
    var ring = outer.subtract(inner);
    if (style == 'thickHalo' || style == 'solarDisc') ring = ring.dilated();
    if (style == 'doubleHalo') {
      final secondOuter = PixelMask()
        ..fillEllipse(24 - tilt, centerY - 3, size - 2, size ~/ 3);
      final secondInner = PixelMask()
        ..fillEllipse(
            24 - tilt, centerY - 3, size - 4, clampInt(size ~/ 3 - 1, 1, 8));
      ring = ring.union(secondOuter.subtract(secondInner));
    }
    if (style == 'brokenHalo' || c.integer('v4.haloBreakage') > 2) {
      ring = ring.subtract(maskFromPredicate(
          (x, y) => (x > 27 && y < centerY) || positiveMod(x + y, 9) == 0));
    }
    if (style == 'floatingSegments' || style == 'glitchHalo') {
      ring = ring.intersect(
          maskFromPredicate((x, y) => positiveMod(x + y + c.phase, 4) != 0));
    }
    if (style == 'runicHalo' ||
        style == 'holySpikes' ||
        style == 'crownHalo' ||
        style == 'thornHalo') {
      for (var i = 0; i < 10; i++) {
        final x = 8 + i * 4;
        final y = centerY + (i.isEven ? -size ~/ 3 : size ~/ 3);
        ring.set(x, y);
        if (style == 'holySpikes' || style == 'thornHalo') {
          ring.line(x, y, x, y + (i.isEven ? -3 : 3));
        }
      }
    }
    if (style == 'flameHalo' ||
        style == 'iceHalo' ||
        style == 'electricHalo' ||
        style == 'cosmicHalo') {
      for (var x = 8; x < 41; x += 4) {
        ring.line(x, centerY, x + (x.isEven ? 1 : -1),
            centerY - 3 - positiveMod(x, 4));
      }
    }
    if (style == 'mechanicalHalo' || style == 'neonHalo') {
      for (var x = 9; x < 40; x += 6) ring.fillRect(x, centerY - 1, 3, 3);
    }
    final headBand =
        maskFromPredicate((x, y) => y <= c.integer('head.topY') + 1);
    back.data.setAll(0, ring.intersect(headBand).data);
    front.data.setAll(0, ring.subtract(headBand).data);
    final glowAmount = c.integer('v4.haloGlow');
    if (glowAmount > 0) {
      var expanded = ring;
      for (var i = 0; i < clampInt(glowAmount, 1, 3); i++)
        expanded = expanded.dilated();
      glow.data.setAll(
          0,
          expanded
              .subtract(ring)
              .intersect(
                  maskFromPredicate((x, y) => positiveMod(x + y, 2) == 0))
              .data);
    }
    return _HaloResult(back, front, glow);
  }

  _SymbolResult _symbols(AvatarRenderContext c) {
    final style = c.string('v4.symbolOverlay');
    final density = c.integer('v4.symbolDensity');
    final back = PixelMask();
    final front = PixelMask();
    if (style == 'none' || density == 0) return _SymbolResult(back, front);
    final phase = c.string('v4.eventMotion') == 'symbolOrbit' ? c.phase : 0;
    if (style == 'magicCircle' ||
        style == 'clockworkRing' ||
        style == 'spiral') {
      final outer = PixelMask()..fillEllipse(24, 24, 20, 24);
      final inner = PixelMask()..fillEllipse(24, 24, 18, 22);
      back.data.setAll(0, outer.subtract(inner).data);
      if (style == 'spiral') back.line(24, 24, 42, 24 - positiveMod(phase, 6));
    }
    final count = 3 + density * 2;
    for (var i = 0; i < count; i++) {
      final x = 4 + positiveMod(i * 13 + phase, 40);
      final y = 5 + positiveMod(i * 9 - phase, 38);
      if (style == 'runes' || style == 'glyphs' || style == 'prayerText') {
        back.vLine(x, y - 2, y + 2).set(x + 1, y);
      } else if (style == 'crosshair' || style == 'targetLock') {
        back.hLine(x - 2, x + 2, y).vLine(x, y - 2, y + 2);
      } else if (style == 'musicNotes') {
        front.vLine(x, y - 3, y + 1).fillEllipse(x - 1, y + 2, 1, 1);
      } else if (style == 'stars' || style == 'constellationLines') {
        back.set(x, y).set(x - 1, y).set(x + 1, y).set(x, y - 1).set(x, y + 1);
      } else if (style == 'hearts') {
        front
            .set(x - 1, y)
            .set(x + 1, y)
            .hLine(x - 1, x + 1, y + 1)
            .set(x, y + 2);
      } else if (style == 'chains' || style == 'thorns') {
        back.line(x, y - 3, x + 3, y + 3);
      } else if (style == 'warningTriangles') {
        back.fillTriangle(
            (x: x - 2, y: y + 2), (x: x + 2, y: y + 2), (x: x, y: y - 2));
      } else if (style == 'electroLines') {
        front.line(x, y - 3, x + 2, y).line(x + 2, y, x - 1, y + 3);
      } else if (style == 'smokeSwirls' || style == 'petalSwirls') {
        front.fillEllipse(x, y, 2, 1);
      }
    }
    return _SymbolResult(back, front);
  }

  _TripleMask _backAdornment(AvatarRenderContext c) {
    final style = c.string('v4.backAdornment');
    final dark = PixelMask();
    final base = PixelMask();
    final light = PixelMask();
    if (style == 'none') return _TripleMask(dark, base, light);
    if (style == 'bannerBack' || style == 'prayerScrollBack') {
      base.fillRect(18, 21, 12, 27);
      light.hLine(18, 29, 24).vLine(24, 22, 46);
    } else if (style == 'totemPoleBack' || style == 'boneSpineBack') {
      base.fillRect(21, 10, 6, 38);
      for (var y = 13; y < 47; y += 6) light.hLine(18, 30, y);
    } else if (style == 'spiritRibbon') {
      base
          .line(12, 47, 19, 21, thickness: 3)
          .line(36, 47, 29, 21, thickness: 3);
    } else if (style == 'energyBackpack' ||
        style == 'jetpackSmall' ||
        style == 'jetpackLarge') {
      final w = style == 'jetpackLarge' ? 18 : 12;
      base.fillRect(24 - w ~/ 2, 30, w, 17);
      light.fillRect(17, 38, 3, 8).fillRect(28, 38, 3, 8);
    } else if (style == 'crystalClusterBack') {
      for (var x = 8; x <= 40; x += 8) {
        base.fillTriangle((x: x - 3, y: 44), (x: x + 3, y: 44),
            (x: x, y: 17 + positiveMod(x, 9)));
        light.set(x, 20 + positiveMod(x, 9));
      }
    } else if (style == 'capeTorn' ||
        style == 'capeRoyal' ||
        style == 'cloakStarry') {
      base.fillTriangle((x: 8, y: 29), (x: 40, y: 29), (x: 24, y: 48));
      if (style == 'capeTorn')
        base.data.setAll(
            0,
            base
                .subtract(maskFromPredicate(
                    (x, y) => y > 40 && positiveMod(x + y, 5) == 0))
                .data);
      if (style == 'cloakStarry') {
        for (var i = 0; i < 12; i++)
          light.set(11 + positiveMod(i * 7, 27), 31 + positiveMod(i * 5, 15));
      }
    } else if (style.startsWith('wings')) {
      base.fillTriangle((x: 15, y: 34), (x: 0, y: 11), (x: 7, y: 44));
      base.fillTriangle((x: 33, y: 34), (x: 47, y: 11), (x: 41, y: 44));
      for (var y = 18; y < 42; y += 5) {
        light.line(14, 34, 3, y);
        light.line(34, 34, 44, y);
      }
      if (style == 'wingsHologram' || style == 'wingsGhostly') {
        base.data.setAll(
            0, orderedDither(base, style == 'wingsGhostly' ? 3 : 5).data);
      }
    }
    dark.data.setAll(0, shadingMask(base, kind: 'clothing', strength: 2).data);
    return _TripleMask(dark, base, light.intersect(base));
  }

  _TripleMask _headDetails(AvatarRenderContext c, AvatarRenderState state) {
    final style = c.string('v4.headAdornment');
    final side = c.string('v4.sideHeadFeature');
    final dark = PixelMask();
    final base = PixelMask();
    final light = PixelMask();
    final eyeY = c.integer('face.eyeY');
    if (style == 'foreheadGem' || style == 'tiaraGem') {
      base.fillEllipse(24, eyeY - 5, 2, 2);
      light.set(23, eyeY - 6);
    } else if (style == 'thirdEyeMark') {
      base.fillEllipse(24, eyeY - 5, 3, 1);
      dark.set(24, eyeY - 5);
    } else if (style == 'moonCrescent') {
      base.fillEllipse(24, eyeY - 5, 3, 3);
      base.data.setAll(
          0, base.subtract(PixelMask()..fillEllipse(26, eyeY - 6, 3, 3)).data);
    } else if (style == 'sunDisc') {
      base.fillEllipse(24, eyeY - 5, 2, 2);
      base.hLine(19, 29, eyeY - 5).vLine(24, eyeY - 10, eyeY);
    } else if (style == 'sigil' ||
        style == 'runeStrip' ||
        style == 'crackGlow') {
      base.vLine(24, eyeY - 9, eyeY - 2).hLine(21, 27, eyeY - 6);
      if (style == 'crackGlow') light.line(24, eyeY - 8, 21, eyeY - 3);
    } else if (style == 'chainForehead' || style == 'crownFrontlet') {
      base.line(15, eyeY - 7, 24, eyeY - 4).line(24, eyeY - 4, 33, eyeY - 7);
      light.set(24, eyeY - 4);
    } else if (style == 'laurelFront') {
      for (var x = 15; x < 34; x += 3)
        base.fillEllipse(x, eyeY - 7 - positiveMod(x, 3), 2, 1);
    } else if (style == 'bandageForehead') {
      base.fillRect(15, eyeY - 8, 18, 4);
      dark.line(16, eyeY - 8, 31, eyeY - 5);
    } else if (style == 'warPaintStripe') {
      base.line(16, eyeY - 8, 32, eyeY - 3, thickness: 2);
    } else if (style == 'ritualDots') {
      for (var x = 18; x <= 30; x += 3) base.set(x, eyeY - 6);
    } else if (style == 'mechanicalPlate' || style == 'visorPlate') {
      base.fillRect(17, eyeY - 9, 14, 5);
      dark.hLine(18, 30, eyeY - 7);
      light.set(19, eyeY - 8).set(29, eyeY - 8);
    }

    if (side != 'none') {
      final y = c.integer('ears.centerY');
      for (final direction in const <int>[-1, 1]) {
        final x = direction < 0
            ? c.integer('head.leftX') - 1
            : c.integer('head.rightX') + 1;
        if (side == 'finFrill' || side == 'leafEarsAccent') {
          base.fillTriangle(
              (x: x, y: y - 4), (x: x + direction * 7, y: y), (x: x, y: y + 4));
        } else if (side == 'featherTuft' || side == 'furTufts') {
          base.fillTriangle((x: x, y: y - 3), (x: x + direction * 5, y: y - 7),
              (x: x + direction * 2, y: y + 1));
        } else if (side == 'gillSlits') {
          for (var i = 0; i < 3; i++)
            dark.line(x, y - 2 + i * 2, x + direction * 4, y - 1 + i * 2);
        } else if (side == 'sideSpikes' || side == 'smallHorns') {
          base.fillTriangle(
              (x: x, y: y - 3), (x: x + direction * 6, y: y - 5), (x: x, y: y));
          base.fillTriangle((x: x, y: y + 1), (x: x + direction * 5, y: y + 5),
              (x: x, y: y + 4));
        } else if (side == 'antennaBulb' || side == 'antennaFeather') {
          base.line(x, y - 3, x + direction * 4, y - 10);
          light.fillEllipse(
              x + direction * 4, y - 10, 1, side == 'antennaFeather' ? 3 : 1);
        } else if (side == 'mechanicalPort' ||
            side == 'audioReceiver' ||
            side == 'orbitalNode') {
          base.fillRect(x + (direction < 0 ? -3 : 0), y - 3, 4, 7);
          light.set(x + direction, y);
        }
      }
    }
    final clip = state
        .mask('head')
        .dilated(iterations: 2)
        .union(state.mask('ears').dilated());
    return _TripleMask(
        dark.intersect(clip), base.intersect(clip), light.intersect(clip));
  }

  _TripleMask _creature(AvatarRenderContext c, AvatarRenderState state) {
    final style = c.string('v4.creatureTrait');
    final dark = PixelMask();
    final base = PixelMask();
    final light = PixelMask();
    if (style == 'none') return _TripleMask(dark, base, light);
    final mouthY = c.integer('face.mouthY');
    final noseY = c.integer('face.noseTipY');
    if (style == 'fangs') {
      light.fillTriangle(
          (x: 21, y: mouthY), (x: 23, y: mouthY), (x: 22, y: mouthY + 3));
      light.fillTriangle(
          (x: 25, y: mouthY), (x: 27, y: mouthY), (x: 26, y: mouthY + 3));
    } else if (style == 'tusks') {
      light.line(20, mouthY, 18, mouthY + 4, thickness: 2);
      light.line(28, mouthY, 30, mouthY + 4, thickness: 2);
    } else if (style == 'whiskers') {
      for (var i = -1; i <= 1; i++) {
        dark.line(19, noseY + i, 11, noseY + i * 3);
        dark.line(29, noseY + i, 37, noseY + i * 3);
      }
    } else if (style == 'snoutHint' ||
        style == 'catNose' ||
        style == 'beakHint') {
      dark.fillEllipse(24, noseY, style == 'beakHint' ? 3 : 2, 1);
      if (style == 'beakHint')
        base.fillTriangle(
            (x: 20, y: noseY), (x: 28, y: noseY), (x: 24, y: noseY + 4));
    } else if (style == 'gills') {
      for (var i = 0; i < 3; i++) {
        dark.line(14, noseY + i * 2, 18, noseY + 1 + i * 2);
        dark.line(34, noseY + i * 2, 30, noseY + 1 + i * 2);
      }
    } else if (style == 'scales' ||
        style == 'furPatches' ||
        style == 'featherCheeks' ||
        style == 'stoneSkin' ||
        style == 'barkSkin') {
      final area = state
          .mask('faceInner')
          .subtract(state.mask('eyeSafety'))
          .subtract(state.mask('mouthSafety'));
      base.data
          .setAll(0, orderedDither(area, style == 'stoneSkin' ? 5 : 3).data);
    } else if (style == 'glowVeins' || style == 'voidCracks') {
      light
          .line(15, c.integer('face.eyeY'), 20, noseY + 3)
          .line(33, c.integer('face.eyeY') + 1, 28, mouthY + 2);
      if (style == 'voidCracks') dark.data.setAll(0, light.data);
    } else if (style == 'slimeDroplets') {
      for (var x = 15; x < 34; x += 5)
        base.line(x, c.integer('head.bottomY') - 3, x,
            c.integer('head.bottomY') + positiveMod(x, 4));
    } else if (style == 'crystalGrowth') {
      for (var x = 14; x <= 34; x += 5)
        base.fillTriangle((x: x - 2, y: noseY + 8), (x: x + 2, y: noseY + 8),
            (x: x, y: noseY + 2 - positiveMod(x, 4)));
    } else if (style == 'mushroomGrowth') {
      for (var x = 16; x <= 32; x += 8) {
        base.vLine(x, c.integer('head.topY'), c.integer('head.topY') + 3);
        light.fillEllipse(x, c.integer('head.topY') - 1, 3, 2);
      }
    }
    final clip = state.mask('head').dilated(iterations: 2);
    return _TripleMask(
        dark.intersect(clip), base.intersect(clip), light.intersect(clip));
  }

  _TripleMask _relic(AvatarRenderContext c) {
    final style = c.string('v4.relic');
    final dark = PixelMask();
    final base = PixelMask();
    final light = PixelMask();
    if (style == 'none') return _TripleMask(dark, base, light);
    final y = c.integer('body.neckBaseY') + 5;
    if (style == 'multipleChains' || style == 'prayerBeads') {
      for (var offset = 0; offset < 3; offset++) {
        base
            .line(15 + offset, y, 24, y + 5 + offset)
            .line(33 - offset, y, 24, y + 5 + offset);
      }
      if (style == 'prayerBeads') {
        for (var x = 17; x < 32; x += 3) light.set(x, y + positiveMod(x, 5));
      }
    } else if (style == 'boneNecklace' || style == 'fangNecklace') {
      base.line(16, y, 24, y + 6).line(32, y, 24, y + 6);
      for (var x = 18; x <= 30; x += 3) light.line(x, y + 2, x, y + 5);
    } else if (style == 'medalCluster' || style == 'factionSeal') {
      base.hLine(18, 30, y);
      for (var x = 20; x <= 28; x += 4) light.fillEllipse(x, y + 5, 2, 2);
    } else {
      base.line(16, y, 24, y + 7).line(32, y, 24, y + 7);
      final radius = style == 'amuletLarge' || style == 'sacredRelic' ? 4 : 3;
      base.fillEllipse(24, y + 9, radius, radius);
      light.fillEllipse(24, y + 9, 1, 1);
      if (style == 'crystalPendant') {
        base.fillTriangle(
            (x: 20, y: y + 8), (x: 28, y: y + 8), (x: 24, y: y + 15));
      }
    }
    dark.data.setAll(0, shadingMask(base, kind: 'clothing', strength: 1).data);
    return _TripleMask(dark, base, light.intersect(base));
  }

  _TripleMask _companion(AvatarRenderContext c) {
    final style = c.string('v4.extraShoulderProp');
    final dark = PixelMask();
    final base = PixelMask();
    final light = PixelMask();
    if (style == 'none') return _TripleMask(dark, base, light);
    final side = c.random('v42.companion.side').nextBool() ? -1 : 1;
    final x = side < 0 ? 7 : 40;
    final y = 31;
    if (style == 'owl' ||
        style == 'crow' ||
        style == 'raven' ||
        style == 'bat') {
      base.fillEllipse(x, y - 7, 4, 5);
      base.fillEllipse(x, y - 12, 3, 3);
      if (style == 'bat') {
        base.fillTriangle((x: x, y: y - 8), (x: x - side * 8, y: y - 13),
            (x: x - side * 4, y: y - 4));
      } else {
        base.fillTriangle(
            (x: x - 3, y: y - 13), (x: x, y: y - 12), (x: x - 2, y: y - 16));
        base.fillTriangle(
            (x: x, y: y - 12), (x: x + 3, y: y - 13), (x: x + 2, y: y - 16));
      }
      light.set(x - 1, y - 12).set(x + 1, y - 12);
    } else if (style == 'snake') {
      base
          .line(x, y, x + side * 5, y - 8, thickness: 2)
          .line(x + side * 5, y - 8, x, y - 14, thickness: 2);
      light.set(x, y - 14);
    } else if (style == 'frog' || style == 'mushroomBuddy') {
      base.fillEllipse(x, y - 4, 5, 4);
      base.fillEllipse(x, y - 8, 4, 3);
      light.set(x - 2, y - 9).set(x + 2, y - 9);
      if (style == 'mushroomBuddy') light.fillEllipse(x, y - 11, 5, 2);
    } else if (style == 'floatingSkull') {
      base.fillEllipse(x, y - 10, 5, 5).fillRect(x - 3, y - 7, 6, 4);
      dark.set(x - 2, y - 11).set(x + 2, y - 11).set(x, y - 8);
    } else if (style == 'miniDrone') {
      base.fillRect(x - 4, y - 11, 8, 6);
      base.hLine(x - 7, x + 7, y - 12);
      light.set(x, y - 9);
    } else if (style == 'candle' || style == 'lanternSpirit') {
      base.fillRect(x - 2, y - 9, 4, 8);
      light.fillTriangle(
          (x: x - 2, y: y - 9), (x: x + 2, y: y - 9), (x: x, y: y - 14));
    } else if (style == 'starOrb' || style == 'cloudSpirit') {
      base.fillEllipse(x, y - 10, 5, style == 'cloudSpirit' ? 3 : 5);
      light.fillEllipse(x, y - 10, 2, 2);
    } else if (style == 'bookFamiliar') {
      base.fillRect(x - 6, y - 10, 12, 7);
      dark.vLine(x, y - 10, y - 3);
      light.set(x - 3, y - 7).set(x + 3, y - 7);
    }
    return _TripleMask(dark, base, light);
  }

  _DoubleMask _hornAccent(AvatarRenderContext c, AvatarRenderState state) {
    final style = c.string('fantasy.hornStyle');
    final base = PixelMask();
    final light = PixelMask();
    final horns = state.mask('horns');
    if (horns.count == 0) return _DoubleMask(base, light);
    if (style.contains('crystal') ||
        style.contains('neon') ||
        style.contains('ice') ||
        style.contains('mechanical')) {
      light.data.setAll(
          0,
          horns
              .intersect(
                  maskFromPredicate((x, y) => positiveMod(x + y, 3) == 0))
              .data);
    }
    if (style == 'brokenLeft') {
      base.data.setAll(
          0,
          horns
              .intersect(maskFromPredicate(
                  (x, y) => x < 24 && y < c.integer('head.topY') - 2))
              .data);
    } else if (style == 'brokenRight') {
      base.data.setAll(
          0,
          horns
              .intersect(maskFromPredicate(
                  (x, y) => x > 24 && y < c.integer('head.topY') - 2))
              .data);
    } else if (style.contains('branching') ||
        style.contains('Antlers') ||
        style == 'mooseFlat') {
      for (final direction in const <int>[-1, 1]) {
        final x = 24 + direction * 8;
        base.line(x, c.integer('head.topY'), x + direction * 7,
            c.integer('head.topY') - 8);
        base.line(x + direction * 3, c.integer('head.topY') - 4,
            x + direction * 8, c.integer('head.topY') - 5);
      }
    }
    return _DoubleMask(base, light);
  }
}

/// Rebuilds expressive eyebrows and mouths over the base face without changing
/// the stable 48x48 sprite framing.
final class ExpressionRenderer implements AvatarPartRenderer {
  const ExpressionRenderer();

  @override
  void render(AvatarRenderContext c, AvatarRenderState state) {
    final head = state.mask('head');
    if (head.count == 0) return;
    final expression = c.string('v4.expression', 'neutral');
    final intensity = c.integer('v4.expressionIntensity');
    final faceAnimation = c.string('v4.faceAnimation');
    final mouthMotion = c.string('v4.mouthMotionStyle');
    final eyeStyle = _effectiveEye(c, expression);
    final browStyle = _effectiveBrow(c, expression);
    final mouthStyle = _animatedMouth(
        c, _effectiveMouth(c, expression), faceAnimation, mouthMotion);
    final mouth = _mouth(c, mouthStyle, intensity);
    final brows = _brows(c, browStyle, intensity);
    final eyes = _eyes(c, eyeStyle, intensity);
    final marks = _emotionMarks(c, state, expression);

    final mouthClear = state.mask('mouthSafety').intersect(head.eroded());
    final browClear = state.mask('foreheadZone').intersect(maskFromPredicate((x,
            y) =>
        y >= c.integer('face.eyeY') - 7 && y <= c.integer('face.eyeY') - 1));

    state
      ..addLayer('expression.mouth.clear', 113, mouthClear, c.color('skinBase'),
          meta: const {'part': 'expression'})
      ..addLayer('expression.mouth.dark', 114, mouth.dark, c.color('mouthDark'),
          meta: const {'part': 'expression'})
      ..addLayer('expression.mouth.base', 115, mouth.base, c.color('mouthBase'),
          meta: const {'part': 'expression'})
      ..addLayer('expression.mouth.light', 116, mouth.light, c.color('white'),
          meta: const {'part': 'expression'})
      ..addLayer('expression.brows.clear', 121, browClear, c.color('skinBase'),
          meta: const {'part': 'expression'})
      ..addLayer('expression.brows', 122, brows, c.color('hairShadow'),
          meta: const {'part': 'expression'})
      ..addLayer('expression.eyes.skin', 98, eyes.skin, c.color('skinBase'),
          meta: const {'part': 'expression'})
      ..addLayer('expression.eyes.dark', 99, eyes.dark, c.color('outline'),
          meta: const {'part': 'expression'})
      ..addLayer('expression.eyes.light', 100, eyes.light, c.color('white'),
          meta: const {'part': 'expression'})
      ..addLayer('expression.mark.dark', 123, marks.dark, c.color('skinDeep'),
          meta: const {'part': 'expressionMark'})
      ..addLayer('expression.mark.base', 124, marks.base, c.color('skinAccent'),
          meta: const {'part': 'expressionMark'})
      ..addLayer(
          'expression.mark.light', 125, marks.light, c.color('fantasyLight'),
          meta: const {'part': 'expressionMark'});
  }

  String _effectiveEye(AvatarRenderContext c, String expression) {
    final explicit = c.string('v4.eyeExpression', 'auto');
    if (explicit != 'auto') return explicit;
    if (<String>['smile', 'bigSmile', 'laugh', 'openLaugh', 'blushingHappy']
        .contains(expression)) return 'happy';
    if (<String>['angry', 'furious', 'determined'].contains(expression))
      return 'angry';
    if (<String>['sad', 'crying', 'worried'].contains(expression)) return 'sad';
    if (<String>['sleepy', 'tired', 'bored'].contains(expression))
      return 'halfLidded';
    if (<String>['surprised', 'shocked', 'manic'].contains(expression))
      return 'wide';
    if (<String>['suspicious', 'confident', 'mischievous', 'evilSmile']
        .contains(expression)) return 'suspicious';
    return 'neutral';
  }

  String _effectiveBrow(AvatarRenderContext c, String expression) {
    final explicit = c.string('v4.browExpression', 'auto');
    if (explicit != 'auto') return explicit;
    if (<String>['angry', 'furious', 'determined'].contains(expression))
      return 'angryDown';
    if (<String>['sad', 'crying', 'worried'].contains(expression))
      return 'sadUp';
    if (<String>['surprised', 'shocked'].contains(expression))
      return 'surprisedHigh';
    if (<String>['suspicious', 'confident', 'mischievous', 'evilSmile']
        .contains(expression)) return 'skepticalSingle';
    if (<String>['sleepy', 'tired', 'bored'].contains(expression))
      return 'sleepyFlat';
    return 'relaxed';
  }

  String _effectiveMouth(AvatarRenderContext c, String expression) {
    final explicit = c.string('v4.mouthExpression', 'auto');
    if (explicit != 'auto') return explicit;
    const mapping = <String, String>{
      'softSmile': 'smallSmile',
      'smile': 'closedSmile',
      'bigSmile': 'wideSmile',
      'grin': 'toothyGrin',
      'smirkLeft': 'smirkLeft',
      'smirkRight': 'smirkRight',
      'laugh': 'laughOpen',
      'openLaugh': 'laughWide',
      'mischievous': 'smirkLeft',
      'angry': 'clenched',
      'furious': 'snarl',
      'sad': 'sadFrown',
      'worried': 'frown',
      'shy': 'tinySmile',
      'surprised': 'oShape',
      'shocked': 'shout',
      'suspicious': 'flatAnnoyed',
      'confident': 'smirkRight',
      'proud': 'closedSmile',
      'sleepy': 'breathingOpen',
      'tired': 'flatAnnoyed',
      'bored': 'flatAnnoyed',
      'annoyed': 'grimace',
      'determined': 'clenched',
      'evilSmile': 'fangSmile',
      'manic': 'laughWide',
      'crying': 'sadFrown',
      'blushingHappy': 'wideSmile',
      'disgusted': 'grimace',
    };
    return mapping[expression] ?? 'neutral';
  }

  String _animatedMouth(
      AvatarRenderContext c, String base, String animation, String motion) {
    final speed = c.integer('v4.expressionSpeed', 3);
    final phase = positiveMod(c.phase * clampInt(speed, 1, 6), 16);
    if (animation == 'laugh' || motion == 'laughLoop') {
      return phase < 8 ? 'laughWide' : 'wideSmile';
    }
    if (animation == 'talk' || motion.startsWith('talk')) {
      final fast = motion == 'talkFast'
          ? 2
          : motion == 'talkSmall'
              ? 5
              : 3;
      return <String>[
        'speakingM',
        'speakingA',
        'speakingE',
        'speakingO'
      ][(c.phase ~/ fast) % 4];
    }
    if (motion == 'chewLoop') return phase < 8 ? 'chewing' : 'speakingM';
    if (motion == 'breathLoop' || animation == 'sleepy') {
      return phase < 4 ? 'breathingOpen' : base;
    }
    if (animation == 'surprised') return phase < 5 ? 'oShape' : base;
    if (animation == 'angry') return phase < 6 ? 'snarl' : 'clenched';
    if (animation == 'smirk') return phase < 8 ? 'smirkLeft' : 'smirkRight';
    return base;
  }

  _MouthResult _mouth(AvatarRenderContext c, String style, int intensity) {
    final dark = PixelMask();
    final base = PixelMask();
    final light = PixelMask();
    final y = c.integer('face.mouthY');
    final open = clampInt(c.integer('v4.mouthOpen') + intensity ~/ 2, 0, 5);
    var width = clampInt(c.integer('mouth.width'), 4, 13);
    if (style == 'tinySmile' || style == 'smallSmile')
      width = clampInt(width - 3, 3, 9);
    if (<String>['wideSmile', 'laughWide', 'shout'].contains(style))
      width = clampInt(width + 2, 6, 15);
    final left = 24 - width ~/ 2;
    final right = 24 + width ~/ 2;
    if (style == 'neutral' || style == 'speakingM' || style == 'flatAnnoyed') {
      dark.hLine(left, right, y + (style == 'flatAnnoyed' ? 1 : 0));
    } else if (<String>[
      'smallSmile',
      'closedSmile',
      'wideSmile',
      'grin',
      'toothyGrin'
    ].contains(style)) {
      dark.line(left, y, 24, y + 1).line(24, y + 1, right, y);
      if (style == 'wideSmile' || style == 'grin' || style == 'toothyGrin') {
        base.hLine(left + 2, right - 2, y + 1);
      }
      if (style == 'toothyGrin') light.hLine(left + 2, right - 2, y);
    } else if (style == 'smirkLeft' || style == 'smirkRight') {
      final highLeft = style == 'smirkLeft';
      dark
          .line(left, y + (highLeft ? -1 : 1), 24, y + 1)
          .line(24, y + 1, right, y + (highLeft ? 1 : -1));
    } else if (style == 'laughOpen' ||
        style == 'laughWide' ||
        style == 'openSmile' ||
        style == 'shout') {
      final height = clampInt(
          open + (style == 'laughWide' || style == 'shout' ? 3 : 2), 2, 7);
      dark.fillEllipse(24, y + 1, width / 2, height / 2);
      light.hLine(left + 2, right - 2, y - 1);
      base.hLine(20, 28, y + height ~/ 2);
    } else if (style == 'oShape' || style == 'speakingO' || style == 'kiss') {
      final radius = style == 'kiss' ? 2 : clampInt(2 + open, 2, 5);
      dark.fillEllipse(24, y, radius, radius);
      final inner = PixelMask()
        ..fillEllipse(
            24, y, clampInt(radius - 1, 1, 4), clampInt(radius - 1, 1, 4));
      dark.data.setAll(0, dark.subtract(inner).data);
    } else if (style == 'frown' || style == 'sadFrown') {
      dark.line(left, y + 1, 24, y - 1).line(24, y - 1, right, y + 1);
    } else if (style == 'pout') {
      dark.fillEllipse(24, y + 1, 3, 1);
    } else if (style == 'grimace' || style == 'clenched') {
      dark.hLine(left, right, y);
      light.hLine(left + 1, right - 1, y + 1);
      for (var x = left + 2; x < right; x += 3) dark.vLine(x, y, y + 1);
    } else if (style == 'snarl' || style == 'fangSmile') {
      dark.line(left, y + 1, 24, y).line(24, y, right, y + 1);
      light.fillTriangle((x: 20, y: y), (x: 23, y: y), (x: 22, y: y + 3));
      light.fillTriangle((x: 25, y: y), (x: 28, y: y), (x: 26, y: y + 3));
    } else if (style == 'chewing') {
      dark.fillEllipse(26, y + 1, 4, 2);
    } else if (style == 'speakingA') {
      dark.fillTriangle(
          (x: left + 2, y: y + 2), (x: right - 2, y: y + 2), (x: 24, y: y - 2));
    } else if (style == 'speakingE') {
      dark.fillRect(left + 1, y - 1, width - 1, 3);
      light.hLine(left + 2, right - 2, y - 1);
    } else if (style == 'breathingOpen') {
      dark.fillEllipse(24, y + 1, 3 + open ~/ 2, 1 + open ~/ 2);
    }
    final clip = maskRect(14, y - 4, 21, 10).intersect(
        maskFromPredicate((x, yy) => yy < c.integer('head.bottomY')));
    return _MouthResult(
        dark.intersect(clip), base.intersect(clip), light.intersect(clip));
  }

  PixelMask _brows(AvatarRenderContext c, String style, int intensity) {
    final output = PixelMask();
    final y = c.integer('face.eyeY') - 3;
    final leftX = c.integer('face.leftEyeX');
    final rightX = c.integer('face.rightEyeX');
    var motion = 0;
    final browMotion = c.string('v4.browMotion');
    if (browMotion == 'bounce') motion = cyclicOffset(c.phase, 12, 1);
    final high = clampInt(intensity ~/ 2 + motion, -1, 3);
    void draw(int center, bool left) {
      if (style == 'surprisedHigh') {
        output.hLine(center - 3, center + 3, y - 2 - high);
      } else if (style == 'angryDown' || style == 'furrowed') {
        output.line(
            center - 3, y - (left ? 2 : 0), center + 3, y - (left ? 0 : 2),
            thickness: intensity >= 4 ? 2 : 1);
      } else if (style == 'sadUp' || style == 'liftedInner') {
        output.line(center - 3, y, center + 3, y - (left ? 2 : -2));
      } else if (style == 'liftedOuter') {
        output.line(
            center - 3, y - (left ? 2 : 0), center + 3, y - (left ? 0 : 2));
      } else if (style == 'arched' || style == 'mischiefCurve') {
        output
            .line(center - 3, y, center, y - 2 - high)
            .line(center, y - 2 - high, center + 3, y);
      } else if (style == 'confidentTilt') {
        output.line(
            center - 3, y + (left ? 1 : -1), center + 3, y + (left ? -1 : 1));
      } else if (style == 'skepticalSingle') {
        output.hLine(center - 3, center + 3, y - (left ? 2 + high : 0));
      } else {
        output.hLine(center - 3, center + 3, y - high ~/ 2);
      }
    }

    draw(leftX, true);
    draw(rightX, false);
    if (browMotion == 'raiseLeft') {
      return output
          .subtract(maskRect(leftX - 4, y - 4, 9, 6))
          .union(PixelMask()..hLine(leftX - 3, leftX + 3, y - 3));
    }
    if (browMotion == 'raiseRight') {
      return output
          .subtract(maskRect(rightX - 4, y - 4, 9, 6))
          .union(PixelMask()..hLine(rightX - 3, rightX + 3, y - 3));
    }
    return output;
  }

  _EyeExpressionResult _eyes(
      AvatarRenderContext c, String style, int intensity) {
    final skin = PixelMask();
    final dark = PixelMask();
    final light = PixelMask();
    final y = c.integer('face.eyeY');
    final leftX = c.integer('face.leftEyeX');
    final rightX = c.integer('face.rightEyeX');
    final width = clampInt(c.integer('eyes.width'), 2, 7);
    final blink = c.string('v4.blinkStyle');
    final speed = c.integer('v4.expressionSpeed', 3);
    final cycle = animationPeriod(speed,
        slow: blink == 'slowBlink' ? 30 : 20,
        fast: blink == 'nervousBlink' ? 7 : 11);
    final step = positiveMod(
        c.phase + (blink == 'doubleBlink' ? positiveMod(c.phase, 5) : 0),
        cycle);
    final blinkNow = step >= cycle - 2;
    void one(int x, bool left) {
      var closeTop = 0;
      var closeBottom = 0;
      if (style == 'happy' || style == 'laughing')
        closeBottom = 1 + intensity ~/ 3;
      if (style == 'sleepy' || style == 'halfLidded')
        closeTop = 1 + intensity ~/ 3;
      if (style == 'narrowed' || style == 'angry' || style == 'determined') {
        closeTop = 1;
        closeBottom = 1;
      }
      final wink =
          (blink == 'winkLeft' && left) || (blink == 'winkRight' && !left);
      if (blinkNow || wink) {
        skin.fillRect(x - width ~/ 2 - 1, y - 3, width + 2, 7);
        dark.hLine(x - width ~/ 2, x + width ~/ 2, y);
        return;
      }
      if (closeTop > 0)
        skin.fillRect(x - width ~/ 2 - 1, y - 3, width + 2, closeTop + 2);
      if (closeBottom > 0)
        skin.fillRect(x - width ~/ 2 - 1, y + 1, width + 2, closeBottom + 2);
      if (style == 'wide' || style == 'crazy') {
        light.set(x - width ~/ 2 - 1, y).set(x + width ~/ 2 + 1, y);
      }
      if (style == 'sparkly') {
        light.set(x, y).set(x - 1, y).set(x + 1, y).set(x, y - 1).set(x, y + 1);
      }
      if (style == 'teary' || style == 'sad') {
        light.line(x, y + 2, x + (left ? -1 : 1), y + 5);
      }
      if (style == 'glowing') light.fillEllipse(x, y, 2, 2);
      if (style == 'suspicious')
        dark.hLine(x - width ~/ 2, x + width ~/ 2, y - (left ? 1 : 0));
    }

    one(leftX, true);
    one(rightX, false);
    return _EyeExpressionResult(skin, dark, light);
  }

  _TripleMask _emotionMarks(
      AvatarRenderContext c, AvatarRenderState state, String expression) {
    var style = c.string('v4.emotionMark');
    if (style == 'none') {
      if (expression == 'crying') style = 'tearBoth';
      if (expression == 'blushingHappy' || expression == 'shy') style = 'blush';
      if (expression == 'angry' || expression == 'furious') style = 'angerMark';
    }
    final dark = PixelMask();
    final base = PixelMask();
    final light = PixelMask();
    final eyeY = c.integer('face.eyeY');
    if (style == 'blush') {
      base.data.setAll(
          0,
          orderedDither(
                  state
                      .mask('lowerCheekLeftZone')
                      .union(state.mask('lowerCheekRightZone')),
                  4)
              .data);
    } else if (style == 'tearLeft' || style == 'tearBoth') {
      light.line(
          c.integer('face.leftEyeX'),
          eyeY + 2,
          c.integer('face.leftEyeX') - 1,
          eyeY + 5 + c.integer('v4.tearAmount'));
      if (style == 'tearBoth')
        light.line(
            c.integer('face.rightEyeX'),
            eyeY + 2,
            c.integer('face.rightEyeX') + 1,
            eyeY + 5 + c.integer('v4.tearAmount'));
    } else if (style == 'sweatDrop') {
      light.fillEllipse(c.integer('head.rightX') - 1, eyeY - 3, 2, 3);
    } else if (style == 'angerMark') {
      dark
          .line(c.integer('head.rightX') - 4, eyeY - 7,
              c.integer('head.rightX'), eyeY - 3)
          .line(c.integer('head.rightX'), eyeY - 7,
              c.integer('head.rightX') - 4, eyeY - 3);
    } else if (style == 'stressLines') {
      for (var i = 0; i < 3; i++)
        dark.line(17 + i * 7, eyeY - 8, 18 + i * 7, eyeY - 4);
    } else if (style == 'sleepBubble') {
      light
          .fillEllipse(
              c.integer('head.rightX') + 3, c.integer('face.mouthY'), 2, 2)
          .fillEllipse(
              c.integer('head.rightX') + 6, c.integer('face.mouthY') - 4, 3, 3);
    } else if (style == 'sparkleMarks' || style == 'cheekStars') {
      for (final x in <int>[15, 33]) {
        light
            .set(x, eyeY + 3)
            .set(x - 1, eyeY + 3)
            .set(x + 1, eyeY + 3)
            .set(x, eyeY + 2)
            .set(x, eyeY + 4);
      }
    } else if (style == 'heartMark') {
      base
          .set(34, eyeY - 5)
          .set(36, eyeY - 5)
          .hLine(34, 36, eyeY - 4)
          .set(35, eyeY - 3);
    } else if (style == 'underEyeShadow') {
      dark
          .hLine(c.integer('face.leftEyeX') - 2, c.integer('face.leftEyeX') + 2,
              eyeY + 2)
          .hLine(c.integer('face.rightEyeX') - 2,
              c.integer('face.rightEyeX') + 2, eyeY + 2);
    } else if (style == 'magicFreckles') {
      for (var i = 0; i < 8; i++)
        light.set(16 + positiveMod(i * 7, 17), eyeY + 2 + positiveMod(i, 4));
    } else if (style == 'voidTears') {
      dark
          .line(c.integer('face.leftEyeX'), eyeY + 1,
              c.integer('face.leftEyeX'), eyeY + 7)
          .line(c.integer('face.rightEyeX'), eyeY + 1,
              c.integer('face.rightEyeX'), eyeY + 7);
    }
    return _TripleMask(dark, base, light);
  }
}

final class _TripleMask {
  const _TripleMask(this.dark, this.base, this.light) : accent = light;
  final PixelMask dark;
  final PixelMask base;
  final PixelMask light;
  final PixelMask accent;
}

final class _DoubleMask {
  const _DoubleMask(this.base, this.light);
  final PixelMask base;
  final PixelMask light;
}

final class _HaloResult {
  const _HaloResult(this.back, this.front, this.glow);
  final PixelMask back;
  final PixelMask front;
  final PixelMask glow;
}

final class _SymbolResult {
  const _SymbolResult(this.back, this.front);
  final PixelMask back;
  final PixelMask front;
}

final class _MouthResult {
  const _MouthResult(this.dark, this.base, this.light);
  final PixelMask dark;
  final PixelMask base;
  final PixelMask light;
}

final class _EyeExpressionResult {
  const _EyeExpressionResult(this.skin, this.dark, this.light);
  final PixelMask skin;
  final PixelMask dark;
  final PixelMask light;
}
