import 'package:avatar_genome/avatar_genome.dart';
import 'package:test/test.dart';

void main() {
  test('static phases reuse one clip-wide camera decision', () {
    final generator = AvatarGenerator();
    final first = generator.generate(const AvatarRequest(
      seed: 'camera-cache-reuse',
      overrides: <String, Object>{'v4.animation': 'idle'},
    ));
    final second = generator.generate(const AvatarRequest(
      seed: 'camera-cache-reuse',
      phase: 7,
      overrides: <String, Object>{'v4.animation': 'idle'},
    ));

    final firstCache =
        first.layout.graph.nodes['rig.cameraCache']!.value as Map;
    final secondCache =
        second.layout.graph.nodes['rig.cameraCache']!.value as Map;
    expect(firstCache['hit'], isFalse);
    expect(secondCache['hit'], isTrue);
    expect(
      first.layout.graph.nodes['rig.camera']!.value,
      second.layout.graph.nodes['rig.camera']!.value,
    );
  });
}
