import '../api/avatar_request.dart';
import '../catalog/parameter_catalog.dart';
import 'avatar_property_binding.dart';

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

final class AvatarRequestValidator {
  AvatarRequestValidator({
    ParameterCatalog? catalog,
    AvatarPropertyRegistry? registry,
  })  : catalog = catalog ?? ParameterCatalog.v41,
        registry = registry ?? AvatarPropertyRegistry(catalog: catalog);

  final ParameterCatalog catalog;
  final AvatarPropertyRegistry registry;

  void validate(AvatarRequest request) {
    if (request.seed.trim().isEmpty) {
      _fail('request.seed', 'Seed must not be empty.');
    }
    if (request.seed.length > 512) {
      _fail('request.seed', 'Seed must not exceed 512 characters.');
    }
    for (final binding in registry.requestBindings) {
      final value = binding.read(request);
      if (!binding.accepts(value)) {
        _fail(binding.id, 'Value is not accepted by the request binding.');
      }
    }
    _validateFlatMap(request.overrides, 'overrides');
    _validateFlatMap(request.lockedParameters, 'lockedParameters');

    for (final categoryEntry in request.lockedCategories.entries) {
      final category = catalog.categoryById[categoryEntry.key];
      if (category == null) {
        _fail(
          'lockedCategories.${categoryEntry.key}',
          'Unknown category.',
        );
      }
      final allowed = category!.fields.map((field) => field.id).toSet();
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
      if (!field!.accepts(entry.value)) {
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
