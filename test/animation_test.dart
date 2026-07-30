import 'package:avatar_genome/avatar_genome.dart';
import 'package:avatar_genome/src/rendering/render_helpers.dart';
import 'package:test/test.dart';

void main() {
  test('animation speed shortens the shared motion period', () {
    expect(animationPeriod(1, slow: 20, fast: 10), 20);
    expect(animationPeriod(6, slow: 20, fast: 10), 10);
    expect(
      List<int>.generate(
        6,
        (index) => animationPeriod(index + 1, slow: 20, fast: 10),
      ),
      orderedEquals(<int>[20, 18, 16, 14, 12, 10]),
    );
  });

  test('background motion can animate independently from the avatar channel', () {
    final generator = AvatarGenerator();
    const request = AvatarRequest(
      seed: 'living-background',
      overrides: <String, Object>{
        'v4.background': 'neonCity',
        'v4.animation': 'none',
      },
      rendering: AvatarRenderSettings(size: 64),
    );
    final first = generator.generate(request.copyWith(phase: 0));
    final later = generator.generate(request.copyWith(phase: 12));
    expect(later.imageHash, isNot(first.imageHash));

    final staticFirst = generator.generate(request.copyWith(
      phase: 0,
      rendering: request.rendering.copyWith(animateBackground: false),
    ));
    final staticLater = generator.generate(request.copyWith(
      phase: 12,
      rendering: request.rendering.copyWith(animateBackground: false),
    ));
    expect(staticLater.imageHash, staticFirst.imageHash);
  });

  test('idle composes contextual motion without changing the catalog API', () {
    for (final channel in <String>[
      'blink',
      'hairWind',
      'jewelrySwing',
      'smoke',
      'auraPulse',
      'particles',
    ]) {
      expect(
        animationChannelEnabled('idle', channel),
        isTrue,
        reason: 'idle should include $channel',
      );
    }
    expect(animationChannelEnabled('lookAround', 'blink'), isTrue);
    expect(animationChannelEnabled('none', 'blink'), isFalse);
    expect(animationChannelEnabled('particles', 'hairWind'), isFalse);
  });

  test('idle preserves the anatomical sprite footprint across frames', () {
    final generator = AvatarGenerator();
    const request = AvatarRequest(
      seed: 'idle-stable-footprint',
      overrides: <String, Object>{
        'v4.animation': 'idle',
        'v4.animationSpeed': 1,
        'v4.animationAmplitude': 4,
        'hair.lengthStyle': 'shoulder',
        'v4.earJewelry': 'dangling',
        'v4.aura': 'magic',
        'v4.effect': 'snow',
      },
    );
    final first = generator.generate(request.copyWith(phase: 0));
    final later = generator.generate(request.copyWith(phase: 7));

    const stableLayerIds = <String>{
      'torso.outline',
      'chest.skin',
      'clothing.base',
      'clothing.shadow',
      'clothing.highlight',
      'neck.outline',
      'neck.base',
      'neck.shadow',
      'neck.highlight',
      'head.outline',
      'head.base',
      'head.shadow',
      'head.highlight',
    };

    Map<String, RenderLayer> stableLayers(AvatarResult result) =>
        <String, RenderLayer>{
          for (final layer in result.layers)
            if (stableLayerIds.contains(layer.id)) layer.id: layer,
        };

    final firstLayers = stableLayers(first);
    final laterLayers = stableLayers(later);
    expect(laterLayers.keys.toSet(), firstLayers.keys.toSet());
    for (final id in firstLayers.keys) {
      expect(
        laterLayers[id]!.mask.data,
        orderedEquals(firstLayers[id]!.mask.data),
        reason: '$id must stay anchored during idle animation',
      );
    }
  });

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
