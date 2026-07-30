import '../../pixels/pixel_mask.dart';
import '../../util/math_utils.dart';
import '../render_helpers.dart';
import '../render_model.dart';

/// Adds distinct geometry for the extended V4.2 aura options.
final class ExtendedAuraRenderer implements AvatarPartRenderer {
  const ExtendedAuraRenderer();

  static const Set<String> _extended = <String>{
    'radiant',
    'divine',
    'corrupted',
    'shadowFlame',
    'storm',
    'plasma',
    'poison',
    'nature',
    'bloodMist',
    'arcaneCircle',
    'void',
    'dream',
    'starlight',
    'goldenDust',
    'sacredRunes',
    'toxicSteam',
  };

  @override
  void render(AvatarRenderContext context, AvatarRenderState state) {
    final style = context.string('v4.aura');
    if (!_extended.contains(style)) return;
    final result = _aura(context, style);
    state
      ..addLayer(
        'aura.v42.extended.dark',
        4,
        result.dark,
        context.color('fantasyDark'),
        meta: const {'part': 'aura'},
      )
      ..addLayer(
        'aura.v42.extended.base',
        5,
        result.base,
        context.color('fantasyBase'),
        meta: const {'part': 'aura'},
      )
      ..addLayer(
        'aura.v42.extended.light',
        6,
        result.light,
        context.color('fantasyLight'),
        meta: const {'part': 'aura'},
      );
  }

  _AuraResult _aura(AvatarRenderContext c, String style) {
    final dark = PixelMask();
    final base = PixelMask();
    final light = PixelMask();
    final speed = clampInt(c.integer('v4.motionSpeed'), 1, 6);
    final phase = c.rendering.animateBackground ? c.phase : 0;
    final period = animationPeriod(speed, slow: 32, fast: 14);
    final pulse = cyclicOffset(
      phase,
      period,
      clampInt(c.integer('v4.animationAmplitude'), 1, 3),
    ).abs();
    final outer = PixelMask()..fillEllipse(24, 25, 18 + pulse, 23 + pulse);
    final inner = PixelMask()..fillEllipse(24, 25, 15 + pulse, 20 + pulse);
    dark.data.setAll(0, outer.subtract(inner).data);

    if (style == 'radiant' || style == 'divine') {
      for (var x = 2; x < 47; x += 5) {
        light.line(24, 24, x, x.isEven ? 0 : 47);
      }
      if (style == 'divine') {
        base.fillEllipse(24, 25, 20 + pulse, 25 + pulse);
        base.data.setAll(0, orderedDither(base, 2, phase: phase).data);
      }
    } else if (style == 'corrupted' || style == 'void') {
      for (var i = 0; i < 14; i++) {
        final x = 4 + positiveMod(i * 13 + phase, 40);
        final y = 3 + positiveMod(i * 9 - phase, 42);
        dark.fillRect(x, y, 2 + i % 2, 2);
      }
      if (style == 'void') {
        base.data.setAll(
          0,
          orderedDither(PixelMask.filled(), 2 + pulse, phase: phase).data,
        );
      }
    } else if (style == 'shadowFlame') {
      for (var x = 4; x < 45; x += 5) {
        final tip = 39 - positiveMod(x * 3 + phase, 15);
        dark.fillTriangle(
          (x: x - 3, y: 47),
          (x: x + 3, y: 47),
          (x: x, y: tip),
        );
        base.set(x, tip + 4);
      }
    } else if (style == 'storm') {
      for (var i = 0; i < 7; i++) {
        final x = 5 + positiveMod(i * 11 + phase, 38);
        final y = 5 + positiveMod(i * 7, 35);
        light.line(x, y, x + (i.isEven ? 3 : -3), y + 5);
      }
      base.data.setAll(
        0,
        orderedDither(outer, 2 + pulse, phase: phase).data,
      );
    } else if (style == 'plasma') {
      for (var y = 4; y < 47; y += 4) {
        base.line(
          7 + positiveMod(y + phase, 5),
          y,
          41 - positiveMod(y * 2 + phase, 5),
          y + 1,
        );
      }
      light.data.setAll(0, base.intersect(outer).data);
    } else if (style == 'poison' || style == 'toxicSteam') {
      for (var i = 0; i < 12; i++) {
        final x = 5 + positiveMod(i * 13 + phase, 38);
        final y = 45 - positiveMod(i * 7 + phase, 38);
        base.fillEllipse(x, y, 2 + i % 3, 1 + i % 2);
        if (style == 'poison') dark.set(x, y);
      }
    } else if (style == 'nature') {
      for (var i = 0; i < 14; i++) {
        final x = 4 + positiveMod(i * 13 + phase, 40);
        final y = 4 + positiveMod(i * 7 - phase, 40);
        base.set(x, y).set(x + 1, y + 1).set(x + 2, y);
      }
    } else if (style == 'bloodMist') {
      for (var y = 8; y < 47; y += 6) {
        base.hLine(positiveMod(y + phase, 6), 47 - positiveMod(y, 5), y);
      }
      dark.data.setAll(0, orderedDither(base.dilated(), 4, phase: phase).data);
    } else if (style == 'arcaneCircle' || style == 'sacredRunes') {
      final secondOuter = PixelMask()..fillEllipse(24, 25, 21, 25);
      final secondInner = PixelMask()..fillEllipse(24, 25, 19, 23);
      base.data.setAll(0, secondOuter.subtract(secondInner).data);
      for (var i = 0; i < 12; i++) {
        final x = 5 + positiveMod(i * 13 + phase, 38);
        final y = 4 + positiveMod(i * 7 - phase, 40);
        light
          ..vLine(x, y - 2, y + 2)
          ..set(x + 1, y);
      }
    } else if (style == 'dream') {
      for (var i = 0; i < 10; i++) {
        final x = 5 + positiveMod(i * 11 + phase, 38);
        final y = 6 + positiveMod(i * 8 - phase ~/ 2, 35);
        base.fillEllipse(x, y, 3, 1);
      }
      light.data.setAll(0, orderedDither(outer, 2, phase: phase).data);
    } else if (style == 'starlight' || style == 'goldenDust') {
      final count = style == 'starlight' ? 16 : 24;
      for (var i = 0; i < count; i++) {
        final x = 3 + positiveMod(i * 13 + phase, 42);
        final y = 3 + positiveMod(i * 9 - phase, 42);
        light.set(x, y);
        if (i % 5 == 0) {
          light
            ..set(x - 1, y)
            ..set(x + 1, y)
            ..set(x, y - 1)
            ..set(x, y + 1);
        }
      }
    }
    return _AuraResult(dark, base, light);
  }
}

final class _AuraResult {
  const _AuraResult(this.dark, this.base, this.light);

  final PixelMask dark;
  final PixelMask base;
  final PixelMask light;
}
