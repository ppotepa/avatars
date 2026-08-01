import 'package:avatar_genome/avatar_genome.dart';
import 'package:test/test.dart';

void main() {
  test('color budget is genome-backed, deterministic and respected by pixels',
      () {
    final generator = AvatarGenerator();
    for (final budget in const <int>[4, 8, 16, 32]) {
      final request = AvatarRequest(
        seed: 'palette-budget-$budget',
        overrides: <String, Object>{
          'colors.paletteStyle': 'vivid',
          'colors.colorBudget': '$budget',
          'v4.effect': 'none',
          'v4.weather': 'none',
        },
      );
      final first = generator.generate(request);
      final second = generator.generate(request);

      expect(first.genome.values['colors.colorBudget'], '$budget');
      expect(first.palette.colors.toSet().length, lessThanOrEqualTo(budget));
      expect(first.metrics.usedColorCount, lessThanOrEqualTo(budget));
      expect(first.palette.id, endsWith('.$budget'));
      expect(first.imageHash, second.imageHash);
    }
  });
}
