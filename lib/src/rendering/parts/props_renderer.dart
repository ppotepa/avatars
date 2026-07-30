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
    final shoulderKind = context.string('v4.shoulderProp');
    final isCompanion = const <String>{
      'cat',
      'parrot',
      'smallDragon',
      'ghost',
      'insect',
      'shoulderRobot',
    }.contains(shoulderKind);
    if (shoulderKind != 'none') {
      final side = _shoulderSide(context);
      final anchor = side < 0 ? 'left-shoulder' : 'right-shoulder';
      if (isCompanion) {
        state.anchorNode('shoulderCompanion', anchor);
      } else {
        state
          ..anchorNode('shoulderObject', anchor)
          ..parentNode('shoulderObject', side < 0 ? 'leftArm' : 'rightArm');
      }
    }
    Map<String, Object?> shoulderMeta(String part) => <String, Object?>{
          'part': part,
          'shoulderPropKind': shoulderKind,
        };
    state
      ..putMask('mouthProp', mouth.base)
      ..putMask('shoulderProp', shoulder.base)
      ..addLayer(
          'shoulderProp.outline',
          194,
          (isCompanion ? shoulder.body : shoulder.base).outline(diagonal: true),
          context.color('outline'),
          meta: shoulderMeta('shoulderProp'))
      ..addLayer('shoulderProp.headOutline', 194,
          shoulder.head.outline(diagonal: true), context.color('outline'),
          meta: shoulderMeta('shoulderPropHead'))
      ..addLayer('shoulderProp.wingsOutline', 194,
          shoulder.wings.outline(diagonal: true), context.color('outline'),
          meta: shoulderMeta('shoulderPropWings'))
      ..addLayer('shoulderProp.tailOutline', 194,
          shoulder.tail.outline(diagonal: true), context.color('outline'),
          meta: shoulderMeta('shoulderPropTail'))
      ..addLayer('shoulderProp.earsOutline', 194,
          shoulder.ears.outline(diagonal: true), context.color('outline'),
          meta: shoulderMeta('shoulderPropEars'))
      ..addLayer('shoulderProp.beakOutline', 194,
          shoulder.beak.outline(diagonal: true), context.color('outline'),
          meta: shoulderMeta('shoulderPropBeak'))
      ..addLayer(
          'shoulderProp.base', 195, shoulder.body, context.color('clothAccent'),
          meta: shoulderMeta('shoulderProp'))
      ..addLayer(
          'shoulderProp.tail', 195, shoulder.tail, context.color('clothAccent'),
          meta: shoulderMeta('shoulderPropTail'))
      ..addLayer('shoulderProp.wings', 196, shoulder.wings,
          context.color('clothLight'),
          meta: shoulderMeta('shoulderPropWings'))
      ..addLayer(
          'shoulderProp.ears', 196, shoulder.ears, context.color('clothAccent'),
          meta: shoulderMeta('shoulderPropEars'))
      ..addLayer(
          'shoulderProp.head', 197, shoulder.head, context.color('clothAccent'),
          meta: shoulderMeta('shoulderPropHead'))
      ..addLayer(
          'shoulderProp.beak', 198, shoulder.beak, context.color('clothLight'),
          meta: shoulderMeta('shoulderPropBeak'))
      ..addLayer('shoulderProp.eyes', 199, shoulder.eyes,
          context.color('fantasyLight'),
          meta: shoulderMeta('shoulderPropEyes'))
      ..addLayer('shoulderProp.shadow', 196, shoulder.shadow,
          context.color('clothDark'),
          meta: shoulderMeta('shoulderProp'))
      ..addLayer('shoulderProp.light', 198, shoulder.light,
          context.color('fantasyLight'),
          meta: shoulderMeta('shoulderProp'))
      ..addLayer('mouthProp.outline', 200, mouth.base.outline(diagonal: true),
          context.color('outline'),
          meta: const {'part': 'mouthProp'})
      ..addLayer(
          'mouthProp.base',
          201,
          mouth.base,
          mouth.organic
              ? context.color('clothAccent')
              : context.color('clothLight'),
          meta: const {'part': 'mouthProp'})
      ..addLayer('mouthProp.dark', 202, mouth.dark, context.color('clothDark'),
          meta: const {'part': 'mouthProp'})
      ..addLayer(
          'mouthProp.light', 203, mouth.light, context.color('fantasyLight'),
          meta: const {'part': 'mouthProp'})
      ..addLayer(
          'mouthProp.smoke.dark', 204, mouth.smokeDark, context.color('bgDark'),
          meta: const {'part': 'smoke'})
      ..addLayer('mouthProp.smoke', 205, mouth.smoke, context.color('bgLight'),
          meta: const {'part': 'smoke'});
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
    final animationSwing = c.animation.propSwingX();

    if (<String>[
      'cigarette',
      'cigar',
      'matchstick',
      'toothpick',
      'straw',
      'thermometer',
      'instrumentMouthpiece',
      'cyberCable'
    ].contains(style)) {
      base.line(startX, startY, endX, endY,
          thickness:
              style == 'cigar' || style == 'instrumentMouthpiece' ? 2 : 1);
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
        light.fillEllipse(endX + side * (i.isEven ? 1 : -1),
            endY - 2 + positiveMod(i, 3), 1, 1);
      }
      dark.set(endX, endY - 1);
    } else if (style == 'whistle') {
      base.line(startX, startY, endX, endY, thickness: 2);
      dark.fillEllipse(endX, endY, 2, 2);
      light.set(endX, endY);
    }

    if (animationSwing != 0) {
      for (final mask in <PixelMask>[base, dark, light]) {
        mask.data.setAll(0, mask.translated(animationSwing, 0).data);
      }
    }

    if (<String>['cigarette', 'cigar', 'pipe', 'matchstick'].contains(style) &&
        c.integer('v4.smokeAmount') > 0) {
      final amount = c.integer('v4.smokeAmount');
      final animated =
          c.string('v4.animation') == 'smoke' || animationSwing != 0;
      final phase = animated ? c.phase : 0;
      var x = (style == 'pipe' ? endX + side * 2 : endX) + animationSwing;
      var y = endY - 2;
      for (var i = 0; i < amount; i++) {
        final drift = side * (i ~/ 2) + cyclicOffset(phase + i * 2, 16, 1);
        final radius = 1 + i ~/ 3;
        smoke.fillEllipse(
            x + drift, y - i * 2 - positiveMod(phase, 2), radius, 1);
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
    final side = _shoulderSide(c);
    final x = side < 0 ? 8 : 39;
    final y = 32;
    final body = PixelMask();
    final head = PixelMask();
    final wings = PixelMask();
    final tail = PixelMask();
    final ears = PixelMask();
    final beak = PixelMask();
    final eyes = PixelMask();
    final shadow = PixelMask();
    final light = PixelMask();

    if (style == 'parrot') {
      body.fillEllipse(x, y - 3, 4, 6);
      head.fillEllipse(x - side * 2, y - 9, 3, 3);
      wings.fillEllipse(x + side, y - 4, 2, 4);
      tail
        ..line(x + side, y + 1, x + side * 3, y + 7, thickness: 2)
        ..line(x - side, y + 1, x + side, y + 7);
      beak.fillTriangle(
        (x: x - side * 4, y: y - 10),
        (x: x - side * 8, y: y - 8),
        (x: x - side * 4, y: y - 7),
      );
      eyes.set(x - side * 3, y - 10);
      light.set(x - side, y - 11);
    } else if (style == 'cat') {
      body.fillEllipse(x, y - 2, 5, 5);
      head.fillEllipse(x, y - 8, 4, 4);
      ears
        ..fillTriangle(
            (x: x - 4, y: y - 10), (x: x - 1, y: y - 9), (x: x - 3, y: y - 14))
        ..fillTriangle(
            (x: x + 1, y: y - 9), (x: x + 4, y: y - 10), (x: x + 3, y: y - 14));
      tail
        ..line(x + side * 4, y, x + side * 7, y - 2, thickness: 2)
        ..line(x + side * 7, y - 2, x + side * 6, y - 6, thickness: 2);
      eyes.set(x - 2, y - 9).set(x + 2, y - 9);
      light.set(x, y - 6);
    } else if (style == 'smallDragon') {
      body.fillEllipse(x, y - 4, 4, 6);
      head.fillEllipse(x + side * 2, y - 10, 3, 3);
      wings
        ..fillTriangle((x: x - 1, y: y - 7), (x: x - side * 9, y: y - 13),
            (x: x - side * 5, y: y - 2))
        ..line(x, y - 7, x - side * 6, y - 10);
      tail
        ..line(x - side * 2, y, x - side * 7, y + 5, thickness: 2)
        ..set(x - side * 8, y + 6);
      ears.fillTriangle((x: x + side, y: y - 12), (x: x + side * 3, y: y - 12),
          (x: x + side * 2, y: y - 16));
      eyes.set(x + side * 3, y - 11);
      light.set(x + side, y - 12);
    } else if (style == 'shoulderRobot') {
      body.fillRect(x - 4, y - 8, 8, 7);
      head.fillRect(x - 3, y - 13, 6, 5);
      ears
        ..line(x, y - 13, x + side * 2, y - 17)
        ..set(x + side * 2, y - 18);
      eyes.set(x - 1, y - 11).set(x + 1, y - 11);
      shadow.vLine(x, y - 8, y - 3);
      light.hLine(x - 2, x + 2, y - 9);
    } else if (style == 'ghost') {
      head.fillEllipse(x, y - 10, 5, 4);
      body.fillRect(x - 5, y - 10, 11, 7);
      for (var i = -4; i <= 4; i += 2)
        tail.fillTriangle((x: x + i - 1, y: y - 4), (x: x + i + 1, y: y - 4),
            (x: x + i, y: y));
      eyes.set(x - 2, y - 10).set(x + 2, y - 10);
      shadow.hLine(x - 2, x + 2, y - 7);
    } else if (style == 'insect') {
      body.fillEllipse(x, y - 5, 2, 4);
      head.fillEllipse(x, y - 10, 2, 2);
      wings
        ..fillEllipse(x - 3, y - 6, 3, 2)
        ..fillEllipse(x + 3, y - 6, 3, 2);
      ears
        ..line(x - 1, y - 11, x - 3, y - 15)
        ..line(x + 1, y - 11, x + 3, y - 15);
      eyes.set(x - 1, y - 10).set(x + 1, y - 10);
    } else if (style == 'flowerBundle') {
      for (var i = 0; i < 5; i++) {
        body.line(x, y, x - 4 + i * 2, y - 9 - positiveMod(i, 3));
        light.fillEllipse(x - 4 + i * 2, y - 10 - positiveMod(i, 3), 1, 1);
      }
    } else if (style == 'skull') {
      body.fillEllipse(x, y - 7, 5, 5);
      body.fillRect(x - 3, y - 4, 6, 4);
      shadow.set(x - 2, y - 8).set(x + 2, y - 8).set(x, y - 5);
    } else if (style == 'radio') {
      body.fillRect(x - 5, y - 10, 10, 10);
      shadow.fillRect(x - 3, y - 8, 6, 4);
      body.line(x + side * 4, y - 10, x + side * 7, y - 17);
      light.set(x - 3, y - 3).set(x, y - 3).set(x + 3, y - 3);
    } else if (style == 'flashlight') {
      body.fillRect(x - 2, y - 12, 4, 11);
      body.fillTriangle(
          (x: x - 3, y: y - 12), (x: x + 3, y: y - 12), (x: x, y: y - 17));
      light.fillTriangle(
          (x: x - 1, y: y - 16), (x: x + 1, y: y - 16), (x: x, y: y - 22));
    } else if (style == 'energyOrb') {
      body.fillEllipse(x, y - 9, 5, 5);
      light.fillEllipse(x, y - 9, 2, 2);
      shadow.data.setAll(0, body.outline(diagonal: true).data);
    }
    final animatedCompanion = const <String>{
      'cat',
      'parrot',
      'smallDragon',
      'ghost',
      'insect',
      'shoulderRobot',
    }.contains(style);
    var silhouette =
        body.union(head).union(wings).union(tail).union(ears).union(beak);
    if (c.animation.blinkFrame()) {
      final eyeBounds = eyes.bounds;
      if (eyeBounds != null) {
        eyes.data.fillRange(0, eyes.data.length, 0);
        eyes.hLine(
          eyeBounds.left,
          eyeBounds.right,
          (eyeBounds.top + 1).clamp(0, 47),
        );
      }
    }
    if (!animatedCompanion) {
      return _ShoulderProp(
        silhouette,
        silhouette,
        PixelMask(),
        PixelMask(),
        PixelMask(),
        PixelMask(),
        PixelMask(),
        PixelMask(),
        shadow.intersect(silhouette),
        light,
      );
    }
    if (c.animation.id == 'sleeping') {
      light
        ..set(x - side, y - 15)
        ..set(x + side, y - 17)
        ..set(x + side * 3, y - 19);
    }
    silhouette = silhouette.union(eyes);
    return _ShoulderProp(
      silhouette,
      body,
      head,
      wings,
      tail,
      ears,
      beak,
      eyes,
      shadow.intersect(silhouette),
      light,
    );
  }

  int _shoulderSide(AvatarRenderContext c) => c.integer('v4.propSide') == 0
      ? (c.random('shoulderProp.side').nextBool() ? 1 : -1)
      : c.integer('v4.propSide');
}

final class _MouthProp {
  const _MouthProp(this.base, this.dark, this.light, this.smoke, this.smokeDark,
      this.organic);
  factory _MouthProp.empty() => _MouthProp(
      PixelMask(), PixelMask(), PixelMask(), PixelMask(), PixelMask(), false);
  final PixelMask base;
  final PixelMask dark;
  final PixelMask light;
  final PixelMask smoke;
  final PixelMask smokeDark;
  final bool organic;
}

final class _ShoulderProp {
  const _ShoulderProp(this.base, this.body, this.head, this.wings, this.tail,
      this.ears, this.beak, this.eyes, this.shadow, this.light);
  factory _ShoulderProp.empty() => _ShoulderProp(
      PixelMask(),
      PixelMask(),
      PixelMask(),
      PixelMask(),
      PixelMask(),
      PixelMask(),
      PixelMask(),
      PixelMask(),
      PixelMask(),
      PixelMask());
  final PixelMask base;
  final PixelMask body;
  final PixelMask head;
  final PixelMask wings;
  final PixelMask tail;
  final PixelMask ears;
  final PixelMask beak;
  final PixelMask eyes;
  final PixelMask shadow;
  final PixelMask light;
}
