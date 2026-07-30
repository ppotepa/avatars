import '../../pixels/pixel_mask.dart';
import '../../util/math_utils.dart';
import '../render_helpers.dart';
import '../render_model.dart';

final class AnatomyRenderer implements AvatarPartRenderer {
  const AnatomyRenderer();

  @override
  void render(AvatarRenderContext context, AvatarRenderState state) {
    final head = _head(context);
    final neck = _neck(context);
    final torso = _torso(context);
    final ears = _ears(context);
    final torsoCore = torso.torso
        .subtract(torso.leftArm)
        .subtract(torso.rightArm)
        .subtract(torso.leftHand)
        .subtract(torso.rightHand);

    state
      ..putMask('head', head)
      ..putMask('neck', neck)
      ..putMask('torso', torsoCore)
      ..putMask('clothing', torso.clothing)
      ..putMask('skinChest', torso.skinChest)
      ..putMask('leftArm', torso.leftArm)
      ..putMask('rightArm', torso.rightArm)
      ..putMask('leftHand', torso.leftHand)
      ..putMask('rightHand', torso.rightHand)
      ..putMask('ears', ears.outer);

    final skinShadow = shadingMask(
      head,
      kind: 'skin',
      strength: context.integer('skin.shadowDepth', 2),
      eyeY: context.integer('face.eyeY'),
      mouthY: context.integer('face.mouthY'),
    );
    final skinLight = highlightMask(
      head,
      kind: 'skin',
      strength: context.integer('skin.highlightStrength', 2),
      eyeY: context.integer('face.eyeY'),
      mouthY: context.integer('face.mouthY'),
    );
    final neckShadow = shadingMask(
      neck,
      kind: 'neck',
      strength: context.integer('neck.shadowDepth', 1),
      topY: context.integer('body.neckTopY'),
    );
    final neckLight = highlightMask(
      neck,
      kind: 'neck',
      strength: context.integer('neck.shadowDepth', 1),
      topY: context.integer('body.neckTopY'),
    );
    final clothShadow = shadingMask(
      torso.clothing,
      kind: 'clothing',
      strength: context.integer('clothing.shadowStrength', 1),
    );
    final clothLight = highlightMask(
      torso.clothing,
      kind: 'clothing',
      strength: context.integer('clothing.shadowStrength', 1),
    );

    state
      ..addLayer('torso.outline', 38, torsoCore.outline(diagonal: true),
          context.color('outline'),
          meta: const <String, Object?>{'part': 'torso'})
      ..addLayer('chest.skin', 39, torso.skinChest, context.color('skinBase'),
          meta: const <String, Object?>{'part': 'chest'})
      ..addLayer(
          'clothing.base', 40, torso.clothing, context.color('clothBase'),
          meta: const <String, Object?>{'part': 'clothing'})
      ..addLayer('clothing.shadow', 41, clothShadow, context.color('clothDark'),
          meta: const <String, Object?>{'part': 'clothing'})
      ..addLayer(
          'clothing.highlight', 42, clothLight, context.color('clothLight'),
          meta: const <String, Object?>{'part': 'clothing'})
      ..addLayer(
          'clothing.pattern', 43, torso.pattern, context.color('clothAccent'),
          meta: const <String, Object?>{'part': 'clothing'})
      ..addLayer('clothing.seams', 44, torso.seams, context.color('clothDark'),
          meta: const <String, Object?>{'part': 'clothing'})
      ..addLayer(
          'clothing.collar', 45, torso.collar, context.color('clothDark'),
          meta: const <String, Object?>{'part': 'clothing'})
      ..addLayer('leftArm.outline', 46, torso.leftArm.outline(diagonal: true),
          context.color('outline'),
          meta: const <String, Object?>{'part': 'leftArm'})
      ..addLayer('rightArm.outline', 46, torso.rightArm.outline(diagonal: true),
          context.color('outline'),
          meta: const <String, Object?>{'part': 'rightArm'})
      ..addLayer('leftArm.base', 47, torso.leftArm, context.color('clothBase'),
          meta: const <String, Object?>{'part': 'leftArm'})
      ..addLayer(
          'rightArm.base', 47, torso.rightArm, context.color('clothBase'),
          meta: const <String, Object?>{'part': 'rightArm'})
      ..addLayer('leftHand.base', 48, torso.leftHand, context.color('skinBase'),
          meta: const <String, Object?>{'part': 'leftHand'})
      ..addLayer(
          'rightHand.base', 48, torso.rightHand, context.color('skinBase'),
          meta: const <String, Object?>{'part': 'rightHand'})
      ..addLayer('neck.outline', 48, neck.outline(diagonal: true),
          context.color('outline'),
          meta: const <String, Object?>{'part': 'neck'})
      ..addLayer('neck.base', 50, neck, context.color('skinBase'),
          meta: const <String, Object?>{'part': 'neck'})
      ..addLayer('neck.shadow', 51, neckShadow, context.color('skinShadow'),
          meta: const <String, Object?>{'part': 'neck'})
      ..addLayer('neck.highlight', 52, neckLight, context.color('skinLight'),
          meta: const <String, Object?>{'part': 'neck'})
      ..addLayer('ears.outline', 58, ears.outer.outline(diagonal: true),
          context.color('outline'),
          meta: const <String, Object?>{'part': 'ears'})
      ..addLayer('ears.base', 60, ears.outer, context.color('skinBase'),
          meta: const <String, Object?>{'part': 'ears'})
      ..addLayer('ears.inner', 61, ears.inner, context.color('skinShadow'),
          meta: const <String, Object?>{'part': 'ears'})
      ..addLayer('head.outline', 68, head.outline(diagonal: true),
          context.color('outline'),
          meta: const <String, Object?>{'part': 'head'})
      ..addLayer('head.base', 70, head, context.color('skinBase'),
          meta: const <String, Object?>{'part': 'head'})
      ..addLayer('head.shadow', 72, skinShadow, context.color('skinShadow'),
          meta: const <String, Object?>{'part': 'head'})
      ..addLayer('head.highlight', 73, skinLight.subtract(skinShadow),
          context.color('skinLight'),
          meta: const <String, Object?>{'part': 'head'});
  }

  ({
    double top,
    double temple,
    double cheek,
    double cheek2,
    double jaw,
    double chin
  }) _headControls(AvatarRenderContext c) {
    final width = c.integer('head.width');
    var top = c.integer('head.topWidth').toDouble();
    var temple = c.integer('head.templeWidth').toDouble();
    var cheek = c.integer('head.cheekWidth').toDouble();
    var cheek2 = cheek;
    var jaw = c.integer('head.jawWidth').toDouble();
    var chin = c.integer('head.chinWidth').toDouble();
    final shape = c.string('head.shape');
    final presets = <String, List<double>>{
      'round': <double>[.78, .96, 1, .97, .84, .58],
      'oval': <double>[.68, .9, 1, .91, .72, .46],
      'elongated': <double>[.69, .87, .94, .85, .67, .42],
      'broad': <double>[.82, 1, 1, .98, .87, .58],
      'square': <double>[.84, 1, 1, 1, .93, .72],
      'rectangular': <double>[.88, 1, 1, 1, .91, .74],
      'triangle': <double>[.58, .7, .83, .95, 1, .76],
      'invertedTriangle': <double>[.87, 1, .95, .76, .58, .36],
      'diamond': <double>[.6, .82, 1, .82, .62, .39],
      'heart': <double>[.84, 1, .95, .76, .56, .32],
      'pear': <double>[.6, .7, .83, .96, 1, .72],
      'egg': <double>[.66, .88, 1, .96, .81, .54],
      'wideJaw': <double>[.71, .9, .95, 1, 1, .7],
      'narrowJaw': <double>[.76, 1, 1, .76, .53, .35],
      'strongChin': <double>[.73, .92, 1, .9, .79, .7],
      'softOval': <double>[.73, .92, 1, .91, .69, .5],
      'highSkull': <double>[.58, .82, 1, .9, .7, .46],
      'flatTop': <double>[.92, 1, 1, .9, .73, .5],
      'angular': <double>[.73, 1, 1, .88, .82, .52],
    };
    final preset = presets[shape];
    if (preset != null) {
      top = lerpDouble(width * preset[0], top, 0.42);
      temple = lerpDouble(width * preset[1], temple, 0.42);
      cheek = lerpDouble(width * preset[2], cheek, 0.42);
      cheek2 = lerpDouble(width * preset[3], cheek2, 0.42);
      jaw = lerpDouble(width * preset[4], jaw, 0.42);
      chin = lerpDouble(width * preset[5], chin, 0.42);
    }
    switch (c.string('forehead.shape')) {
      case 'low':
        top += 2;
        temple += 1;
        break;
      case 'high':
        top -= 1;
        break;
      case 'veryHigh':
        top -= 2;
        temple -= 1;
        break;
      case 'wide':
        top += 2;
        temple += 2;
        break;
      case 'narrow':
        top -= 2;
        temple -= 1;
        break;
      case 'sloped':
        top -= 1;
        break;
      case 'rounded':
        top += c.integer('forehead.roundness') * 0.5;
        break;
    }
    final roundness = c.integer('head.roundness');
    final angularity = c.integer('head.angularity');
    top += c.integer('forehead.width') * 0.1 + (roundness - angularity) * .16;
    temple += (roundness - angularity) * .12;
    cheek += roundness * .12;
    jaw += angularity * .35 - roundness * .08;
    chin += c.integer('head.chinDepth') * .42 + angularity * .12;
    double fit(double value) =>
        clampInt(value.round(), 3, width + 1).toDouble();
    return (
      top: fit(top),
      temple: fit(temple),
      cheek: fit(cheek),
      cheek2: fit(cheek2),
      jaw: fit(jaw),
      chin: fit(chin),
    );
  }

  PixelMask _head(AvatarRenderContext c) {
    final mask = PixelMask();
    final controls = _headControls(c);
    final top = c.integer('head.topY');
    final bottom = c.integer('head.bottomY');
    final height = c.integer('head.actualHeight');
    final center = 23.5 + c.integer('head.asymmetry') * .5;
    for (var y = top; y <= bottom; y++) {
      final t = (y - top) / (height - 1).clamp(1, 99);
      var width = rowWidth(controls, t).round();
      if (c.string('head.shape') == 'flatTop' && y <= top + 1)
        width = controls.top.round();
      if (c.string('forehead.shape') == 'sloped' && y < top + height * .22) {
        width -= ((top + height * .22 - y) * c.integer('forehead.slope') * .15)
            .round();
      }
      if (width.isEven) width += 1;
      final left = (center - width / 2).round();
      mask.hLine(left, left + width - 1, y);
    }
    return largestComponent(mask);
  }

  PixelMask _neck(AvatarRenderContext c) {
    final mask = PixelMask();
    final top = c.integer('body.neckTopY');
    final bottom = c.integer('body.neckBaseY');
    final center = 24 + c.integer('neck.offsetX');
    var topWidth = c.integer('neck.widthTop');
    var bottomWidth = c.integer('neck.widthBottom');
    switch (c.string('neck.variant')) {
      case 'thin':
        topWidth -= 1;
        bottomWidth -= 1;
        break;
      case 'wide':
        topWidth += 2;
        bottomWidth += 2;
        break;
      case 'taperUp':
        topWidth -= 1;
        bottomWidth += 1;
        break;
      case 'flareDown':
        bottomWidth += 2;
        break;
      case 'asymmetric':
        break;
    }
    for (var y = top; y <= bottom; y++) {
      final t = (y - top) / (bottom - top).clamp(1, 99);
      final width =
          lerpDouble(topWidth, bottomWidth + c.integer('neck.taper'), t)
              .round();
      final shift = c.string('neck.variant') == 'tilted' ? (t * 2).round() : 0;
      final left = center + shift - width ~/ 2;
      mask.hLine(left, left + width - 1, y);
    }
    return mask;
  }

  _TorsoResult _torso(AvatarRenderContext c) {
    final torso = PixelMask();
    final arms = PixelMask();
    final skinChest = PixelMask();
    final pattern = PixelMask();
    final collar = PixelMask();
    final seams = PixelMask();
    final top = c.integer('torso.topY');
    final center = 23.5;
    final bodyDelta = (c.integer('body.width') - 36) * .48;
    final massDelta = (c.integer('body.mass') - 3) * .7;
    var shoulderWidth = clampInt(
        (c.integer('shoulders.width') + bodyDelta + massDelta).round(), 24, 48);
    var topWidth = clampInt(
        (c.integer('torso.widthTop') + bodyDelta * .65 + massDelta).round(),
        20,
        48);
    var bottomWidth = clampInt(
        (c.integer('torso.widthBottom') +
                c.integer('torso.taper') +
                bodyDelta * .75 +
                massDelta * .6)
            .round(),
        20,
        48);
    final bodyType = c.string('body.type');
    if (<String>['massive', 'muscular', 'broad', 'shortWide']
        .contains(bodyType)) {
      shoulderWidth = clampInt(
          (shoulderWidth + 2 + c.integer('body.mass') * .3).round(), 24, 48);
      topWidth = clampInt(topWidth + 2, 20, 48);
    }
    if (<String>['petite', 'verySlim', 'slim', 'tallNarrow'].contains(bodyType))
      shoulderWidth -= 2;
    final torsoShape = c.string('torso.shape');
    if (torsoShape == 'wideChest')
      topWidth = topWidth < bottomWidth + 3 ? bottomWidth + 3 : topWidth;
    if (torsoShape == 'taperedDown')
      bottomWidth = clampInt(
          topWidth - 4 - clampInt(c.integer('torso.taper'), 0, 10), 20, 48);
    if (torsoShape == 'taperedUp')
      bottomWidth = clampInt(
          topWidth + 5 + clampInt(c.integer('torso.taper'), 0, 10), 20, 48);
    if (torsoShape == 'rectangle') bottomWidth = topWidth;
    if (torsoShape == 'delicate') topWidth -= 2;
    var slope = c.integer('shoulders.slope');
    var roundness = c.integer('shoulders.roundness');
    switch (c.string('shoulders.shape')) {
      case 'straight':
        slope = clampInt(slope, 0, 1);
        break;
      case 'sloping':
        slope += 2;
        break;
      case 'raised':
        slope = clampInt(slope - 2, 0, 20);
        break;
      case 'narrow':
        shoulderWidth -= 3;
        break;
      case 'broad':
        shoulderWidth += 3;
        break;
      case 'rounded':
        roundness += 2;
        break;
      case 'angular':
        roundness = 0;
        slope += 1;
        break;
      case 'muscular':
        shoulderWidth += 2;
        topWidth += 2;
        break;
      case 'delicate':
        shoulderWidth -= 2;
        roundness += 1;
        break;
    }
    final asymmetry = c.integer('shoulders.asymmetry');
    final leftDrop = slope + clampInt(asymmetry, 0, 10);
    final rightDrop = slope + clampInt(-asymmetry, 0, 10);
    for (var y = top; y <= 47; y++) {
      final t = (y - top) / (47 - top).clamp(1, 99);
      var width = lerpDouble(topWidth, bottomWidth, t).round();
      if (y <= top + 5) {
        final d = y - top;
        final shoulderInset =
            clampInt(d - leftDrop, 0, 20) + clampInt(d - rightDrop, 0, 20);
        final shoulderAt = shoulderWidth -
            clampInt(d * 2 - roundness, 0, 20) -
            (shoulderInset * .25).round();
        if (shoulderAt > width) width = shoulderAt;
      }
      if (torsoShape == 'rounded')
        width -= ((t - .5).abs() * (2 + roundness * .4)).round();
      if (torsoShape == 'muscular' && y < top + 6) width += 2;
      var left = (center - width / 2).round();
      var right = left + width - 1;
      if (y <= top + 5) {
        final d = y - top;
        left += clampInt(leftDrop - d - roundness + 1, 0, 20);
        right -= clampInt(rightDrop - d - roundness + 1, 0, 20);
      }
      torso.hLine(left, right, y);
    }
    final armDepth = clampInt(c.integer('body.armVisibility'), 0, 5);
    if (armDepth > 0) {
      for (final direction in const <int>[-1, 1]) {
        final shoulderX =
            (center + direction * (shoulderWidth / 2 - 1)).round();
        for (var y = top + 2;
            y <= clampInt(top + 5 + armDepth * 2, 0, 47);
            y++) {
          final outward = ((y - top) * .35).round();
          final thickness =
              clampInt(((c.integer('body.mass') + armDepth) / 2).round(), 2, 8);
          arms.hLine(
            shoulderX + direction * outward - direction * (thickness - 1),
            shoulderX + direction * outward,
            y,
          );
        }
      }
    }
    final fullTorso = torso.union(arms);
    var leftArm = arms.intersect(maskFromPredicate((x, y) => x < 24));
    var rightArm = arms.intersect(maskFromPredicate((x, y) => x >= 24));
    PixelMask handFor(PixelMask arm) {
      final bounds = arm.bounds;
      if (bounds == null) return PixelMask();
      return arm
          .intersect(maskFromPredicate((x, y) => y >= bounds.bottom - 1))
          .dilated();
    }

    final leftHand = handFor(leftArm);
    final rightHand = handFor(rightArm);
    final necklineCut = PixelMask();
    final necklineDepth = c.integer('clothing.necklineDepth');
    final neckWidth = (c.integer('neck.widthBottom') + 2) >
            (c.integer('clothing.collarWidth') + 5)
        ? c.integer('neck.widthBottom') + 2
        : c.integer('clothing.collarWidth') + 5;
    switch (c.string('clothing.neckline')) {
      case 'v':
        necklineCut.fillTriangle(
          (x: 24 - neckWidth / 2, y: top),
          (x: 24 + neckWidth / 2, y: top),
          (x: 24, y: top + necklineDepth + 4),
        );
        break;
      case 'square':
        necklineCut.fillRect(
            24 - neckWidth ~/ 2, top, neckWidth, necklineDepth + 3);
        break;
      case 'open':
        necklineCut.fillRect(
            24 - neckWidth ~/ 2, top, neckWidth, necklineDepth + 5);
        break;
      case 'asymmetric':
        necklineCut.fillTriangle(
          (x: 24 - neckWidth / 2, y: top),
          (x: 24 + neckWidth / 2, y: top),
          (x: 20, y: top + necklineDepth + 4),
        );
        break;
      case 'high':
      case 'turtleneck':
      default:
        necklineCut.fillEllipse(23.5, top, neckWidth / 2, necklineDepth + 2);
        break;
    }
    final shoulderCoverage =
        clampInt(c.integer('clothing.shoulderCoverage'), 0, 5);
    if (shoulderCoverage < 5) {
      final shoulderSkin = maskFromPredicate((x, y) =>
          fullTorso.get(x, y) != 0 &&
          y <= top + (5 - shoulderCoverage) &&
          (x - center).abs() > c.integer('neck.widthBottom') / 2 + 2);
      skinChest.data.setAll(0, shoulderSkin.data);
    }
    skinChest.data
        .setAll(0, skinChest.union(necklineCut.intersect(fullTorso)).data);
    final torsoWithoutArms = fullTorso.subtract(arms);
    var clothing = torsoWithoutArms.subtract(skinChest);
    final garment = c.string('clothing.garment');
    if (garment == 'top')
      clothing = clothing.intersect(maskFromPredicate((x, y) => y >= top + 1));
    if (garment == 'hoodie') {
      final hood = PixelMask()
        ..fillEllipse(23.5, top + 1, (neckWidth / 2 + 2).clamp(5, 20), 4);
      collar.data.setAll(0, hood.subtract(necklineCut).data);
      seams.vLine(24, top + 5, 47);
    }
    if (garment == 'sweater') {
      for (var y = top + 4; y < 48; y += 3) seams.hLine(5, 42, y);
    }
    if (garment == 'tunic' || garment == 'robe') seams.vLine(24, top + 4, 47);
    if (garment == 'armor') {
      for (var y = top + 3; y < 48; y += 4) seams.hLine(7, 40, y);
      seams.vLine(16, top + 2, 47).vLine(31, top + 2, 47);
    }
    if (garment == 'jumpsuit')
      seams.vLine(24, top + 3, 47).hLine(18, 29, top + 5);
    if (garment == 'coat') seams.vLine(23, top + 4, 47).vLine(25, top + 4, 47);
    if (c.string('clothing.neckline') == 'turtleneck') {
      collar.fillRect(24 - c.integer('neck.widthBottom') ~/ 2 - 1, top - 1,
          c.integer('neck.widthBottom') + 2, 4);
    } else if ((garment == 'shirt' || garment == 'coat') &&
        c.integer('clothing.collarWidth') > 0) {
      final cw = c.integer('clothing.collarWidth');
      collar.fillTriangle((x: 24 - cw - 2, y: top),
          (x: 22, y: top + 4 + (cw / 2).ceil()), (x: 24 - cw + 1, y: top + 2));
      collar.fillTriangle((x: 24 + cw + 2, y: top),
          (x: 25, y: top + 4 + (cw / 2).ceil()), (x: 24 + cw - 1, y: top + 2));
      collar.hLine(24 - cw - 1, 24 + cw + 1, top);
    } else if (garment == 'armor') {
      collar.hLine(16, 31, top + 2).hLine(18, 29, top + 3);
    }
    final patternStyle = c.string('clothing.pattern');
    final density = clampInt(5 - c.integer('clothing.patternDensity'), 1, 5);
    final bounds = clothing.bounds;
    if (bounds != null) {
      if (patternStyle == 'stripe' || patternStyle == 'doubleStripe') {
        for (var y = bounds.y + 3; y <= bounds.bottom; y += density + 2)
          pattern.hLine(bounds.x, bounds.right, y);
      } else if (patternStyle == 'checker') {
        for (var y = bounds.y; y <= bounds.bottom; y++) {
          for (var x = bounds.x; x <= bounds.right; x++) {
            if ((((x - bounds.x) ~/ (density + 1)) +
                    ((y - bounds.y) ~/ (density + 1)))
                .isEven) pattern.set(x, y);
          }
        }
      } else if (patternStyle == 'dots') {
        for (var y = bounds.y + 2; y <= bounds.bottom; y += density + 2) {
          for (var x = bounds.x + 2; x < bounds.right - 1; x += density + 3)
            pattern.set(x, y);
        }
      } else if (patternStyle == 'diagonal') {
        for (var k = bounds.x - bounds.height;
            k < bounds.x + bounds.width + bounds.height;
            k += density + 3) {
          pattern.line(k, bounds.bottom, k + bounds.height, bounds.y);
        }
      } else if (patternStyle == 'sash') {
        pattern.line(bounds.x + 5, bounds.y, bounds.right - 6, bounds.bottom,
            thickness: 3);
      } else if (patternStyle == 'trim') {
        pattern
            .hLine(bounds.x, bounds.right, bounds.y + 3)
            .vLine(24, bounds.y + 3, 47);
      } else if (patternStyle == 'runes') {
        for (var x = bounds.x + 7; x < bounds.right - 6; x += 5) {
          pattern.vLine(x, bounds.y + 5, bounds.y + 8).set(x + 1, bounds.y + 6);
        }
      } else if (patternStyle == 'plates') {
        pattern.data.setAll(0, seams.data);
      }
    }
    return _TorsoResult(
      torso: torsoWithoutArms.union(leftArm).union(rightArm),
      clothing: clothing,
      skinChest: skinChest,
      pattern: pattern.intersect(clothing),
      collar: collar.intersect(fullTorso),
      seams: seams.intersect(clothing),
      leftArm: leftArm.subtract(leftHand),
      rightArm: rightArm.subtract(rightHand),
      leftHand: leftHand,
      rightHand: rightHand,
    );
  }

  _EarResult _ears(AvatarRenderContext c) {
    final outer = PixelMask();
    final inner = PixelMask();
    final shape = c.string('ears.shape');
    if (shape == 'none') return _EarResult(outer: outer, inner: inner);
    final animal = <String>[
      'cat',
      'fox',
      'rabbit',
      'bat',
      'owl',
      'deer',
      'moth',
      'draconic',
      'bone'
    ].contains(shape);
    if (animal) {
      final top = c.integer('head.topY');
      final baseY = top + 3;
      final width = c.integer('ears.width');
      final availableTop = clampInt(top, 0, 20);
      final requestedHeight =
          c.integer('ears.height') + c.integer('ears.tipLength');
      final height = clampInt(requestedHeight, 3, availableTop + 3);
      for (final side in const <int>[-1, 1]) {
        final cx = 23.5 + side * (c.integer('head.width') * .28);
        if (shape == 'rabbit' || shape == 'owl' || shape == 'deer') {
          outer.fillEllipse(cx, top - height / 2 + 2, width / 2, height / 2);
          if (shape == 'deer') {
            outer.fillTriangle(
                (x: cx - side * width / 2, y: baseY),
                (x: cx - side * (width + 2), y: top - height + 1),
                (x: cx, y: baseY));
          }
          if (shape == 'owl') {
            inner.fillEllipse(cx - side * 2, baseY - height ~/ 2, 2, 2);
          }
        } else if (shape == 'moth') {
          outer.fillTriangle(
              (x: cx, y: baseY),
              (x: cx + side * (width + 3), y: top - height + 2),
              (x: cx + side * width / 2, y: baseY));
        } else if (shape == 'bat') {
          outer.fillTriangle(
              (x: cx - side * width / 2, y: baseY),
              (x: cx + side * (width + 2), y: top - height + 2),
              (x: cx + side * width / 2, y: baseY));
          outer.fillTriangle(
              (x: cx, y: baseY - 1),
              (x: cx + side * (width + 4), y: top - height / 2),
              (x: cx + side * width / 2, y: baseY));
        } else if (shape == 'bone') {
          outer.fillRect((cx - width / 3).round(), top - height + 2,
              (width * 2 / 3).round(), height);
          inner.vLine(cx.round(), top - height + 3, baseY - 1);
        } else {
          outer.fillTriangle((
            x: cx - side * width / 2,
            y: baseY
          ), (
            x: cx,
            y: top - height + 2 - c.integer('ears.tipSharpness') * .25
          ), (
            x: cx + side * width / 2,
            y: baseY
          ));
        }
        inner.line(cx.round(), baseY - 1, cx.round(), top - height + 4);
      }
      return _EarResult(outer: outer, inner: inner.intersect(outer));
    }
    for (final side in const <int>[-1, 1]) {
      final anchorX =
          side < 0 ? c.integer('head.leftX') : c.integer('head.rightX');
      final centerY = c.integer('ears.centerY') +
          (side < 0
              ? clampInt(c.integer('ears.asymmetry'), 0, 5)
              : clampInt(-c.integer('ears.asymmetry'), 0, 5));
      var width = c.integer('ears.width');
      var height = c.integer('ears.height');
      var protrusion = c.integer('ears.protrusion');
      final availableTop = clampInt(centerY, 0, 24);
      height = clampInt(height, 3, availableTop + 2);
      final isElf = shape.startsWith('elf') ||
          <String>['goblin', 'fairy', 'demon', 'fin'].contains(shape);
      if (isElf) {
        final extra = shape == 'elfLong' ? 3 : (shape == 'elfMedium' ? 1 : 0);
        final maxLength = clampInt(availableTop + height ~/ 2, 1, 24);
        final length =
            clampInt(c.integer('ears.tipLength') + extra, 1, maxLength);
        final tipX = anchorX + side * (width + protrusion + length);
        var tipY = centerY -
            c.integer('ears.angle') -
            (shape == 'elfUp' ? 4 : 0) +
            (shape == 'elfSide' ? 2 : 0);
        if (shape == 'goblin') tipY += 2;
        if (shape == 'fairy') tipY -= 2;
        tipY = clampInt(tipY, 0, 47);
        outer.fillTriangle((x: anchorX, y: centerY - height / 2),
            (x: anchorX, y: centerY + height / 2), (x: tipX, y: tipY));
        inner.line(anchorX + side, centerY,
            anchorX + side * (width + length - 1), tipY);
      } else if (shape == 'mechanical') {
        final x = side < 0 ? anchorX - width - protrusion : anchorX + 1;
        outer.fillRect(x, centerY - height ~/ 2, width + protrusion, height);
        inner
            .line(anchorX + side, centerY,
                anchorX + side * (width + protrusion), centerY)
            .vLine(anchorX + side * (width + protrusion), centerY - 1,
                centerY + 1);
      } else {
        if (shape == 'humanTiny') {
          width = 2;
          height = clampInt(height - 2, 3, 20);
        }
        if (shape == 'humanSmall') {
          width = clampInt(width - 1, 2, 20);
          height = clampInt(height - 1, 3, 20);
        }
        if (shape == 'humanLong') height += 2;
        if (shape == 'humanWide') width += 2;
        if (shape == 'humanRound') height = height < width ? width : height - 1;
        if (shape == 'attached') protrusion = 0;
        if (shape == 'protruding') protrusion += 2;
        final cx = anchorX + side * (width / 2 + protrusion);
        final shift = c.integer('ears.angle') * side * .25;
        if (shape == 'humanRect') {
          outer.fillRect((cx - width / 2).round(),
              (centerY - height / 2 + shift).round(), width, height);
        } else {
          outer.fillEllipse(cx, centerY + shift, width / 2, height / 2);
        }
        outer.hLine(
            anchorX,
            anchorX + side * (protrusion + width * .35).round(),
            (centerY + shift).round());
        final detail = c.string('ears.innerDetail');
        if (detail != 'none') {
          if (detail == 'shell') {
            inner.fillEllipse(cx, centerY, (width / 4).clamp(1, 10),
                (height / 3).clamp(1, 10));
          } else {
            inner.line(
                anchorX + side,
                centerY - height ~/ 4,
                anchorX + side * clampInt(width - 1, 1, 20),
                centerY + height ~/ 4);
            if (detail == 'doubleLine') {
              inner.line(
                  anchorX + side,
                  centerY + 1,
                  anchorX + side * clampInt(width - 2, 1, 20),
                  centerY - height ~/ 4);
            }
          }
        }
      }
    }
    return _EarResult(outer: outer, inner: inner.intersect(outer));
  }
}

final class _TorsoResult {
  const _TorsoResult({
    required this.torso,
    required this.clothing,
    required this.skinChest,
    required this.pattern,
    required this.collar,
    required this.seams,
    required this.leftArm,
    required this.rightArm,
    required this.leftHand,
    required this.rightHand,
  });
  final PixelMask torso;
  final PixelMask clothing;
  final PixelMask skinChest;
  final PixelMask pattern;
  final PixelMask collar;
  final PixelMask seams;
  final PixelMask leftArm;
  final PixelMask rightArm;
  final PixelMask leftHand;
  final PixelMask rightHand;
}

final class _EarResult {
  const _EarResult({required this.outer, required this.inner});
  final PixelMask outer;
  final PixelMask inner;
}
