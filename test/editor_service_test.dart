import 'package:avatar_genome/avatar_genome.dart';
import 'package:test/test.dart';

void main() {
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
    expect(response.result.metrics.faceReadabilityScore, inInclusiveRange(0, 100));
    expect(
      response.result.metrics.visibility.sourcePixels['eyes'],
      greaterThan(0),
    );
  });

  test('phase binding exposes animation frames to the web editor', () {
    final service = AvatarEditorService();
    final response = service.generate(
      const AvatarRequest(
        seed: 'editor-animation',
        overrides: <String, Object>{'v4.animation': 'idle'},
      ),
      actions: const <AvatarEditorAction>[
        AvatarEditorAction(operation: 'set', id: 'request.phase', value: 5),
      ],
    );
    expect(response.request.phase, 5);
    expect(response.toJson()['result'], isNotNull);
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
}
