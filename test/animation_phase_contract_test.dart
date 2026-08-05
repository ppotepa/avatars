import 'package:avatar_genome/avatar_genome.dart';
import 'package:test/test.dart';

void main() {
  test('single generation preserves phases beyond camera sampling window', () {
    final generator = AvatarGenerator();
    final request = AvatarRequest(
      seed: 'phase-contract',
      phase: 16,
      overrides: const <String, Object>{
        'v4.animation': 'idle',
        'v4.animationAmplitude': 4,
        'hair.lengthStyle': 'belowShoulder',
        'hair.length': 15,
      },
    );

    final single = generator.generate(request);
    final clip = generator.generateAnimation(request, frameCount: 20);

    expect(single.imageHash, clip.frames[16].imageHash);
  });
}
