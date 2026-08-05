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

  test('rig pipeline renderSingle renders the requested phase exactly', () {
    final generator = AvatarGenerator(cacheCapacity: 0);
    final request = AvatarRequest(
      seed: 'pipeline-phase-contract',
      phase: 19,
      overrides: const <String, Object>{
        'v4.animation': 'idle',
        'v4.animationAmplitude': 4,
      },
    );

    final single = generator.pipeline.renderSingle(request);
    final clip = generator.pipeline.renderClip(request, frameCount: 20);
    final singleFrame = single.frames.single;
    final clipFrame = clip.frames[19];

    expect(singleFrame.phase, 19);
    expect(
      singleFrame.image.hashWithPalette(single.prepared.palette.colors),
      clipFrame.image.hashWithPalette(clip.prepared.palette.colors),
    );
  });
}
