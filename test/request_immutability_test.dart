import 'package:avatar_genome/avatar_genome.dart';
import 'package:test/test.dart';

void main() {
  test('frozen request owns deeply copied collections', () {
    final overrides = <String, Object>{'eyes.width': 4};
    final hair = <String, Object>{'hair.length': 5};
    final categories = <String, Map<String, Object>>{'hair': hair};
    final nonces = <String, int>{'hair': 1};
    final request = AvatarRequest.frozen(
      seed: 'immutable-request',
      overrides: overrides,
      lockedCategories: categories,
      categoryNonces: nonces,
    );

    overrides['eyes.width'] = 7;
    hair['hair.length'] = 9;
    categories.clear();
    nonces['hair'] = 3;

    final frozenHair = request.lockedCategories['hair']!;
    expect(request.overrides['eyes.width'], 4);
    expect(frozenHair['hair.length'], 5);
    expect(request.categoryNonces['hair'], 1);
    expect(() => request.overrides['eyes.width'] = 8, throwsUnsupportedError);
    expect(() => frozenHair['hair.length'] = 8, throwsUnsupportedError);
  });

  test('generator freezes legacy const-compatible requests at its boundary', () {
    final overrides = <String, Object>{'eyes.width': 4};
    final request = AvatarRequest(seed: 'boundary-freeze', overrides: overrides);
    final generator = AvatarGenerator();
    final first = generator.generate(request);
    overrides['eyes.width'] = 7;
    final frozen = request.frozenCopy();

    expect(first.genome.values['eyes.width'], 4);
    expect(frozen.overrides['eyes.width'], 7);
    expect(() => frozen.overrides.clear(), throwsUnsupportedError);
  });
}
