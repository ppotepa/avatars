import 'package:avatar_genome/avatar_genome.dart';
import 'package:test/test.dart';

void main() {
  final catalog = ParameterCatalog.v41;
  final generator = AvatarGenerator();

  group('generator reachability contract', () {
    test('every background has a positive automatic probability', () {
      final field = catalog.fieldById['v4.background']!;
      const policy = BackgroundDiversityPolicy();
      final catalogOptions = field.options.map((option) => option.value).toSet();

      for (final world in catalog.fieldById['v4.worldStyle']!.options) {
        final weights = policy.weights(field, world.value);
        expect(weights.keys.toSet(), catalogOptions, reason: world.value);
        for (final entry in weights.entries) {
          expect(entry.value, greaterThan(0),
              reason: '${world.value}:${entry.key}');
        }
      }

      expect(catalogOptions, containsAll(<String>{
        'diagonalStripes',
        'dots',
        'pixelNoise',
        'sunset',
        'snowField',
        'factionSymbol',
      }));
      expect(
        BackgroundDiversityPolicy.preferredByWorld['postApocalyptic'],
        isNot(contains('rust')),
      );
      expect(
        BackgroundDiversityPolicy.preferredByWorld['postApocalyptic'],
        isNot(contains('dust')),
      );
    });

    test('every select option passes complete generation and rendering', () {
      for (final field in catalog.fields.where(
        (field) => field.kind == ParameterKind.select,
      )) {
        for (final option in field.options) {
          final result = generator.generate(
            AvatarRequest(
              seed: 'reach-select-${field.id}-${option.value}',
              settings: const GenomeSettings(
                fantasy: FantasyLevel.strong,
                symmetry: false,
              ),
              overrides: <String, Object>{field.id: option.value},
            ),
          );

          expect(result.genome.values[field.id], option.value,
              reason: '${field.id}:${option.value}');
          expect(result.imageHash, matches(RegExp(r'^[0-9a-f]{12}$')),
              reason: '${field.id}:${option.value}');
          expect(result.image.indices, hasLength(48 * 48),
              reason: '${field.id}:${option.value}');
        }
      }
    });

    test('every numeric endpoint passes complete generation and rendering', () {
      for (final field in catalog.fields.where(
        (field) => field.kind == ParameterKind.range,
      )) {
        for (final value in <int>{field.min!, field.max!}) {
          final result = generator.generate(
            AvatarRequest(
              seed: 'reach-range-${field.id}-$value',
              settings: const GenomeSettings(
                fantasy: FantasyLevel.strong,
                symmetry: false,
              ),
              overrides: <String, Object>{field.id: value},
            ),
          );

          expect(result.genome.values[field.id], value,
              reason: '${field.id}:$value');
          expect(result.imageHash, matches(RegExp(r'^[0-9a-f]{12}$')),
              reason: '${field.id}:$value');
          expect(result.image.indices, hasLength(48 * 48),
              reason: '${field.id}:$value');
        }
      }
    });
  });
}
