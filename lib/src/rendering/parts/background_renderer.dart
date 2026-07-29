import '../../pixels/pixel_mask.dart';
import '../../util/math_utils.dart';
import '../render_helpers.dart';
import '../render_model.dart';

/// Produces deterministic backgrounds, vignettes and rear atmospheric effects.
final class BackgroundRenderer implements AvatarPartRenderer {
  const BackgroundRenderer();

  @override
  void render(AvatarRenderContext context, AvatarRenderState state) {
    final background = _background(context);
    final aura = _aura(context);
    final backEffect = _effect(context, back: true);
    state
      ..putMask('background.base', background.base)
      ..putMask('background.dark', background.dark)
      ..putMask('background.light', background.light)
      ..putMask('aura.back', aura.dark.union(aura.light))
      ..addLayer('background.base', 0, background.base, context.color('bg'),
          meta: const {'part': 'background'})
      ..addLayer('background.dark', 1, background.dark,
          context.color('bgDark'), meta: const {'part': 'background'})
      ..addLayer('background.light', 2, background.light,
          context.color('bgLight'), meta: const {'part': 'background'})
      ..addLayer('background.symbol', 3, background.accent,
          context.color('clothAccent'), meta: const {'part': 'background'})
      ..addLayer('aura.back.dark', 4, aura.dark,
          context.color('fantasyDark'), meta: const {'part': 'aura'})
      ..addLayer('aura.back', 5, aura.light,
          context.color('fantasyBase'), meta: const {'part': 'aura'})
      ..addLayer('effect.back.dark', 6, backEffect.dark,
          context.color('bgDark'), meta: const {'part': 'effect'})
      ..addLayer('effect.back', 7, backEffect.base,
          context.color('fantasyBase'), meta: const {'part': 'effect'})
      ..addLayer('effect.back.light', 8, backEffect.light,
          context.color('fantasyLight'), meta: const {'part': 'effect'});
  }

  _Background _background(AvatarRenderContext c) {
    final base = PixelMask.filled();
    final dark = PixelMask();
    final light = PixelMask();
    final accent = PixelMask();
    final style = c.string('v4.background');
    final contrast = c.integer('v4.backgroundContrast');
    final phase = c.phase;

    if (style == 'blockGradient') {
      dark.fillRect(0, 31, 48, 17);
      light.fillRect(0, 0, 48, 13);
    } else if (style == 'verticalSplit') {
      dark.fillRect(0, 0, 24, 48);
      light.fillRect(24, 0, 24, 48);
    } else if (style == 'horizontalSplit') {
      light.fillRect(0, 0, 48, 24);
      dark.fillRect(0, 24, 48, 24);
    } else if (style == 'diagonalStripes') {
      for (var offset = -48; offset < 96; offset += 8) {
        dark.line(offset, 0, offset + 48, 47, thickness: 3);
      }
    } else if (style == 'checker') {
      for (var y = 0; y < 48; y += 6) {
        for (var x = 0; x < 48; x += 6) {
          if (((x ~/ 6) + (y ~/ 6)).isEven) dark.fillRect(x, y, 6, 6);
        }
      }
    } else if (style == 'dots') {
      for (var y = 3; y < 48; y += 6) {
        for (var x = 3; x < 48; x += 6) light.set(x, y);
      }
    } else if (style == 'pixelNoise') {
      final rng = c.random('background.noise');
      for (var i = 0; i < 30 + contrast * 8; i++) {
        final x = rng.nextInt(0, 47);
        final y = rng.nextInt(0, 47);
        (i.isEven ? dark : light).fillRect(x, y, 2, 2);
      }
    } else if (style == 'sunset') {
      light.fillRect(0, 0, 48, 21);
      dark.fillRect(0, 30, 48, 18);
      accent.fillEllipse(35, 13, 5, 5);
      for (var x = 0; x < 48; x += 6) dark.fillTriangle(
          (x: x, y: 34), (x: x + 8, y: 34), (x: x + 4, y: 24));
    } else if (style == 'night') {
      dark.fillRect(0, 0, 48, 48);
      final rng = c.random('background.stars');
      for (var i = 0; i < 18; i++) light.set(rng.nextInt(1, 46), rng.nextInt(1, 26));
      accent.fillEllipse(37, 8, 4, 4).subtract(PixelMask()..fillEllipse(39, 7, 4, 4));
    } else if (style == 'neonCity' || style == 'rainCity') {
      dark.fillRect(0, 0, 48, 48);
      for (var x = 0; x < 48; x += 7) {
        final h = 12 + positiveMod(x * 3, 18);
        light.fillRect(x, 48 - h, 5, h);
        for (var y = 48 - h + 3; y < 47; y += 5) accent.set(x + 2, y);
      }
      if (style == 'rainCity') {
        final offset = positiveMod(phase, 4);
        for (var x = offset; x < 48; x += 7) light.line(x, 2, x - 2, 8);
      }
    } else if (style == 'forest') {
      light.fillRect(0, 0, 48, 22);
      dark.fillRect(0, 24, 48, 24);
      for (var x = -2; x < 52; x += 8) {
        dark.fillTriangle((x: x, y: 31), (x: x + 8, y: 31), (x: x + 4, y: 12));
        dark.fillRect(x + 3, 29, 2, 19);
      }
    } else if (style == 'space') {
      dark.fillRect(0, 0, 48, 48);
      final rng = c.random('background.space');
      for (var i = 0; i < 26; i++) (i % 5 == 0 ? accent : light)
          .set(rng.nextInt(0, 47), rng.nextInt(0, 47));
      accent.fillEllipse(8, 38, 8, 3);
    } else if (style == 'dungeon') {
      dark.fillRect(0, 0, 48, 48);
      for (var y = 0; y < 48; y += 6) {
        for (var x = (y ~/ 6).isEven ? 0 : -4; x < 48; x += 9) {
          light.hLine(x, x + 7, y);
          light.vLine(x, y, y + 5);
        }
      }
    } else if (style == 'laboratory' || style == 'spaceship') {
      dark.fillRect(0, 0, 48, 48);
      light.fillRect(3, 4, 42, 35);
      dark.fillRect(5, 6, 38, 31);
      for (var x = 8; x < 43; x += 8) accent.set(x, 9).set(x, 34);
      if (style == 'laboratory') accent.line(8, 30, 15, 20).line(15, 20, 22, 30);
    } else if (style == 'flames') {
      dark.fillRect(0, 0, 48, 48);
      for (var x = 0; x < 48; x += 5) {
        final tip = 22 + positiveMod(x * 5 + phase, 16);
        accent.fillTriangle((x: x - 2, y: 48), (x: x + 4, y: 48), (x: x + 1, y: tip));
        light.fillTriangle((x: x, y: 48), (x: x + 3, y: 48), (x: x + 1, y: tip + 7));
      }
    } else if (style == 'snowField') {
      light.fillRect(0, 0, 48, 48);
      dark.fillRect(0, 34, 48, 14);
      for (var x = 0; x < 48; x += 7) dark.set(x, 30 + positiveMod(x, 5));
    } else if (style == 'magicAura') {
      dark.fillRect(0, 0, 48, 48);
      accent.fillEllipse(24, 25, 20, 25);
      dark.fillEllipse(24, 25, 15, 20);
      for (var i = 0; i < 8; i++) light.set(5 + positiveMod(i * 11, 38), 5 + positiveMod(i * 7, 32));
    } else if (style == 'terminal') {
      dark.fillRect(0, 0, 48, 48);
      for (var y = 3; y < 48; y += 4) {
        light.hLine(2 + positiveMod(y, 5), 10 + positiveMod(y * 3, 30), y);
      }
      accent.fillRect(2, 2, 2, 2);
    } else if (style == 'factionSymbol') {
      dark.fillRect(0, 0, 48, 48);
      accent.fillEllipse(24, 24, 15, 15);
      dark.fillEllipse(24, 24, 10, 10);
      accent.fillTriangle((x: 24, y: 7), (x: 12, y: 35), (x: 36, y: 35));
    }

    final vignette = c.integer('v4.vignette');
    if (vignette > 0) {
      for (var i = 0; i < vignette; i++) {
        dark.hLine(i, 47 - i, i);
        dark.hLine(i, 47 - i, 47 - i);
        dark.vLine(i, i, 47 - i);
        dark.vLine(47 - i, i, 47 - i);
      }
    }
    return _Background(base, dark, light, accent);
  }

  _Aura _aura(AvatarRenderContext c) {
    final style = c.string('v4.aura');
    if (style == 'none') return _Aura(PixelMask(), PixelMask());
    final pulse = c.string('v4.animation') == 'auraPulse' ||
            c.string('v4.animation') == 'glowPulse'
        ? cyclicOffset(
            c.phase,
            (6 + c.integer('v4.animationSpeed')) * 4,
            c.integer('v4.animationAmplitude'),
          ).abs()
        : 0;
    final dark = PixelMask();
    final light = PixelMask();
    final rx = 16 + pulse;
    final ry = 22 + pulse;
    final ring = PixelMask()..fillEllipse(24, 25, rx, ry);
    final inner = PixelMask()..fillEllipse(24, 25, rx - 3, ry - 3);
    dark.data.setAll(0, ring.subtract(inner).data);
    if (<String>['holy', 'magic', 'holographic', 'runic', 'electric'].contains(style)) {
      for (var i = 0; i < 12; i++) {
        final x = 5 + positiveMod(i * 13 + c.phase, 38);
        final y = 4 + positiveMod(i * 7 - c.phase, 40);
        light.set(x, y);
      }
    }
    if (style == 'fire') {
      for (var x = 6; x < 43; x += 5) light.line(x, 44, x + 1, 36 - positiveMod(x, 7));
    } else if (style == 'ice') {
      for (var x = 8; x < 41; x += 6) light.line(x, 44, x - 2, 37);
    } else if (style == 'runic') {
      light.fillEllipse(24, 25, 20, 25).subtract(PixelMask()..fillEllipse(24, 25, 19, 24));
    }
    return _Aura(dark, light);
  }

  _Effect _effect(AvatarRenderContext c, {required bool back}) {
    final style = c.string('v4.effect');
    if (style == 'none') return _Effect(PixelMask(), PixelMask(), PixelMask());
    final density = c.integer('v4.particleDensity');
    final phase = c.phase;
    final rng = c.random('effect.$style.${back ? 'back' : 'front'}');
    final dark = PixelMask();
    final base = PixelMask();
    final light = PixelMask();
    final count = clampInt(3 + density * 2, 3, 18);
    for (var i = 0; i < count; i++) {
      var x = rng.nextInt(1, 46);
      var y = rng.nextInt(1, 46);
      if (c.string('v4.animation') == 'particles') {
        y = positiveMod(y + phase * (1 + i % 2), 48);
      }
      if (style == 'rain') {
        base.line(x, y, x - 1, y + 4);
      } else if (style == 'snow') {
        light.set(x, y).set(x - 1, y).set(x, y - 1);
      } else if (style == 'leaves') {
        base.set(x, y).set(x + 1, y + 1).set(x + 2, y);
      } else if (style == 'bubbles') {
        light.fillEllipse(x, y, 1 + i % 2, 1 + i % 2);
        dark.set(x, y);
      } else if (style == 'sparks' || style == 'electricity') {
        light.line(x, y, x + (i.isEven ? 2 : -2), y + 3);
      } else if (style == 'glitch' || style == 'hologram') {
        base.hLine(x - 2, x + 3, y);
      } else if (style == 'fire' || style == 'embers') {
        light.set(x, y).set(x, y - 1);
        base.set(x, y + 1);
      } else if (style == 'smoke' || style == 'steam') {
        base.fillEllipse(x, y, 2, 1);
        if (style == 'smoke') dark.set(x, y);
      } else {
        (i.isEven ? base : light).fillRect(x, y, 2, 2);
      }
    }
    return _Effect(dark, base, light);
  }
}

final class ForegroundEffectsRenderer implements AvatarPartRenderer {
  const ForegroundEffectsRenderer();

  @override
  void render(AvatarRenderContext context, AvatarRenderState state) {
    final helper = const BackgroundRenderer();
    final effect = helper._effect(context, back: false);
    final silhouette = state.mask('head').union(state.mask('torso'))
        .union(state.mask('hair.all')).dilated();
    final clearCenter = maskFromPredicate((x, y) => x < 12 || x > 35 || y < 5);
    final dark = effect.dark.subtract(silhouette).intersect(clearCenter);
    final base = effect.base.subtract(silhouette).intersect(clearCenter);
    final light = effect.light.subtract(silhouette).intersect(clearCenter);
    state
      ..addLayer('effect.front.dark', 230, dark, context.color('bgDark'),
          meta: const {'part': 'effect'})
      ..addLayer('effect.front', 231, base, context.color('fantasyBase'),
          meta: const {'part': 'effect'})
      ..addLayer('effect.front.light', 232, light, context.color('fantasyLight'),
          meta: const {'part': 'effect'});
  }
}

final class _Background {
  const _Background(this.base, this.dark, this.light, this.accent);
  final PixelMask base;
  final PixelMask dark;
  final PixelMask light;
  final PixelMask accent;
}

final class _Aura {
  const _Aura(this.dark, this.light);
  final PixelMask dark;
  final PixelMask light;
}

final class _Effect {
  const _Effect(this.dark, this.base, this.light);
  final PixelMask dark;
  final PixelMask base;
  final PixelMask light;
}
