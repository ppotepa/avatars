import 'package:avatar_genome/avatar_genome.dart';
import 'package:test/test.dart';

void main() {
  test('palette owns immutable colors and roles', () {
    final colors = <int>[0x000000ff, 0xffffffff];
    final roles = <String, int>{'outline': 0, 'white': 1};
    final palette = AvatarPalette(id: 'test', colors: colors, roles: roles);

    colors[0] = 0xffffffff;
    roles.clear();

    expect(palette.colors, <int>[0x000000ff, 0xffffffff]);
    expect(palette.roles, <String, int>{'outline': 0, 'white': 1});
    expect(() => palette.colors[0] = 0, throwsUnsupportedError);
    expect(() => palette.roles['outline'] = 1, throwsUnsupportedError);
  });

  test('palette rejects invalid colors and role indices', () {
    expect(
      () => AvatarPalette(id: 'empty', colors: const <int>[], roles: const {}),
      throwsArgumentError,
    );
    expect(
      () => AvatarPalette(
        id: 'invalid-rgba',
        colors: const <int>[-1],
        roles: const <String, int>{},
      ),
      throwsArgumentError,
    );
    expect(
      () => AvatarPalette(
        id: 'invalid-role',
        colors: const <int>[0x000000ff],
        roles: const <String, int>{'white': 1},
      ),
      throwsArgumentError,
    );
  });
}
