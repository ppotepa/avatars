import '../../pixels/pixel_mask.dart';
import '../../util/math_utils.dart';
import '../render_helpers.dart';
import '../render_model.dart';

/// Covers the remaining V4.2 fine-grained controls with visible pixel output.
final class ExtendedDetailRenderer implements AvatarPartRenderer {
  const ExtendedDetailRenderer();

  @override
  void render(AvatarRenderContext context, AvatarRenderState state) {
    final cheeks = _cheekLift(context, state);
    final symbolRotation = _symbolRotation(context);
    final horns = _extendedHorns(context);

    state
      ..addLayer(
        'expression.cheekLift.v42',
        126,
        cheeks,
        context.color('skinLight'),
        meta: const {'part': 'expression'},
      )
      ..addLayer(
        'symbols.rotation.v42',
        191,
        symbolRotation,
        context.color('fantasyLight'),
        meta: const {'part': 'symbols'},
      )
      ..addLayer(
        'horns.extended.v42.outline',
        148,
        horns.outline(diagonal: true),
        context.color('outline'),
        meta: const {'part': 'fantasy'},
      )
      ..addLayer(
        'horns.extended.v42',
        149,
        horns,
        context.color('fantasyBase'),
        meta: const {'part': 'fantasy'},
      )
      ..addLayer(
        'horns.extended.v42.light',
        150,
        horns.intersect(
          maskFromPredicate((x, y) => positiveMod(x + y, 3) == 0),
        ),
        context.color('fantasyLight'),
        meta: const {'part': 'fantasy'},
      );
  }

  PixelMask _cheekLift(AvatarRenderContext c, AvatarRenderState state) {
    final amount = clampInt(c.integer('v4.cheekLift'), 0, 4);
    if (amount == 0) return PixelMask();
    final left = state.mask('lowerCheekLeftZone');
    final right = state.mask('lowerCheekRightZone');
    final eyeY = c.integer('face.eyeY');
    final raised = left.union(right).intersect(
          maskFromPredicate((x, y) =>
              y >= eyeY + 1 && y <= eyeY + 2 + amount),
        );
    return orderedDither(raised, clampInt(amount + 2, 2, 6));
  }

  PixelMask _symbolRotation(AvatarRenderContext c) {
    final style = c.string('v4.symbolOverlay');
    final rotation = c.integer('v4.symbolRotation');
    if (style == 'none' || rotation == 0) return PixelMask();
    final phase = c.string('v4.eventMotion') == 'symbolOrbit' ? c.phase : 0;
    final offset = positiveMod(rotation + phase, 8);
    final output = PixelMask();
    final points = <(int, int)>[
      (24, 4),
      (37, 9),
      (44, 24),
      (37, 39),
      (24, 44),
      (11, 39),
      (4, 24),
      (11, 9),
    ];
    for (var i = 0; i < clampInt(c.integer('v4.symbolDensity') + 2, 2, 8);
        i++) {
      final point = points[(i + offset) % points.length];
      output
        ..set(point.$1, point.$2)
        ..set(point.$1 - 1, point.$2)
        ..set(point.$1 + 1, point.$2)
        ..set(point.$1, point.$2 - 1)
        ..set(point.$1, point.$2 + 1);
    }
    return output;
  }

  PixelMask _extendedHorns(AvatarRenderContext c) {
    final style = c.string('fantasy.hornStyle');
    const extendedStyles = <String>{
      'ramCurl',
      'bullForward',
      'bullWide',
      'antelopeTall',
      'gazelleThin',
      'deerBranching',
      'mooseFlat',
      'demonHook',
      'demonJagged',
      'dragonBack',
      'dragonSpikes',
      'crownHorns',
      'brokenLeft',
      'brokenRight',
      'unicorn',
      'boneHorns',
      'obsidianHorns',
      'crystalHorns',
      'mechanicalHorns',
      'neonHorns',
      'coralHorns',
      'iceAntlers',
    };
    if (!extendedStyles.contains(style)) return PixelMask();

    final output = PixelMask();
    final top = c.integer('head.topY');
    final length = clampInt(c.integer('fantasy.hornLength'), 1, 10);
    final width = clampInt(c.integer('fantasy.hornWidth'), 1, 5);
    final angle = c.integer('fantasy.hornAngle');
    final curve = c.integer('fantasy.hornCurvature');

    void straightHorn(int x, int direction, int extra,
        {int spread = 0, bool jagged = false}) {
      final tipX = x + direction * (angle + spread);
      final tipY = clampInt(top - length - extra, 0, 47);
      output.fillTriangle(
        (x: x - width, y: top + 2),
        (x: x + width, y: top + 2),
        (x: tipX, y: tipY),
      );
      if (jagged) {
        for (var i = 2; i < length; i += 3) {
          output.line(
            x + direction * (i ~/ 2),
            top - i,
            x + direction * (i ~/ 2 + 3),
            top - i + 1,
          );
        }
      }
    }

    void curvedHorn(int x, int direction, {bool curl = false}) {
      final midX = x + direction * (4 + curve);
      final midY = clampInt(top - length ~/ 2, 0, 47);
      final tipX = x + direction * (curl ? 2 : length ~/ 2 + curve);
      final tipY = clampInt(top - length + (curl ? 4 : 0), 0, 47);
      output
        ..line(x, top + 1, midX, midY, thickness: width)
        ..line(midX, midY, tipX, tipY, thickness: clampInt(width - 1, 1, 4));
      if (curl) {
        output.line(tipX, tipY, x + direction * 5, top - 2,
            thickness: clampInt(width - 1, 1, 3));
      }
    }

    void branchAntler(int x, int direction, {bool flat = false}) {
      final tipX = x + direction * (flat ? 9 : 5);
      final tipY = clampInt(top - length, 0, 47);
      output.line(x, top + 1, tipX, tipY, thickness: width);
      for (var i = 2; i <= 6; i += 2) {
        final y = clampInt(top - i, 0, 47);
        final trunkX = x + direction * (flat ? i : i ~/ 2);
        output.line(
          trunkX,
          y,
          trunkX + direction * (flat ? 6 : 4),
          y - (flat ? 0 : 3),
          thickness: clampInt(width - 1, 1, 3),
        );
      }
    }

    if (style == 'unicorn') {
      straightHorn(24, 1, 2, jagged: true);
    } else if (style == 'ramCurl') {
      curvedHorn(17, -1, curl: true);
      curvedHorn(31, 1, curl: true);
    } else if (style == 'deerBranching' || style == 'iceAntlers') {
      branchAntler(18, -1);
      branchAntler(30, 1);
    } else if (style == 'mooseFlat') {
      branchAntler(18, -1, flat: true);
      branchAntler(30, 1, flat: true);
    } else if (style == 'demonHook') {
      curvedHorn(18, -1);
      curvedHorn(30, 1);
    } else if (style == 'bullForward' || style == 'bullWide') {
      final spread = style == 'bullWide' ? 8 : 4;
      straightHorn(17, -1, -2, spread: spread);
      straightHorn(31, 1, -2, spread: spread);
    } else if (style == 'antelopeTall' || style == 'gazelleThin') {
      straightHorn(19, -1, 3, jagged: style == 'antelopeTall');
      straightHorn(29, 1, 3, jagged: style == 'antelopeTall');
    } else if (style == 'dragonBack' || style == 'dragonSpikes') {
      for (var x = 15; x <= 33; x += 6) {
        straightHorn(x, x < 24 ? -1 : 1, positiveMod(x, 3),
            jagged: style == 'dragonSpikes');
      }
    } else if (style == 'crownHorns' || style == 'coralHorns') {
      for (var x = 14; x <= 34; x += 5) {
        straightHorn(x, x < 24 ? -1 : 1, positiveMod(x, 4),
            jagged: style == 'coralHorns');
      }
    } else if (style == 'brokenLeft') {
      straightHorn(18, -1, -4);
      straightHorn(30, 1, 1);
    } else if (style == 'brokenRight') {
      straightHorn(18, -1, 1);
      straightHorn(30, 1, -4);
    } else {
      final jagged = style == 'demonJagged' || style == 'mechanicalHorns';
      straightHorn(18, -1, 1, jagged: jagged);
      straightHorn(30, 1, 1, jagged: jagged);
    }
    return output;
  }
}
