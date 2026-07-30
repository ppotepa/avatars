import '../../pixels/pixel_mask.dart';
import '../../util/math_utils.dart';
import '../render_helpers.dart';
import '../render_model.dart';

/// Provides visible animation for every high-level V4.2 emote and event motion.
final class ExtendedEmoteEventRenderer implements AvatarPartRenderer {
  const ExtendedEmoteEventRenderer();

  @override
  void render(AvatarRenderContext context, AvatarRenderState state) {
    final emote = _emote(context, state);
    final event = _eventMotion(context);
    state
      ..addLayer(
        'emote.v42.dark',
        128,
        emote.dark,
        context.color('skinDeep'),
        meta: const {'part': 'expression'},
      )
      ..addLayer(
        'emote.v42.base',
        129,
        emote.base,
        context.color('skinAccent'),
        meta: const {'part': 'expression'},
      )
      ..addLayer(
        'emote.v42.light',
        130,
        emote.light,
        context.color('fantasyLight'),
        meta: const {'part': 'expression'},
      )
      ..addLayer(
        'eventMotion.v42.dark',
        7,
        event.dark,
        context.color('fantasyDark'),
        meta: const {'part': 'backgroundEvent'},
      )
      ..addLayer(
        'eventMotion.v42.base',
        8,
        event.base,
        context.color('fantasyBase'),
        meta: const {'part': 'backgroundEvent'},
      )
      ..addLayer(
        'eventMotion.v42.light',
        9,
        event.light,
        context.color('fantasyLight'),
        meta: const {'part': 'backgroundEvent'},
      );
  }

  _Triple _emote(AvatarRenderContext c, AvatarRenderState state) {
    final style = c.string('v4.faceAnimation');
    final dark = PixelMask();
    final base = PixelMask();
    final light = PixelMask();
    if (style == 'none' ||
        <String>['laugh', 'talk', 'smirk', 'angry', 'sleepy', 'surprised']
            .contains(style)) {
      return _Triple(dark, base, light);
    }
    final speed = clampInt(c.integer('v4.expressionSpeed'), 1, 6);
    final intensity = clampInt(c.integer('v4.expressionIntensity'), 0, 5);
    final period = animationPeriod(speed, slow: 24, fast: 10);
    final pulse = cyclicOffset(c.phase, period, clampInt(intensity, 1, 2));
    final eyeY = c.integer('face.eyeY');
    final leftX = c.integer('face.leftEyeX');
    final rightX = c.integer('face.rightEyeX');

    if (style == 'curious') {
      final side = pulse < 0 ? leftX : rightX;
      light
        ..set(side, eyeY)
        ..set(side - 1, eyeY - 1);
      dark
        ..hLine(leftX - 3, leftX + 3, eyeY - 5 - (pulse > 0 ? 1 : 0))
        ..hLine(rightX - 3, rightX + 3, eyeY - 5 - (pulse < 0 ? 1 : 0));
      final x = c.integer('head.rightX') + 3;
      base
        ..fillEllipse(x, eyeY - 7, 2, 2)
        ..set(x, eyeY - 3);
    } else if (style == 'proud') {
      light
        ..hLine(leftX - 2, leftX + 2, eyeY + 2 + pulse)
        ..hLine(rightX - 2, rightX + 2, eyeY + 2 + pulse);
      base.data.setAll(
        0,
        orderedDither(
          state.mask('lowerCheekLeftZone')
              .union(state.mask('lowerCheekRightZone')),
          2 + intensity,
          phase: c.phase,
        ).data,
      );
    } else if (style == 'sad') {
      final length = 3 + intensity + pulse.abs();
      light
        ..line(leftX, eyeY + 2, leftX - 1, eyeY + length)
        ..line(rightX, eyeY + 2, rightX + 1, eyeY + length);
      dark
        ..line(leftX - 3, eyeY - 4, leftX + 3, eyeY - 6)
        ..line(rightX - 3, eyeY - 6, rightX + 3, eyeY - 4);
    } else if (style == 'evil') {
      light
        ..fillEllipse(leftX, eyeY, 1 + pulse.abs(), 1)
        ..fillEllipse(rightX, eyeY, 1 + pulse.abs(), 1);
      dark
        ..line(leftX - 3, eyeY - 5, leftX + 3, eyeY - 3)
        ..line(rightX - 3, eyeY - 3, rightX + 3, eyeY - 5);
      for (var x = 20; x <= 28; x += 4) {
        light.fillTriangle(
          (x: x - 1, y: c.integer('face.mouthY')),
          (x: x + 1, y: c.integer('face.mouthY')),
          (x: x, y: c.integer('face.mouthY') + 3 + pulse.abs()),
        );
      }
    } else if (style == 'happy') {
      base.data.setAll(
        0,
        orderedDither(
          state.mask('lowerCheekLeftZone')
              .union(state.mask('lowerCheekRightZone')),
          3 + pulse.abs(),
          phase: c.phase,
        ).data,
      );
      for (final x in <int>[leftX - 5, rightX + 5]) {
        light
          ..set(x, eyeY)
          ..set(x - 1, eyeY)
          ..set(x + 1, eyeY)
          ..set(x, eyeY - 1)
          ..set(x, eyeY + 1);
      }
    } else if (style == 'bashful') {
      base.data.setAll(
        0,
        orderedDither(
          state.mask('lowerCheekLeftZone')
              .union(state.mask('lowerCheekRightZone')),
          4 + pulse.abs(),
          phase: c.phase,
        ).data,
      );
      dark
        ..hLine(leftX - 2, leftX + 2, eyeY + (pulse > 0 ? 1 : 0))
        ..hLine(rightX - 2, rightX + 2, eyeY + (pulse < 0 ? 1 : 0));
    } else if (style == 'confused') {
      dark
        ..hLine(leftX - 3, leftX + 3, eyeY - 6)
        ..line(rightX - 3, eyeY - 4, rightX + 3, eyeY - 6);
      final x = c.integer('head.rightX') + 3;
      light
        ..fillEllipse(x, eyeY - 7 + pulse, 2, 2)
        ..set(x, eyeY - 3 + pulse);
    }
    return _Triple(dark, base, light);
  }

  _Triple _eventMotion(AvatarRenderContext c) {
    final style = c.string('v4.eventMotion');
    final dark = PixelMask();
    final base = PixelMask();
    final light = PixelMask();
    if (!c.rendering.animateBackground ||
        !<String>['flameSurge', 'lightning'].contains(style)) {
      return _Triple(dark, base, light);
    }
    final speed = clampInt(c.integer('v4.motionSpeed'), 1, 6);
    final intensity = clampInt(c.integer('v4.motionIntensity'), 1, 5);
    final period = animationPeriod(speed, slow: 24, fast: 10);
    final step = positiveMod(c.phase + c.integer('v4.motionPhaseOffset'), period);
    if (style == 'flameSurge') {
      final surge = 3 + intensity + (period - step < 4 ? 5 : 0);
      for (var x = -2; x < 52; x += 5) {
        final tip = clampInt(47 - surge * 2 - positiveMod(x + c.phase, 8), 8, 45);
        base.fillTriangle(
          (x: x - 3, y: 48),
          (x: x + 4, y: 48),
          (x: x, y: tip),
        );
        light.fillTriangle(
          (x: x - 1, y: 48),
          (x: x + 2, y: 48),
          (x: x, y: tip + 5),
        );
      }
    } else if (step < 2) {
      final x = 12 + positiveMod(c.phase * 11, 25);
      light
        ..line(x, 0, x - 4, 12, thickness: 2)
        ..line(x - 4, 12, x + 2, 24, thickness: 2)
        ..line(x + 2, 24, x - 5, 39, thickness: 2)
        ..line(x - 2, 17, x - 10, 26);
      dark.data.setAll(
        0,
        orderedDither(PixelMask.filled(), 1 + intensity, phase: c.phase).data,
      );
    }
    return _Triple(dark, base, light);
  }
}

final class _Triple {
  const _Triple(this.dark, this.base, this.light);

  final PixelMask dark;
  final PixelMask base;
  final PixelMask light;
}
