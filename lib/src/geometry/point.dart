final class PixelPoint {
  const PixelPoint(this.x, this.y);

  final int x;
  final int y;

  PixelPoint translate(int dx, int dy) => PixelPoint(x + dx, y + dy);

  Map<String, Object> toJson() => <String, Object>{'x': x, 'y': y};

  @override
  bool operator ==(Object other) =>
      other is PixelPoint && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);
}
