import '../../pixels/pixel_mask.dart';
import '../../util/math_utils.dart';
import '../render_helpers.dart';
import '../render_model.dart';

/// Renders face zones and features. The renderer owns no mutable global state;
/// all geometry comes from the resolved genome and anatomical head mask.
final class FaceRenderer implements AvatarPartRenderer {
  const FaceRenderer();

  @override
  void render(AvatarRenderContext context, AvatarRenderState state) {
    final head = state.mask('head');
    if (head.count == 0) return;

    final eyes = _eyes(context, head);
    final mouth = _mouth(context, head);
    final zones = _zones(context, head, eyes.combined, mouth.combined);
    final brows = _brows(context, head, eyes.combined, zones);
    final nose = _nose(context, head, eyes.combined, mouth.combined, zones);
    final cheeks = _cheeks(context, zones);
    final details = _skinDetails(context, zones, eyes.combined);

    state
      ..putMask('eye.left', eyes.left)
      ..putMask('eye.right', eyes.right)
      ..putMask('eyes', eyes.combined)
      ..putMask('eyeSafety', zones.eyeSafety)
      ..putMask('mouth', mouth.combined)
      ..putMask('mouthSafety', zones.mouthSafety)
      ..putMask('nose', nose.combined)
      ..putMask('noseZone', zones.noseZone)
      ..putMask('foreheadZone', zones.forehead)
      ..putMask('chinZone', zones.chin)
      ..putMask('jawLeftZone', zones.jawLeft)
      ..putMask('jawRightZone', zones.jawRight)
      ..putMask('lowerCheekLeftZone', zones.cheekLeft)
      ..putMask('lowerCheekRightZone', zones.cheekRight)
      ..putMask('sideburnZone', zones.sideburns)
      ..putMask('beardGrowthZone', zones.beardGrowth)
      ..putMask('centralFaceZone', zones.centralFace)
      ..putMask('faceInner', zones.inner);

    state
      ..addLayer('cheeks.shadow', 75, cheeks.shadow,
          context.color('skinShadow'), meta: const {'part': 'cheeks'})
      ..addLayer('cheeks.blush', 76, cheeks.blush,
          context.color('skinAccent'), meta: const {'part': 'cheeks'})
      ..addLayer('skin.details.shadow', 77, details.shadow,
          context.color('skinDeep'), meta: const {'part': 'skinDetails'})
      ..addLayer('skin.details.accent', 78, details.accent,
          context.color('skinAccent'), meta: const {'part': 'skinDetails'})
      ..addLayer('eyes.sclera', 90, eyes.sclera,
          context.color('sclera'), meta: const {'part': 'eyes'})
      ..addLayer('eyes.iris.dark', 92, eyes.irisDark,
          context.color('irisDark'), meta: const {'part': 'eyes'})
      ..addLayer('eyes.iris', 93, eyes.iris,
          context.color('irisBase'), meta: const {'part': 'eyes'})
      ..addLayer('eyes.iris.light', 94, eyes.irisLight,
          context.color('irisLight'), meta: const {'part': 'eyes'})
      ..addLayer('eyes.pupil', 95, eyes.pupil,
          context.color('pupil'), meta: const {'part': 'eyes'})
      ..addLayer('eyes.lids', 96, eyes.lids,
          context.color('outlineSoft'), meta: const {'part': 'eyes'})
      ..addLayer('eyes.lashes', 97, eyes.lashes,
          context.color('outline'), meta: const {'part': 'eyes'})
      ..addLayer('nose.shadow', 101, nose.shadow,
          context.color('skinShadow'), meta: const {'part': 'nose'})
      ..addLayer('nose.deep', 102, nose.deep,
          context.color('skinDeep'), meta: const {'part': 'nose'})
      ..addLayer('nose.highlight', 103, nose.highlight,
          context.color('skinLight'), meta: const {'part': 'nose'})
      ..addLayer('mouth.dark', 110, mouth.dark,
          _mouthDarkColor(context), meta: const {'part': 'mouth'})
      ..addLayer('mouth.base', 111, mouth.base,
          _mouthBaseColor(context), meta: const {'part': 'mouth'})
      ..addLayer('mouth.light', 112, mouth.light,
          context.color('mouthLight'), meta: const {'part': 'mouth'})
      ..addLayer('brows', 120, brows,
          _browColor(context), meta: const {'part': 'brows'});
  }

  _EyeResult _eyes(AvatarRenderContext c, PixelMask head) {
    final leftCenter = c.integer('face.leftEyeX');
    final rightCenter = c.integer('face.rightEyeX');
    final eyeY = c.integer('face.eyeY');
    final width = clampInt(c.integer('eyes.width'), 1, 7);
    final height = clampInt(c.integer('eyes.height'), 1, 4);
    final asymmetry = clampInt(c.integer('eyes.asymmetry'), -1, 1);

    final left = _oneEye(c, leftCenter, eyeY, width, height, -1);
    final right = _oneEye(c, rightCenter, eyeY + asymmetry, width, height, 1);

    PixelMask clip(PixelMask mask) => mask.intersect(head.eroded());
    return _EyeResult(
      left: clip(left.shape),
      right: clip(right.shape),
      sclera: clip(left.sclera.union(right.sclera)),
      irisDark: clip(left.irisDark.union(right.irisDark)),
      iris: clip(left.iris.union(right.iris)),
      irisLight: clip(left.irisLight.union(right.irisLight)),
      pupil: clip(left.pupil.union(right.pupil)),
      lids: clip(left.lids.union(right.lids)),
      lashes: clip(left.lashes.union(right.lashes)),
    );
  }

  _SingleEye _oneEye(
    AvatarRenderContext c,
    int centerX,
    int centerY,
    int width,
    int height,
    int side,
  ) {
    final shape = c.string('eyes.shape');
    final outline = PixelMask();
    final sclera = PixelMask();
    final iris = PixelMask();
    final irisDark = PixelMask();
    final irisLight = PixelMask();
    final pupil = PixelMask();
    final lids = PixelMask();
    final lashes = PixelMask();
    final angle = clampInt(c.integer('eyes.outerAngle'), -2, 2);
    final left = centerX - width ~/ 2;
    final top = centerY - height ~/ 2;

    if (shape == 'dot') {
      outline.set(centerX, centerY);
    } else if (shape == 'twoPixel') {
      outline.hLine(centerX - 1, centerX, centerY);
    } else if (shape == 'vertical') {
      outline.vLine(centerX, top, top + height - 1);
    } else if (shape == 'triangular') {
      outline.fillTriangle(
        (x: left, y: top + height - 1),
        (x: left + width - 1, y: top + height - 1 - angle * side),
        (x: centerX, y: top),
      );
    } else if (shape == 'robotic') {
      outline.fillRect(left, top, width, height);
      outline
        ..set(left, top, false)
        ..set(left + width - 1, top, false)
        ..set(left, top + height - 1, false)
        ..set(left + width - 1, top + height - 1, false);
    } else if (shape == 'rectangular') {
      outline.fillRect(left, top, width, height);
    } else if (shape == 'narrow' || shape == 'horizontal' || shape == 'deepSet') {
      outline.line(left, centerY, left + width - 1, centerY + angle * side.sign,
          thickness: height > 2 ? 2 : 1);
    } else if (shape == 'upturned' || shape == 'downturned') {
      final direction = shape == 'upturned' ? -1 : 1;
      outline.line(left, centerY, centerX, centerY - direction * side,
          thickness: height > 2 ? 2 : 1);
      outline.line(centerX, centerY - direction * side,
          left + width - 1, centerY + direction * side,
          thickness: height > 2 ? 2 : 1);
    } else if (shape == 'almond' || shape == 'realistic') {
      outline.line(left, centerY, centerX, top, thickness: 1);
      outline.line(centerX, top, left + width - 1, centerY + angle * side.sign,
          thickness: 1);
      outline.line(left, centerY, centerX, top + height - 1, thickness: 1);
      outline.line(centerX, top + height - 1, left + width - 1,
          centerY + angle * side.sign, thickness: 1);
      if (shape == 'realistic' && width >= 5 && height >= 3) {
        outline.hLine(left + 1, left + width - 2, centerY);
      }
    } else {
      final rx = (width - 1) / 2;
      final ry = shape == 'round'
          ? clampDouble(rx, .5, (height + 1) / 2)
          : shape == 'cartoon' || shape == 'wide'
              ? (height + 1) / 2
              : (height - 1) / 2;
      outline.fillEllipse(centerX, centerY, rx, ry < .5 ? .5 : ry);
    }

    // Solid black is intentionally a pupil-only silhouette.
    if (shape == 'solidBlack') {
      pupil.data.setAll(0, outline.data);
      return _SingleEye(outline, PixelMask(), PixelMask(), PixelMask(),
          PixelMask(), pupil, PixelMask(), PixelMask());
    }

    final interior = outline.eroded(diagonal: false);
    final scleraVisibility = clampInt(c.integer('eyes.scleraVisibility'), 0, 3);
    if (outline.count <= 3 || scleraVisibility == 0) {
      sclera.set(centerX, centerY);
    } else {
      final candidate = interior.count > 0 ? interior : outline;
      for (var y = 0; y < 48; y++) {
        for (var x = 0; x < 48; x++) {
          if (candidate.get(x, y) != 0 &&
              (scleraVisibility >= 2 || x == centerX || y == centerY)) {
            sclera.set(x, y);
          }
        }
      }
    }

    final irisStyle = c.string('eyes.irisStyle');
    final irisSize = clampInt(c.integer('eyes.irisSize'), 0, 3);
    if (irisStyle != 'none') {
      final radius = irisStyle == 'full'
          ? 2
          : irisStyle == 'large'
              ? 2
              : clampInt(irisSize, 1, 2);
      if (irisStyle == 'pixel' || width <= 2 || height <= 1) {
        iris.set(centerX, centerY);
      } else if (irisStyle == 'ring') {
        final ring = PixelMask()..fillEllipse(centerX, centerY, radius, radius);
        iris.data.setAll(0, ring.subtract(PixelMask()..set(centerX, centerY)).data);
      } else {
        iris.fillEllipse(centerX, centerY, radius, radius);
      }
      iris.data.setAll(0, iris.intersect(outline.dilated()).data);
      if (irisStyle == 'twoTone') {
        irisDark.data.setAll(0,
            iris.intersect(maskFromPredicate((x, y) => x <= centerX)).data);
        irisLight.data.setAll(0,
            iris.intersect(maskFromPredicate((x, y) => x > centerX && y <= centerY)).data);
      } else if (irisStyle == 'glow') {
        irisLight.data.setAll(0, iris.dilated().intersect(outline).data);
      } else {
        irisDark.data.setAll(0,
            iris.intersect(maskFromPredicate((x, y) => y > centerY)).data);
        irisLight.set(centerX - 1, centerY - 1);
      }
    }

    final pupilStyle = c.string('eyes.pupilStyle');
    final pupilSize = clampInt(c.integer('eyes.pupilSize'), 1, 3);
    if (pupilStyle != 'none') {
      if (pupilStyle == 'vertical') {
        pupil.vLine(centerX, centerY - pupilSize ~/ 2,
            centerY + pupilSize ~/ 2);
      } else if (pupilStyle == 'horizontal') {
        pupil.hLine(centerX - pupilSize ~/ 2,
            centerX + pupilSize ~/ 2, centerY);
      } else if (pupilStyle == 'square') {
        pupil.fillRect(centerX - pupilSize ~/ 2,
            centerY - pupilSize ~/ 2, pupilSize, pupilSize);
      } else if (pupilStyle == 'fullBlack') {
        pupil.data.setAll(0, (iris.count > 0 ? iris : outline).data);
      } else {
        final radius = pupilStyle == 'large'
            ? 1.5
            : pupilStyle == 'medium'
                ? 1.0
                : .4;
        pupil.fillEllipse(centerX, centerY, radius, radius);
      }
      pupil.data.setAll(0, pupil.intersect(outline.dilated()).data);
      if (pupilStyle == 'glowing') {
        irisLight.data.setAll(0, irisLight.union(pupil.dilated()).intersect(outline).data);
      }
    }

    if (animationChannelEnabled(c.string('v4.animation'), 'lookAround')) {
      final speed = clampInt(c.integer('v4.animationSpeed'), 1, 6);
      final amplitude = clampInt(c.integer('v4.animationAmplitude'), 1, 2);
      final lookX = cyclicOffset(
        c.phase,
        animationPeriod(speed, slow: 20, fast: 10),
        amplitude,
      );
      if (lookX != 0) {
        void shiftInsideEye(PixelMask target) {
          final shifted = target.translated(lookX, 0).intersect(outline);
          target.data.setAll(0, shifted.data);
        }

        shiftInsideEye(irisDark);
        shiftInsideEye(iris);
        shiftInsideEye(irisLight);
        shiftInsideEye(pupil);
      }
    }

    final eyelid = c.string('eyes.eyelid');
    final lidThickness = clampInt(c.integer('eyes.lidThickness'), 0, 2);
    if (eyelid != 'none' && lidThickness > 0 && outline.count > 2) {
      final upper = PixelMask()..line(left, top, left + width - 1,
          top + angle * side.sign, thickness: lidThickness);
      final lower = PixelMask()..line(left, top + height - 1,
          left + width - 1, top + height - 1 + angle * side.sign,
          thickness: 1);
      if (<String>['upper', 'heavy', 'drooping', 'double', 'both'].contains(eyelid)) {
        lids.data.setAll(0, lids.union(upper).data);
      }
      if (<String>['lower', 'both'].contains(eyelid)) {
        lids.data.setAll(0, lids.union(lower).data);
      }
      if (eyelid == 'drooping') {
        lids.set(left + (side < 0 ? 0 : width - 1), top + 1);
      }
      if (eyelid == 'double') {
        lids.data.setAll(0, lids.union(upper.translated(0, -1)).data);
      }
    }

    final lashStyle = c.string('eyes.lashes');
    final lashLength = clampInt(c.integer('eyes.lashLength'), 0, 3);
    if (lashStyle != 'none' && lashLength > 0 && width >= 2) {
      final outerX = side < 0 ? left : left + width - 1;
      final innerX = side < 0 ? left + width - 1 : left;
      final direction = side < 0 ? -1 : 1;
      if (<String>['single', 'short', 'medium', 'long', 'outerShort', 'outerLong', 'stylized', 'upper'].contains(lashStyle)) {
        lashes.line(outerX, top, outerX + direction * lashLength,
            top - clampInt(lashLength, 1, 2));
      }
      if (<String>['medium', 'long', 'stylized', 'upper'].contains(lashStyle)) {
        lashes.line(centerX, top, centerX, top - lashLength);
      }
      if (lashStyle == 'stylized') {
        lashes.line(innerX, top, innerX - direction, top - 1);
      }
      if (lashStyle == 'lower') {
        lashes.line(outerX, top + height - 1,
            outerX + direction * lashLength, top + height);
      }
    }

    if (animationChannelEnabled(c.string('v4.animation'), 'blink')) {
      final speed = clampInt(c.integer('v4.animationSpeed'), 1, 6);
      final cycleLength = animationPeriod(speed, slow: 16, fast: 9);
      final step = positiveMod(c.phase + 3, cycleLength);
      final remaining = cycleLength - step;
      final closing = remaining == 4 || remaining == 1
          ? 1
          : remaining == 3 || remaining == 2
              ? 2
              : 0;
      if (closing > 0) {
        final visibleBand = maskFromPredicate(
          (x, y) => closing == 1
              ? y >= centerY && y <= centerY + 1
              : y == centerY,
        );
        for (final mask in <PixelMask>[
          sclera,
          irisDark,
          iris,
          irisLight,
          pupil,
        ]) {
          mask.data.setAll(0, mask.intersect(visibleBand).data);
        }
        lids.data.fillRange(0, lids.data.length, 0);
        lashes.data.fillRange(0, lashes.data.length, 0);
        lids.line(
          left,
          centerY,
          left + width - 1,
          centerY + angle * side.sign,
          thickness: closing == 2 ? 2 : 1,
        );
      }
    }

    return _SingleEye(outline, sclera.intersect(outline), irisDark,
        iris.intersect(outline), irisLight.intersect(outline), pupil,
        lids, lashes);
  }

  PixelMask _brows(
    AvatarRenderContext c,
    PixelMask head,
    PixelMask eyes,
    _FaceZones zones,
  ) {
    final shape = c.string('brows.shape');
    if (shape == 'none' || c.integer('brows.thickness') == 0) {
      return PixelMask();
    }
    var width = clampInt(c.integer('brows.width'), 2, 9);
    if (shape == 'short') width = clampInt(width - 2, 2, 9);
    if (shape == 'long') width = clampInt(width + 2, 2, 10);
    final thickness = clampInt(c.integer('brows.thickness'), 1, 3);
    final eyeY = c.integer('face.eyeY');
    final height = clampInt(c.integer('brows.height'), -1, 5);
    final spacing = clampInt(c.integer('brows.spacing'), 1, 8);
    final centerGap = spacing ~/ 2;
    final leftCenter = c.integer('face.leftEyeX') - centerGap ~/ 2;
    final rightCenter = c.integer('face.rightEyeX') + centerGap ~/ 2;
    final asym = clampInt(c.integer('brows.asymmetry'), -1, 1);

    PixelMask one(int centerX, int side, int yOffset) {
      final base = PixelMask();
      final start = centerX - width ~/ 2;
      final baseY = eyeY - 2 - height + yOffset;
      final arch = clampInt(c.integer('brows.arch'), -2, 3);
      for (var i = 0; i < width; i++) {
        final normalized = width <= 1 ? 0.0 : i / (width - 1);
        var y = baseY;
        if (<String>['rounded', 'highArch', 'lowArch', 'bushy'].contains(shape)) {
          final peak = (1 - (normalized * 2 - 1).abs());
          var amplitude = arch.abs() + (shape == 'highArch' ? 2 : 1);
          if (shape == 'lowArch') amplitude = (amplitude / 2).ceil();
          y -= (peak * amplitude).round() * (arch >= 0 ? 1 : -1);
        } else if (shape == 'angular') {
          y -= i < width ~/ 2 ? i ~/ 2 : (width - 1 - i) ~/ 2;
        } else if (shape == 'gap' && i == width ~/ 2) {
          continue;
        } else if (shape == 'asymmetric') {
          y += side < 0 ? 0 : 1;
        }
        base.set(start + i, y);
      }
      var thick = base;
      // Add thickness upwards first so the eye remains readable.
      for (var t = 1; t < thickness; t++) {
        thick = thick.union(base.translated(0, -t));
      }
      if (shape == 'veryThin' || shape == 'thin') {
        thick = base;
      } else if (shape == 'veryThick' || shape == 'bushy') {
        thick = thick.union(base.translated(0, -thickness));
      }
      return thick;
    }

    var result = one(leftCenter, -1, 0).union(one(rightCenter, 1, asym));
    final safe = eyes.dilated(diagonal: true, iterations: 1);
    result = result.subtract(safe).intersect(head.eroded()).intersect(zones.forehead.dilated());
    return result.removeSmallComponents(1, maxComponents: 4);
  }

  _NoseResult _nose(
    AvatarRenderContext c,
    PixelMask head,
    PixelMask eyes,
    PixelMask mouth,
    _FaceZones zones,
  ) {
    final style = c.string('nose.shape');
    if (style == 'none') return _NoseResult.empty();
    final centerX = 24 + clampInt(c.integer('nose.asymmetry'), -1, 1);
    final tipY = c.integer('face.noseTipY');
    final length = clampInt(c.integer('nose.length'), 0, 8);
    final width = clampInt(c.integer('nose.width'), 1, 7);
    final bridgeWidth = clampInt(c.integer('nose.bridgeWidth'), 0, 3);
    final tipWidth = clampInt(c.integer('nose.tipWidth'), 1, 6);
    final nostrilSpacing = clampInt(c.integer('nose.nostrilSpacing'), 0, 5);
    final shadow = PixelMask();
    final deep = PixelMask();
    final light = PixelMask();

    if (style == 'pixel' || style == 'dot') {
      deep.set(centerX, tipY);
    } else if (style == 'nostrilsOnly') {
      deep.set(centerX - (nostrilSpacing ~/ 2 + 1), tipY);
      deep.set(centerX + (nostrilSpacing ~/ 2 + 1), tipY);
    } else if (style == 'shadowOnly') {
      shadow.line(centerX + 1, tipY - length, centerX + 1, tipY);
    } else if (style == 'animal') {
      deep.fillTriangle(
        (x: centerX - tipWidth / 2, y: tipY - 1),
        (x: centerX + tipWidth / 2, y: tipY - 1),
        (x: centerX, y: tipY + 2),
      );
      deep.set(centerX - 1, tipY + 1).set(centerX + 1, tipY + 1);
    } else if (style == 'mechanical') {
      shadow.fillRect(centerX - width ~/ 2, tipY - length, width, length + 1);
      deep.vLine(centerX, tipY - length, tipY);
      light.hLine(centerX - tipWidth ~/ 2, centerX + tipWidth ~/ 2, tipY - 1);
    } else {
      final startY = clampInt(tipY - length, c.integer('face.eyeY') + 1, tipY);
      final hook = style == 'hooked' ? 1 : 0;
      final bridgeX = centerX + hook;
      for (var offset = 0; offset < clampInt(bridgeWidth + 1, 1, 3); offset++) {
        shadow.vLine(bridgeX + offset, startY, tipY - 1);
      }
      if (style == 'flat' || style == 'wide' || style == 'square') {
        shadow.hLine(centerX - width ~/ 2, centerX + width ~/ 2, tipY);
      } else if (style == 'triangular') {
        shadow.fillTriangle(
          (x: centerX, y: startY),
          (x: centerX - tipWidth / 2, y: tipY),
          (x: centerX + tipWidth / 2, y: tipY),
        );
      } else if (style == 'rounded' || style == 'button' || style == 'largeTip') {
        shadow.fillEllipse(centerX, tipY, tipWidth / 2, 1);
      } else if (style == 'upturned') {
        shadow.hLine(centerX - tipWidth ~/ 2, centerX + tipWidth ~/ 2, tipY - 1);
        deep.set(centerX - 1, tipY).set(centerX + 1, tipY);
      } else {
        shadow.hLine(centerX - tipWidth ~/ 2, centerX + tipWidth ~/ 2, tipY);
      }
      if (!<String>['smallTip', 'narrow', 'short'].contains(style)) {
        final gap = clampInt(nostrilSpacing ~/ 2 + 1, 1, 3);
        deep.set(centerX - gap, tipY).set(centerX + gap, tipY);
      }
      light.vLine(centerX - 1, startY + 1, tipY - 1);
    }

    final unsafe = eyes.dilated(diagonal: true).union(mouth.dilated());
    final clip = zones.noseZone.intersect(head.eroded()).subtract(unsafe);
    final strength = clampInt(c.integer('nose.shadowStrength'), 0, 3);
    var finalShadow = shadow.intersect(clip);
    if (strength == 0) finalShadow = PixelMask();
    if (strength >= 2) finalShadow = finalShadow.union(finalShadow.translated(1, 0)).intersect(clip);
    if (strength >= 3) finalShadow = finalShadow.union(finalShadow.translated(0, 1)).intersect(clip);
    return _NoseResult(finalShadow, deep.intersect(clip), light.intersect(clip));
  }

  _MouthResult _mouth(AvatarRenderContext c, PixelMask head) {
    final shape = c.string('mouth.shape');
    if (shape == 'none') return _MouthResult.empty();
    final centerX = 24 + clampInt(c.integer('mouth.asymmetry'), -1, 1);
    final centerY = c.integer('face.mouthY');
    var width = clampInt(c.integer('mouth.width'), 2, 12);
    final height = clampInt(c.integer('mouth.height'), 1, 3);
    final upper = clampInt(c.integer('mouth.upperLipThickness'), 0, 2);
    final lower = clampInt(c.integer('mouth.lowerLipThickness'), 0, 2);
    final dip = clampInt(c.integer('mouth.centerDip'), 0, 2);
    final dark = PixelMask();
    final base = PixelMask();
    final light = PixelMask();
    if (shape == 'pixel') {
      dark.set(centerX, centerY);
    } else if (shape == 'smallRound') {
      dark.fillEllipse(centerX, centerY, width / 4, height / 2);
    } else if (shape == 'angular') {
      dark.line(centerX - width ~/ 2, centerY,
          centerX, centerY + 1);
      dark.line(centerX, centerY + 1,
          centerX + width ~/ 2, centerY);
    } else {
      if (shape == 'shortLine') width = clampInt(width - 2, 2, 12);
      if (shape == 'wideLine') width = clampInt(width + 2, 2, 14);
      final left = centerX - width ~/ 2;
      final right = centerX + width ~/ 2;
      dark.hLine(left, right, centerY);
      if (shape == 'cupid' || dip > 0) {
        dark.set(centerX, centerY + (dip > 0 ? 1 : 0));
        dark.set(centerX - 1, centerY - 1).set(centerX + 1, centerY - 1);
      }
      if (<String>['full', 'upperFull', 'twoTone'].contains(shape) || upper > 0) {
        for (var t = 1; t <= (shape == 'upperFull' ? 2 : upper); t++) {
          base.hLine(left + t, right - t, centerY - t);
        }
      }
      if (<String>['full', 'lowerFull', 'twoTone', 'shadowed'].contains(shape) || lower > 0) {
        for (var t = 1; t <= (shape == 'lowerFull' ? 2 : lower); t++) {
          base.hLine(left + t, right - t, centerY + t);
        }
      }
      if (shape == 'openGap') {
        dark.hLine(left + 1, right - 1, centerY + 1);
      }
      if (shape == 'thin') {
        base.data.fillRange(0, base.data.length, 0);
      }
      light.hLine(centerX - width ~/ 4, centerX + width ~/ 4,
          centerY + (lower > 0 ? 1 : 0));
    }
    final clip = head.eroded().intersect(maskFromPredicate((x, y) => y < c.integer('head.bottomY') - 1));
    return _MouthResult(dark.intersect(clip), base.intersect(clip), light.intersect(clip));
  }

  _CheekResult _cheeks(AvatarRenderContext c, _FaceZones zones) {
    final shape = c.string('cheeks.shape');
    final shadow = PixelMask();
    final blush = PixelMask();
    final width = clampInt(c.integer('cheeks.width'), 0, 8);
    final height = clampInt(c.integer('cheeks.height'), 0, 4);
    final offsetY = clampInt(c.integer('cheeks.positionY'), -2, 2);
    final roundness = clampInt(c.integer('cheeks.roundness'), 0, 4);
    final centerY = c.integer('face.noseTipY') + 1 + offsetY;
    final radiusX = clampDouble(1 + width / 2, 1, 6);
    final radiusY = clampDouble(1 + height / 2 + roundness / 5, 1, 4);

    PixelMask shapedArea() {
      if (width == 0 || height == 0) return PixelMask();
      final left = PixelMask()
        ..fillEllipse(c.integer('face.leftEyeX') - 1, centerY, radiusX, radiusY);
      final right = PixelMask()
        ..fillEllipse(c.integer('face.rightEyeX') + 1, centerY, radiusX, radiusY);
      var area = left.intersect(zones.cheekLeft)
          .union(right.intersect(zones.cheekRight));
      if (roundness == 0 || shape == 'sharp') {
        area = area.intersect(maskFromPredicate(
          (x, y) => positiveMod(x + y, 2) == 0 || y == centerY,
        ));
      } else if (roundness >= 3 || shape == 'round' || shape == 'full') {
        area = area.dilated().intersect(
          zones.cheekLeft.union(zones.cheekRight),
        );
      }
      return area;
    }

    final geometricArea = shapedArea();
    if (shape != 'none') {
      var area = geometricArea;
      final strength = clampInt(c.integer('cheeks.shadowStrength'), 0, 3);
      if (shape == 'hollow' || shape == 'sharp') {
        shadow.data.setAll(0, orderedDither(area, 2 + strength).data);
      } else if (shape == 'full' || shape == 'round') {
        area = area.eroded();
        shadow.data.setAll(0, orderedDither(area, strength).data);
      } else if (strength > 0) {
        shadow.data.setAll(0, orderedDither(area, strength).data);
      }
    }
    final blushStrength = clampInt(c.integer('cheeks.blush'), 0, 3);
    if (blushStrength > 0) {
      final area = geometricArea.eroded();
      blush.data.setAll(0, orderedDither(area, 1 + blushStrength, phase: 1).data);
    }
    return _CheekResult(shadow, blush);
  }

  _SkinDetails _skinDetails(
    AvatarRenderContext c,
    _FaceZones zones,
    PixelMask eyes,
  ) {
    final style = c.string('skin.detail');
    final density = clampInt(c.integer('skin.detailDensity'), 0, 4);
    final shadow = PixelMask();
    final accent = PixelMask();
    if (style == 'none' || density == 0) return _SkinDetails(shadow, accent);
    final rng = c.random('skin.detail.$style');
    PixelMask deterministicPoints(PixelMask area, int count) {
      final points = PixelMask();
      final candidates = <(int, int)>[];
      for (var y = 0; y < 48; y++) {
        for (var x = 0; x < 48; x++) {
          if (area.get(x, y) != 0) candidates.add((x, y));
        }
      }
      for (var i = 0; i < count && candidates.isNotEmpty; i++) {
        final index = rng.nextInt(0, candidates.length - 1);
        final p = candidates.removeAt(index);
        points.set(p.$1, p.$2);
      }
      return points;
    }

    if (style == 'freckles' || style == 'manyFreckles') {
      final area = zones.cheekLeft.union(zones.cheekRight)
          .union(zones.noseZone.intersect(maskFromPredicate((x, y) => y >= c.integer('face.eyeY'))));
      accent.data.setAll(0, deterministicPoints(area,
          (style == 'manyFreckles' ? 7 : 3) * density).data);
    } else if (style == 'moles') {
      accent.data.setAll(0, deterministicPoints(zones.inner.subtract(eyes.dilated()), density).data);
    } else if (style == 'scar') {
      shadow.line(c.integer('face.leftEyeX') - 2, c.integer('face.eyeY') - 3,
          c.integer('face.leftEyeX') + 2, c.integer('face.eyeY') + 4);
    } else if (style == 'foreheadWrinkles') {
      for (var i = 0; i < density; i++) {
        shadow.hLine(19 + i, 28 - i, c.integer('face.eyeY') - 5 - i);
      }
    } else if (style == 'underEyeWrinkles' || style == 'underEyeShadow') {
      final y = c.integer('face.eyeY') + 2;
      shadow.hLine(c.integer('face.leftEyeX') - 2, c.integer('face.leftEyeX') + 2, y);
      shadow.hLine(c.integer('face.rightEyeX') - 2, c.integer('face.rightEyeX') + 2, y);
    } else if (style == 'cheekLines') {
      shadow.line(15, c.integer('face.mouthY') - 3, 18, c.integer('face.mouthY') - 1);
      shadow.line(32, c.integer('face.mouthY') - 3, 29, c.integer('face.mouthY') - 1);
    } else if (style == 'blush') {
      accent.data.setAll(0, orderedDither(zones.cheekLeft.union(zones.cheekRight), 3).data);
    } else if (style == 'mechanicalJoints') {
      shadow.line(14, c.integer('face.eyeY'), 18, c.integer('face.mouthY'));
      accent.set(15, c.integer('face.eyeY') + 2).set(32, c.integer('face.eyeY') + 3);
    } else if (style == 'scales' || style == 'spots') {
      accent.data.setAll(0, deterministicPoints(zones.inner.subtract(eyes.dilated()), density * 5).data);
    }
    return _SkinDetails(shadow.intersect(zones.inner), accent.intersect(zones.inner));
  }

  _FaceZones _zones(
    AvatarRenderContext c,
    PixelMask head,
    PixelMask eyes,
    PixelMask mouth,
  ) {
    final inner = head.eroded(diagonal: true);
    final eyeY = c.integer('face.eyeY');
    final noseY = c.integer('face.noseTipY');
    final mouthY = c.integer('face.mouthY');
    final bottom = c.integer('head.bottomY');
    final forehead = inner.intersect(maskFromPredicate((x, y) => y < eyeY - 1));
    final eyeSafety = eyes.dilated(diagonal: true, iterations: 1);
    final noseZone = inner.intersect(maskFromPredicate((x, y) =>
        x >= 19 && x <= 28 && y >= eyeY + 1 && y <= mouthY - 1));
    final mouthSafety = mouth.dilated(diagonal: true, iterations: 1)
        .union(maskRect(17, mouthY - 2, 15, 5).intersect(inner));
    final chin = inner.intersect(maskFromPredicate((x, y) => y > mouthY + 1 && y <= bottom));
    final jawLeft = inner.intersect(maskFromPredicate((x, y) =>
        x < 24 && y >= noseY && y <= bottom));
    final jawRight = inner.intersect(maskFromPredicate((x, y) =>
        x >= 24 && y >= noseY && y <= bottom));
    final cheekLeft = inner.intersect(maskFromPredicate((x, y) =>
        x < 21 && y > eyeY + 1 && y < mouthY + 1));
    final cheekRight = inner.intersect(maskFromPredicate((x, y) =>
        x > 26 && y > eyeY + 1 && y < mouthY + 1));
    final sideburns = inner.intersect(maskFromPredicate((x, y) =>
        (x < 16 || x > 31) && y >= eyeY - 2 && y <= mouthY + 3));
    final beardGrowth = jawLeft.union(jawRight).union(chin)
        .union(cheekLeft).union(cheekRight).union(sideburns)
        .subtract(eyeSafety).subtract(mouthSafety).subtract(noseZone);
    final centralFace = inner.intersect(maskFromPredicate((x, y) =>
        x >= 16 && x <= 31 && y >= eyeY - 1 && y <= mouthY + 2));
    return _FaceZones(inner, forehead, eyeSafety, noseZone, mouthSafety,
        chin, jawLeft, jawRight, cheekLeft, cheekRight, sideburns,
        beardGrowth, centralFace);
  }

  int _browColor(AvatarRenderContext c) {
    return switch (c.string('brows.colorMode')) {
      'darkerHair' => c.color('hairShadow'),
      'lighterHair' => c.color('hairLight'),
      'independent' => c.color('browIndependent'),
      _ => c.color('hairBase'),
    };
  }

  int _mouthDarkColor(AvatarRenderContext c) {
    return switch (c.string('mouth.colorMode')) {
      'black' => c.color('outline'),
      'skinShadow' => c.color('skinDeep'),
      _ => c.color('mouthDark'),
    };
  }

  int _mouthBaseColor(AvatarRenderContext c) {
    return c.string('mouth.colorMode') == 'skinShadow'
        ? c.color('skinShadow')
        : c.color('mouthBase');
  }
}

final class _SingleEye {
  const _SingleEye(this.shape, this.sclera, this.irisDark, this.iris,
      this.irisLight, this.pupil, this.lids, this.lashes);
  final PixelMask shape;
  final PixelMask sclera;
  final PixelMask irisDark;
  final PixelMask iris;
  final PixelMask irisLight;
  final PixelMask pupil;
  final PixelMask lids;
  final PixelMask lashes;
}

final class _EyeResult {
  const _EyeResult({required this.left, required this.right, required this.sclera,
    required this.irisDark, required this.iris, required this.irisLight,
    required this.pupil, required this.lids, required this.lashes});
  final PixelMask left;
  final PixelMask right;
  final PixelMask sclera;
  final PixelMask irisDark;
  final PixelMask iris;
  final PixelMask irisLight;
  final PixelMask pupil;
  final PixelMask lids;
  final PixelMask lashes;
  PixelMask get combined => left.union(right);
}

final class _MouthResult {
  const _MouthResult(this.dark, this.base, this.light);
  factory _MouthResult.empty() => _MouthResult(PixelMask(), PixelMask(), PixelMask());
  final PixelMask dark;
  final PixelMask base;
  final PixelMask light;
  PixelMask get combined => dark.union(base).union(light);
}

final class _NoseResult {
  const _NoseResult(this.shadow, this.deep, this.highlight);
  factory _NoseResult.empty() => _NoseResult(PixelMask(), PixelMask(), PixelMask());
  final PixelMask shadow;
  final PixelMask deep;
  final PixelMask highlight;
  PixelMask get combined => shadow.union(deep).union(highlight);
}

final class _CheekResult {
  const _CheekResult(this.shadow, this.blush);
  final PixelMask shadow;
  final PixelMask blush;
}

final class _SkinDetails {
  const _SkinDetails(this.shadow, this.accent);
  final PixelMask shadow;
  final PixelMask accent;
}

final class _FaceZones {
  const _FaceZones(this.inner, this.forehead, this.eyeSafety, this.noseZone,
      this.mouthSafety, this.chin, this.jawLeft, this.jawRight,
      this.cheekLeft, this.cheekRight, this.sideburns,
      this.beardGrowth, this.centralFace);
  final PixelMask inner;
  final PixelMask forehead;
  final PixelMask eyeSafety;
  final PixelMask noseZone;
  final PixelMask mouthSafety;
  final PixelMask chin;
  final PixelMask jawLeft;
  final PixelMask jawRight;
  final PixelMask cheekLeft;
  final PixelMask cheekRight;
  final PixelMask sideburns;
  final PixelMask beardGrowth;
  final PixelMask centralFace;
}
