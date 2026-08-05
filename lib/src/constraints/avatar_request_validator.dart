import '../api/avatar_request.dart';
import '../catalog/parameter_catalog.dart';

final class AvatarRequestValidationException implements Exception {
  const AvatarRequestValidationException({
    required this.field,
    required this.message,
  });

  final String field;
  final String message;

  Map<String, Object> toJson() => <String, Object>{
        'error': 'Invalid request',
        'field': field,
        'message': message,
      };

  @override
  String toString() => 'AvatarRequestValidationException($field: $message)';
}

/// Validates the complete public request contract against a parameter catalog.
final class AvatarRequestValidator {
  AvatarRequestValidator({ParameterCatalog? catalog})
      : catalog = catalog ?? ParameterCatalog.current;

  final ParameterCatalog catalog;

  void validate(AvatarRequest request) {
    if (request.seed.trim().isEmpty) {
      _fail('request.seed', 'Seed must not be empty.');
    }
    if (request.seed.length > 512) {
      _fail('request.seed', 'Seed must not exceed 512 characters.');
    }
    if (request.settings.bias < -100 || request.settings.bias > 100) {
      _fail('settings.bias', 'Bias must be between -100 and 100.');
    }
    if (request.settings.age < 0 || request.settings.age > 100) {
      _fail('settings.age', 'Age must be between 0 and 100.');
    }
    if (request.phase < 0 || request.phase > 1000000) {
      _fail('request.phase', 'Phase must be between 0 and 1000000.');
    }
    if (!AvatarRenderSettings.supportedSizes.contains(request.rendering.size)) {
      _fail('rendering.size', 'Supported sizes are 48, 64, 80 and 96.');
    }
    if (request.rendering.shadingStrength < 0 ||
        request.rendering.shadingStrength > 3) {
      _fail('rendering.shadingStrength', 'Must be between 0 and 3.');
    }

    _validateFlatMap(request.overrides, 'overrides');
    _validateFlatMap(request.lockedParameters, 'lockedParameters');

    for (final categoryEntry in request.lockedCategories.entries) {
      final category = catalog.categoryById[categoryEntry.key];
      if (category == null) {
        _fail('lockedCategories.${categoryEntry.key}', 'Unknown category.');
      }
      final allowed = category.fields.map((field) => field.id).toSet();
      for (final entry in categoryEntry.value.entries) {
        if (!allowed.contains(entry.key)) {
          _fail(
            'lockedCategories.${categoryEntry.key}.${entry.key}',
            'Field does not belong to the locked category.',
          );
        }
        final field = catalog.fieldById[entry.key]!;
        if (!field.accepts(entry.value)) {
          _fail(
            'lockedCategories.${categoryEntry.key}.${entry.key}',
            'Value is not accepted by the catalog definition.',
          );
        }
      }
    }

    for (final entry in request.categoryNonces.entries) {
      if (!catalog.categoryById.containsKey(entry.key)) {
        _fail('categoryNonces.${entry.key}', 'Unknown category.');
      }
      if (entry.value < 0) {
        _fail('categoryNonces.${entry.key}', 'Nonce must not be negative.');
      }
    }
  }

  void _validateFlatMap(Map<String, Object> values, String path) {
    for (final entry in values.entries) {
      final field = catalog.fieldById[entry.key];
      if (field == null) {
        _fail('$path.${entry.key}', 'Unknown parameter id.');
      }
      if (!field.accepts(entry.value)) {
        _fail(
          '$path.${entry.key}',
          'Value is not accepted by the catalog definition.',
        );
      }
    }
  }

  Never _fail(String field, String message) =>
      throw AvatarRequestValidationException(field: field, message: message);
}
