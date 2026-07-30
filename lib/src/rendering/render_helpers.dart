import '../pixels/pixel_mask.dart';
import '../util/math_utils.dart';

PixelMask maskFromPredicate(bool Function(int x, int y) predicate) {
  final mask = PixelMask();
  for (var y = 0; y < 48; y++) {
    for (var x = 0; x < 48; x++) {
      if (predicate(x, y)) mask.set(x, y);
    }
  }
  return mask;
}

PixelMask maskRect(int x, int y, int width, int height) =>
    PixelMask()..fillRect(x, y, width, height);

int countOverlap(PixelMask a, PixelMask b) => a.intersect(b).count;

bool masksTouch(PixelMask a, PixelMask b) =>
    a.dilated(diagonal: true).intersect(b).count > 0;

({int left, int right})? rowBounds(PixelMask mask, int y) {
  var left = mask.width;
  var right = -1;
  for (var x = 0; x < mask.width; x++) {
    if (mask.get(x, y) == 0) continue;
    if (x < left) left = x;
    if (x > right) right = x;
  }
  return right < 0 ? null : (left: left, right: right);
}

PixelMask largestComponent(PixelMask mask) {
  final components = mask.connectedComponents();
  if (components.isEmpty) return PixelMask();
  components.sort((a, b) => b.length.compareTo(a.length));
  final output = PixelMask();
  for (final (x, y) in components.first) output.set(x, y);
  return output;
}

PixelMask orderedDither(PixelMask area, int amount, {int phase = 0}) {
  final limit = clampInt(amount, 0, 8);
  const matrix = <List<int>>[
    <int>[0, 4, 1, 5],
    <int>[6, 2, 7, 3],
    <int>[1, 5, 0, 4],
    <int>[7, 3, 6, 2],
  ];
  final output = PixelMask();
  for (var y = 0; y < 48; y++) {
    for (var x = 0; x < 48; x++) {
      if (area.get(x, y) != 0 && matrix[(y + phase) % 4][x % 4] < limit) {
        output.set(x, y);
      }
    }
  }
  return output;
}

double rowWidth(
  ({
    double top,
    double temple,
    double cheek,
    double cheek2,
    double jaw,
    double chin
  }) controls,
  double t,
) {
  final points = <(double, double)>[
    (0, controls.top),
    (0.15, controls.temple),
    (0.42, controls.cheek),
    (0.65, controls.cheek2),
    (0.84, controls.jaw),
    (1, controls.chin),
  ];
  for (var i = 0; i < points.length - 1; i++) {
    if (t <= points[i + 1].$1) {
      final a = points[i];
      final b = points[i + 1];
      return lerpDouble(a.$2, b.$2, (t - a.$1) / (b.$1 - a.$1));
    }
  }
  return controls.chin;
}

PixelMask shadingMask(
  PixelMask base, {
  required String kind,
  required int strength,
  double centerX = 23.5,
  int eyeY = 17,
  int mouthY = 27,
  int topY = 5,
}) {
  final shadow = PixelMask();
  if (strength <= 0) return shadow;
  for (var y = 0; y < 48; y++) {
    for (var x = 0; x < 48; x++) {
      if (base.get(x, y) == 0) continue;
      final rightEdge = base.get(x + 1, y) == 0;
      final bottomEdge = base.get(x, y + 1) == 0;
      var shade = false;
      switch (kind) {
        case 'skin':
          shade = (x > centerX + 2 && rightEdge) ||
              (y > mouthY && bottomEdge) ||
              (x > centerX + 5 && y > eyeY);
          break;
        case 'hair':
          shade = (rightEdge && x > centerX) || (bottomEdge && y > topY + 3);
          break;
        case 'neck':
          shade = x > centerX || y <= topY + strength - 1;
          break;
        case 'clothing':
          shade = (rightEdge && x > centerX) ||
              bottomEdge ||
              ((x - centerX).abs() > 12 && positiveMod(y, 3) == 0);
          break;
        default:
          shade = rightEdge || bottomEdge;
          break;
      }
      if (shade) shadow.set(x, y);
    }
  }
  var result = shadow.intersect(base);
  if (strength == 1) {
    result = result
        .intersect(maskFromPredicate((x, y) => positiveMod(x + y, 2) == 0));
  }
  if (strength > 1) {
    result = result.union(result.translated(-1, 0).intersect(base));
  }
  if (strength > 2) {
    result = result.union(result.translated(0, -1).intersect(base));
  }
  return result.intersect(base);
}

PixelMask highlightMask(
  PixelMask base, {
  required String kind,
  required int strength,
  double centerX = 23.5,
  int eyeY = 17,
  int mouthY = 27,
  int topY = 5,
}) {
  final output = PixelMask();
  if (strength <= 0) return output;
  for (var y = 0; y < 48; y++) {
    for (var x = 0; x < 48; x++) {
      if (base.get(x, y) == 0) continue;
      final leftEdge = base.get(x - 1, y) == 0;
      final topEdge = base.get(x, y - 1) == 0;
      final light = switch (kind) {
        'skin' => (x < centerX - 3 && leftEdge && y < mouthY) ||
            (topEdge && x < centerX),
        'hair' => (topEdge && x < centerX + 2) || (leftEdge && y < eyeY),
        'neck' => leftEdge && x < centerX,
        'clothing' => topEdge && x < centerX,
        _ => leftEdge || topEdge,
      };
      if (light) output.set(x, y);
    }
  }
  var result = output.intersect(base);
  if (strength == 1) {
    result = result
        .intersect(maskFromPredicate((x, y) => positiveMod(x + y, 2) == 0));
  }
  if (strength > 2) {
    result = result.union(result.translated(1, 0).intersect(base));
  }
  return result.intersect(base);
}

const List<int> _cycleLut = <int>[
  0,
  195,
  383,
  556,
  707,
  831,
  924,
  981,
  1000,
  981,
  924,
  831,
  707,
  556,
  383,
  195,
  0,
  -195,
  -383,
  -556,
  -707,
  -831,
  -924,
  -981,
  -1000,
  -981,
  -924,
  -831,
  -707,
  -556,
  -383,
  -195,
];

/// Returns a deterministic sinusoid-like integer offset.
///
/// The lookup table avoids platform math-library differences in animation
/// frame generation. [period] is expressed in integer render phases.
int cyclicOffset(int phase, int period, int amplitude) {
  final safePeriod = period < 4 ? 4 : period;
  final safeAmplitude = amplitude < 0 ? -amplitude : amplitude;
  final index =
      positiveMod((phase * _cycleLut.length) ~/ safePeriod, _cycleLut.length);
  final scaled = _cycleLut[index] * safeAmplitude;
  if (scaled >= 0) return (scaled + 500) ~/ 1000;
  return -((-scaled + 500) ~/ 1000);
}
