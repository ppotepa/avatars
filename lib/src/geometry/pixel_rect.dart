import 'point.dart';

final class PixelRect {
  const PixelRect(this.x, this.y, this.width, this.height);

  final int x;
  final int y;
  final int width;
  final int height;

  int get left => x;
  int get top => y;
  int get right => x + width - 1;
  int get bottom => y + height - 1;
  bool get isEmpty => width <= 0 || height <= 0;
  PixelPoint get center => PixelPoint(x + width ~/ 2, y + height ~/ 2);

  bool contains(int px, int py) =>
      px >= x && px <= right && py >= y && py <= bottom;

  PixelRect inflate(int amount) => PixelRect(
        x - amount,
        y - amount,
        width + amount * 2,
        height + amount * 2,
      );

  Map<String, Object> toJson() => <String, Object>{
        'x': x,
        'y': y,
        'width': width,
        'height': height,
      };
}
