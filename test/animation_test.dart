import 'package:avatar_genome/avatar_genome.dart';
import 'package:avatar_genome/src/rendering/avatar_animation.dart';
import 'package:test/test.dart';

void main() {
  test('idle timing is deterministic per avatar and varies between avatars',
      () {
    List<bool> blinkPattern(String seed) => List<bool>.generate(
          96,
          (phase) => AvatarAnimationState(
            id: 'idle',
            phase: phase,
            speed: 3,
            amplitude: 2,
            randomKey: seed,
          ).blinkFrame(),
          growable: false,
        );

    final first = blinkPattern('idle-timing-a');
    expect(blinkPattern('idle-timing-a'), first);
    expect(blinkPattern('idle-timing-b'), isNot(first));
    expect(first.where((value) => value).length, greaterThan(0));
  });

  final cases = <String, Map<String, Object>>{
    'blink': <String, Object>{
      'v4.animation': 'blink',
      'v4.animationSpeed': 1,
      'v4.eyewear': 'none',
      'v4.faceMask': 'none',
      'v4.headwear': 'none',
      'eyes.shape': 'round',
      'eyes.width': 5,
      'eyes.height': 3,
      'hair.fringe': 'none',
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
      'v4.faceMask': 'none',
      'v4.mouthProp': 'cigarette',
      'v4.propLength': 7,
      'v4.propAngle': 1,
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
    'talking': <String, Object>{
      'v4.animation': 'talking',
      'mouth.shape': 'full',
      'mouth.width': 7,
      'mouth.height': 2,
    },
    'laughing': <String, Object>{
      'v4.animation': 'laughing',
      'mouth.shape': 'full',
      'mouth.width': 8,
      'mouth.height': 2,
      'v4.earJewelry': 'dangling',
    },
    'scared': <String, Object>{
      'v4.animation': 'scared',
      'eyes.shape': 'round',
      'eyes.width': 5,
      'eyes.height': 3,
      'mouth.shape': 'smallRound',
      'mouth.width': 4,
    },
    'sleeping': <String, Object>{
      'v4.animation': 'sleeping',
      'mouth.shape': 'full',
      'v4.shoulderProp': 'cat',
    },
    'surprised': <String, Object>{
      'v4.animation': 'surprised',
      'eyes.shape': 'round',
      'eyes.width': 5,
      'mouth.shape': 'smallRound',
      'mouth.width': 4,
    },
    'angry': <String, Object>{
      'v4.animation': 'angry',
      'brows.shape': 'angular',
      'mouth.shape': 'full',
    },
    'sad': <String, Object>{
      'v4.animation': 'sad',
      'brows.shape': 'rounded',
      'mouth.shape': 'full',
    },
    'happy': <String, Object>{
      'v4.animation': 'happy',
      'mouth.shape': 'full',
      'v4.neckJewelry': 'medallion',
    },
    'thinking': <String, Object>{
      'v4.animation': 'thinking',
      'eyes.shape': 'round',
      'mouth.shape': 'full',
      'fantasy.antennaStyle': 'ballTip',
      'fantasy.antennaLength': 7,
    },
    'confused': <String, Object>{
      'v4.animation': 'confused',
      'eyes.shape': 'round',
      'mouth.shape': 'full',
      'fantasy.hornStyle': 'curved',
      'fantasy.hornLength': 5,
      'fantasy.hornWidth': 2,
    },
    'hurt': <String, Object>{
      'v4.animation': 'hurt',
      'mouth.shape': 'full',
      'brows.shape': 'angular',
    },
    'celebration': <String, Object>{
      'v4.animation': 'celebration',
      'mouth.shape': 'full',
      'v4.earJewelry': 'dangling',
      'fantasy.hornStyle': 'curved',
      'fantasy.hornLength': 6,
      'fantasy.hornWidth': 2,
      'v4.shoulderProp': 'parrot',
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
      final imageHashes =
          animation.frames.map((frame) => frame.imageHash).toSet().length;
      final layerHashes = animation.frames
          .map((frame) => _animationSignature(entry.key, frame))
          .toSet()
          .length;
      expect(imageHashes > 1 || layerHashes > 1, isTrue,
          reason: 'Animation ${entry.key} should change either the composed '
              'image or its animated layers.');
      for (final frame in animation.frames) {
        for (final layer in frame.layers) {
          expect(layer.mask.count, layer.sourcePixelCount,
              reason: 'Animation ${entry.key} clipped layer ${layer.id}.');
        }
      }
    });
  }

  test('sleeping adds dedicated sleep effect layer', () {
    final generator = AvatarGenerator();
    final request = AvatarRequest(
      seed: 'animation-sleep-effect',
      overrides: const <String, Object>{
        'v4.animation': 'sleeping',
        'mouth.shape': 'full',
      },
    );

    final frame = generator.generate(request);
    expect(frame.layers.any((layer) => layer.id == 'effect.sleep'), isTrue);
    final sleep = frame.layers.singleWhere(
      (layer) => layer.id == 'effect.sleep',
    );
    expect(sleep.mask.bounds?.width, greaterThanOrEqualTo(10));
    expect(sleep.mask.bounds?.height, greaterThanOrEqualTo(10));
  });

  test('scared remains readable with an occluded face', () {
    final generator = AvatarGenerator();
    final frame = generator.generate(
      const AvatarRequest(
        seed: 'animation-occluded-shock',
        phase: 2,
        overrides: <String, Object>{
          'v4.animation': 'scared',
          'v4.faceMask': 'respirator',
          'v4.eyewear': 'roundGlasses',
          'v4.headwear': 'baseballCap',
        },
      ),
    );

    expect(frame.layers.any((layer) => layer.id == 'effect.shock'), isTrue);
  });

  test('laughing moves head independently from torso', () {
    final generator = AvatarGenerator();
    final relativeOffsets = <int>{};
    for (var phase = 0; phase < 12; phase++) {
      final frame = generator.generate(
        AvatarRequest(
          seed: 'animation-layered-laugh',
          phase: phase,
          overrides: const <String, Object>{
            'v4.animation': 'laughing',
            'v4.headwear': 'baseballCap',
          },
        ),
      );
      final head = frame.layers
          .singleWhere((layer) => layer.id == 'head.base')
          .mask
          .bounds;
      final torso = frame.layers
          .singleWhere((layer) => layer.id == 'torso.outline')
          .mask
          .bounds;
      expect(head, isNotNull);
      expect(torso, isNotNull);
      relativeOffsets.add(head!.y - torso!.y);
    }

    expect(relativeOffsets.length, greaterThan(1));
  });

  test('non-facial emotion cues remain available outside the face', () {
    final generator = AvatarGenerator();
    for (final id in const <String>[
      'talking',
      'angry',
      'sad',
      'happy',
      'thinking',
      'confused',
      'hurt',
      'celebration',
    ]) {
      final frame = generator.generate(
        AvatarRequest(
          seed: 'animation-external-cue-$id',
          phase: 3,
          overrides: <String, Object>{
            'v4.animation': id,
            'v4.faceMask': 'gasMask',
            'v4.eyewear': 'cyberVisor',
            'v4.headwear': 'spaceHelmet',
          },
        ),
      );
      expect(
        frame.layers.any((layer) => layer.id == 'effect.emotion.$id'),
        isTrue,
        reason: '$id should remain readable when the face is occluded.',
      );
    }
  });

  test('utility animations retain a native cue without optional equipment', () {
    final generator = AvatarGenerator();
    for (final id in const <String>[
      'blink',
      'lookAround',
      'smoke',
      'hairWind',
      'jewelrySwing',
      'glowPulse',
      'auraPulse',
      'particles',
    ]) {
      final frames = List<AvatarResult>.generate(
        8,
        (phase) => generator.generate(
          AvatarRequest(
            seed: 'animation-native-cue-$id',
            phase: phase,
            overrides: <String, Object>{
              'v4.animation': id,
              'v4.mouthProp': 'none',
              'v4.earJewelry': 'none',
              'v4.neckJewelry': 'none',
              'v4.aura': 'none',
              'v4.effect': 'none',
            },
          ),
        ),
      );
      final cueId = 'effect.utility.$id';
      expect(
        frames.every((frame) => frame.layers.any((layer) => layer.id == cueId)),
        isTrue,
        reason: '$id should have a native cue independent of optional gear.',
      );
      expect(
        frames
            .map((frame) => frame.layers
                .singleWhere((layer) => layer.id == cueId)
                .mask
                .data
                .join())
            .toSet()
            .length,
        greaterThan(1),
        reason: '$id native cue should animate across phases.',
      );
    }
  });
}

String _animationSignature(String animation, AvatarResult frame) {
  final prefixes = switch (animation) {
    'blink' => const <String>['eyes.'],
    'lookAround' => const <String>['eyes.'],
    'smoke' => const <String>['mouthProp.', 'mouth.'],
    'hairWind' => const <String>['hair.'],
    'jewelrySwing' => const <String>['jewelry.'],
    'glowPulse' => const <String>['aura.', 'cyber.', 'armor.glow'],
    'auraPulse' => const <String>['aura.'],
    'particles' => const <String>['effect.'],
    'talking' => const <String>['mouth.'],
    'laughing' => const <String>['mouth.', 'jewelry.'],
    'scared' => const <String>['eyes.', 'mouth.'],
    'sleeping' => const <String>['eyes.', 'mouth.', 'effect.sleep'],
    'surprised' => const <String>['eyes.', 'mouth.'],
    'angry' => const <String>['brows', 'mouth.', 'eyes.lids'],
    'sad' => const <String>['brows', 'mouth.', 'eyes.lids'],
    'happy' => const <String>['mouth.'],
    'thinking' => const <String>['eyes.', 'fantasy.front'],
    'confused' => const <String>['eyes.', 'brows', 'fantasy.'],
    'hurt' => const <String>['mouth.', 'eyes.lids'],
    'celebration' => const <String>[
        'mouth.',
        'jewelry.',
        'fantasy.',
        'shoulderProp.'
      ],
    _ => const <String>[],
  };
  final buffer = StringBuffer();
  for (final layer in frame.layers) {
    if (prefixes.any(layer.id.startsWith)) {
      buffer
        ..write(layer.id)
        ..write(':')
        ..write(layer.mask.count)
        ..write(':')
        ..write(layer.mask.bounds?.x ?? -1)
        ..write(':')
        ..write(layer.mask.bounds?.y ?? -1)
        ..write('|');
    }
  }
  return buffer.toString();
}
