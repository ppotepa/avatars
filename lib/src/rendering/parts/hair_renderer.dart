import '../../pixels/pixel_mask.dart';
import '../../util/math_utils.dart';
import '../render_helpers.dart';
import '../render_model.dart';

/// Builds modular hair, balding, facial hair and base fantasy anatomy.
final class HairRenderer implements AvatarPartRenderer {
  const HairRenderer();

  @override
  void render(AvatarRenderContext context, AvatarRenderState state) {
    final head = state.mask('head');
    if (head.count == 0) return;
    final hair = _hair(context, head, state);
    final facialHair = _facialHair(context, state);
    final fantasy = _fantasy(context, head, state);

    state
      ..putMask('hair.back', hair.back)
      ..putMask('hair.front', hair.front)
      ..putMask('hair.all', hair.back.union(hair.front))
      ..putMask('facialHair', facialHair.base)
      ..putMask('horns', fantasy.back.union(fantasy.front));

    state
      ..addLayer('fantasy.back.outline', 6,
          fantasy.back.outline(diagonal: true), context.color('outline'),
          meta: const {'part': 'fantasy'})
      ..addLayer('fantasy.back', 7, fantasy.back, context.color('fantasyBase'),
          meta: const {'part': 'fantasy'})
      ..addLayer('hair.back.outline', 16, hair.back.outline(diagonal: true),
          context.color('outline'),
          meta: const {'part': 'hair'})
      ..addLayer('hair.back', 18, hair.back, context.color('hairBase'),
          meta: const {'part': 'hair'})
      ..addLayer(
          'hair.back.shadow', 19, hair.backShadow, context.color('hairShadow'),
          meta: const {'part': 'hair'})
      ..addLayer(
          'hair.back.light', 20, hair.backLight, context.color('hairLight'),
          meta: const {'part': 'hair'})
      ..addLayer('facialHair.shadow', 126, facialHair.shadow,
          _facialHairColor(context, shadow: true),
          meta: const {'part': 'facialHair'})
      ..addLayer('facialHair', 128, facialHair.base, _facialHairColor(context),
          meta: const {'part': 'facialHair'})
      ..addLayer(
          'facialHair.light', 129, facialHair.light, context.color('hairLight'),
          meta: const {'part': 'facialHair'})
      ..addLayer(
          'hair.front.outline',
          136,
          hair.front.outline(diagonal: true).subtract(hair.back),
          context.color('outline'),
          meta: const {'part': 'hair'})
      ..addLayer('hair.front', 138, hair.front, context.color('hairBase'),
          meta: const {'part': 'hair'})
      ..addLayer('hair.front.shadow', 139, hair.frontShadow,
          context.color('hairShadow'),
          meta: const {'part': 'hair'})
      ..addLayer(
          'hair.front.light', 140, hair.frontLight, context.color('hairLight'),
          meta: const {'part': 'hair'})
      ..addLayer('hair.gray', 141, hair.gray, context.color('hairGray'),
          meta: const {'part': 'hair'})
      ..addLayer('hair.part', 142, hair.part, context.color('hairDeep'),
          meta: const {'part': 'hair'})
      ..addLayer('fantasy.front.outline', 149,
          fantasy.front.outline(diagonal: true), context.color('outline'),
          meta: const {'part': 'fantasy'})
      ..addLayer(
          'fantasy.front', 150, fantasy.front, context.color('fantasyBase'),
          meta: const {'part': 'fantasy'})
      ..addLayer('fantasy.marking', 151, fantasy.marking,
          context.color('fantasyLight'),
          meta: const {'part': 'fantasy'});
  }

  _HairResult _hair(
    AvatarRenderContext c,
    PixelMask head,
    AvatarRenderState state,
  ) {
    final lengthStyle = c.string('hair.lengthStyle');
    final balding = c.string('hair.balding');
    if (lengthStyle == 'none' || balding == 'fullBald') {
      return _HairResult.empty();
    }
    final headBounds = head.bounds;
    if (headBounds == null) return _HairResult.empty();
    final topY = c.integer('head.topY');
    final eyeY = c.integer('face.eyeY');
    final bottomY = c.integer('head.bottomY');
    final volumeTop = c.integer('hair.actualTopVolume');
    final volumeSides = c.integer('hair.volumeSides');
    final volumeBack = c.integer('hair.volumeBack');
    final length = c.integer('hair.length');
    final hairlineY = _hairlineY(c, topY, eyeY);

    var back = PixelMask();
    var front = PixelMask();
    final part = PixelMask();

    // Back silhouette is generated row-by-row around the anatomical head.
    final extension = _lengthExtension(lengthStyle, length);
    final maxBackY = clampInt(bottomY + extension, topY, 47);
    for (var y = clampInt(topY - volumeTop, 0, 47); y <= maxBackY; y++) {
      final sourceY = clampInt(y, topY, bottomY);
      final row = rowBounds(head, sourceY);
      if (row == null) continue;
      final verticalRatio =
          (y - (topY - volumeTop)) / (maxBackY - (topY - volumeTop) + 1);
      var sideExtra = volumeSides;
      if (y > bottomY) sideExtra += volumeBack + (verticalRatio * 2).round();
      if (lengthStyle == 'veryShort' || lengthStyle == 'shaved') sideExtra = 0;
      if (c.string('hair.back') == 'narrow') sideExtra -= 2;
      if (c.string('hair.back') == 'wide') sideExtra += 2;
      final left = row.left - sideExtra;
      final right = row.right + sideExtra;
      back.hLine(left, right, y);
    }

    // Crown/top mass. Each strategy creates a connected silhouette rather than
    // deleting random pixels.
    final topMass = c.string('hair.topMass');
    if (topMass != 'none' && lengthStyle != 'shaved') {
      final crown = _crown(c, headBounds.left + headBounds.width ~/ 2, topY,
          headBounds.width, volumeTop, topMass);
      back = back.union(crown);
    }

    // Front cap follows head rows and a parameterized hairline.
    for (var y = topY; y <= clampInt(hairlineY, topY, eyeY + 2); y++) {
      final row = rowBounds(head, y);
      if (row == null) continue;
      var left = row.left;
      var right = row.right;
      final temples =
          c.integer('hair.templeDepth') + c.integer('hair.recession');
      if (y >= hairlineY - 2) {
        left += temples ~/ 2;
        right -= temples ~/ 2;
      }
      front.hLine(left, right, y);
    }

    front = front.union(_fringe(c, head, hairlineY, eyeY));
    front = front.union(_templesAndSides(c, head, hairlineY, bottomY));

    // Balding is a mask transformation, not an independent sprite.
    final removal = _baldingRemoval(c, head, hairlineY);
    back = back.subtract(removal);
    front = front.subtract(removal);
    if (balding == 'sidesOnly') {
      final middle = maskRect(18, topY - volumeTop, 12, bottomY - topY + 4);
      back = back.subtract(middle);
      front = front.subtract(middle);
    }
    if (balding == 'tuft') {
      back = PixelMask();
      front = PixelMask()
        ..fillTriangle((x: 22, y: topY + 1), (x: 26, y: topY + 1),
            (x: 24, y: clampInt(topY - volumeTop, 0, 47)));
    }

    // Hair density controls coherent edge recession and cluster thickness.
    final density = c.integer('hair.topDensity');
    if (density <= 1) {
      final core = front.eroded(diagonal: true);
      front = core.count > 0 ? core : front;
    } else if (density == 2) {
      front = front.subtract(front
          .outline()
          .intersect(maskFromPredicate((x, y) => positiveMod(x + y, 3) == 0)));
    } else if (density >= 5) {
      front = front.union(front.dilated().intersect(head));
    }

    // Optional compression is provided by the equipment planner.
    final compression = c.integer('v4.hairCompression');
    final headwear = c.string('v4.headwear');
    if (headwear != 'none' && compression > 0) {
      final compressedAbove =
          maskFromPredicate((x, y) => y < topY + clampInt(compression, 1, 5));
      front = front.subtract(compressedAbove);
      back = back.subtract(compressedAbove);
    }

    // Face safety: only declared eye-covering fringes may enter eye sockets.
    final eyeSafety = state.mask('eyeSafety');
    final mouthSafety = state.mask('mouthSafety');
    final noseZone = state.mask('noseZone');
    final fringe = c.string('hair.fringe');
    if (!<String>['oneEye', 'bothEyes'].contains(fringe)) {
      front = front.subtract(eyeSafety);
    } else if (fringe == 'oneEye') {
      final protectedSide = c.integer('hair.partPosition') <= 0
          ? maskFromPredicate((x, y) => x >= 24)
          : maskFromPredicate((x, y) => x < 24);
      front = front.subtract(eyeSafety.intersect(protectedSide));
    }
    front = front.subtract(mouthSafety).subtract(noseZone);

    if (c.string('v4.animation') == 'hairWind') {
      final speed = clampInt(c.integer('v4.animationSpeed'), 1, 6);
      final amplitude = clampInt(c.integer('v4.animationAmplitude'), 1, 2);
      final windX = cyclicOffset(c.phase, 9 + speed * 2, amplitude);
      if (windX != 0) {
        final lowerBackZone = maskFromPredicate((x, y) => y >= eyeY + 2);
        final lowerBack = back.intersect(lowerBackZone);
        final lowerSeam = back.intersect(
          maskFromPredicate((x, y) => y == eyeY + 1 || y == eyeY + 2),
        );
        if (lowerBack.count > 0) {
          back = back
              .subtract(lowerBack)
              .union(lowerBack.translated(windX, 0))
              .union(lowerSeam);
        }

        final sideFrontZone = maskFromPredicate((x, y) =>
            y >= hairlineY + 1 &&
            (x <= headBounds.left + 4 || x >= headBounds.right - 4));
        final sideFront = front.intersect(sideFrontZone);
        if (sideFront.count > 0) {
          front =
              front.subtract(sideFront).union(sideFront.translated(windX, 0));
        }
        front = front.subtract(mouthSafety).subtract(noseZone);
        if (!<String>['oneEye', 'bothEyes'].contains(fringe)) {
          front = front.subtract(eyeSafety);
        }
      }
    }

    back = largestComponent(back).removeSmallComponents(2, maxComponents: 2);
    front = front.removeSmallComponents(1, maxComponents: 8);

    _drawParting(c, part, front, hairlineY, topY);
    final gray = _gray(c, back.union(front), topY, hairlineY);
    final backShadow =
        shadingMask(back, kind: 'hair', strength: 2, eyeY: eyeY, topY: topY);
    final backLight =
        highlightMask(back, kind: 'hair', strength: 2, eyeY: eyeY, topY: topY);
    final frontShadow =
        shadingMask(front, kind: 'hair', strength: 2, eyeY: eyeY, topY: topY);
    var frontLight =
        highlightMask(front, kind: 'hair', strength: 2, eyeY: eyeY, topY: topY);
    frontLight = frontLight.union(_textureHighlights(c, front));

    return _HairResult(back, front, backShadow, backLight, frontShadow,
        frontLight, gray, part.intersect(front));
  }

  int _hairlineY(AvatarRenderContext c, int topY, int eyeY) {
    var y = topY + c.integer('hair.hairlineHeight');
    final variant = c.string('hair.hairline');
    if (variant == 'veryLow') y -= 2;
    if (variant == 'low') y -= 1;
    if (variant == 'high') y += 1;
    if (variant == 'veryHigh' || variant == 'receded') y += 2;
    if (variant == 'deepTemples') y += 1;
    if (variant == 'hidden') y = eyeY + 1;
    return clampInt(y, topY, eyeY + 2);
  }

  int _lengthExtension(String style, int length) {
    final base = switch (style) {
      'shaved' => 0,
      'veryShort' => 1,
      'short' => 2,
      'ear' => 4,
      'jaw' => 7,
      'neck' => 10,
      'shoulder' => 14,
      'belowShoulder' => 18,
      _ => 2,
    };
    return clampInt(base + length ~/ 4, 0, 19);
  }

  PixelMask _crown(
    AvatarRenderContext c,
    int centerX,
    int topY,
    int headWidth,
    int volume,
    String style,
  ) {
    final mask = PixelMask();
    if (volume <= 0) return mask;
    final crownTop = clampInt(topY - volume, 0, 47);
    final half = headWidth ~/ 2;
    if (style == 'flat') {
      mask.fillRect(centerX - half + 2, crownTop, headWidth - 4, volume + 2);
    } else if (style == 'mohawk') {
      final width = clampInt(2 + volume ~/ 2, 2, 6);
      mask.fillTriangle(
          (x: centerX - width, y: topY + 2),
          (x: centerX + width, y: topY + 2),
          (x: centerX + c.integer('hair.partPosition') ~/ 2, y: crownTop));
    } else if (style == 'spiky' || c.string('hair.texture') == 'spiky') {
      final spikes = clampInt(3 + c.integer('hair.volumeTop') ~/ 2, 3, 7);
      for (var i = 0; i < spikes; i++) {
        final x =
            centerX - half + 2 + ((headWidth - 4) * i / (spikes - 1)).round();
        final spikeTop = clampInt(crownTop + positiveMod(i * 2, 3), 0, 47);
        mask.fillTriangle((x: x - 2, y: topY + 2), (x: x + 2, y: topY + 2),
            (x: x, y: spikeTop));
      }
    } else if (style == 'angular') {
      mask.fillTriangle(
          (x: centerX - half, y: topY + 3),
          (x: centerX + half, y: topY + 3),
          (x: centerX - c.integer('hair.partPosition'), y: crownTop));
    } else if (style == 'tuft') {
      mask.fillTriangle((x: centerX - 3, y: topY + 2),
          (x: centerX + 3, y: topY + 2), (x: centerX, y: crownTop));
    } else if (style == 'afro') {
      mask.fillEllipse(
          centerX, topY + 1, half + c.integer('hair.volumeSides'), volume + 4);
    } else if (style == 'curly') {
      for (var x = centerX - half; x <= centerX + half; x += 3) {
        mask.fillEllipse(x, topY, 2, volume ~/ 2 + 1);
      }
    } else {
      mask.fillEllipse(
          centerX, topY + 2, half, style == 'high' ? volume + 2 : volume);
    }
    return mask;
  }

  PixelMask _fringe(
    AvatarRenderContext c,
    PixelMask head,
    int hairlineY,
    int eyeY,
  ) {
    final style = c.string('hair.fringe');
    final result = PixelMask();
    if (style == 'none') return result;
    final length = c.integer('hair.fringeLength');
    final density = c.integer('hair.fringeDensity');
    final left = c.integer('head.leftX') + 1;
    final right = c.integer('head.rightX') - 1;
    final targetY = clampInt(hairlineY + length, hairlineY, eyeY + 2);
    if (style == 'shortStraight' || style == 'straight') {
      result.fillRect(left + 2, hairlineY - 1, right - left - 3,
          clampInt(targetY - hairlineY + 1, 1, 8));
    } else if (style == 'straightLong' || style == 'bothEyes') {
      result.fillRect(left + 1, hairlineY - 1, right - left - 1,
          clampInt(targetY - hairlineY + 2, 1, 11));
    } else if (style == 'sideLeft' || style == 'oneEye') {
      result.fillTriangle((x: left, y: hairlineY), (x: right - 2, y: hairlineY),
          (x: left + 4, y: targetY));
    } else if (style == 'sideRight') {
      result.fillTriangle((x: left + 2, y: hairlineY), (x: right, y: hairlineY),
          (x: right - 4, y: targetY));
    } else if (style == 'split' || style == 'curtain') {
      result.fillTriangle(
          (x: left, y: hairlineY), (x: 23, y: hairlineY), (x: 20, y: targetY));
      result.fillTriangle(
          (x: 25, y: hairlineY), (x: right, y: hairlineY), (x: 28, y: targetY));
    } else if (style == 'singleTuft') {
      result.fillTriangle(
          (x: 21, y: hairlineY), (x: 27, y: hairlineY), (x: 24, y: targetY));
    } else if (style == 'choppy' || style == 'uneven') {
      final strands = clampInt(3 + density, 3, 7);
      for (var i = 0; i < strands; i++) {
        final x = left + 2 + ((right - left - 4) * i / (strands - 1)).round();
        final y = targetY - positiveMod(i * 2 + density, 3);
        result.fillTriangle(
            (x: x - 2, y: hairlineY), (x: x + 2, y: hairlineY), (x: x, y: y));
      }
    } else if (style == 'asymmetric') {
      result.fillTriangle((
        x: left,
        y: hairlineY
      ), (
        x: right,
        y: hairlineY
      ), (
        x: c.integer('hair.partPosition') <= 0 ? left + 5 : right - 5,
        y: targetY
      ));
    }
    return result.intersect(head.dilated());
  }

  PixelMask _templesAndSides(
    AvatarRenderContext c,
    PixelMask head,
    int hairlineY,
    int bottomY,
  ) {
    final style = c.string('hair.sides');
    final mask = PixelMask();
    if (style == 'none' || style == 'shaved') return mask;
    final coverage = c.integer('hair.earCoverage');
    final extra = c.integer('hair.volumeSides');
    var sideBottom = hairlineY + 4 + coverage;
    if (<String>['longStrands', 'coverEars'].contains(style))
      sideBottom = bottomY + 2;
    if (style == 'partialEars') sideBottom = c.integer('face.eyeY') + 6;
    for (var y = hairlineY; y <= clampInt(sideBottom, hairlineY, 47); y++) {
      final row = rowBounds(head, clampInt(y, c.integer('head.topY'), bottomY));
      if (row == null) continue;
      var thickness = style == 'veryShort' ? 1 : 2 + extra ~/ 2;
      if (style == 'outward') thickness += 2;
      mask.hLine(row.left - extra, row.left + thickness, y);
      mask.hLine(row.right - thickness, row.right + extra, y);
    }
    if (style == 'asymmetric') {
      return mask.subtract(
          maskFromPredicate((x, y) => x > 24 && positiveMod(y, 2) == 0));
    }
    return mask;
  }

  PixelMask _baldingRemoval(
    AvatarRenderContext c,
    PixelMask head,
    int hairlineY,
  ) {
    final style = c.string('hair.balding');
    final removal = PixelMask();
    if (style == 'none' || style == 'shaved') return removal;
    final topY = c.integer('head.topY');
    final recession = c.integer('hair.recession');
    final crown = c.integer('hair.crownRadius');
    if (<String>[
      'slightRecession',
      'temples',
      'deepTemples',
      'frontal',
      'frontCrown'
    ].contains(style)) {
      final depth = recession +
          (style == 'deepTemples'
              ? 3
              : style == 'temples'
                  ? 1
                  : 0);
      removal.fillTriangle(
          (x: c.integer('head.leftX'), y: hairlineY - 2),
          (x: 20, y: hairlineY - 2),
          (x: c.integer('head.leftX') + depth, y: hairlineY + depth));
      removal.fillTriangle(
          (x: 28, y: hairlineY - 2),
          (x: c.integer('head.rightX'), y: hairlineY - 2),
          (x: c.integer('head.rightX') - depth, y: hairlineY + depth));
    }
    if (<String>['crownThin', 'tonsure', 'frontCrown'].contains(style)) {
      final radius = clampInt(crown + (style == 'tonsure' ? 2 : 0), 1, 7);
      removal.fillEllipse(24, topY + 5, radius, clampInt(radius - 1, 1, 6));
    }
    if (style == 'frontal' || style == 'frontCrown') {
      removal.fillEllipse(24, hairlineY, 7 + recession, 3 + recession ~/ 2);
    }
    return removal.intersect(head.dilated());
  }

  void _drawParting(
    AvatarRenderContext c,
    PixelMask part,
    PixelMask front,
    int hairlineY,
    int topY,
  ) {
    final style = c.string('hair.parting');
    if (style == 'none' || front.count == 0) return;
    var x = 24 + c.integer('hair.partPosition');
    if (style == 'left') x -= 2;
    if (style == 'right') x += 2;
    if (style == 'deepLeft') x -= 4;
    if (style == 'deepRight') x += 4;
    if (style == 'zigzag') {
      part.line(x, topY + 1, x - 1, topY + 3);
      part.line(x - 1, topY + 3, x + 1, hairlineY);
    } else if (style == 'irregular') {
      part.line(x, topY + 1, x + 1, topY + 3);
      part.line(x + 1, topY + 3, x, hairlineY);
    } else {
      part.line(x, topY + 1, x, hairlineY);
    }
  }

  PixelMask _textureHighlights(AvatarRenderContext c, PixelMask hair) {
    final texture = c.string('hair.texture');
    final output = PixelMask();
    if (texture == 'smooth' || texture == 'straight') {
      for (var x = 16; x <= 31; x += 5) {
        output.vLine(x, c.integer('head.topY') + 1, c.integer('face.eyeY') - 2);
      }
    } else if (<String>['slightlyWavy', 'wavy', 'veryWavy'].contains(texture)) {
      final amplitude = texture == 'veryWavy' ? 2 : 1;
      for (var y = c.integer('head.topY');
          y < c.integer('head.bottomY');
          y += 3) {
        final x = 18 + positiveMod(y, 5) * amplitude;
        output.line(x, y, x + 4, y + 1);
        output.line(30 - positiveMod(y, 5) * amplitude, y, 26, y + 1);
      }
    } else if (<String>['curly', 'tightCurls', 'afro'].contains(texture)) {
      for (var y = c.integer('head.topY') - 1;
          y < c.integer('face.eyeY');
          y += 3) {
        for (var x = 15; x <= 33; x += texture == 'tightCurls' ? 2 : 3) {
          if (hair.get(x, y) != 0) output.set(x, y).set(x + 1, y + 1);
        }
      }
    } else if (texture == 'spiky' || texture == 'messy') {
      output.data.setAll(
          0,
          hair
              .outline()
              .intersect(maskFromPredicate((x, y) =>
                  y < c.integer('face.eyeY') && positiveMod(x + y, 3) == 0))
              .data);
    } else if (texture == 'fluffy') {
      output.data.setAll(
          0,
          hair
              .outline()
              .intersect(
                  maskFromPredicate((x, y) => x < 24 && positiveMod(y, 2) == 0))
              .data);
    } else if (texture == 'heavy') {
      output.data.setAll(
          0,
          hair
              .intersect(maskFromPredicate((x, y) =>
                  y > c.integer('face.eyeY') - 2 && positiveMod(x, 3) == 0))
              .data);
    }
    return output.intersect(hair);
  }

  PixelMask _gray(
    AvatarRenderContext c,
    PixelMask hair,
    int topY,
    int hairlineY,
  ) {
    final pattern = c.string('hair.grayingPattern');
    final amount = c.integer('hair.grayingAmount');
    if (pattern == 'none' || amount == 0) return PixelMask();
    PixelMask area;
    if (pattern == 'temples') {
      area = maskFromPredicate((x, y) =>
          (x < 18 || x > 29) && y >= hairlineY - 2 && y <= hairlineY + 7);
    } else if (pattern == 'front') {
      area = maskFromPredicate((x, y) => y >= topY && y <= hairlineY + 3);
    } else if (pattern == 'strands') {
      area = maskFromPredicate((x, y) => positiveMod(x * 3 + y, 7) == 0);
    } else if (pattern == 'full') {
      area = PixelMask.filled();
    } else {
      area = maskFromPredicate((x, y) => positiveMod(x + y, 6 - amount) == 0);
    }
    return hair.intersect(orderedDither(area, clampInt(amount + 2, 1, 8)));
  }

  _FacialHairResult _facialHair(
    AvatarRenderContext c,
    AvatarRenderState state,
  ) {
    final style = c.string('facialHair.style');
    if (style == 'none') return _FacialHairResult.empty();
    final growth = state.mask('beardGrowthZone');
    final mouthSafety = state.mask('mouthSafety');
    final eyes = state.mask('eyeSafety');
    final chin = state.mask('chinZone');
    final jaw = state.mask('jawLeftZone').union(state.mask('jawRightZone'));
    final cheeks = state
        .mask('lowerCheekLeftZone')
        .union(state.mask('lowerCheekRightZone'));
    final sideburns = state.mask('sideburnZone');
    final mouthY = c.integer('face.mouthY');
    final density = c.integer('facialHair.density');
    final length = c.integer('facialHair.length');
    final base = PixelMask();
    final shadow = PixelMask();
    final light = PixelMask();

    if (style == 'shadow' || style == 'stubble' || style == 'fullStubble') {
      var area = jaw.union(chin);
      if (style != 'shadow') area = area.union(cheeks);
      if (style == 'fullStubble') area = area.union(sideburns);
      final dither = orderedDither(area, clampInt(2 + density, 2, 7), phase: 1);
      if (style == 'shadow') {
        shadow.data.setAll(0, dither.data);
      } else {
        base.data.setAll(0, dither.data);
      }
    } else if (<String>['thinMustache', 'thickMustache', 'curledMustache']
        .contains(style)) {
      final thickness = style == 'thinMustache'
          ? 1
          : clampInt(c.integer('facialHair.mustacheThickness'), 1, 3);
      for (var t = 0; t < thickness; t++) {
        base.hLine(
            19 - (style == 'curledMustache' ? 1 : 0), 23, mouthY - 2 - t);
        base.hLine(
            25, 29 + (style == 'curledMustache' ? 1 : 0), mouthY - 2 - t);
      }
      if (style == 'curledMustache') {
        base.set(17, mouthY - 3).set(30, mouthY - 3);
      }
    } else if (style == 'goatee' || style == 'chinOnly') {
      final width = clampInt(c.integer('facialHair.chinCoverage') + 2, 3, 8);
      final bottom = clampInt(
          mouthY + 2 + length, mouthY + 3, c.integer('head.bottomY') + 5);
      base.fillTriangle((x: 24 - width / 2, y: mouthY + 2),
          (x: 24 + width / 2, y: mouthY + 2), (x: 24, y: bottom));
      if (style == 'goatee') {
        base.hLine(20, 23, mouthY - 2);
        base.hLine(25, 28, mouthY - 2);
      }
    } else if (style == 'sideburns') {
      final bottom =
          c.integer('face.eyeY') + c.integer('facialHair.sideburnLength');
      base.data.setAll(0,
          sideburns.intersect(maskFromPredicate((x, y) => y <= bottom)).data);
    } else {
      var beard = chin.union(jaw);
      final cheekCoverage = c.integer('facialHair.cheekCoverage');
      if (cheekCoverage > 0) {
        beard = beard
            .union(orderedDither(cheeks, clampInt(cheekCoverage + 2, 2, 7)));
      }
      if (<String>['longBeard', 'pointedBeard', 'squareBeard']
          .contains(style)) {
        final bottom = clampInt(c.integer('head.bottomY') + length, 0, 47);
        if (style == 'pointedBeard') {
          beard = beard.union(PixelMask()
            ..fillTriangle((x: 18, y: mouthY + 2), (x: 30, y: mouthY + 2),
                (x: 24, y: bottom)));
        } else {
          beard = beard.union(PixelMask()
            ..fillRect(18, mouthY + 2, 12, clampInt(bottom - mouthY, 2, 16)));
        }
      }
      base.data.setAll(0, beard.data);
      if (style == 'mustacheBeard') {
        base.hLine(19, 23, mouthY - 2);
        base.hLine(25, 29, mouthY - 2);
      }
      if (style == 'asymmetric') {
        final removed = base.intersect(
            maskFromPredicate((x, y) => x > 24 && positiveMod(x + y, 3) == 0));
        base.data.setAll(0, base.subtract(removed).data);
      }
    }

    final safeArea = growth
        .union(chin.dilated())
        .union(jaw.dilated())
        .subtract(mouthSafety)
        .subtract(eyes);
    var finalBase =
        base.intersect(safeArea).removeSmallComponents(1, maxComponents: 12);
    var finalShadow = shadow.intersect(safeArea);
    if (style.contains('Beard') ||
        <String>['shortBeard', 'longBeard', 'pointedBeard', 'squareBeard']
            .contains(style)) {
      finalShadow = finalShadow.union(shadingMask(finalBase,
          kind: 'hair',
          strength: 1,
          eyeY: c.integer('face.eyeY'),
          topY: mouthY));
      light.data.setAll(
          0,
          highlightMask(finalBase,
                  kind: 'hair',
                  strength: 1,
                  eyeY: c.integer('face.eyeY'),
                  topY: mouthY)
              .data);
    }
    // Ensure all output remains below the eye line even in extreme genomes.
    final belowEyes =
        maskFromPredicate((x, y) => y > c.integer('face.eyeY') + 1);
    finalBase = finalBase.intersect(belowEyes);
    finalShadow = finalShadow.intersect(belowEyes);
    return _FacialHairResult(
        finalBase, finalShadow, light.intersect(belowEyes));
  }

  _FantasyResult _fantasy(
    AvatarRenderContext c,
    PixelMask head,
    AvatarRenderState state,
  ) {
    final back = PixelMask();
    final front = PixelMask();
    final marking = PixelMask();
    final hornStyle = c.string('fantasy.hornStyle');
    final hornLength = c.integer('fantasy.hornLength');
    final hornWidth = c.integer('fantasy.hornWidth');
    final asym = c.integer('fantasy.hornAsymmetry');
    final topY = c.integer('head.topY');
    final headBounds = head.bounds;
    if (headBounds == null) return _FantasyResult(back, front, marking);
    final hornBaseLeft = headBounds.left + 2;
    final hornBaseRight = headBounds.right - 2;
    final topSpace = clampInt(topY + 1, 1, 24);
    final traitSwing = c.animation.traitSwingX();
    if (hornStyle != 'none' && hornLength > 0) {
      void horn(int baseX, int direction, int extraLength) {
        final curvature = clampInt(c.integer('fantasy.hornCurvature'), 0, 5);
        final fittedLength =
            clampInt(hornLength + extraLength, 1, topSpace + 2);
        final tipY = clampInt(topY - fittedLength, 0, 47);
        var tipX =
            baseX + direction * c.integer('fantasy.hornAngle') + traitSwing;
        if (<String>['sideways', 'ram', 'curved'].contains(hornStyle)) {
          tipX += direction * (fittedLength ~/ 2);
        }
        tipX = clampInt(tipX, 0, 47);
        final target =
            hornStyle == 'ram' || hornStyle == 'curved' ? back : front;
        if ((hornStyle == 'ram' || hornStyle == 'curved') && curvature > 0) {
          final midX = clampInt(
              baseX + direction * (fittedLength ~/ 3 + curvature), 0, 47);
          final midY =
              clampInt(topY - fittedLength ~/ 2 + curvature ~/ 2, 0, 47);
          target.fillTriangle((x: baseX - hornWidth, y: topY + 2),
              (x: baseX + hornWidth, y: topY + 2), (x: midX, y: midY));
          target.line(midX, midY, tipX, tipY,
              thickness: clampInt(hornWidth, 1, 3));
          if (curvature >= 3) {
            target.line(midX - direction, midY + 1, tipX - direction, tipY + 1);
          }
        } else {
          target.fillTriangle((x: baseX - hornWidth, y: topY + 2),
              (x: baseX + hornWidth, y: topY + 2), (x: tipX, y: tipY));
        }
        if (hornStyle == 'antler') {
          target.line(tipX, tipY + 2, tipX - direction * 3, tipY);
          target.line(tipX, tipY + 4, tipX + direction * 3, tipY + 1);
        }
      }

      if (hornStyle == 'single') {
        horn(24, 1, 0);
      } else {
        horn(hornBaseLeft, -1, asym < 0 ? 1 : 0);
        horn(hornBaseRight, 1, asym > 0 ? 1 : 0);
      }
    }

    final antenna = c.string('fantasy.antennaStyle');
    if (antenna != 'none') {
      final length =
          clampInt(c.integer('fantasy.antennaLength'), 1, topSpace + 2);
      final count = antenna == 'single' ? 1 : 2;
      for (var i = 0; i < count; i++) {
        final x = count == 1
            ? 24
            : (i == 0 ? headBounds.left + 4 : headBounds.right - 4);
        final direction = count == 1 ? 0 : (i == 0 ? -1 : 1);
        front.line(x, topY, x + direction * 2 + traitSwing,
            clampInt(topY - length, 0, 47));
        if (<String>['ballTip', 'fairy'].contains(antenna)) {
          front.fillEllipse(x + direction * 2 + traitSwing,
              clampInt(topY - length, 0, 47), 1, 1);
        }
      }
    }

    final markingStyle = c.string('fantasy.marking');
    final intensity = c.integer('fantasy.markingIntensity');
    final forehead = state.mask('foreheadZone');
    if (markingStyle == 'foreheadRune') {
      marking.line(
          24, c.integer('face.eyeY') - 7, 24, c.integer('face.eyeY') - 3);
      marking.hLine(22, 26, c.integer('face.eyeY') - 5);
    } else if (markingStyle == 'templeDots') {
      for (var i = 0; i < intensity; i++) {
        marking.set(16 - i, c.integer('face.eyeY') - 1 + i);
        marking.set(31 + i, c.integer('face.eyeY') - 1 + i);
      }
    } else if (markingStyle == 'cheekStripes') {
      for (var i = 0; i < intensity; i++) {
        marking.line(14, c.integer('face.mouthY') - 4 + i * 2, 18,
            c.integer('face.mouthY') - 3 + i * 2);
        marking.line(33, c.integer('face.mouthY') - 4 + i * 2, 29,
            c.integer('face.mouthY') - 3 + i * 2);
      }
    } else if (markingStyle == 'circuit') {
      marking.line(15, c.integer('face.eyeY'), 15, c.integer('face.mouthY'));
      marking.line(15, c.integer('face.mouthY'), 19, c.integer('face.mouthY'));
    } else if (markingStyle == 'scales') {
      marking.data.setAll(
          0,
          orderedDither(
                  state
                      .mask('lowerCheekLeftZone')
                      .union(state.mask('lowerCheekRightZone')),
                  intensity + 2)
              .data);
    } else if (markingStyle == 'star') {
      marking.hLine(22, 26, c.integer('face.eyeY') - 4);
      marking.vLine(24, c.integer('face.eyeY') - 6, c.integer('face.eyeY') - 2);
    } else if (markingStyle == 'thirdEye') {
      marking.fillEllipse(24, c.integer('face.eyeY') - 5, 2, 1);
      marking.set(24, c.integer('face.eyeY') - 5);
    }
    final allowedTop = maskFromPredicate((x, y) => y <= headBounds.bottom);
    return _FantasyResult(
      back.intersect(allowedTop).removeSmallComponents(1, maxComponents: 4),
      front.intersect(allowedTop).removeSmallComponents(1, maxComponents: 4),
      marking.intersect(head.union(forehead)),
    );
  }

  int _facialHairColor(AvatarRenderContext c, {bool shadow = false}) {
    final mode = c.string('facialHair.colorMode');
    if (mode == 'independent') return c.color('facialIndependent');
    if (mode == 'lighterHair')
      return c.color(shadow ? 'hairBase' : 'hairLight');
    if (mode == 'darkerHair') return c.color('hairShadow');
    return c.color(shadow ? 'hairShadow' : 'hairBase');
  }
}

final class _HairResult {
  const _HairResult(this.back, this.front, this.backShadow, this.backLight,
      this.frontShadow, this.frontLight, this.gray, this.part);
  factory _HairResult.empty() => _HairResult(
      PixelMask(),
      PixelMask(),
      PixelMask(),
      PixelMask(),
      PixelMask(),
      PixelMask(),
      PixelMask(),
      PixelMask());
  final PixelMask back;
  final PixelMask front;
  final PixelMask backShadow;
  final PixelMask backLight;
  final PixelMask frontShadow;
  final PixelMask frontLight;
  final PixelMask gray;
  final PixelMask part;
}

final class _FacialHairResult {
  const _FacialHairResult(this.base, this.shadow, this.light);
  factory _FacialHairResult.empty() =>
      _FacialHairResult(PixelMask(), PixelMask(), PixelMask());
  final PixelMask base;
  final PixelMask shadow;
  final PixelMask light;
}

final class _FantasyResult {
  const _FantasyResult(this.back, this.front, this.marking);
  final PixelMask back;
  final PixelMask front;
  final PixelMask marking;
}
