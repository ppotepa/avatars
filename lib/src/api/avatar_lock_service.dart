import '../catalog/parameter_catalog.dart';
import '../genome/avatar_genome_model.dart';
import 'avatar_request.dart';

/// Creates immutable lock snapshots from a generated genome.
final class AvatarLockService {
  AvatarLockService({ParameterCatalog? catalog})
      : catalog = catalog ?? ParameterCatalog.v41;

  final ParameterCatalog catalog;

  AvatarRequest lockParameter(
    AvatarRequest request,
    AvatarGenome genome,
    String parameterId,
  ) {
    final value = genome[parameterId];
    if (value == null || !catalog.fieldById.containsKey(parameterId)) {
      throw ArgumentError.value(parameterId, 'parameterId');
    }
    return request.copyWith(
      lockedParameters: <String, Object>{
        ...request.lockedParameters,
        parameterId: value,
      },
    );
  }

  AvatarRequest unlockParameter(AvatarRequest request, String parameterId) {
    return request.copyWith(
      lockedParameters: <String, Object>{
        for (final entry in request.lockedParameters.entries)
          if (entry.key != parameterId) entry.key: entry.value,
      },
    );
  }

  AvatarRequest lockCategory(
    AvatarRequest request,
    AvatarGenome genome,
    String categoryId,
  ) {
    final category = catalog.categoryById[categoryId];
    if (category == null) {
      throw ArgumentError.value(categoryId, 'categoryId');
    }
    final snapshot = <String, Object>{
      for (final field in category.fields) field.id: genome.values[field.id]!,
    };
    return request.copyWith(
      lockedCategories: <String, Map<String, Object>>{
        ...request.lockedCategories,
        categoryId: Map.unmodifiable(snapshot),
      },
    );
  }

  AvatarRequest unlockCategory(AvatarRequest request, String categoryId) {
    return request.copyWith(
      lockedCategories: <String, Map<String, Object>>{
        for (final entry in request.lockedCategories.entries)
          if (entry.key != categoryId) entry.key: entry.value,
      },
    );
  }
}
