import 'package:avatar_genome/avatar_genome.dart';
import 'package:test/test.dart';

void main() {
  test('actor metrics exclude an opaque full-canvas background', () {
    final result = AvatarGenerator().generate(const AvatarRequest(
      seed: 'actor-metrics-background',
      overrides: <String, Object>{
        'v4.background': 'solid',
        'v4.weather': 'none',
        'v4.effect': 'none',
        'v4.aura': 'none',
      },
    ));

    final metrics = result.metrics;
    expect(metrics.occupiedPixelCount, greaterThan(metrics.actorOccupiedPixelCount));
    expect(metrics.actorOccupiedPixelCount, greaterThan(0));
    expect(metrics.actorAreaOccupancy, greaterThan(0));
    expect(metrics.actorAreaOccupancy, lessThan(1));
    expect(metrics.actorHeightOccupancy, greaterThan(.70));
    expect(metrics.faceHeightOccupancy, greaterThan(.20));
  });
}
