import 'package:avatar_genome/avatar_genome.dart';
import 'package:test/test.dart';

void main() {
  group('ParameterCatalog V4.2', () {
    final catalog = ParameterCatalog.v41;

    test('contains the preserved V4.1 catalog and V4.2 extension', () {
      expect(catalog.categoryCount, 30);
      expect(catalog.fieldCount, 275);
      expect(catalog.wholePresets.length, 13);
      expect(catalog.categoryById, contains('expressionV42'));
      expect(catalog.categoryById, contains('adornmentV42'));
      expect(catalog.categoryById, contains('atmosphereV42'));
      expect(catalog.categoryById, contains('motionV42'));
    });

    test('uses unique field identifiers', () {
      final ids = catalog.fields.map((field) => field.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('every selectable field has unique options', () {
      for (final field in catalog.fields) {
        if (field.kind == ParameterKind.select) {
          expect(field.options, isNotEmpty, reason: field.id);
          final values = field.options.map((option) => option.value).toList();
          expect(values.toSet().length, values.length, reason: field.id);
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

    test('server-visible expression and atmosphere controls are present', () {
      expect(catalog.fieldById, contains('v4.expression'));
      expect(catalog.fieldById, contains('v4.halo'));
      expect(catalog.fieldById, contains('v4.weather'));
      expect(catalog.fieldById, contains('v4.backgroundEvent'));
      expect(catalog.fieldById, contains('v4.faceAnimation'));
      expect(catalog.fieldById, contains('v4.poseMotion'));
    });
  });
}
