import 'package:avatar_genome/avatar_genome.dart';
import 'package:test/test.dart';

void main() {
  final generator = AvatarGenerator();

  test('public generator rejects unknown overrides', () {
    expect(
      () => generator.generate(
        AvatarRequest(
          seed: 'unknown-override',
          overrides: <String, Object>{'unknown.field': 1},
        ),
      ),
      throwsA(isA<AvatarRequestValidationException>()),
    );
  });

  test('public generator rejects unknown locked parameters', () {
    expect(
      () => generator.generate(
        AvatarRequest(
          seed: 'unknown-lock',
          lockedParameters: <String, Object>{'unknown.field': 1},
        ),
      ),
      throwsA(isA<AvatarRequestValidationException>()),
    );
  });

  test('public generator rejects invalid request settings', () {
    expect(
      () => generator.generate(
        AvatarRequest(
          seed: 'invalid-age',
          settings: const GenomeSettings(age: 101),
        ),
      ),
      throwsA(isA<AvatarRequestValidationException>()),
    );
    expect(
      () => generator.generate(
        AvatarRequest(
          seed: 'invalid-bias',
          settings: const GenomeSettings(bias: -101),
        ),
      ),
      throwsA(isA<AvatarRequestValidationException>()),
    );
  });

  test('public generator rejects unknown category nonces', () {
    expect(
      () => generator.generate(
        AvatarRequest(
          seed: 'unknown-category',
          categoryNonces: <String, int>{'unknown': 1},
        ),
      ),
      throwsA(isA<AvatarRequestValidationException>()),
    );
  });
}
