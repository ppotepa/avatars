import 'package:avatar_genome/avatar_genome.dart';
import 'package:test/test.dart';

void main() {
  test('new editor sessions default to a serializable idle reaction', () {
    final request = AvatarEditorService().defaultRequest;
    expect(request.overrides['v4.animation'], 'idle');
    expect(AvatarRequest.fromJson(request.toJson()).overrides['v4.animation'],
        'idle');
  });

  test('editor service applies binding actions and returns SVG', () {
    final service = AvatarEditorService();
    final response = service.generate(
      const AvatarRequest(seed: 'server-test'),
      actions: const <AvatarEditorAction>[
        AvatarEditorAction(operation: 'set', id: 'settings.age', value: 55),
        AvatarEditorAction(operation: 'set', id: 'eyes.shape', value: 'almond'),
      ],
    );
    expect(response.request.settings.age, 55);
    expect(response.request.overrides['eyes.shape'], 'almond');
    expect(response.svg, contains('<svg'));
    expect(response.propertyState['eyes.shape'], isNotNull);
  });

  test('unknown override is rejected', () {
    final validator = AvatarRequestValidator();
    expect(
      () => validator.validate(
        const AvatarRequest(
          seed: 'invalid',
          overrides: <String, Object>{'unknown.field': 1},
        ),
      ),
      throwsA(isA<AvatarRequestValidationException>()),
    );
  });

  test('category reroll updates nonce', () {
    final service = AvatarEditorService();
    final response = service.generate(
      const AvatarRequest(seed: 'reroll-test'),
      actions: const <AvatarEditorAction>[
        AvatarEditorAction(operation: 'rerollCategory', category: 'hair'),
      ],
    );
    expect(response.request.categoryNonces['hair'], 1);
  });

  test('single animation clip endpoint materializes only requested clip', () {
    final bundle = AvatarEditorService().generateAnimationClip(
      const AvatarRequest(seed: 'single-clip-test'),
      animationId: 'talking',
    );

    expect(bundle.clips, hasLength(1));
    expect(bundle.clips.single.id, 'talking');
    expect(bundle.clips.single.variants.single.frames, isNotEmpty);
    expect(bundle.baseSvg, contains('<svg'));
    expect(bundle.renderGraph['nodes'], isNotEmpty);
  });

  test('animation bundle pre-generates clips with idle variants', () {
    final service = AvatarEditorService();
    final bundle = service.generateAnimationBundle(
      const AvatarRequest(
        seed: 'bundle-test',
        overrides: <String, Object>{
          'v4.faceMask': 'gasMask',
          'v4.eyewear': 'cyberVisor',
          'v4.aura': 'electric',
        },
      ),
    );
    expect(bundle.clips, isNotEmpty);
    expect(bundle.defaultAnimationId, 'idle');
    final idle = bundle.clips.firstWhere((clip) => clip.id == 'idle');
    expect(idle.variants.length, greaterThan(1));
    expect(idle.variants.first.frames, isNotEmpty);
    final talking = bundle.clips.firstWhere((clip) => clip.id == 'talking');
    expect(talking.effectiveId, 'talking');
    expect(
      bundle.profile.faceMaskVisible || bundle.profile.eyewearVisible,
      isTrue,
    );
    expect(idle.quality.isMeaningful, isTrue);
    expect(talking.quality.uniqueFrameCount, greaterThan(1));

    for (final id in const <String>[
      'talking',
      'laughing',
      'happy',
      'sad',
      'angry',
      'hurt',
      'thinking',
      'confused',
      'surprised',
      'scared',
    ]) {
      final clip = bundle.clips.firstWhere((candidate) => candidate.id == id);
      expect(
        clip.effectiveId,
        id,
        reason: 'Occlusion must enhance $id without replacing the emotion.',
      );
      if (bundle.profile.faceMostlyOccluded) {
        expect(clip.fallbackReason, 'faceOccludedEnhanced');
      }
    }
  });

  test('animation bundle keeps visible motion across representative seeds', () {
    final service = AvatarEditorService();
    final requests = <AvatarRequest>[
      const AvatarRequest(seed: 'bundle-quality-base'),
      const AvatarRequest(
        seed: 'bundle-quality-occluded',
        overrides: <String, Object>{
          'v4.faceMask': 'gasMask',
          'v4.eyewear': 'cyberVisor',
          'v4.aura': 'electric',
        },
      ),
      const AvatarRequest(
        seed: 'bundle-quality-companion',
        overrides: <String, Object>{
          'v4.shoulderProp': 'cat',
          'v4.earJewelry': 'dangling',
          'v4.headwear': 'spaceHelmet',
        },
      ),
      const AvatarRequest(
        seed: 'bundle-quality-fx',
        overrides: <String, Object>{
          'v4.effect': 'snow',
          'v4.aura': 'magic',
          'v4.animation': 'idle',
        },
      ),
    ];

    for (final request in requests) {
      final bundle = service.generateAnimationBundle(request);
      expect(bundle.clips, isNotEmpty);
      for (final clip in bundle.clips) {
        expect(
          clip.effectiveId,
          clip.id,
          reason:
              '${request.seed}:${clip.id} must not be replaced by another animation.',
        );
        expect(
          clip.quality.isMeaningful,
          isTrue,
          reason: '${request.seed}:${clip.id} should keep visible motion.',
        );
      }
    }
  });
}
