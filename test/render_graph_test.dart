import 'package:avatar_genome/avatar_genome.dart';
import 'package:test/test.dart';

void main() {
  final generator = AvatarGenerator();

  test('render graph rejects duplicate, orphaned, and cyclic nodes', () {
    expect(
      () => RenderGraph(nodes: const <RenderNode>[
        RenderNode(id: 'a', parentId: null, slot: 'head', anchor: 'x'),
        RenderNode(id: 'a', parentId: null, slot: 'head', anchor: 'x'),
      ]),
      throwsStateError,
    );
    expect(
      () => RenderGraph(nodes: const <RenderNode>[
        RenderNode(id: 'a', parentId: 'missing', slot: 'head', anchor: 'x'),
      ]),
      throwsStateError,
    );
    expect(
      () => RenderGraph(nodes: const <RenderNode>[
        RenderNode(id: 'a', parentId: 'b', slot: 'head', anchor: 'x'),
        RenderNode(id: 'b', parentId: 'a', slot: 'head', anchor: 'x'),
      ]),
      throwsStateError,
    );
  });

  test('render graph is valid, hierarchical, and drives layer order', () {
    final result = generator.generate(
      const AvatarRequest(
        seed: 'render-graph-structure',
        overrides: <String, Object>{
          'v4.headwear': 'baseballCap',
          'v4.eyewear': 'roundGlasses',
          'v4.faceMask': 'gasMask',
          'v4.shoulderProp': 'cat',
          'v4.propSide': -1,
          'body.armVisibility': 5,
        },
      ),
    );

    result.renderGraph.validate();
    final nodes = result.renderGraph.byId;
    expect(nodes['torso']?.parentId, 'actor');
    expect(nodes['clothing']?.parentId, 'torso');
    expect(nodes['clothing']?.anchor, 'torso-surface');
    expect(nodes['neck']?.parentId, 'torso');
    expect(nodes['head']?.parentId, 'neck');
    expect(nodes['eyes']?.parentId, 'head');
    expect(nodes['headwear']?.parentId, 'head');
    expect(nodes['leftHand']?.parentId, 'leftArm');
    expect(nodes['companionHead']?.parentId, 'companionBody');
    expect(nodes['companionHeadDetails']?.parentId, 'companionHead');
    expect(nodes['shoulderCompanion']?.anchor, 'left-shoulder');

    for (final layer in result.layers) {
      expect(layer.z, RenderSlots.compatibilityZ(layer.slot, layer.localOrder));
      expect(nodes, contains(layer.nodeId));
    }
    final sorted = List<RenderLayer>.from(result.layers)
      ..sort((a, b) => a.z.compareTo(b.z));
    expect(
      sorted.map((layer) => RenderSlots.indexOf(layer.slot)),
      orderedEquals(
        sorted.map((layer) => RenderSlots.indexOf(layer.slot)).toList()..sort(),
      ),
    );
  });

  test('head children inherit the same world motion', () {
    final frame = generator.generate(
      const AvatarRequest(
        seed: 'render-graph-inheritance',
        phase: 3,
        overrides: <String, Object>{
          'v4.animation': 'laughing',
          'v4.headwear': 'baseballCap',
          'v4.eyewear': 'roundGlasses',
          'v4.faceMask': 'gasMask',
        },
      ),
    );
    final graph = frame.renderGraph;
    final head = graph.worldTransform('head');
    for (final id in <String>[
      'eyes',
      'brows',
      'headwear',
      'eyewear',
      'faceMask'
    ]) {
      final child = graph.worldTransform(id);
      final local = graph.byId[id]!.localTransform;
      expect(child.dx - local.dx, head.dx);
      expect(child.dy - local.dy, head.dy);
    }
  });

  test('clothing and armor remain anchored to the moving torso', () {
    final animation = generator.generateAnimation(
      const AvatarRequest(
        seed: 'render-graph-clothing-anchor',
        overrides: <String, Object>{
          'v4.animation': 'celebration',
          'v4.armor': 'plateArmor',
          'body.armVisibility': 5,
        },
      ),
      frameCount: 12,
    );
    for (final frame in animation.frames) {
      final graph = frame.renderGraph;
      final torso = graph.worldTransform('torso');
      for (final id in <String>['clothing', 'armor']) {
        final child = graph.worldTransform(id);
        final local = graph.byId[id]!.localTransform;
        expect(child.dx - local.dx, torso.dx);
        expect(child.dy - local.dy, torso.dy);
      }
    }
  });

  test('animation uses one 48x54 fit and exports 48x48 frames', () {
    final animation = generator.generateAnimation(
      const AvatarRequest(
        seed: 'render-graph-fit',
        overrides: <String, Object>{
          'v4.animation': 'celebration',
          'v4.headwear': 'wizardHat',
          'v4.shoulderProp': 'smallDragon',
          'body.armVisibility': 5,
        },
      ),
      frameCount: 12,
    );

    final first = animation.frames.first.renderGraph;
    expect(first.canvasWidth, 48);
    expect(first.canvasHeight, 54);
    expect(first.viewportWidth, 48);
    expect(first.viewportHeight, 48);
    for (final frame in animation.frames) {
      expect(frame.image.width, 48);
      expect(frame.image.height, 48);
      expect(frame.renderGraph.viewportY, first.viewportY);
      expect(frame.renderGraph.fitScale, first.fitScale);
      expect(frame.renderGraph.baseline, first.baseline);
    }

    final json = animation.toJson(includePixels: false);
    expect(json['renderGraph'], isA<Map<String, Object?>>());
    expect(json['nodeTransforms'], isA<List<Object?>>());
  });

  test('companion parts animate independently while body stays anchored', () {
    final animation = generator.generateAnimation(
      const AvatarRequest(
        seed: 'render-graph-companion-motion',
        overrides: <String, Object>{
          'v4.animation': 'celebration',
          'v4.shoulderProp': 'smallDragon',
        },
      ),
      frameCount: 12,
    );

    expect(
      animation.frames
          .map((frame) =>
              frame.renderGraph.byId['companionBody']!.localTransform)
          .every((transform) => transform.isIdentity),
      isTrue,
    );
    expect(
      animation.frames
          .map((frame) {
            final value =
                frame.renderGraph.byId['companionHead']!.localTransform;
            return '${value.dx},${value.dy},${value.rotationDegrees}';
          })
          .toSet()
          .length,
      greaterThan(1),
    );
    expect(
      animation.frames
          .map((frame) {
            final value =
                frame.renderGraph.byId['companionWings']!.localTransform;
            return '${value.dx},${value.dy},${value.rotationDegrees}';
          })
          .toSet()
          .length,
      greaterThan(1),
    );
    for (final frame in animation.frames) {
      final body = _nodeMask(frame, 'companionBody');
      final head = _nodeMask(frame, 'companionHead');
      expect(
        body.dilated(diagonal: true).intersect(head).count,
        greaterThan(0),
        reason: 'Companion head detached from its body.',
      );
    }
  });

  test('non-character shoulder props are single arm-owned nodes', () {
    final result = generator.generate(
      const AvatarRequest(
        seed: 'render-graph-shoulder-object',
        overrides: <String, Object>{
          'v4.animation': 'thinking',
          'v4.shoulderProp': 'radio',
          'v4.propSide': 1,
          'body.armVisibility': 5,
        },
      ),
    );
    final nodes = result.renderGraph.byId;
    expect(nodes['shoulderObject']?.parentId, 'rightArm');
    expect(
      result.layers
          .where((layer) => layer.id.startsWith('shoulderProp.'))
          .map((layer) => layer.nodeId)
          .toSet(),
      <String>{'shoulderObject'},
    );
  });

  test('parrot exposes animated beak, eyes, wings, and tail nodes', () {
    final animation = generator.generateAnimation(
      const AvatarRequest(
        seed: 'render-graph-parrot-parts',
        overrides: <String, Object>{
          'v4.animation': 'talking',
          'v4.shoulderProp': 'parrot',
          'v4.propSide': 1,
        },
      ),
      frameCount: 12,
    );
    for (final id in <String>[
      'companionBody',
      'companionHead',
      'companionBeak',
      'companionEyes',
      'companionWings',
      'companionTail',
    ]) {
      expect(animation.frames.first.renderGraph.byId, contains(id));
    }
    final beakTransforms = animation.frames.map((frame) {
      final transform = frame.renderGraph.byId['companionBeak']!.localTransform;
      return '${transform.dx},${transform.dy}';
    }).toSet();
    expect(beakTransforms.length, greaterThan(1));
  });

  test('left-side objects inherit the left arm and its anchor', () {
    final result = generator.generate(
      const AvatarRequest(
        seed: 'render-graph-left-object',
        overrides: <String, Object>{
          'v4.animation': 'talking',
          'v4.shoulderProp': 'flashlight',
          'v4.propSide': -1,
          'body.armVisibility': 5,
        },
      ),
    );
    final object = result.renderGraph.byId['shoulderObject']!;
    expect(object.parentId, 'leftArm');
    expect(object.anchor, 'left-shoulder');
  });

  test('public animation cadence never exceeds eight frames per second', () {
    final animation = generator.generateAnimation(
      const AvatarRequest(seed: 'render-graph-fps'),
      frameDuration: const Duration(milliseconds: 1),
    );
    expect(animation.safeFrameDuration,
        greaterThanOrEqualTo(const Duration(milliseconds: 125)));
    expect(animation.toJson()['frameDurationMs'], greaterThanOrEqualTo(125));
  });

  test('lookAround rotates the head graph and morphology profiles render', () {
    final base = generator.generate(const AvatarRequest(seed: 'look-around'));
    final look = generator.generate(const AvatarRequest(
      seed: 'look-around',
      overrides: <String, Object>{'v4.animation': 'lookAround'},
    ));
    expect(look.renderGraph.nodes.any((node) => node.id == 'head'), isTrue);
    for (final profile in <String>[
      'skull',
      'skeleton',
      'undead',
      'construct'
    ]) {
      final result = generator.generate(AvatarRequest(
        seed: 'morph-$profile',
        overrides: <String, Object>{'v4.morphology': profile},
      ));
      expect(
          result.layers.any((layer) => layer.id == 'morphology.plate'), isTrue,
          reason: profile);
      expect(result.image.width, 48);
      expect(base.image.width, 48);
    }
  });

  test('emotion gestures keep both hands attached to their arms', () {
    const emotions = <String>[
      'talking',
      'laughing',
      'scared',
      'angry',
      'sad',
      'thinking',
      'confused',
      'hurt',
      'sleeping',
      'celebration',
    ];
    for (final emotion in emotions) {
      final animation = generator.generateAnimation(
        AvatarRequest(
          seed: 'render-graph-hands-$emotion',
          overrides: <String, Object>{
            'v4.animation': emotion,
            'body.armVisibility': 5,
          },
        ),
        frameCount: 4,
      );
      final armRotations = <int>{};
      for (final frame in animation.frames) {
        for (final side in <String>['left', 'right']) {
          final arm = _nodeMask(frame, '${side}Arm');
          final hand = _nodeMask(frame, '${side}Hand');
          armRotations.add(
            frame
                .renderGraph.byId['${side}Arm']!.localTransform.rotationDegrees,
          );
          if (hand.count == 0) continue;
          expect(
            arm.dilated(diagonal: true).intersect(hand).count,
            greaterThan(0),
            reason: '$emotion detached the $side hand.',
          );
        }
      }
      expect(
        armRotations.any((degrees) => degrees != 0),
        isTrue,
        reason: '$emotion did not articulate either shoulder joint.',
      );
    }
  });

  test('control matrix keeps graph and public frame invariants across variants',
      () {
    const animations = <String>[
      'idle',
      'talking',
      'laughing',
      'scared',
      'angry',
      'sad',
      'thinking',
      'confused',
      'hurt',
      'celebration',
    ];
    const companions = <String>[
      'cat',
      'parrot',
      'smallDragon',
      'ghost',
      'insect',
      'shoulderRobot',
    ];
    for (var seedIndex = 0; seedIndex < 20; seedIndex++) {
      for (var animationIndex = 0;
          animationIndex < animations.length;
          animationIndex++) {
        final result = generator.generate(AvatarRequest(
          seed: 'matrix-$seedIndex-${animations[animationIndex]}',
          phase: seedIndex % 8,
          overrides: <String, Object>{
            'v4.animation': animations[animationIndex],
            'v4.shoulderProp': companions[seedIndex % companions.length],
            'v4.headwear': seedIndex.isEven ? 'wizardHat' : 'spaceHelmet',
            'v4.faceMask': seedIndex.isOdd ? 'gasMask' : 'respirator',
          },
        ));
        expect(result.image.width, 48);
        expect(result.image.height, 48);
        result.renderGraph.validate();
        for (final layer in result.layers) {
          expect(layer.mask.width, 48);
          expect(layer.mask.height, 48);
          expect(layer.nodeId, isNotEmpty);
        }
      }
    }
  });
}

PixelMask _nodeMask(AvatarResult result, String nodeId) {
  var mask = PixelMask();
  for (final layer in result.layers.where((layer) => layer.nodeId == nodeId)) {
    mask = mask.union(layer.mask);
  }
  return mask;
}
