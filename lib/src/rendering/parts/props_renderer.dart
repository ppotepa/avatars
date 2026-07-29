import '../../pixels/pixel_mask.dart';
import '../../util/math_utils.dart';
import '../render_helpers.dart';
import '../render_model.dart';

/// Renders deterministic mouth and shoulder props. Animated props use the
/// request phase without mutating the genome.
final class PropsRenderer implements AvatarPartRenderer {
  const PropsRenderer();

  @override
  void render(AvatarRenderContext context, AvatarRenderState state) {
    final mouth = _mouthProp(context, state);
    final shoulder = _shoulderProp(context);
    state
      ..putMask('mouthProp', mouth.base)
      ..putMask('shoulderProp', shoulder.base)
      ..addLayer('shoulderProp.outline', 194,
          shoulder.base.outline(diagonal: true), context.color('outline'),
          meta: const {'part': 'shoulderProp'})
      ..addLayer('shoulderProp.base', 195, shoulder.base,
          context.color('clothAccent'), meta: const {'part': 'shoulderProp'})
      ..addLayer('shoulderProp.shadow', 196, shoulder.shadow,
          context.color('clothDark'), meta: const {'part': 'shoulderProp'})
      ..addLayer('shoulderProp.light', 197, shoulder.light,
          context.color('fantasyLight'), meta: const {'part': 'shoulderProp'})
      ..addLayer('mouthProp.outline', 200,
          mouth.base.outline(diagonal: true), context.color('outline'),
          meta: const {'part': 'mouthProp'})
      ..addLayer('mouthProp.base', 201, mouth.base,
          mouth.organic ? context.color('clothAccent') : context.color('clothLight'),
          meta: const {'part': 'mouthProp'})
      ..addLayer('mouthProp.dark', 202, mouth.dark,
          context.color('clothDark'), meta: const {'part': 'mouthProp'})
      ..addLayer('mouthProp.light', 203, mouth.light,
          context.color('fantasyLight'), meta: const {'part': 'mouthProp'})
      ..addLayer('mouthProp.smoke.dark', 204, mouth.smokeDark,
          context.color('bgDark'), meta: const {'part': 'smoke'})
      ..addLayer('mouthProp.smoke', 205, mouth.smoke,
          context.color('bgLight'), meta: const {'part': 'smoke'});
  }

  _MouthProp _mouthProp(AvatarRenderContext c, AvatarRenderState state) {
    final style = c.string('v4.mouthProp');
    if (style == 'none' || c.string('v4.faceMask') != 'none') {
      return _MouthProp.empty();
    }
    final base = PixelMask();
    final dark = PixelMask();
    final light = PixelMask();
    final smoke = PixelMask();
    final smokeDark = PixelMask();
    final side = c.integer('v4.propSide') == 0
        ? (c.random('mouthProp.side').nextBool() ? 1 : -1)
        : c.integer('v4.propSide');
    final length = c.integer('v4.propLength');
    final angle = c.integer('v4.propAngle');
    final startX = 24 + side * (c.integer('mouth.width') ~/ 3);
    final startY = c.integer('face.mouthY');
    final endX = startX + side * length;
    final endY = startY - angle;
    var organic = false;

    if (<String>['cigarette', 'cigar', 'matchstick', 'toothpick', 'straw',
      'thermometer', 'instrumentMouthpiece', 'cyberCable'].contains(style)) {
      base.line(startX, startY, endX, endY,
          thickness: style == 'cigar' || style == 'instrumentMouthpiece' ? 2 : 1);
      if (style == 'cigarette' || style == 'cigar' || style == 'matchstick') {
        dark.set(endX, endY);
        light.set(endX - side, endY);
      }
      if (style == 'thermometer') light.fillEllipse(endX, endY, 1, 1);
      if (style == 'cyberCable') {
        base.line(endX, endY, endX + side * 2, endY + 3);
        light.set(endX + side * 2, endY + 3);
      }
    } else if (style == 'pipe') {
      base.line(startX, startY, endX, endY, thickness: 2);
      base.fillEllipse(endX + side * 2, endY - 1, 3, 2);
      dark.fillEllipse(endX + side * 2, endY - 2, 2, 1);
    } else if (style == 'grassBlade') {
      organic = true;
      base.line(startX, startY, endX, endY);
      base.line(endX, endY, endX + side * 2, endY - 3);
    } else if (style == 'lollipop') {
      base.line(startX, startY, endX, endY);
      light.fillEllipse(endX + side, endY - 1, 2, 2);
    } else if (style == 'flower' || style == 'rose') {
      organic = true;
      base.line(startX, startY, endX, endY);
      for (var i = 0; i < 5; i++) {
        light.fillEllipse(endX + side * (i.isEven ? 1 : -1), endY - 2 + positiveMod(i, 3), 1, 1);
      }
      dark.set(endX, endY - 1);
    } else if (style == 'whistle') {
      base.line(startX, startY, endX, endY, thickness: 2);
      dark.fillEllipse(endX, endY, 2, 2);
      light.set(endX, endY);
    }

    if (<String>['cigarette', 'cigar', 'pipe', 'matchstick'].contains(style) &&
        c.integer('v4.smokeAmount') > 0) {
      final amount = c.integer('v4.smokeAmount');
      final animated = c.string('v4.animation') == 'smoke';
      final phase = animated ? c.phase : 0;
      var x = style == 'pipe' ? endX + side * 2 : endX;
      var y = endY - 2;
      for (var i = 0; i < amount; i++) {
        final drift = side * (i ~/ 2) +
            cyclicOffset(phase + i * 2, 16, 1);
        final radius = 1 + i ~/ 3;
        smoke.fillEllipse(x + drift, y - i * 2 - positiveMod(phase, 2), radius, 1);
        if (i.isOdd) smokeDark.set(x + drift, y - i * 2);
      }
    }
    // Mouth props may not overwrite the full mouth; preserve the anchor only.
    final mouthSafety = state.mask('mouthSafety');
    final allowedAnchor = maskRect(startX - 1, startY - 1, 3, 3);
    final safeBase = base.subtract(mouthSafety.subtract(allowedAnchor));
    return _MouthProp(safeBase, dark, light, smoke, smokeDark, organic);
  }

  _ShoulderProp _shoulderProp(AvatarRenderContext c) {
    final style = c.string('v4.shoulderProp');
    if (style == 'none') return _ShoulderProp.empty();
    final side = c.integer('v4.propSide') == 0
        ? (c.random('shoulderProp.side').nextBool() ? 1 : -1)
        : c.integer('v4.propSide');
    final x = side < 0 ? 8 : 39;
    final y = 32;
    final base = PixelMask();
    final shadow = PixelMask();
    final light = PixelMask();

    if (style == 'parrot') {
      base.fillEllipse(x, y - 3, 4, 6);
      base.fillEllipse(x - side * 2, y - 9, 3, 3);
      base.fillTriangle((x: x - side * 4, y: y - 9),
          (x: x - side * 7, y: y - 8), (x: x - side * 4, y: y - 7));
      light.set(x - side * 3, y - 10);
    } else if (style == 'cat') {
      base.fillEllipse(x, y - 2, 5, 5);
      base.fillEllipse(x, y - 8, 4, 4);
      base.fillTriangle((x: x - 4, y: y - 10), (x: x - 1, y: y - 9), (x: x - 3, y: y - 13));
      base.fillTriangle((x: x + 1, y: y - 9), (x: x + 4, y: y - 10), (x: x + 3, y: y - 13));
      light.set(x - 1, y - 8).set(x + 1, y - 8);
    } else if (style == 'smallDragon') {
      base.fillEllipse(x, y - 4, 4, 6);
      base.fillEllipse(x + side * 2, y - 10, 3, 3);
      base.fillTriangle((x: x, y: y - 5), (x: x - side * 8, y: y - 12), (x: x - side * 5, y: y - 2));
      light.set(x + side * 3, y - 10);
    } else if (style == 'shoulderRobot') {
      base.fillRect(x - 4, y - 9, 8, 8);
      base.fillRect(x - 3, y - 13, 6, 4);
      light.set(x - 1, y - 11).set(x + 1, y - 11);
      shadow.vLine(x, y - 8, y - 3);
    } else if (style == 'ghost') {
      base.fillEllipse(x, y - 8, 5, 7);
      for (var i = -4; i <= 4; i += 2) base.fillTriangle(
          (x: x + i - 1, y: y - 4), (x: x + i + 1, y: y - 4), (x: x + i, y: y));
      shadow.set(x - 2, y - 9).set(x + 2, y - 9);
    } else if (style == 'insect') {
      base.fillEllipse(x, y - 6, 2, 4);
      base.fillEllipse(x - 3, y - 6, 3, 2).fillEllipse(x + 3, y - 6, 3, 2);
      light.set(x, y - 8);
    } else if (style == 'flowerBundle') {
      for (var i = 0; i < 5; i++) {
        base.line(x, y, x - 4 + i * 2, y - 9 - positiveMod(i, 3));
        light.fillEllipse(x - 4 + i * 2, y - 10 - positiveMod(i, 3), 1, 1);
      }
    } else if (style == 'skull') {
      base.fillEllipse(x, y - 7, 5, 5);
      base.fillRect(x - 3, y - 4, 6, 4);
      shadow.set(x - 2, y - 8).set(x + 2, y - 8).set(x, y - 5);
    } else if (style == 'radio') {
      base.fillRect(x - 5, y - 10, 10, 10);
      shadow.fillRect(x - 3, y - 8, 6, 4);
      base.line(x + side * 4, y - 10, x + side * 7, y - 17);
      light.set(x - 3, y - 3).set(x, y - 3).set(x + 3, y - 3);
    } else if (style == 'flashlight') {
      base.fillRect(x - 2, y - 12, 4, 11);
      base.fillTriangle((x: x - 3, y: y - 12), (x: x + 3, y: y - 12), (x: x, y: y - 17));
      light.fillTriangle((x: x - 1, y: y - 16), (x: x + 1, y: y - 16), (x: x, y: y - 22));
    } else if (style == 'energyOrb') {
      base.fillEllipse(x, y - 9, 5, 5);
      light.fillEllipse(x, y - 9, 2, 2);
      shadow.data.setAll(0, base.outline(diagonal: true).data);
    }
    return _ShoulderProp(base, shadow.intersect(base), light);
  }
}

final class _MouthProp {
  const _MouthProp(this.base, this.dark, this.light, this.smoke,
      this.smokeDark, this.organic);
  factory _MouthProp.empty() => _MouthProp(PixelMask(), PixelMask(),
      PixelMask(), PixelMask(), PixelMask(), false);
  final PixelMask base;
  final PixelMask dark;
  final PixelMask light;
  final PixelMask smoke;
  final PixelMask smokeDark;
  final bool organic;
}

final class _ShoulderProp {
  const _ShoulderProp(this.base, this.shadow, this.light);
  factory _ShoulderProp.empty() => _ShoulderProp(PixelMask(), PixelMask(), PixelMask());
  final PixelMask base;
  final PixelMask shadow;
  final PixelMask light;
}
