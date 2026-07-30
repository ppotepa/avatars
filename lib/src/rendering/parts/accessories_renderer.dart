import '../../pixels/pixel_mask.dart';
import '../../util/math_utils.dart';
import '../render_helpers.dart';
import '../render_model.dart';

/// Renders headwear, helmets, eyewear, face masks, jewelry, scars and
/// cybernetic overlays. Geometry is anchored to resolved face landmarks.
final class AccessoriesRenderer implements AvatarPartRenderer {
  const AccessoriesRenderer();

  @override
  void render(AvatarRenderContext context, AvatarRenderState state) {
    final headwear = _headwear(context);
    final eyewear = _eyewear(context, state);
    final faceMask = _faceMask(context, state);
    final jewelry = _jewelry(context);
    final cyber = _cyber(context, state);

    state
      ..putMask('headwear', headwear.base)
      ..putMask('eyewear', eyewear.frame.union(eyewear.lens))
      ..putMask('faceMask', faceMask.base)
      ..putMask('jewelry', jewelry.base.union(jewelry.accent))
      ..putMask('cybernetics', cyber.base.union(cyber.glow))
      ..addLayer('cyber.base', 146, cyber.base, context.color('outlineSoft'),
          meta: const {'part': 'cybernetics'})
      ..addLayer('cyber.accent', 147, cyber.accent,
          context.color('clothAccent'), meta: const {'part': 'cybernetics'})
      ..addLayer('cyber.glow', 148, cyber.glow,
          context.color('fantasyLight'), meta: const {'part': 'cybernetics'})
      ..addLayer('headwear.outline', 164,
          headwear.base.outline(diagonal: true), context.color('outline'),
          meta: const {'part': 'headwear'})
      ..addLayer('headwear.base', 165, headwear.base,
          context.color('clothBase'), meta: const {'part': 'headwear'})
      ..addLayer('headwear.shadow', 166, headwear.shadow,
          context.color('clothDark'), meta: const {'part': 'headwear'})
      ..addLayer('headwear.light', 167, headwear.light,
          context.color('clothLight'), meta: const {'part': 'headwear'})
      ..addLayer('headwear.accent', 168, headwear.accent,
          context.color('clothAccent'), meta: const {'part': 'headwear'})
      ..addLayer('eyewear.frame', 174, eyewear.frame,
          context.color('outline'), meta: const {'part': 'eyewear'})
      ..addLayer('eyewear.lens', 175, eyewear.lens,
          eyewear.darkLens ? context.color('irisDark') : context.color('bgLight'),
          meta: const {'part': 'eyewear'})
      ..addLayer('eyewear.reflection', 176, eyewear.reflection,
          context.color('white'), meta: const {'part': 'eyewear'})
      ..addLayer('faceMask.outline', 180,
          faceMask.base.outline(diagonal: true), context.color('outline'),
          meta: const {'part': 'faceMask'})
      ..addLayer('faceMask.base', 181, faceMask.base,
          context.color('clothBase'), meta: const {'part': 'faceMask'})
      ..addLayer('faceMask.shadow', 182, faceMask.shadow,
          context.color('clothDark'), meta: const {'part': 'faceMask'})
      ..addLayer('faceMask.accent', 183, faceMask.accent,
          context.color('clothAccent'), meta: const {'part': 'faceMask'})
      ..addLayer('jewelry.dark', 186, jewelry.base,
          context.color('clothDark'), meta: const {'part': 'jewelry'})
      ..addLayer('jewelry.accent', 187, jewelry.accent,
          context.color('fantasyLight'), meta: const {'part': 'jewelry'})
      ..addLayer('jewelry.light', 188, jewelry.light,
          context.color('white'), meta: const {'part': 'jewelry'});
  }

  _Headwear _headwear(AvatarRenderContext c) {
    final style = c.string('v4.headwear');
    if (style == 'none') return _Headwear.empty();
    final base = PixelMask();
    final shadow = PixelMask();
    final light = PixelMask();
    final accent = PixelMask();
    final width = clampInt(c.integer('v4.headwearWidth'), 8, 40);
    final coverage = clampInt(c.integer('v4.headwearCoverage'), 0, 6);
    final height = clampInt(c.integer('v4.headwearHeight') + coverage ~/ 2, 2, 18);
    final x = 24 + c.integer('v4.headwearOffsetX');
    final tilt = c.integer('v4.headwearTilt');
    final headTop = c.integer('head.topY');
    final top = clampInt(headTop - height + 2, 0, 47);
    final left = x - width ~/ 2;
    final right = x + width ~/ 2;

    if (style == 'baseballCap') {
      base.fillEllipse(x, headTop, width / 2, height / 2);
      base.fillTriangle((x: x, y: headTop), (x: right + 5, y: headTop + tilt),
          (x: x + 3, y: headTop + 3));
      accent.line(x, top, x, headTop);
    } else if (style == 'beanie' || style == 'winterHat') {
      base.fillEllipse(x, headTop + 1, width / 2, height);
      base.fillRect(left, headTop, width + 1, 3);
      if (style == 'winterHat') base.fillEllipse(x, top, 2, 2);
      for (var xx = left + 2; xx < right; xx += 4) accent.vLine(xx, top + 2, headTop + 1);
    } else if (style == 'beret') {
      base.fillEllipse(x + tilt * 2, headTop, width / 2, height / 2);
      accent.set(x + tilt * 2, top);
    } else if (style == 'fedora' || style == 'cowboyHat' || style == 'topHat' || style == 'strawHat') {
      final crownWidth = style == 'topHat' ? width ~/ 2 : width * 2 ~/ 3;
      base.fillRect(x - crownWidth ~/ 2, top, crownWidth, height);
      base.hLine(left - (style == 'cowboyHat' ? 3 : 0),
          right + (style == 'cowboyHat' ? 3 : 0), headTop + 1 + tilt);
      if (style == 'cowboyHat') {
        base.line(left - 3, headTop + 1, left + 3, headTop - 1);
        base.line(right + 3, headTop + 1, right - 3, headTop - 1);
      }
      accent.hLine(x - crownWidth ~/ 2, x + crownWidth ~/ 2, headTop - 1);
    } else if (style == 'wizardHat') {
      base.fillTriangle((x: left + 4, y: headTop + 1),
          (x: right - 4, y: headTop + 1),
          (x: x + tilt * 2, y: top));
      base.hLine(left, right, headTop + 1);
      accent.set(x + tilt, top + height ~/ 3);
    } else if (style == 'hood') {
      base.fillEllipse(x, headTop + 7, width / 2, height + 5);
      final opening = PixelMask()..fillEllipse(x, headTop + 9, width / 2 - 4, height + 1);
      base.data.setAll(0, base.subtract(opening).data);
    } else if (style == 'bandana' || style == 'headband') {
      base.fillRect(left, headTop, width, style == 'bandana' ? 4 : 2);
      if (style == 'bandana') {
        base.fillTriangle((x: left + 2, y: headTop + 2),
            (x: left - 5, y: headTop + 6), (x: left + 1, y: headTop + 7));
      }
    } else if (style == 'turban') {
      for (var i = 0; i < 4; i++) base.fillEllipse(x, headTop - i, width / 2 - i, height / 2);
      accent.line(left + 3, headTop - 4, right - 3, headTop + 2);
    } else if (style == 'crown' || style == 'tiara') {
      final crownY = headTop;
      base.hLine(left + 4, right - 4, crownY + 2);
      final points = style == 'crown' ? 5 : 3;
      for (var i = 0; i < points; i++) {
        final px = left + 5 + ((width - 10) * i / (points - 1)).round();
        base.fillTriangle((x: px - 2, y: crownY + 2),
            (x: px + 2, y: crownY + 2),
            (x: px, y: top + positiveMod(i, 2)));
        accent.set(px, top + positiveMod(i, 2));
      }
    } else if (style == 'wreath') {
      for (var xx = left + 3; xx <= right - 3; xx += 3) {
        base.fillEllipse(xx, headTop, 2, 1);
        accent.set(xx, headTop - 1);
      }
    } else if (<String>['sailorCap', 'militaryCap', 'chefHat', 'pirateHat'].contains(style)) {
      if (style == 'chefHat') {
        for (var xx = x - 7; xx <= x + 7; xx += 5) base.fillEllipse(xx, top + 3, 4, 4);
        base.fillRect(x - 10, top + 4, 20, height);
      } else if (style == 'pirateHat') {
        base.fillTriangle((x: left, y: headTop + 2), (x: right, y: headTop + 2), (x: x, y: top));
        base.fillTriangle((x: left, y: headTop + 2), (x: x, y: headTop - 1), (x: left + 4, y: top + 2));
        accent.fillEllipse(x, top + height ~/ 2, 2, 2);
      } else {
        base.fillRect(left + 3, top + 2, width - 6, height - 1);
        base.hLine(left, right, headTop + 1);
        if (style == 'militaryCap') accent.hLine(left + 4, right - 4, headTop - 1);
      }
    } else {
      _helmet(c, style, base, shadow, light, accent, x, top, headTop, width, height, coverage);
    }

    final damage = c.integer('v4.headwearDamage');
    if (damage > 0) {
      final rng = c.random('headwear.damage.$style');
      final cuts = PixelMask();
      for (var i = 0; i < damage; i++) {
        cuts.line(rng.nextInt(left, right), rng.nextInt(top, headTop + 4),
            rng.nextInt(left, right), rng.nextInt(top, headTop + 4));
      }
      base.data.setAll(0, base.subtract(cuts).data);
    }
    shadow.data.setAll(0, shadow.union(shadingMask(base, kind: 'clothing', strength: 2)).intersect(base).data);
    light.data.setAll(0, light.union(highlightMask(base, kind: 'clothing', strength: 2)).intersect(base).data);
    return _Headwear(base.removeSmallComponents(2, maxComponents: 5), shadow, light, accent.intersect(base));
  }

  void _helmet(
    AvatarRenderContext c,
    String style,
    PixelMask base,
    PixelMask shadow,
    PixelMask light,
    PixelMask accent,
    int x,
    int top,
    int headTop,
    int width,
    int height,
    int coverage,
  ) {
    final closed = <String>['helmetKnightClosed', 'spaceHelmet',
      'motorcycleHelmet', 'diverHelmet', 'demonHelmet', 'robotHelmet'];
    base.fillEllipse(x, headTop + 7, width / 2, height + 6);
    final lower = c.integer('face.mouthY') +
        (closed.contains(style) ? 3 + coverage ~/ 2 : -3 + coverage ~/ 3);
    base.fillRect(x - width ~/ 2, headTop, width, clampInt(lower - headTop, 4, 26));
    if (!closed.contains(style) || style == 'helmetKnightOpen') {
      final faceOpening = PixelMask()..fillRect(x - width ~/ 2 + 4,
          c.integer('face.eyeY') - 3, width - 8, 10);
      base.data.setAll(0, base.subtract(faceOpening).data);
    } else {
      final visorY = c.integer('face.eyeY') - 1;
      shadow.fillRect(x - width ~/ 2 + 4, visorY, width - 8, 4);
      for (var xx = x - width ~/ 2 + 6; xx < x + width ~/ 2 - 4; xx += 4) {
        accent.vLine(xx, visorY, visorY + 3);
      }
    }
    if (style == 'helmetNorse' || style == 'hornedHelmet') {
      base.fillTriangle((x: x - width / 2 + 4, y: headTop),
          (x: x - width / 2 - 6, y: top), (x: x - width / 2 + 9, y: headTop + 4));
      base.fillTriangle((x: x + width / 2 - 4, y: headTop),
          (x: x + width / 2 + 6, y: top), (x: x + width / 2 - 9, y: headTop + 4));
    }
    if (style == 'helmetGladiator') {
      for (var xx = x - 8; xx <= x + 8; xx += 3) base.line(xx, headTop, x, top);
    }
    if (style == 'helmetSamurai') {
      base.fillTriangle((x: x - width / 2 - 3, y: headTop + 2),
          (x: x + width / 2 + 3, y: headTop + 2), (x: x, y: top));
      accent.hLine(x - 8, x + 8, headTop - 2);
    }
    if (style == 'helmetFuturistic' || style == 'robotHelmet') {
      accent.fillRect(x - 8, c.integer('face.eyeY') - 1, 16, 3);
      light.set(x - 6, c.integer('face.eyeY')).set(x + 6, c.integer('face.eyeY'));
    }
    if (style == 'tacticalHelmet' || style == 'minerHelmet') {
      base.fillRect(x - width ~/ 2, top + height ~/ 2, width, height ~/ 2);
      if (style == 'minerHelmet') accent.fillEllipse(x, top + height ~/ 2, 2, 2);
    }
    if (style == 'ceremonialHelmet') {
      accent.vLine(x, top, headTop + 5);
      accent.hLine(x - 8, x + 8, headTop);
    }
    if (style == 'demonHelmet') {
      accent.fillTriangle((x: x - 7, y: c.integer('face.mouthY')),
          (x: x, y: c.integer('face.mouthY') + 3),
          (x: x + 7, y: c.integer('face.mouthY')));
    }
  }

  _Eyewear _eyewear(AvatarRenderContext c, AvatarRenderState state) {
    final style = c.string('v4.eyewear');
    if (style == 'none') return _Eyewear.empty();
    final frame = PixelMask();
    final lens = PixelMask();
    final reflection = PixelMask();
    final eyeY = c.integer('face.eyeY');
    final leftX = c.integer('face.leftEyeX');
    final rightX = c.integer('face.rightEyeX');
    final width = clampInt(c.integer('eyes.width') + 3, 3, 10);
    final height = clampInt(c.integer('v4.lensHeight'), 1, 6);
    final thickness = clampInt(c.integer('v4.frameThickness'), 1, 3);
    final bridgeWidth = clampInt(c.integer('v4.bridgeWidth'), 1, 5);
    final asymmetry = clampInt(c.integer('v4.accessoryAsymmetry'), 0, 5);
    final asymmetryDirection = c.random('eyewear.asymmetry').nextBool() ? 1 : -1;
    final rightEyeY = eyeY + (asymmetry >= 3 ? asymmetryDirection : 0);
    final tint = c.integer('v4.lensTint');

    if (style == 'monocleLeft' || style == 'monocleRight') {
      final cx = style == 'monocleLeft' ? leftX : rightX;
      lens.fillEllipse(cx, eyeY, width / 2, height / 2);
      frame.data.setAll(0, lens.outline(diagonal: true).data);
      frame.line(cx + (style == 'monocleLeft' ? -width ~/ 2 : width ~/ 2),
          eyeY + 1, cx + (style == 'monocleLeft' ? -width : width),
          c.integer('face.mouthY') + 4);
    } else if (style == 'eyePatchLeft' || style == 'eyePatchRight') {
      final cx = style == 'eyePatchLeft' ? leftX : rightX;
      lens.fillRect(cx - width ~/ 2, eyeY - height ~/ 2, width, height + 1);
      frame.line(4, eyeY - 5, 43, eyeY + 3);
    } else if (style == 'cyberVisor' || style == 'monoVisor' || style == 'mirrorShades') {
      lens.fillRect(leftX - width ~/ 2, eyeY - height ~/ 2,
          rightX - leftX + width, height + 1);
      frame.data.setAll(0, lens.outline(diagonal: true).data);
      if (style == 'monoVisor') frame.vLine(24, eyeY - height ~/ 2, eyeY + height ~/ 2);
    } else if (style == 'targetingLens') {
      final targetLeft = c.random('eyewear.targetingLens.side').nextBool();
      final cx = targetLeft ? leftX : rightX;
      lens.fillEllipse(cx, eyeY, width / 2, height / 2);
      frame.data.setAll(0, lens.outline(diagonal: true).data);
      reflection.hLine(cx - 2, cx + 2, eyeY).vLine(cx, eyeY - 2, eyeY + 2);
    } else if (style == 'weldingGoggles') {
      lens.fillEllipse(leftX, eyeY, width / 2 + 1, height / 2 + 1);
      lens.fillEllipse(rightX, rightEyeY, width / 2 + 1, height / 2 + 1);
      frame.data.setAll(0, lens.outline(diagonal: true).dilated().data);
      frame.hLine(leftX + width ~/ 2, rightX - width ~/ 2, eyeY);
    } else {
      for (final eye in <(int, int)>[(leftX, eyeY), (rightX, rightEyeY)]) {
        final cx = eye.$1;
        final cy = eye.$2;
        if (<String>['roundGlasses', 'ovalGlasses', 'aviator', 'catEye', 'retro'].contains(style)) {
          final rx = style == 'oversizeGlasses' ? width / 2 + 2 : width / 2;
          final ry = style == 'ovalGlasses' || style == 'aviator' ? height / 2 + 1 : height / 2;
          lens.fillEllipse(cx, cy, rx, ry);
        } else {
          final extra = style == 'oversizeGlasses' ? 2 : 0;
          lens.fillRect(cx - width ~/ 2 - extra, cy - height ~/ 2,
              width + extra * 2, height + 1);
        }
      }
      frame.data.setAll(0, lens.outline(diagonal: true).data);
      if (style == 'rimless') frame.data.fillRange(0, frame.data.length, 0);
      if (style == 'halfFrames') {
        frame.data.setAll(0, frame.intersect(maskFromPredicate((x, y) => y <= eyeY)).data);
      }
      final bridgeLeft = leftX + width ~/ 2;
      final bridgeRight = rightX - width ~/ 2;
      for (var offset = 0; offset < bridgeWidth; offset++) {
        final y = eyeY - (bridgeWidth - 1) ~/ 2 + offset;
        frame.hLine(bridgeLeft, bridgeRight, y);
      }
      frame.line(leftX - width ~/ 2, eyeY, c.integer('head.leftX') - 1, eyeY - 1);
      frame.line(rightX + width ~/ 2, rightEyeY, c.integer('head.rightX') + 1, rightEyeY - 1);
    }
    if (style != 'rimless') {
      final expansion = clampInt(
        thickness - 1 + (style == 'thickFrames' ? 1 : 0),
        0,
        2,
      );
      for (var step = 0; step < expansion; step++) {
        frame.data.setAll(0, frame.dilated().data);
      }
    }
    if (c.integer('v4.reflection') > 0) {
      reflection.set(leftX - 1, eyeY - 1).set(rightX - 1, rightEyeY - 1);
      if (c.integer('v4.reflection') > 1) {
        reflection.set(leftX, eyeY - 1).set(rightX, rightEyeY - 1);
      }
    }
    final bounds = state.mask('head').dilated();
    return _Eyewear(frame.intersect(bounds), lens.intersect(bounds),
        reflection.intersect(lens), tint >= 2 || style.contains('Shades') || style.contains('Visor'));
  }

  _FaceMask _faceMask(AvatarRenderContext c, AvatarRenderState state) {
    final style = c.string('v4.faceMask');
    if (style == 'none') return _FaceMask.empty();
    final base = PixelMask();
    final shadow = PixelMask();
    final accent = PixelMask();
    final coverage = c.integer('v4.maskCoverage');
    final eyeY = c.integer('face.eyeY');
    final mouthY = c.integer('face.mouthY');
    final head = state.mask('head');
    final left = c.integer('head.leftX') + 2;
    final right = c.integer('head.rightX') - 2;

    if (style == 'surgicalMask' || style == 'faceBandana' || style == 'scarfMask') {
      final top = style == 'surgicalMask' ? c.integer('face.noseTipY') - 1 : c.integer('face.noseTipY') - 2;
      base.fillTriangle((x: left, y: top), (x: right, y: top),
          (x: 24, y: mouthY + 4 + coverage ~/ 2));
      if (style == 'surgicalMask') {
        for (var y = top + 1; y < mouthY + 3; y += 2) accent.hLine(left + 3, right - 3, y);
      }
    } else if (style == 'respirator' || style == 'gasMask') {
      base.fillEllipse(24, mouthY, 8 + coverage, 6 + coverage ~/ 2);
      final filterSize = c.integer('v4.maskFilterSize');
      base.fillEllipse(14, mouthY + 1, 2 + filterSize, 2 + filterSize);
      base.fillEllipse(34, mouthY + 1, 2 + filterSize, 2 + filterSize);
      accent.fillEllipse(14, mouthY + 1, 1 + filterSize ~/ 2, 1 + filterSize ~/ 2);
      accent.fillEllipse(34, mouthY + 1, 1 + filterSize ~/ 2, 1 + filterSize ~/ 2);
      if (style == 'gasMask') base.fillRect(20, eyeY - 1, 8, mouthY - eyeY + 4);
    } else if (style == 'ninjaMask' || style == 'balaclava') {
      base.data.setAll(0, head.data);
      final opening = PixelMask()..fillRect(left + 3, eyeY - 2, right - left - 5, 5);
      base.data.setAll(0, base.subtract(opening).data);
    } else if (style == 'theaterMask' || style == 'venetianMask') {
      base.fillEllipse(24, eyeY + 2, 11 + coverage, 7);
      base.data.setAll(0, base.subtract(state.mask('eyes').dilated()).data);
      if (style == 'venetianMask') {
        base.fillTriangle((x: 13, y: eyeY), (x: 4, y: eyeY - 3), (x: 14, y: eyeY + 3));
        base.fillTriangle((x: 35, y: eyeY), (x: 44, y: eyeY - 3), (x: 34, y: eyeY + 3));
      }
    } else if (style == 'demonMask' || style == 'robotMask' || style == 'hockeyMask' || style == 'ceremonialMask') {
      base.fillEllipse(24, eyeY + 5, 11 + coverage, 12);
      base.data.setAll(0, base.subtract(state.mask('eyes').dilated()).data);
      if (style == 'hockeyMask') {
        for (var y = eyeY + 3; y < mouthY + 5; y += 3) {
          accent.set(20, y).set(24, y + 1).set(28, y);
        }
      } else if (style == 'robotMask') {
        accent.hLine(18, 30, eyeY + 4).vLine(24, eyeY + 4, mouthY + 4);
      } else if (style == 'demonMask') {
        accent.fillTriangle((x: 18, y: mouthY), (x: 24, y: mouthY + 4), (x: 30, y: mouthY));
      } else {
        accent.vLine(24, eyeY, mouthY + 4).hLine(18, 30, mouthY);
      }
    } else if (style == 'halfMask') {
      base.data.setAll(0, head.intersect(maskFromPredicate((x, y) => x >= 24 && y >= eyeY - 2)).data);
    }
    final damage = c.integer('v4.maskDamage');
    if (damage > 0) {
      final cuts = PixelMask();
      for (var i = 0; i < damage; i++) cuts.line(18 + i * 3, eyeY + 2, 22 + i * 3, mouthY + 3);
      base.data.setAll(0, base.subtract(cuts).data);
    }
    shadow.data.setAll(0, shadingMask(base, kind: 'clothing', strength: 2).data);
    return _FaceMask(base.intersect(head.dilated()), shadow.intersect(base), accent.intersect(base));
  }

  _Jewelry _jewelry(AvatarRenderContext c) {
    final base = PixelMask();
    final accent = PixelMask();
    final light = PixelMask();
    final size = c.integer('v4.jewelrySize');
    final count = c.integer('v4.jewelryCount');
    final asymmetry = clampInt(c.integer('v4.accessoryAsymmetry'), 0, 5);
    final asymmetryLeft = c.random('jewelry.asymmetry').nextBool();
    final earStyle = c.string('v4.earJewelry');
    if (earStyle != 'none') {
      void earPiece(int x, int y, int side) {
        if (earStyle == 'stud' || earStyle == 'pearl') {
          accent.fillEllipse(x, y, size ~/ 2, size ~/ 2);
        } else if (earStyle == 'smallHoop' || earStyle == 'largeHoop' || earStyle == 'tunnel') {
          final radius = earStyle == 'largeHoop' ? size + 2 : size;
          final ring = PixelMask()..fillEllipse(x, y + radius, radius, radius);
          base.data.setAll(0, base.union(ring.subtract(PixelMask()..fillEllipse(x, y + radius, clampInt(radius - 1, 0, 8), clampInt(radius - 1, 0, 8)))).data);
        } else if (earStyle == 'dangling' || earStyle == 'chainEarring' || earStyle == 'fantasyEarring') {
          base.line(x, y, x + side, y + size + 4);
          accent.fillEllipse(x + side, y + size + 5, size ~/ 2 + 1, size ~/ 2 + 1);
        } else if (earStyle == 'industrial') {
          base.line(x - side * 2, y - 4, x + side * 2, y + 3);
        } else if (earStyle == 'multiPiercing') {
          for (var i = 0; i < count; i++) accent.set(x, y - i * 2);
        }
      }
      final earY = c.integer('ears.centerY') + 2;
      final singleSide = asymmetry >= 4;
      if (!singleSide || asymmetryLeft) {
        earPiece(c.integer('head.leftX') - 2,
            earY + (asymmetry >= 2 && asymmetryLeft ? 1 : 0), -1);
      }
      if (!singleSide || !asymmetryLeft) {
        earPiece(c.integer('head.rightX') + 2,
            earY + (asymmetry >= 2 && !asymmetryLeft ? 1 : 0), 1);
      }
    }
    final piercing = c.string('v4.facePiercing');
    if (piercing == 'noseStud') accent.set(27, c.integer('face.noseTipY'));
    if (piercing == 'septum') base.fillEllipse(24, c.integer('face.noseTipY') + 1, size, size);
    if (piercing == 'browPiercing') accent.set(c.integer('face.leftEyeX') - 2, c.integer('face.eyeY') - 3);
    if (piercing == 'lipRing') base.fillEllipse(27, c.integer('face.mouthY'), size, size);
    if (piercing == 'labret') accent.set(24, c.integer('face.mouthY') + 2);
    if (piercing == 'foreheadGem') accent.fillEllipse(24, c.integer('face.eyeY') - 5, size, size);

    final neckStyle = c.string('v4.neckJewelry');
    if (neckStyle != 'none') {
      final y = c.integer('body.neckBaseY') + 1;
      if (<String>['thinChain', 'thickChain', 'choker', 'beads'].contains(neckStyle)) {
        final thickness = neckStyle == 'thickChain' || neckStyle == 'choker' ? 2 : 1;
        base.line(17, y, 24, y + 3, thickness: thickness)
            .line(24, y + 3, 31, y, thickness: thickness);
        if (neckStyle == 'beads') for (var x = 18; x <= 30; x += 3) accent.set(x, y + positiveMod(x, 3));
      } else if (<String>['medallion', 'amulet', 'dogTags', 'royalMedallion'].contains(neckStyle)) {
        base.line(18, y, 24, y + 8).line(30, y, 24, y + 8);
        accent.fillEllipse(24, y + 8, size + 1, size + 1);
      } else if (neckStyle == 'scarf' || neckStyle == 'cravat') {
        base.fillRect(17, y - 1, 14, 4);
        base.fillTriangle((x: 21, y: y + 2), (x: 27, y: y + 2), (x: 24, y: y + 10));
      } else if (neckStyle == 'bowTie') {
        base.fillTriangle((x: 24, y: y + 2), (x: 16, y: y - 1), (x: 17, y: y + 5));
        base.fillTriangle((x: 24, y: y + 2), (x: 32, y: y - 1), (x: 31, y: y + 5));
        accent.set(24, y + 2);
      } else if (neckStyle == 'tie') {
        base.fillTriangle((x: 21, y: y), (x: 27, y: y), (x: 24, y: y + 11));
      }
    }
    if (animationChannelEnabled(
      c.string('v4.animation'),
      'jewelrySwing',
    )) {
      final speed = clampInt(c.integer('v4.animationSpeed'), 1, 6);
      final amplitude = clampInt(c.integer('v4.animationAmplitude'), 1, 2);
      final swingX = cyclicOffset(
        c.phase - 1,
        animationPeriod(speed, slow: 18, fast: 10),
        amplitude,
      );
      if (swingX != 0) {
        final earY = c.integer('ears.centerY') + 4;
        final neckY = c.integer('body.neckBaseY') + 5;
        final movableZone = maskFromPredicate(
          (x, y) => y >= earY && (x < 18 || x > 30) || y >= neckY,
        );

        void swing(PixelMask target) {
          final movable = target.intersect(movableZone);
          if (movable.count == 0) return;
          final moved = target
              .subtract(movable)
              .union(movable.translated(swingX, 0));
          target.data.setAll(0, moved.data);
        }

        swing(base);
        swing(accent);
      }
    }

    light.data.setAll(0, accent.intersect(maskFromPredicate((x, y) => positiveMod(x + y, 2) == 0)).data);
    return _Jewelry(base, accent, light);
  }

  _Cyber _cyber(AvatarRenderContext c, AvatarRenderState state) {
    final base = PixelMask();
    final accent = PixelMask();
    final glow = PixelMask();
    final style = c.string('v4.cybernetics');
    final coverage = c.integer('v4.cyberCoverage');
    final glowAmount = c.integer('v4.cyberGlow');
    final eyeY = c.integer('face.eyeY');
    final mouthY = c.integer('face.mouthY');
    if (style == 'cyberEyeLeft' || style == 'cyberEyeRight') {
      final x = style == 'cyberEyeLeft' ? c.integer('face.leftEyeX') : c.integer('face.rightEyeX');
      base.fillEllipse(x, eyeY, 3 + coverage ~/ 2, 2 + coverage ~/ 3);
      glow.set(x, eyeY);
      accent.hLine(x - 2, x + 2, eyeY);
    } else if (style == 'metalJaw') {
      base.data.setAll(0, state.mask('chinZone').union(state.mask('jawRightZone')).intersect(
          maskFromPredicate((x, y) => y >= mouthY)).data);
      accent.hLine(18, 30, mouthY + 3).vLine(24, mouthY + 2, c.integer('head.bottomY'));
    } else if (style == 'templeImplant') {
      base.fillRect(13, eyeY - 4, 5 + coverage, 8);
      accent.line(15, eyeY - 2, 20, eyeY + 2);
    } else if (style == 'faceWires') {
      base.line(14, eyeY, 10, mouthY + 6).line(34, eyeY + 1, 39, mouthY + 5);
      glow.set(14, eyeY).set(34, eyeY + 1);
    } else if (style == 'cheekPlate') {
      base.fillTriangle((x: 29, y: eyeY + 2), (x: 36, y: mouthY - 2), (x: 29, y: mouthY + 3));
      accent.line(30, eyeY + 3, 33, mouthY);
    } else if (style == 'artificialEar') {
      base.fillRect(c.integer('head.rightX') + 1, c.integer('ears.centerY') - 4, 4 + coverage ~/ 2, 9);
      glow.set(c.integer('head.rightX') + 3, c.integer('ears.centerY'));
    } else if (style == 'scanner') {
      base.fillRect(c.integer('face.rightEyeX') - 2, eyeY - 2, 7, 5);
      glow.hLine(c.integer('face.rightEyeX') - 1, c.integer('face.rightEyeX') + 3, eyeY);
    } else if (style == 'halfFace') {
      base.data.setAll(0, state.mask('head').intersect(maskFromPredicate((x, y) => x >= 24)).data);
      for (var y = c.integer('head.topY') + 2; y < c.integer('head.bottomY'); y += 4) accent.hLine(25, 34, y);
    } else if (style == 'neckPorts') {
      base.fillRect(20, c.integer('body.neckTopY') + 2, 3, 3)
          .fillRect(26, c.integer('body.neckTopY') + 3, 3, 3);
      glow.set(21, c.integer('body.neckTopY') + 3).set(27, c.integer('body.neckTopY') + 4);
    } else if (style == 'chestReactor') {
      base.fillEllipse(24, 40, 4 + coverage ~/ 2, 4 + coverage ~/ 2);
      glow.fillEllipse(24, 40, 2 + glowAmount ~/ 2, 2 + glowAmount ~/ 2);
      accent.hLine(18, 30, 40).vLine(24, 35, 45);
    }

    final scar = c.string('v4.scar');
    if (scar == 'eyeVertical') accent.line(c.integer('face.leftEyeX'), eyeY - 5, c.integer('face.leftEyeX'), eyeY + 5);
    if (scar == 'eyeSlash') accent.line(c.integer('face.leftEyeX') - 4, eyeY - 4, c.integer('face.leftEyeX') + 4, eyeY + 4);
    if (scar == 'browScar') accent.line(c.integer('face.rightEyeX') - 2, eyeY - 4, c.integer('face.rightEyeX') + 1, eyeY - 2);
    if (scar == 'lipScar') accent.line(20, mouthY - 1, 25, mouthY + 3);
    if (scar == 'chinScar') accent.line(22, mouthY + 3, 26, c.integer('head.bottomY'));
    if (scar == 'smallScars') accent.line(15, eyeY + 2, 18, eyeY + 4).line(31, mouthY - 2, 34, mouthY);
    if (scar == 'stitches') {
      accent.line(16, eyeY + 3, 31, mouthY + 2);
      for (var i = 0; i < 5; i++) accent.line(18 + i * 3, eyeY + 2 + i, 18 + i * 3, eyeY + 4 + i);
    }
    if (scar == 'burn') accent.data.setAll(0, orderedDither(state.mask('lowerCheekRightZone'), 5).data);
    if (scar == 'mechanicalCrack') accent.line(15, eyeY, 20, eyeY + 5).line(20, eyeY + 5, 17, mouthY + 2);

    final marking = c.string('v4.marking');
    final markCoverage = c.integer('v4.markingCoverage');
    if (marking == 'tribal' || marking == 'warPaint') {
      for (var i = 0; i < markCoverage; i++) {
        accent.line(13, eyeY + i * 2, 19, eyeY + 2 + i * 2);
        accent.line(35, eyeY + i * 2, 29, eyeY + 2 + i * 2);
      }
    } else if (marking == 'runes' || marking == 'magicGlyphs') {
      accent.hLine(21, 27, eyeY - 5).vLine(24, eyeY - 7, eyeY - 3);
      glow.data.setAll(0, accent.dilated().intersect(state.mask('head')).data);
    } else if (marking == 'geometric') {
      accent.fillTriangle((x: 18, y: eyeY + 3), (x: 24, y: mouthY + 2), (x: 30, y: eyeY + 3));
    } else if (marking == 'clown') {
      accent.line(18, eyeY + 1, 15, mouthY).line(30, eyeY + 1, 33, mouthY);
      accent.hLine(18, 30, mouthY + 1);
    } else if (marking == 'skullPaint') {
      accent.data.setAll(0, state.mask('eyeSafety').union(state.mask('chinZone')).data);
    } else if (marking == 'camouflage') {
      accent.data.setAll(0, orderedDither(state.mask('faceInner'), 4).data);
    } else if (marking == 'cyberLines') {
      accent.line(14, eyeY, 20, eyeY).line(20, eyeY, 20, mouthY);
      glow.set(14, eyeY).set(20, mouthY);
    }
    if (glowAmount == 0) glow.data.fillRange(0, glow.data.length, 0);
    return _Cyber(base, accent, glow);
  }
}

final class _Headwear {
  const _Headwear(this.base, this.shadow, this.light, this.accent);
  factory _Headwear.empty() => _Headwear(PixelMask(), PixelMask(), PixelMask(), PixelMask());
  final PixelMask base;
  final PixelMask shadow;
  final PixelMask light;
  final PixelMask accent;
}

final class _Eyewear {
  const _Eyewear(this.frame, this.lens, this.reflection, this.darkLens);
  factory _Eyewear.empty() => _Eyewear(PixelMask(), PixelMask(), PixelMask(), false);
  final PixelMask frame;
  final PixelMask lens;
  final PixelMask reflection;
  final bool darkLens;
}

final class _FaceMask {
  const _FaceMask(this.base, this.shadow, this.accent);
  factory _FaceMask.empty() => _FaceMask(PixelMask(), PixelMask(), PixelMask());
  final PixelMask base;
  final PixelMask shadow;
  final PixelMask accent;
}

final class _Jewelry {
  const _Jewelry(this.base, this.accent, this.light);
  final PixelMask base;
  final PixelMask accent;
  final PixelMask light;
}

final class _Cyber {
  const _Cyber(this.base, this.accent, this.glow);
  final PixelMask base;
  final PixelMask accent;
  final PixelMask glow;
}
