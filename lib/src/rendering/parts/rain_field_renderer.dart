import '../../pixels/pixel_mask.dart';
import '../../util/math_utils.dart';
import '../render_model.dart';

final class RainFieldRenderer implements AvatarPartRenderer {
  const RainFieldRenderer();

  static const Set<String> styles = <String>{
    'rain',
    'heavyRain',
    'lightDrizzle',
  };

  @override
  void render(AvatarRenderContext context, AvatarRenderState state) {
    final style = context.string('v4.weather');
    if (!styles.contains(style)) return;

    final density = clampInt(context.integer('v4.weatherDensity', 3), 1, 6);
    final globalWind = clampInt(context.integer('v4.weatherDrift'), -4, 4);
    final count = switch (style) {
      'heavyRain' => 18 + density * 7,
      'lightDrizzle' => 6 + density * 3,
      _ => 12 + density * 5,
    };
    final back = PixelMask();
    final middle = PixelMask();
    final front = PixelMask();
    final splash = PixelMask();
    final collision = _collisionMask(state);
    final trajectories = <Object>[];

    for (var index = 0; index < count; index++) {
      final baseRandom = context.random('rain.field.$style.$index');
      final depth = index % 3;
      final speedY = switch (style) {
        'lightDrizzle' => 2 + depth,
        'heavyRain' => 4 + depth,
        _ => 3 + depth,
      };
      final localWind = globalWind + baseRandom.nextInt(-1, 1);
      final speedX = localWind == 0
          ? 0
          : localWind.sign * clampInt(localWind.abs() + depth ~/ 2, 1, 5);
      final streakLength = switch (style) {
        'lightDrizzle' => 1 + depth,
        'heavyRain' => 2 + depth,
        _ => 2 + depth,
      };
      final cycle =
          clampInt(58 ~/ speedY + 5 + baseRandom.nextInt(0, 5), 10, 36);
      final spawnPhase = baseRandom.nextInt(0, cycle - 1);
      final cycleIndex = (context.phase - spawnPhase) ~/ cycle;
      final age = positiveMod(context.phase - spawnPhase, cycle);
      final cycleRandom = context.random('rain.field.$style.$index.$cycleIndex');
      final startX = cycleRandom.nextInt(-8, 55);
      final startY = cycleRandom.nextInt(-12, -2);
      final x = startX + speedX * age;
      final y = startY + speedY * age;
      if (y < -streakLength || y > 52 || x < -10 || x > 58) continue;

      final magnitude = clampInt(speedX.abs() + speedY, 1, 20);
      final tailX = x - (speedX * streakLength / magnitude).round();
      final tailY = y - (speedY * streakLength / magnitude).round();
      final target = depth == 0 ? back : depth == 1 ? middle : front;
      target.line(tailX, tailY, x, y);

      final hit = _firstHit(collision, tailX, tailY, x, y);
      if (hit != null && depth > 0) {
        target.set(hit.$1, hit.$2, false);
        _splash(splash, hit.$1, hit.$2, speedX.sign);
      } else if (y >= 47 && depth > 0) {
        _splash(splash, x, 47, speedX.sign);
      }

      if (index < 12) {
        trajectories.add(<String, Object>{
          'depth': depth,
          'x': x,
          'y': y,
          'velocityX': speedX,
          'velocityY': speedY,
          'tailX': tailX,
          'tailY': tailY,
          'length': streakLength,
        });
      }
    }

    state
      ..addLayer(
        'rain.field.back',
        7,
        back,
        context.color('weatherRainDark'),
        nodeId: 'atmosphere',
        meta: const <String, Object?>{
          'part': 'rain',
          'depth': 'back',
          'rigSegment': 'atmosphere',
        },
      )
      ..addLayer(
        'rain.field.middle',
        232,
        middle,
        context.color('weatherRainBase'),
        nodeId: 'foreground',
        meta: const <String, Object?>{
          'part': 'rain',
          'depth': 'middle',
          'rigSegment': 'foreground',
        },
      )
      ..addLayer(
        'rain.field.front',
        236,
        front,
        context.color('weatherRainLight'),
        nodeId: 'foreground',
        meta: const <String, Object?>{
          'part': 'rain',
          'depth': 'front',
          'rigSegment': 'foreground',
        },
      )
      ..addLayer(
        'rain.field.splash',
        237,
        splash,
        context.color('weatherLightning'),
        nodeId: 'foreground',
        meta: const <String, Object?>{
          'part': 'rainSplash',
          'rigSegment': 'foreground',
        },
      );

    state.metadata['rainField'] = <String, Object>{
      'style': style,
      'globalWind': globalWind,
      'dropCount': count,
      'trajectories': trajectories,
    };
  }

  PixelMask _collisionMask(AvatarRenderState state) {
    var output = PixelMask();
    for (final id in const <String>[
      'headwear',
      'head',
      'hair.all',
      'torso',
      'armor',
      'cape',
      'shoulderProp',
    ]) {
      final mask = state.mask(id);
      if (mask.count > 0) output = output.union(mask);
    }
    return output;
  }

  (int, int)? _firstHit(
    PixelMask collision,
    int x0,
    int y0,
    int x1,
    int y1,
  ) {
    final steps = clampInt((x1 - x0).abs() + (y1 - y0).abs(), 1, 16);
    for (var step = 0; step <= steps; step++) {
      final x = (x0 + (x1 - x0) * step / steps).round();
      final y = (y0 + (y1 - y0) * step / steps).round();
      if (collision.get(x, y) != 0) return (x, y);
    }
    return null;
  }

  void _splash(PixelMask mask, int x, int y, int direction) {
    mask
      ..set(x, y)
      ..set(x - 1, y)
      ..set(x + 1, y)
      ..set(x - 1 - direction, y - 1)
      ..set(x + 1 - direction, y - 1);
  }
}
