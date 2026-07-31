import 'dart:convert';

import 'catalog_v42_extension.dart';
import 'companion_catalog_extension.dart';
import 'generated_catalog_json.dart';

enum ParameterKind { range, select }

final class ParameterOption {
  const ParameterOption({required this.value, required this.label});

  factory ParameterOption.fromJson(Map<String, Object?> json) => ParameterOption(
        value: json['value']! as String,
        label: json['label']! as String,
      );

  final String value;
  final String label;

  Map<String, Object> toJson() => <String, Object>{
        'value': value,
        'label': label,
      };
}

final class ParameterDefinition {
  const ParameterDefinition({
    required this.id,
    required this.label,
    required this.kind,
    required this.category,
    required this.group,
    this.min,
    this.max,
    this.step = 1,
    this.autoMin,
    this.autoMax,
    this.options = const <ParameterOption>[],
  });

  factory ParameterDefinition.fromJson(
    Map<String, Object?> json, {
    required String category,
    required String group,
  }) {
    final type = json['type']! as String;
    final auto = (json['auto'] as List<Object?>?)?.cast<num>();
    final options = (json['options'] as List<Object?>? ?? const <Object?>[])
        .map(
          (option) => ParameterOption.fromJson(
            Map<String, Object?>.from(option! as Map),
          ),
        )
        .toList(growable: false);
    return ParameterDefinition(
      id: json['id']! as String,
      label: json['label']! as String,
      kind: type == 'range' ? ParameterKind.range : ParameterKind.select,
      category: category,
      group: group,
      min: (json['min'] as num?)?.toInt(),
      max: (json['max'] as num?)?.toInt(),
      step: (json['step'] as num?)?.toInt() ?? 1,
      autoMin: auto == null ? null : auto.first.toInt(),
      autoMax: auto == null ? null : auto.last.toInt(),
      options: options,
    );
  }

  final String id;
  final String label;
  final ParameterKind kind;
  final String category;
  final String group;
  final int? min;
  final int? max;
  final int step;
  final int? autoMin;
  final int? autoMax;
  final List<ParameterOption> options;

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'label': label,
        'kind': kind.name,
        'category': category,
        'group': group,
        if (min != null) 'min': min,
        if (max != null) 'max': max,
        'step': step,
        if (autoMin != null) 'autoMin': autoMin,
        if (autoMax != null) 'autoMax': autoMax,
        if (options.isNotEmpty)
          'options': options
              .map((option) => option.toJson())
              .toList(growable: false),
      };

  bool accepts(Object value) {
    if (kind == ParameterKind.range) {
      return value is int &&
          value >= min! &&
          value <= max! &&
          (value - min!) % step == 0;
    }
    return value is String && options.any((option) => option.value == value);
  }
}

final class ParameterCategory {
  const ParameterCategory({
    required this.id,
    required this.label,
    required this.group,
    required this.fields,
    required this.presets,
  });

  final String id;
  final String label;
  final String group;
  final List<ParameterDefinition> fields;
  final Map<String, Map<String, Object>> presets;

  Map<String, Object> toJson() => <String, Object>{
        'id': id,
        'label': label,
        'group': group,
        'fields': fields
            .map((field) => field.toJson())
            .toList(growable: false),
        'presets': presets,
      };
}

final class WholeAvatarPreset {
  const WholeAvatarPreset({
    required this.id,
    required this.label,
    required this.global,
    required this.values,
  });

  final String id;
  final String label;
  final Map<String, Object> global;
  final Map<String, Object> values;

  Map<String, Object> toJson() => <String, Object>{
        'id': id,
        'label': label,
        'global': global,
        'values': values,
      };
}

final class ParameterCatalog {
  ParameterCatalog._({
    required this.categories,
    required this.wholePresets,
  })  : fields = <ParameterDefinition>[
          for (final category in categories) ...category.fields,
        ],
        categoryById = <String, ParameterCategory>{
          for (final category in categories) category.id: category,
        } {
    fieldById = <String, ParameterDefinition>{
      for (final field in fields) field.id: field,
    };
  }

  /// Preserves the historical name while exposing additive extensions.
  static final ParameterCatalog v41 = _decodeV41();

  final List<ParameterCategory> categories;
  final Map<String, WholeAvatarPreset> wholePresets;
  final List<ParameterDefinition> fields;
  final Map<String, ParameterCategory> categoryById;
  late final Map<String, ParameterDefinition> fieldById;

  int get fieldCount => fields.length;
  int get categoryCount => categories.length;

  Map<String, Object> toJson() => <String, Object>{
        'categories': categories
            .map((category) => category.toJson())
            .toList(growable: false),
        'wholePresets': <String, Object>{
          for (final entry in wholePresets.entries)
            entry.key: entry.value.toJson(),
        },
      };

  static ParameterCatalog _decodeV41() {
    final root = jsonDecode(kV41CatalogJson) as Map<String, Object?>;
    final extension =
        jsonDecode(kV42CatalogExtensionJson) as Map<String, Object?>;

    final rawCategories = (root['categories']! as List<Object?>)
        .map((raw) => Map<String, Object?>.from(raw! as Map))
        .toList(growable: true);
    final optionPatches = <String, Object?>{
      ...Map<String, Object?>.from(
        extension['fieldOptions'] as Map? ?? const <String, Object?>{},
      ),
      for (final entry in kCompanionOptionPatches.entries)
        entry.key: entry.value,
    };

    for (final category in rawCategories) {
      final rawFields = (category['fields']! as List<Object?>)
          .map((raw) => Map<String, Object?>.from(raw! as Map))
          .toList(growable: false);
      for (final field in rawFields) {
        final patch = optionPatches[field['id']];
        if (patch is! List) continue;
        final options =
            (field['options'] as List<Object?>? ?? const <Object?>[])
                .map((raw) => Map<String, Object?>.from(raw! as Map))
                .toList(growable: true);
        final existing = options.map((option) => option['value']).toSet();
        for (final raw in patch) {
          final option = Map<String, Object?>.from(raw! as Map);
          if (existing.add(option['value'])) options.add(option);
        }
        field['options'] = options;
      }
      category['fields'] = rawFields;
    }

    for (final raw in extension['categories'] as List<Object?>? ??
        const <Object?>[]) {
      rawCategories.add(Map<String, Object?>.from(raw! as Map));
    }

    final categories = rawCategories
        .map(_categoryFromJson)
        .toList(growable: false);
    final wholePresets = <String, WholeAvatarPreset>{};
    final rawWhole = root['presets']! as Map<String, Object?>;
    for (final entry in rawWhole.entries) {
      final value = entry.value! as Map<String, Object?>;
      wholePresets[entry.key] = WholeAvatarPreset(
        id: entry.key,
        label: value['label']! as String,
        global: Map<String, Object>.from(
          value['global']! as Map<String, Object?>,
        ),
        values: Map<String, Object>.from(
          value['values']! as Map<String, Object?>,
        ),
      );
    }
    return ParameterCatalog._(
      categories: List.unmodifiable(categories),
      wholePresets: Map.unmodifiable(wholePresets),
    );
  }

  static ParameterCategory _categoryFromJson(Map<String, Object?> json) {
    final id = json['id']! as String;
    final group = json['group']! as String;
    final fields = (json['fields']! as List<Object?>)
        .map(
          (field) => ParameterDefinition.fromJson(
            Map<String, Object?>.from(field! as Map),
            category: id,
            group: group,
          ),
        )
        .toList(growable: false);
    final presets = <String, Map<String, Object>>{};
    final rawPresets = Map<String, Object?>.from(
      json['presets'] as Map? ?? const <String, Object?>{},
    );
    for (final entry in rawPresets.entries) {
      presets[entry.key] = Map<String, Object>.from(entry.value! as Map);
    }
    return ParameterCategory(
      id: id,
      label: json['label']! as String,
      group: group,
      fields: fields,
      presets: Map.unmodifiable(presets),
    );
  }
}
