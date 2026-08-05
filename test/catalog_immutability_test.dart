import 'package:avatar_genome/avatar_genome.dart';
import 'package:test/test.dart';

void main() {
  test('catalog collections are immutable', () {
    final catalog = ParameterCatalog.current;

    expect(() => catalog.fields.clear(), throwsUnsupportedError);
    expect(() => catalog.fieldById.clear(), throwsUnsupportedError);
    expect(() => catalog.categoryById.clear(), throwsUnsupportedError);
    expect(() => catalog.categories.first.fields.clear(), throwsUnsupportedError);
    expect(
      () => catalog.categories.first.presets.clear(),
      throwsUnsupportedError,
    );
    expect(
      () => catalog.fields.first.options.clear(),
      throwsUnsupportedError,
    );
  });

  test('whole-avatar preset values are immutable', () {
    final preset = ParameterCatalog.current.wholePresets.values.first;

    expect(() => preset.global.clear(), throwsUnsupportedError);
    expect(() => preset.values.clear(), throwsUnsupportedError);
  });
}
