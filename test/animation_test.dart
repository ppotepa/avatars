import 'package:avatar_genome/avatar_genome.dart';
import 'package:test/test.dart';

void main() {
  final cases = <String, Map<String, Object>>{
    'blink': <String, Object>{
      'v4.animation': 'blink',
      'v4.animationSpeed': 1,
      'eyes.shape': 'round',
      'eyes.width': 5,
      'eyes.height': 3,
    },
    'lookAround': <String, Object>{
      'v4.animation': 'lookAround',
      'v4.animationSpeed': 1,
      'v4.animationAmplitude': 2,
      'eyes.shape': 'round',
      'eyes.width': 5,
      'eyes.height': 3,
      'eyes.irisStyle': 'large',
      'eyes.pupilStyle': 'medium',
    },
    'idle': <String, Object>{
      'v4.animation': 'idle',
      'v4.animationSpeed': 1,
      'v4.animationAmplitude': 2,
    },
    'smoke': <String, Object>{
      'v4.mouthProp': 'cigarette',
      'v4.smokeAmount': 4,
      'v4.animation': 'smoke',
    },
    'hairWind': <String, Object>{
      'v4.animation': 'hairWind',
      'v4.animationSpeed': 1,
      'v4.animationAmplitude': 2,
      'hair.lengthStyle': 'shoulder',
      'hair.length': 12,
      'hair.volumeBack': 3,
      'hair.volumeSides': 2,
    },
    'jewelrySwing': <String, Object>{
      'v4.animation': 'jewelrySwing',
      'v4.animationSpeed': 1,
      'v4.animationAmplitude': 2,
      'v4.earJewelry': 'dangling',
      'v4.neckJewelry': 'medallion',
      'v4.jewelrySize': 2,
    },
    'glowPulse': <String, Object>{
      'v4.animation': 'glowPulse',
      'v4.aura': 'electric',
      'v4.animationAmplitude': 3,
    },
    'auraPulse': <String, Object>{
      'v4.animation': 'auraPulse',
      'v4.aura': 'magic',
      'v4.animationAmplitude': 3,
    },
    'particles': <String, Object>{
      'v4.animation': 'particles',
      'v4.effect': 'snow',
      'v4.particleDensity': 4,
    },
  };

  for (final entry in cases.entries) {
    test('${entry.key} preserves genome identity and changes pixels', () {
      final generator = AvatarGenerator();
      final request = AvatarRequest(
        seed: 'animation-${entry.key}',
        overrides: entry.value,
      );
      final animation = generator.generateAnimation(request, frameCount: 16);

      expect(animation.frames, hasLength(16));
      expect(
        animation.frames.map((frame) => frame.genome.seed).toSet(),
        <String>{request.seed},
      );
      expect(
        animation.frames.map((frame) => frame.imageHash).toSet().length,
        greaterThan(1),
      );
    });
  }
}
