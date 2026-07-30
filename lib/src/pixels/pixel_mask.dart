import 'dart:math' as math;
import 'dart:typed_data';

import '../geometry/pixel_rect.dart';
import '../util/math_utils.dart';

final class PixelMask {
  PixelMask({this.width = 48, this.height = 48, Uint8List? data})
      : data = data == null
            ? Uint8List(width * height)
            : Uint8List.fromList(data) {
    if (this.data.length != width * height) {
      throw ArgumentError.value(this.data.length, 'data.length');
    }
  }

  factory PixelMask.filled({int width = 48, int height = 48}) {
    final mask = PixelMask(width: width, height: height);
    mask.data.fillRange(0, mask.data.length, 1);
    return mask;
  }

  final int width;
  final int height;
  final Uint8List data;

  PixelMask clone() => PixelMask(width: width, height: height, data: data);

  int index(int x, int y) => y * width + x;
  bool inBounds(int x, int y) => x >= 0 && x < width && y >= 0 && y < height;
  int get(int x, int y) => inBounds(x, y) ? data[index(x, y)] : 0;

  PixelMask set(int x, int y, [bool value = true]) {
    if (inBounds(x, y)) {
      data[index(x, y)] = value ? 1 : 0;
    }
    return this;
  }

  PixelMask hLine(int x1, int x2, int y, [bool value = true]) {
    if (y < 0 || y >= height) return this;
    final minX = x1 < x2 ? x1 : x2;
    final maxX = x1 > x2 ? x1 : x2;
    if (maxX < 0 || minX >= width) return this;
    final a = clampInt(minX, 0, width - 1);
    final b = clampInt(maxX, 0, width - 1);
    for (var x = a; x <= b; x++) {
      set(x, y, value);
    }
    return this;
  }

  PixelMask vLine(int x, int y1, int y2, [bool value = true]) {
    if (x < 0 || x >= width) return this;
    final minY = y1 < y2 ? y1 : y2;
    final maxY = y1 > y2 ? y1 : y2;
    if (maxY < 0 || minY >= height) return this;
    final a = clampInt(minY, 0, height - 1);
    final b = clampInt(maxY, 0, height - 1);
    for (var y = a; y <= b; y++) {
      set(x, y, value);
    }
    return this;
  }

  PixelMask fillRect(int x, int y, int rectWidth, int rectHeight,
      [bool value = true]) {
    for (var yy = y; yy < y + rectHeight; yy++) {
      hLine(x, x + rectWidth - 1, yy, value);
    }
    return this;
  }

  PixelMask fillEllipse(num cx, num cy, num rx, num ry, [bool value = true]) {
    final radiusX = rx < 0 ? 0.0 : rx.toDouble();
    final radiusY = ry < 0 ? 0.0 : ry.toDouble();
    if (radiusX == 0 && radiusY == 0) {
      return set(cx.round(), cy.round(), value);
    }
    for (var y = (cy - radiusY).floor(); y <= (cy + radiusY).ceil(); y++) {
      for (var x = (cx - radiusX).floor(); x <= (cx + radiusX).ceil(); x++) {
        final dx = radiusX == 0 ? 0.0 : (x - cx) / radiusX;
        final dy = radiusY == 0 ? 0.0 : (y - cy) / radiusY;
        if (dx * dx + dy * dy <= 1.02) {
          set(x, y, value);
        }
      }
    }
    return this;
  }

  PixelMask fillTriangle(
    ({num x, num y}) a,
    ({num x, num y}) b,
    ({num x, num y}) c, [
    bool value = true,
  ]) {
    final minY = [a.y, b.y, c.y].reduce((x, y) => x < y ? x : y).floor();
    final maxY = [a.y, b.y, c.y].reduce((x, y) => x > y ? x : y).ceil();
    final minX = [a.x, b.x, c.x].reduce((x, y) => x < y ? x : y).floor();
    final maxX = [a.x, b.x, c.x].reduce((x, y) => x > y ? x : y).ceil();
    double area(
            ({num x, num y}) p1, ({num x, num y}) p2, ({num x, num y}) p3) =>
        (p1.x * (p2.y - p3.y) + p2.x * (p3.y - p1.y) + p3.x * (p1.y - p2.y))
            .toDouble();
    final total = area(a, b, c);
    if (total == 0) return this;
    for (var y = minY; y <= maxY; y++) {
      for (var x = minX; x <= maxX; x++) {
        final p = (x: x, y: y);
        final w1 = area(p, b, c) / total;
        final w2 = area(a, p, c) / total;
        final w3 = area(a, b, p) / total;
        if (w1 >= -0.01 && w2 >= -0.01 && w3 >= -0.01) {
          set(x, y, value);
        }
      }
    }
    return this;
  }

  PixelMask line(int x0, int y0, int x1, int y1,
      {bool value = true, int thickness = 1}) {
    var x = x0;
    var y = y0;
    final dx = (x1 - x).abs();
    final sx = x < x1 ? 1 : -1;
    final dy = -(y1 - y).abs();
    final sy = y < y1 ? 1 : -1;
    var error = dx + dy;
    while (true) {
      for (var oy = -((thickness - 1) ~/ 2); oy <= thickness ~/ 2; oy++) {
        for (var ox = -((thickness - 1) ~/ 2); ox <= thickness ~/ 2; ox++) {
          set(x + ox, y + oy, value);
        }
      }
      if (x == x1 && y == y1) break;
      final e2 = 2 * error;
      if (e2 >= dy) {
        error += dy;
        x += sx;
      }
      if (e2 <= dx) {
        error += dx;
        y += sy;
      }
    }
    return this;
  }

  PixelMask union(PixelMask other) {
    _requireSameSize(other);
    final output = clone();
    for (var i = 0; i < data.length; i++) {
      output.data[i] = data[i] != 0 || other.data[i] != 0 ? 1 : 0;
    }
    return output;
  }

  PixelMask intersect(PixelMask other) {
    _requireSameSize(other);
    final output = clone();
    for (var i = 0; i < data.length; i++) {
      output.data[i] = data[i] != 0 && other.data[i] != 0 ? 1 : 0;
    }
    return output;
  }

  PixelMask subtract(PixelMask other) {
    _requireSameSize(other);
    final output = clone();
    for (var i = 0; i < data.length; i++) {
      output.data[i] = data[i] != 0 && other.data[i] == 0 ? 1 : 0;
    }
    return output;
  }

  PixelMask translated(int dx, int dy) {
    final output = PixelMask(width: width, height: height);
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        if (get(x, y) != 0) output.set(x + dx, y + dy);
      }
    }
    return output;
  }

  /// Nearest-neighbour rotation around a pixel-art joint.
  PixelMask rotated(
    int degrees, {
    required int pivotX,
    required int pivotY,
  }) {
    if (degrees == 0) return clone();
    final output = PixelMask(width: width, height: height);
    final radians = degrees * math.pi / 180;
    final cosine = math.cos(radians);
    final sine = math.sin(radians);
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final dx = x - pivotX;
        final dy = y - pivotY;
        final sourceX = pivotX + cosine * dx + sine * dy;
        final sourceY = pivotY - sine * dx + cosine * dy;
        if (get(sourceX.round(), sourceY.round()) != 0) {
          output.set(x, y);
        }
      }
    }
    return output;
  }

  /// Nearest-neighbour pixel-art scaling around a stable anchor.
  PixelMask scaled(double scale, {int anchorX = 24, int anchorY = 47}) {
    if (scale == 1) return clone();
    final output = PixelMask(width: width, height: height);
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        if (get(x, y) == 0) continue;
        final nx = anchorX + ((x - anchorX) * scale).round();
        final ny = anchorY + ((y - anchorY) * scale).round();
        output.set(nx, ny);
      }
    }
    return output;
  }

  PixelMask mirrorX() {
    final output = PixelMask(width: width, height: height);
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        if (get(x, y) != 0) output.set(width - 1 - x, y);
      }
    }
    return output;
  }

  PixelMask dilated({bool diagonal = false, int iterations = 1}) {
    var base = clone();
    final neighbours = diagonal
        ? const <(int, int)>[
            (-1, -1),
            (0, -1),
            (1, -1),
            (-1, 0),
            (0, 0),
            (1, 0),
            (-1, 1),
            (0, 1),
            (1, 1),
          ]
        : const <(int, int)>[(0, -1), (-1, 0), (0, 0), (1, 0), (0, 1)];
    for (var iteration = 0; iteration < iterations; iteration++) {
      final output = base.clone();
      for (var y = 0; y < height; y++) {
        for (var x = 0; x < width; x++) {
          if (base.get(x, y) == 0) continue;
          for (final (dx, dy) in neighbours) {
            output.set(x + dx, y + dy);
          }
        }
      }
      base = output;
    }
    return base;
  }

  PixelMask eroded({bool diagonal = false}) {
    final output = PixelMask(width: width, height: height);
    final neighbours = diagonal
        ? const <(int, int)>[
            (-1, -1),
            (0, -1),
            (1, -1),
            (-1, 0),
            (0, 0),
            (1, 0),
            (-1, 1),
            (0, 1),
            (1, 1),
          ]
        : const <(int, int)>[(0, -1), (-1, 0), (0, 0), (1, 0), (0, 1)];
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        if (neighbours.every((n) => get(x + n.$1, y + n.$2) != 0)) {
          output.set(x, y);
        }
      }
    }
    return output;
  }

  PixelMask outline({bool diagonal = false}) =>
      dilated(diagonal: diagonal).subtract(this);

  int get count {
    var total = 0;
    for (final value in data) {
      total += value;
    }
    return total;
  }

  PixelRect? get bounds {
    var minX = width;
    var minY = height;
    var maxX = -1;
    var maxY = -1;
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        if (get(x, y) == 0) continue;
        if (x < minX) minX = x;
        if (y < minY) minY = y;
        if (x > maxX) maxX = x;
        if (y > maxY) maxY = y;
      }
    }
    if (maxX < 0) return null;
    return PixelRect(minX, minY, maxX - minX + 1, maxY - minY + 1);
  }

  List<List<(int, int)>> connectedComponents() {
    final seen = Uint8List(data.length);
    final output = <List<(int, int)>>[];
    const directions = <(int, int)>[(1, 0), (-1, 0), (0, 1), (0, -1)];
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final start = index(x, y);
        if (data[start] == 0 || seen[start] != 0) continue;
        final queue = <(int, int)>[(x, y)];
        final pixels = <(int, int)>[];
        seen[start] = 1;
        for (var cursor = 0; cursor < queue.length; cursor++) {
          final (cx, cy) = queue[cursor];
          pixels.add((cx, cy));
          for (final (dx, dy) in directions) {
            final nx = cx + dx;
            final ny = cy + dy;
            if (!inBounds(nx, ny)) continue;
            final next = index(nx, ny);
            if (data[next] != 0 && seen[next] == 0) {
              seen[next] = 1;
              queue.add((nx, ny));
            }
          }
        }
        output.add(pixels);
      }
    }
    return output;
  }

  PixelMask removeSmallComponents(int minimumSize, {int maxComponents = 999}) {
    final components = connectedComponents()
      ..sort((a, b) => b.length.compareTo(a.length));
    final output = PixelMask(width: width, height: height);
    var kept = 0;
    for (final component in components) {
      if (component.length < minimumSize || kept >= maxComponents) continue;
      kept++;
      for (final (x, y) in component) {
        output.set(x, y);
      }
    }
    return output;
  }

  void _requireSameSize(PixelMask other) {
    if (other.width != width || other.height != height) {
      throw ArgumentError('Mask dimensions differ.');
    }
  }
}
