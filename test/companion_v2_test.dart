import 'package:avatar_genome/avatar_genome.dart';
import 'package:avatar_genome/src/rendering/companion/companion_style_registry.dart';
import 'package:test/test.dart';

void main() {
  final generator = AvatarGenerator();

  test('every articulated companion is accepted and renders owned parts', () {
    final shoulderField =
        ParameterCatalog.v41.fieldById['v4.shoulderProp']!;
    final extraField =
        ParameterCatalog.v41.fieldById['v4.extraShoulderProp']!;

    for (final style in kArticulatedCompanionStyles) {
      expect(
        shoulderField.accepts(style) || extraField.accepts(style),
        isTrue,
        reason: '$style must be exposed by at least one companion field',
      );
      final clip = generator.pipeline.renderClip(
        AvatarRequest(
          seed: 'companion-v2-$style',
          overrides: <String, Object>{
            'v4.shoulderProp': style,
            'v4.propSide': 1,
            'v4.animation': 'idle',
          },
        ),
        frameCount: 1,
      );
      final frame = clip.frames.single;
      final layers = frame.state.layers
          .where((layer) => layer.id.startsWith('companion.v2.$style.'))
          .toList(growable: false);
      expect(layers, isNotEmpty, reason: style);
      expect(
        layers.every((layer) => layer.nodeId.startsWith('companion')),
        isTrue,
        reason: '$style has an unowned layer',
      );
      final rig = frame.state.metadata['companionRig']! as Map;
      expect(rig['version'], 2, reason: style);
      expect((rig['anchors']! as Map).isNotEmpty, isTrue, reason: style);
    }
  });

  test('birds expose independently anchored left and right wings', () {
    final clip = generator.pipeline.renderClip(
      const AvatarRequest(
        seed: 'anchored-parrot-wings',
        overrides: <String, Object>{
          'v4.shoulderProp': 'parrot',
          'v4.propSide': 1,
          'v4.animation': 'idle',
          'v4.animationSpeed': 4,
        },
      ),
      frameCount: 8,
    );

    for (final frame in clip.frames) {
      final ids = frame.state.layers.map((layer) => layer.nodeId).toSet();
      expect(ids, contains('companionLeftWing'));
      expect(ids, contains('companionRightWing'));
      final rig = frame.state.metadata['companionRig']! as Map;
      final anchors = rig['anchors']! as Map;
      expect(anchors, contains('companionLeftWing'));
      expect(anchors, contains('companionRightWing'));
      expect(
        anchors['companionLeftWing'],
        isNot(equals(anchors['companionRightWing'])),
      );
      final runtime = frame.state.metadata['rigAnchors']! as Map;
      expect(runtime, contains('companion.leftWing.anchor'));
      expect(runtime, contains('companion.rightWing.anchor'));
    }
  });

  test('skeleton and jellyfish expose limb and tentacle anchors', () {
    final skeleton = generator.pipeline.renderClip(
      const AvatarRequest(
        seed: 'companion-skeleton-limbs',
        overrides: <String, Object>{
          'v4.shoulderProp': 'miniSkeleton',
          'v4.animation': 'idle',
        },
      ),
      frameCount: 2,
    ).frames.first;
    final skeletonAnchors =
        (skeleton.state.metadata['companionRig']! as Map)['anchors']! as Map;
    for (final node in const <String>[
      'companionLeftArm',
      'companionRightArm',
      'companionLeftLeg',
      'companionRightLeg',
    ]) {
      expect(skeletonAnchors, contains(node));
    }

    final jellyfish = generator.pipeline.renderClip(
      const AvatarRequest(
        seed: 'companion-jellyfish-tentacles',
        overrides: <String, Object>{
          'v4.shoulderProp': 'cosmicJellyfish',
          'v4.animation': 'idle',
        },
      ),
      frameCount: 2,
    ).frames.first;
    final jellyfishAnchors =
        (jellyfish.state.metadata['companionRig']! as Map)['anchors']! as Map;
    expect(jellyfishAnchors, contains('companionLeftTentacle'));
    expect(jellyfishAnchors, contains('companionRightTentacle'));
  });

  test('right-side companion remains parented to the right shoulder', () {
    final frame = generator.pipeline.renderClip(
      const AvatarRequest(
        seed: 'companion-right-shoulder',
        overrides: <String, Object>{
          'v4.shoulderProp': 'miniGriffin',
          'v4.propSide': 1,
          'v4.animation': 'idle',
        },
      ),
      frameCount: 1,
    ).frames.single;
    expect(
      frame.state.nodeParents['shoulderCompanion'],
      'rightShoulderAttachment',
    );
  });
}
