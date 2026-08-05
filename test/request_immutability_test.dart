import 'package:avatar_genome/avatar_genome.dart';
import 'package:test/test.dart';

void main() {
  test('default request constructor owns deeply copied collections', () {
    final overrides = <String, Object>{'eyes.width': 4};
    final hair = <String, Object>{'hair.length': 5};
    final categories = <String, Map<String, Object>>{'hair': hair};
    final nonces = <String, int>{'hair': 1};
    final request = AvatarRequest(
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

  test('nested collection values are deeply frozen', () {
    final nested = <String, Object>{
      'custom': <String, Object>{
        'values': <Object>[1, 2, 3],
      },
    };
    final request = AvatarRequest(
      seed: 'nested-freeze',
      overrides: nested,
    );

    final custom = request.overrides['custom']! as Map;
    final values = custom['values']! as List;
    expect(() => custom['other'] = 1, throwsUnsupportedError);
    expect(() => values.add(4), throwsUnsupportedError);
  });

  test('frozen compatibility factory and frozenCopy preserve identity', () {
    final request = AvatarRequest.frozen(
      seed: 'frozen-alias',
      overrides: <String, Object>{'eyes.width': 4},
    );

    expect(request.frozenCopy(), same(request));
    expect(() => request.overrides.clear(), throwsUnsupportedError);
  });
}
