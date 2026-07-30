import 'package:avatar_genome/avatar_genome.dart';
import 'package:test/test.dart';

void main() {
  group('ParameterCatalog V4.1', () {
    final catalog = ParameterCatalog.v41;

    test('contains the complete HTML catalog', () {
      expect(catalog.categoryCount, 26);
      expect(catalog.fieldCount, 224);
      expect(catalog.wholePresets.length, 13);
    });

    test('uses unique field identifiers', () {
      final ids = catalog.fields.map((field) => field.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('every selectable field has options', () {
      for (final field in catalog.fields) {
        if (field.kind == ParameterKind.select) {
          expect(field.options, isNotEmpty, reason: field.id);
        }
      }
    });

    test('every range has a valid automatic range', () {
      for (final field in catalog.fields) {
        if (field.kind == ParameterKind.range) {
          expect(field.min, isNotNull, reason: field.id);
          expect(field.max, isNotNull, reason: field.id);
          expect(field.autoMin, isNotNull, reason: field.id);
          expect(field.autoMax, isNotNull, reason: field.id);
          expect(field.min! <= field.autoMin!, isTrue, reason: field.id);
          expect(field.autoMin! <= field.autoMax!, isTrue, reason: field.id);
          expect(field.autoMax! <= field.max!, isTrue, reason: field.id);
        }
      }
    });
  });
}
