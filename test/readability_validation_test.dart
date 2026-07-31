import 'package:avatar_genome/avatar_genome.dart';
import 'package:test/test.dart';

void main() {
  test('generated avatar exposes readability validation without hard failure', () {
    final result = AvatarGenerator().generate(const AvatarRequest(
      seed: 'readability-validation',
      overrides: <String, Object>{
        'v4.background': 'solid',
        'v4.weather': 'none',
        'v4.effect': 'none',
        'v4.faceAnimation': 'laugh',
        'body.armVisibility': 4,
      },
    ));

    final readability = result.validation.entries
        .where((entry) => entry.id.startsWith('readability.'))
        .toList(growable: false);
    expect(result.validation.isValid, isTrue);
    expect(
      readability.every((entry) => entry.severity == ValidationSeverity.soft),
      isTrue,
    );
  });
}
