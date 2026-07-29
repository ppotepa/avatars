import 'avatar_version.dart';

enum AvatarPresentation { neutral, masculine, feminine }
enum FantasyLevel { none, subtle, moderate, strong }

final class GenomeSettings {
  const GenomeSettings({
    this.presentation = AvatarPresentation.neutral,
    this.bias = 0,
    this.age = 35,
    this.fantasy = FantasyLevel.none,
    this.symmetry = true,
  });

  factory GenomeSettings.fromJson(Map<String, Object?> json) => GenomeSettings(
        presentation: AvatarPresentation.values.firstWhere(
          (value) => value.name == json['presentation'],
          orElse: () => AvatarPresentation.neutral,
        ),
        bias: (json['bias'] as num?)?.toInt() ?? 0,
        age: (json['age'] as num?)?.toInt() ?? 35,
        fantasy: FantasyLevel.values.firstWhere(
          (value) => value.name == json['fantasy'],
          orElse: () => FantasyLevel.none,
        ),
        symmetry: json['symmetry'] as bool? ?? true,
      );

  final AvatarPresentation presentation;
  final int bias;
  final int age;
  final FantasyLevel fantasy;
  final bool symmetry;

  GenomeSettings copyWith({
    AvatarPresentation? presentation,
    int? bias,
    int? age,
    FantasyLevel? fantasy,
    bool? symmetry,
  }) =>
      GenomeSettings(
        presentation: presentation ?? this.presentation,
        bias: bias ?? this.bias,
        age: age ?? this.age,
        fantasy: fantasy ?? this.fantasy,
        symmetry: symmetry ?? this.symmetry,
      );

  Map<String, Object> toJson() => <String, Object>{
        'presentation': presentation.name,
        'bias': bias,
        'age': age,
        'fantasy': fantasy.name,
        'symmetry': symmetry,
      };
}

/// Immutable request describing one deterministic avatar generation.
///
/// The seed is the genome identity. Overrides and locks are persisted so an
/// editor can reproduce exactly the same result on every supported platform.
final class AvatarRequest {
  const AvatarRequest({
    required this.seed,
    this.settings = const GenomeSettings(),
    this.overrides = const <String, Object>{},
    this.lockedParameters = const <String, Object>{},
    this.lockedCategories = const <String, Map<String, Object>>{},
    this.categoryNonces = const <String, int>{},
    this.phase = 0,
    this.guardEnabled = true,
  });

  factory AvatarRequest.fromJson(Map<String, Object?> json) {
    final schema = (json['schemaVersion'] as num?)?.toInt() ?? 1;
    if (schema != AvatarGenomeVersion.requestSchema) {
      throw FormatException('Unsupported AvatarRequest schema: $schema.');
    }
    return AvatarRequest(
        seed: json['seed']! as String,
        settings: GenomeSettings.fromJson(
          Map<String, Object?>.from(
            json['settings'] as Map? ?? const <String, Object?>{},
          ),
        ),
        overrides: _objectMap(json['overrides']),
        lockedParameters: _objectMap(json['lockedParameters']),
        lockedCategories: _nestedObjectMap(json['lockedCategories']),
        categoryNonces: <String, int>{
          for (final entry in _objectMap(json['categoryNonces']).entries)
            entry.key: (entry.value as num).toInt(),
        },
        phase: (json['phase'] as num?)?.toInt() ?? 0,
        guardEnabled: json['guardEnabled'] as bool? ?? true,
      );
  }

  final String seed;
  final GenomeSettings settings;

  /// Manual or preset values. These win over automatic generation.
  final Map<String, Object> overrides;

  /// Fixed values with the highest source priority.
  final Map<String, Object> lockedParameters;

  /// Category snapshots used by editors when a complete section is locked.
  final Map<String, Map<String, Object>> lockedCategories;

  /// Per-category deterministic reroll counters.
  final Map<String, int> categoryNonces;

  /// Deterministic animation phase. Static avatars normally use zero.
  final int phase;
  final bool guardEnabled;

  AvatarRequest copyWith({
    String? seed,
    GenomeSettings? settings,
    Map<String, Object>? overrides,
    Map<String, Object>? lockedParameters,
    Map<String, Map<String, Object>>? lockedCategories,
    Map<String, int>? categoryNonces,
    int? phase,
    bool? guardEnabled,
  }) =>
      AvatarRequest(
        seed: seed ?? this.seed,
        settings: settings ?? this.settings,
        overrides: overrides ?? this.overrides,
        lockedParameters: lockedParameters ?? this.lockedParameters,
        lockedCategories: lockedCategories ?? this.lockedCategories,
        categoryNonces: categoryNonces ?? this.categoryNonces,
        phase: phase ?? this.phase,
        guardEnabled: guardEnabled ?? this.guardEnabled,
      );

  Map<String, Object> toJson() => <String, Object>{
        'schemaVersion': AvatarGenomeVersion.requestSchema,
        'seed': seed,
        'settings': settings.toJson(),
        'overrides': overrides,
        'lockedParameters': lockedParameters,
        'lockedCategories': lockedCategories,
        'categoryNonces': categoryNonces,
        'phase': phase,
        'guardEnabled': guardEnabled,
      };

  static Map<String, Object> _objectMap(Object? value) {
    if (value is! Map) return <String, Object>{};
    return <String, Object>{
      for (final entry in value.entries)
        entry.key.toString(): entry.value as Object,
    };
  }

  static Map<String, Map<String, Object>> _nestedObjectMap(Object? value) {
    if (value is! Map) return <String, Map<String, Object>>{};
    return <String, Map<String, Object>>{
      for (final entry in value.entries)
        entry.key.toString(): _objectMap(entry.value),
    };
  }
}
