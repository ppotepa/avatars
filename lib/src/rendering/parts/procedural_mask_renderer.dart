import '../../pixels/pixel_mask.dart';
import '../../random/random_stream.dart';
import '../../util/math_utils.dart';
import '../render_model.dart';

/// Adds deterministic, seed-level construction details to face masks.
///
/// The base silhouette remains controlled by the catalog fields, while vents,
/// seams, cracks, emblems, filters and asymmetric wear vary independently for
/// each seed. This avoids identical masks appearing on otherwise different
/// characters without adding dozens of editor-only parameters.
final class ProceduralFaceMaskRenderer implements AvatarPartRenderer {
  const ProceduralFaceMaskRenderer();

  @override
  void render(AvatarRenderContext context, AvatarRenderState state) {
    final style = context.string('v4.faceMask');
    final mask = state.mask('faceMask');
    if (style == 'none' || mask.count == 0) return;

    final random = context.random('faceMask.procedural.$style');
    final dark = PixelMask();
    final accent = PixelMask();
    final light = PixelMask();
    final bounds = mask.bounds;
    if (bounds == null) return;

    final centerX = bounds.x + bounds.width ~/ 2;
    final top = bounds.y;
    final bottom = bounds.bottom - 1;
    final left = bounds.x;
    final right = bounds.right - 1;
    final variant = random.nextInt(0, 7);
    final asymmetry = random.nextBool() ? -1 : 1;
    final inset = random.nextInt(1, 3);

    if (style == 'hockeyMask') {
      _hockey(
        random,
        dark,
        accent,
        light,
        centerX: centerX,
        top: top,
        bottom: bottom,
        left: left,
        right: right,
        variant: variant,
        asymmetry: asymmetry,
      );
    } else if (style == 'gasMask' || style == 'respirator') {
      _respirator(
        random,
        dark,
        accent,
        light,
        centerX: centerX,
        top: top,
        bottom: bottom,
        left: left,
        right: right,
        variant: variant,
      );
    } else if (style == 'robotMask') {
      _robot(
        random,
        dark,
        accent,
        light,
        centerX: centerX,
        top: top,
        bottom: bottom,
        left: left,
        right: right,
        variant: variant,
        asymmetry: asymmetry,
      );
    } else if (style == 'theaterMask' ||
        style == 'venetianMask' ||
        style == 'ceremonialMask' ||
        style == 'demonMask') {
      _ornamental(
        random,
        dark,
        accent,
        light,
        centerX: centerX,
        top: top,
        bottom: bottom,
        left: left,
        right: right,
        variant: variant,
        asymmetry: asymmetry,
      );
    } else if (style == 'ninjaMask' ||
        style == 'balaclava' ||
        style == 'faceBandana' ||
        style == 'scarfMask') {
      _fabric(
        random,
        dark,
        accent,
        light,
        centerX: centerX,
        top: top,
        bottom: bottom,
        left: left,
        right: right,
        variant: variant,
      );
    } else {
      _general(
        random,
        dark,
        accent,
        light,
        centerX: centerX,
        top: top,
        bottom: bottom,
        left: left,
        right: right,
        variant: variant,
        asymmetry: asymmetry,
        inset: inset,
      );
    }

    final configuredDamage = context.integer('v4.maskDamage');
    final wear = clampInt(configuredDamage + random.nextInt(0, 3), 0, 7);
    for (var index = 0; index < wear; index++) {
      final startX = random.nextInt(left + inset, right - inset);
      final startY = random.nextInt(top + inset, bottom - inset);
      final length = random.nextInt(2, 6);
      final direction = random.nextBool() ? 1 : -1;
      dark.line(startX, startY, startX + direction * length,
          startY + random.nextInt(1, 4));
      if (index.isEven) light.set(startX - direction, startY);
    }

    final clippedDark = dark.intersect(mask);
    final clippedAccent = accent.intersect(mask);
    final clippedLight = light.intersect(mask);
    state
      ..addLayer('faceMask.procedural.dark', 184, clippedDark,
          context.color('outline'),
          meta: const {'part': 'faceMask'})
      ..addLayer('faceMask.procedural.accent', 185, clippedAccent,
          context.color('clothAccent'),
          meta: const {'part': 'faceMask'})
      ..addLayer('faceMask.procedural.light', 186, clippedLight,
          context.color('clothLight'),
          meta: const {'part': 'faceMask'});
  }

  void _hockey(
    RandomStream random,
    PixelMask dark,
    PixelMask accent,
    PixelMask light, {
    required int centerX,
    required int top,
    required int bottom,
    required int left,
    required int right,
    required int variant,
    required int asymmetry,
  }) {
    final rows = 2 + variant % 4;
    final spacingY = clampInt((bottom - top - 4) ~/ rows, 2, 5);
    final pattern = variant % 4;
    for (var row = 0; row < rows; row++) {
      final y = top + 3 + row * spacingY;
      final offset = row.isOdd ? 1 : 0;
      if (pattern == 0) {
        for (final x in <int>[
          centerX - 5 + offset,
          centerX,
          centerX + 5 - offset
        ]) {
          dark.fillEllipse(x, y, row.isEven ? 1 : 0, 1);
        }
      } else if (pattern == 1) {
        for (var x = centerX - 6 + offset; x <= centerX + 6; x += 3) {
          dark.set(x, y);
        }
      } else if (pattern == 2) {
        dark
            .set(centerX - 4 - row, y)
            .set(centerX + 4 + row, y)
            .set(centerX, y + 1);
      } else {
        dark
            .line(centerX - 6, y, centerX - 2, y + asymmetry)
            .line(centerX + 2, y - asymmetry, centerX + 6, y);
      }
    }
    final stripeX = centerX + asymmetry * random.nextInt(1, 4);
    if (variant.isEven) {
      accent.vLine(stripeX, top + 1, bottom - 2);
    } else {
      accent.line(left + 2, top + 3, right - 2, bottom - 3);
    }
    if (variant % 3 == 0) {
      accent.fillTriangle(
        (x: centerX - 2, y: top + 2),
        (x: centerX + 2, y: top + 2),
        (x: centerX, y: top + 5),
      );
    }
    light.set(left + 2, top + 2).set(right - 2, top + 3);
  }

  void _respirator(
    RandomStream random,
    PixelMask dark,
    PixelMask accent,
    PixelMask light, {
    required int centerX,
    required int top,
    required int bottom,
    required int left,
    required int right,
    required int variant,
  }) {
    final filterY = bottom - random.nextInt(2, 5);
    final filterOffset = random.nextInt(5, 8);
    final radius = 1 + variant % 3;
    for (final direction in <int>[-1, 1]) {
      final x = centerX + direction * filterOffset;
      dark.fillEllipse(x, filterY, radius + 1, radius + 1);
      accent.fillEllipse(x, filterY, radius, radius);
      if (variant.isEven) light.set(x - direction, filterY - 1);
    }
    if (variant % 3 == 0) {
      accent.vLine(centerX, top + 2, bottom - 2);
    } else if (variant % 3 == 1) {
      for (var y = top + 3; y < bottom - 1; y += 3) {
        dark.hLine(centerX - 3, centerX + 3, y);
      }
    } else {
      accent
          .line(left + 2, top + 2, centerX, bottom - 2)
          .line(right - 2, top + 2, centerX, bottom - 2);
    }
  }

  void _robot(
    RandomStream random,
    PixelMask dark,
    PixelMask accent,
    PixelMask light, {
    required int centerX,
    required int top,
    required int bottom,
    required int left,
    required int right,
    required int variant,
    required int asymmetry,
  }) {
    final panelX = centerX + asymmetry * random.nextInt(2, 6);
    final panelWidth = 2 + variant % 4;
    dark.fillRect(
        panelX - panelWidth ~/ 2, top + 2, panelWidth, bottom - top - 3);
    accent.hLine(left + 2, right - 2, top + 3 + variant % 3);
    if (variant.isEven) {
      accent.vLine(centerX, top + 1, bottom - 1);
    } else {
      accent.line(left + 2, bottom - 3, right - 2, top + 3);
    }
    final lightCount = 1 + variant % 4;
    for (var index = 0; index < lightCount; index++) {
      light.set(left + 3 + positiveMod(index * 5 + variant, right - left - 5),
          top + 2 + positiveMod(index * 3, bottom - top - 3));
    }
  }

  void _ornamental(
    RandomStream random,
    PixelMask dark,
    PixelMask accent,
    PixelMask light, {
    required int centerX,
    required int top,
    required int bottom,
    required int left,
    required int right,
    required int variant,
    required int asymmetry,
  }) {
    final spread = random.nextInt(3, 7);
    final motifY = top + random.nextInt(2, 5);
    if (variant % 3 == 0) {
      accent.fillTriangle(
        (x: centerX - spread, y: motifY + 3),
        (x: centerX + spread, y: motifY + 3),
        (x: centerX + asymmetry, y: motifY),
      );
    } else if (variant % 3 == 1) {
      accent.fillEllipse(centerX + asymmetry * 2, motifY + 2, spread, 2);
      dark.fillEllipse(
          centerX + asymmetry * 2, motifY + 2, clampInt(spread - 1, 0, 6), 1);
    } else {
      accent
          .line(left + 2, motifY, centerX, bottom - 2)
          .line(right - 2, motifY + asymmetry, centerX, bottom - 2);
    }
    for (var x = left + 2; x <= right - 2; x += random.nextInt(3, 5)) {
      light.set(x, top + 2 + positiveMod(x + variant, 4));
    }
  }

  void _fabric(
    RandomStream random,
    PixelMask dark,
    PixelMask accent,
    PixelMask light, {
    required int centerX,
    required int top,
    required int bottom,
    required int left,
    required int right,
    required int variant,
  }) {
    final spacing = 2 + variant % 4;
    final direction = variant.isEven ? 1 : -1;
    for (var y = top + 2; y < bottom; y += spacing) {
      accent.line(left + 1, y, right - 1, y + direction);
    }
    final seamX = centerX + random.nextInt(-3, 3);
    dark.vLine(seamX, top + 1, bottom - 1);
    if (variant % 3 == 0) {
      light.hLine(left + 2, right - 2, top + 2);
    }
  }

  void _general(
    RandomStream random,
    PixelMask dark,
    PixelMask accent,
    PixelMask light, {
    required int centerX,
    required int top,
    required int bottom,
    required int left,
    required int right,
    required int variant,
    required int asymmetry,
    required int inset,
  }) {
    if (variant.isEven) {
      accent.vLine(centerX + asymmetry * inset, top + 1, bottom - 1);
    } else {
      accent.hLine(left + inset, right - inset,
          top + 2 + positiveMod(variant, clampInt(bottom - top - 2, 1, 20)));
    }
    final marks = 1 + variant % 4;
    for (var index = 0; index < marks; index++) {
      final x = random.nextInt(left + inset, right - inset);
      final y = random.nextInt(top + inset, bottom - inset);
      dark.set(x, y);
      if (index == 0) light.set(x - asymmetry, y - 1);
    }
  }
}
