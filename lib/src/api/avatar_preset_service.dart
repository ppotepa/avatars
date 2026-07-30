import '../catalog/parameter_catalog.dart';
import 'avatar_request.dart';

/// Applies catalog presets without coupling the generator to any editor UI.
final class AvatarPresetService {
  AvatarPresetService({ParameterCatalog? catalog})
      : catalog = catalog ?? ParameterCatalog.v41;

  final ParameterCatalog catalog;

  AvatarRequest applyWholePreset(AvatarRequest request, String presetId) {
    final preset = catalog.wholePresets[presetId];
    if (preset == null) {
      throw ArgumentError.value(
          presetId, 'presetId', 'Unknown whole-avatar preset.');
    }
    final settings = request.settings.copyWith(
      presentation: _presentation(preset.global['presentation'] as String?),
      bias: (preset.global['bias'] as num?)?.toInt(),
      age: (preset.global['age'] as num?)?.toInt(),
      fantasy: _fantasy(preset.global['fantasy'] as String?),
      symmetry: preset.global['symmetry'] as bool?,
    );
    return request.copyWith(
      settings: settings,
      overrides: <String, Object>{...request.overrides, ...preset.values},
    );
  }

  AvatarRequest applyCategoryPreset(
    AvatarRequest request,
    String categoryId,
    String presetId,
  ) {
    final category = catalog.categoryById[categoryId];
    if (category == null) {
      throw ArgumentError.value(categoryId, 'categoryId', 'Unknown category.');
    }
    final preset = category.presets[presetId];
    if (preset == null) {
      throw ArgumentError.value(
          presetId, 'presetId', 'Unknown preset for category $categoryId.');
    }
    return request.copyWith(
      overrides: <String, Object>{...request.overrides, ...preset},
    );
  }

  AvatarRequest clearCategoryOverrides(
    AvatarRequest request,
    String categoryId,
  ) {
    final category = catalog.categoryById[categoryId];
    if (category == null) {
      throw ArgumentError.value(categoryId, 'categoryId', 'Unknown category.');
    }
    final ids = category.fields.map((field) => field.id).toSet();
    return request.copyWith(
      overrides: <String, Object>{
        for (final entry in request.overrides.entries)
          if (!ids.contains(entry.key)) entry.key: entry.value,
      },
    );
  }

  AvatarRequest rerollCategory(AvatarRequest request, String categoryId) {
    if (!catalog.categoryById.containsKey(categoryId)) {
      throw ArgumentError.value(categoryId, 'categoryId', 'Unknown category.');
    }
    final current = request.categoryNonces[categoryId] ?? 0;
    return request.copyWith(
      categoryNonces: <String, int>{
        ...request.categoryNonces,
        categoryId: current + 1,
      },
    );
  }

  AvatarPresentation? _presentation(String? value) => switch (value) {
        'masculine' => AvatarPresentation.masculine,
        'feminine' => AvatarPresentation.feminine,
        'neutral' => AvatarPresentation.neutral,
        _ => null,
      };

  FantasyLevel? _fantasy(String? value) => switch (value) {
        'subtle' => FantasyLevel.subtle,
        'moderate' => FantasyLevel.moderate,
        'strong' => FantasyLevel.strong,
        'none' => FantasyLevel.none,
        _ => null,
      };
}
