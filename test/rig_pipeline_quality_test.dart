import 'dart:convert';

import 'package:avatar_genome/avatar_genome.dart';
import 'package:test/test.dart';

void main() {
  test('rig clip preserves anchors, fills frame and renders coherent rain', () {
    final generator = AvatarGenerator();
    const request = AvatarRequest(
      seed: 'quality-rig-rain',
      overrides: <String, Object>{
        'v4.animation': 'idle',
        'v4.animationSpeed': 3,
        'v4.animationAmplitude': 2,
        'body.armVisibility': 5,
        'hair.lengthStyle': 'belowShoulder',
        'hair.length': 18,
        'hair.volumeBack': 3,
        'v4.neckJewelry': 'royalMedallion',
        'v4.earJewelry': 'dangling',
        'v4.shoulderProp': 'parrot',
        'v4.propSide': 1,
        'v4.cape': 'longCape',
        'v4.cybernetics': 'chestReactor',
        'v4.weather': 'heavyRain',
        'v4.weatherDensity': 6,
        'v4.weatherDepth': 2,
        'v4.weatherDrift': 2,
      },
    );

    final still = generator.generate(request);
    final animation = generator.generateAnimation(request, frameCount: 16);
    final stillCamera =
        still.layout.graph.nodes['rig.camera']!.value as Map<String, Object?>;
    final animatedCamera = animation.frames.first.layout.graph
        .nodes['rig.camera']!.value as Map<String, Object?>;
    expect(stillCamera, animatedCamera);
    expect((stillCamera['actorOccupancy']! as num).toDouble(),
        greaterThanOrEqualTo(.72));

    final clip = generator.pipeline.renderClip(request, frameCount: 16);
    expect(
      clip.frames
          .map((frame) => jsonEncode(frame.camera.toJson()))
          .toSet(),
      hasLength(1),
    );

    for (final frame in clip.frames) {
      expect(
        frame.state.nodeParents['shoulderCompanion'],
        'rightShoulderAttachment',
      );
      final nodeIds = frame.state.layers.map((layer) => layer.nodeId).toSet();
      expect(nodeIds, contains('leftArm'));
      expect(nodeIds, contains('rightArm'));
      expect(nodeIds, contains('chestWearable'));
      expect(nodeIds, contains('companionHead'));
      expect(nodeIds, contains('capeTipLeft'));
      expect(nodeIds, contains('capeTipRight'));
      expect(frame.state.metadata['rigAnchors'], isA<Map>());
      expect(frame.state.metadata['rigConstraints'], isA<List>());
      expect(frame.state.layers.any((layer) => layer.id.startsWith('particle.v2')),
          isFalse);

      final rain = frame.state.metadata['rainField']! as Map<String, Object>;
      final trajectories = rain['trajectories']! as List<Object>;
      for (final item in trajectories.cast<Map<String, Object>>()) {
        final x = item['x']! as int;
        final y = item['y']! as int;
        final tailX = item['tailX']! as int;
        final tailY = item['tailY']! as int;
        final velocityX = item['velocityX']! as int;
        final velocityY = item['velocityY']! as int;
        final streakX = x - tailX;
        final streakY = y - tailY;
        expect(
          streakX * velocityX + streakY * velocityY,
          greaterThan(0),
          reason: 'rain streak must point along its velocity vector',
        );
      }
    }
  });

  test('rigid shoulder objects do not become artificial companions', () {
    final generator = AvatarGenerator();
    final frame = generator.generate(const AvatarRequest(
      seed: 'rigid-shoulder-object',
      overrides: <String, Object>{
        'v4.animation': 'idle',
        'v4.shoulderProp': 'radio',
        'v4.propSide': -1,
      },
    ));
    final ids = frame.layers.map((layer) => layer.nodeId).toSet();
    expect(ids, contains('shoulderObject'));
    expect(ids, isNot(contains('companionHead')));
    expect(ids, isNot(contains('companionWings')));
  });
}
