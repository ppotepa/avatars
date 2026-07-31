import 'package:avatar_genome/avatar_genome.dart';
import 'package:test/test.dart';

void main() {
  test('legacy laughing face animation alias normalizes to laugh', () {
    final request = AvatarRequest.fromJson(<String, Object?>{
      'schemaVersion': AvatarGenomeVersion.requestSchema,
      'seed': 'legacy-laugh-track',
      'overrides': <String, Object>{
        'v4.faceAnimation': 'laughing',
        'v4.mouthMotionStyle': 'laughLoop',
      },
    });

    expect(request.overrides['v4.faceAnimation'], 'laugh');
    expect(
      ParameterCatalog.v41.fieldById['v4.faceAnimation']!
          .accepts(request.overrides['v4.faceAnimation']!),
      isTrue,
    );
    expect(() => AvatarGenerator().generate(request), returnsNormally);
  });

  test('aliases normalize inside locked categories as well', () {
    final request = AvatarRequest.fromJson(<String, Object?>{
      'schemaVersion': AvatarGenomeVersion.requestSchema,
      'seed': 'legacy-locked-laugh-track',
      'lockedCategories': <String, Object>{
        'expressionV42': <String, Object>{
          'v4.faceAnimation': 'laughing',
        },
      },
    });

    expect(
      request.lockedCategories['expressionV42']!['v4.faceAnimation'],
      'laugh',
    );
  });
}
