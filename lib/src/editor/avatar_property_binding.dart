import '../api/avatar_request.dart';
import '../catalog/parameter_catalog.dart';
import '../genome/avatar_genome_model.dart';

enum EditorFieldKind { text, integer, range, select, boolean }

enum EditorBindingTarget { request, settings, override }

final class EditorFieldOption {
  const EditorFieldOption({required this.value, required this.label});

  final Object value;
  final String label;

  Map<String, Object> toJson() => <String, Object>{
        'value': value,
        'label': label,
      };
}

abstract class AvatarPropertyBinding {
  const AvatarPropertyBinding();

  String get id;
  String get label;
  String get group;
  String get category;
  String get path;
  EditorFieldKind get kind;
  EditorBindingTarget get target;
  int? get min;
  int? get max;
  int get step;
  List<EditorFieldOption> get options;

  Object? read(AvatarRequest request);
  bool accepts(Object? value);
  AvatarRequest write(AvatarRequest request, Object? value);
  AvatarRequest reset(AvatarRequest request);

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'label': label,
        'group': group,
        'category': category,
        'path': path,
        'kind': kind.name,
        'target': target.name,
        if (min != null) 'min': min,
        if (max != null) 'max': max,
        'step': step,
        if (options.isNotEmpty)
          'options': options.map((option) => option.toJson()).toList(growable: false),
      };
}

final class RequestPropertyBinding extends AvatarPropertyBinding {
  const RequestPropertyBinding({
    required this.id,
    required this.label,
    required this.group,
    required this.category,
    required this.kind,
    required this.target,
    this.min,
    this.max,
    this.step = 1,
    this.options = const <EditorFieldOption>[],
  });

  @override
  final String id;
  @override
  final String label;
  @override
  final String group;
  @override
  final String category;
  @override
  String get path => switch (id) {
        'request.seed' => 'seed',
        'request.phase' => 'phase',
        'request.guardEnabled' => 'guardEnabled',
        'rendering.size' => 'rendering.size',
        'rendering.detailLevel' => 'rendering.detailLevel',
        'rendering.lightingDirection' => 'rendering.lightingDirection',
        'rendering.shadingStrength' => 'rendering.shadingStrength',
        'rendering.animateBackground' => 'rendering.animateBackground',
        'rendering.reducedMotion' => 'rendering.reducedMotion',
        _ => id,
      };
  @override
  final EditorFieldKind kind;
  @override
  final EditorBindingTarget target;
  @override
  final int? min;
  @override
  final int? max;
  @override
  final int step;
  @override
  final List<EditorFieldOption> options;

  @override
  Object read(AvatarRequest request) => switch (id) {
        'request.seed' => request.seed,
        'settings.presentation' => request.settings.presentation.name,
        'settings.bias' => request.settings.bias,
        'settings.age' => request.settings.age,
        'settings.fantasy' => request.settings.fantasy.name,
        'settings.symmetry' => request.settings.symmetry,
        'request.phase' => request.phase,
        'request.guardEnabled' => request.guardEnabled,
        'rendering.size' => request.rendering.size,
        'rendering.detailLevel' => request.rendering.detailLevel.name,
        'rendering.lightingDirection' => request.rendering.lightingDirection.name,
        'rendering.shadingStrength' => request.rendering.shadingStrength,
        'rendering.animateBackground' => request.rendering.animateBackground,
        'rendering.reducedMotion' => request.rendering.reducedMotion,
        _ => throw StateError('Unknown request binding: $id'),
      };

  @override
  bool accepts(Object? value) {
    return switch (kind) {
      EditorFieldKind.text => value is String && value.trim().isNotEmpty,
      EditorFieldKind.integer || EditorFieldKind.range =>
        value is int && (min == null || value >= min!) && (max == null || value <= max!),
      EditorFieldKind.select => options.any((option) => option.value == value),
      EditorFieldKind.boolean => value is bool,
    };
  }

  @override
  AvatarRequest write(AvatarRequest request, Object? value) {
    if (!accepts(value)) {
      throw ArgumentError.value(value, id, 'Value is not accepted by the binding.');
    }
    return switch (id) {
      'request.seed' => request.copyWith(seed: value! as String),
      'settings.presentation' => request.copyWith(
          settings: request.settings.copyWith(
            presentation: AvatarPresentation.values.byName(value! as String),
          ),
        ),
      'settings.bias' => request.copyWith(
          settings: request.settings.copyWith(bias: value! as int),
        ),
      'settings.age' => request.copyWith(
          settings: request.settings.copyWith(age: value! as int),
        ),
      'settings.fantasy' => request.copyWith(
          settings: request.settings.copyWith(
            fantasy: FantasyLevel.values.byName(value! as String),
          ),
        ),
      'settings.symmetry' => request.copyWith(
          settings: request.settings.copyWith(symmetry: value! as bool),
        ),
      'request.phase' => request.copyWith(phase: value! as int),
      'request.guardEnabled' => request.copyWith(guardEnabled: value! as bool),
      'rendering.size' => request.copyWith(
          rendering: request.rendering.copyWith(size: value! as int),
        ),
      'rendering.detailLevel' => request.copyWith(
          rendering: request.rendering.copyWith(
            detailLevel: AvatarDetailLevel.values.byName(value! as String),
          ),
        ),
      'rendering.lightingDirection' => request.copyWith(
          rendering: request.rendering.copyWith(
            lightingDirection:
                AvatarLightingDirection.values.byName(value! as String),
          ),
        ),
      'rendering.shadingStrength' => request.copyWith(
          rendering:
              request.rendering.copyWith(shadingStrength: value! as int),
        ),
      'rendering.animateBackground' => request.copyWith(
          rendering:
              request.rendering.copyWith(animateBackground: value! as bool),
        ),
      'rendering.reducedMotion' => request.copyWith(
          rendering: request.rendering.copyWith(reducedMotion: value! as bool),
        ),
      _ => throw StateError('Unknown request binding: $id'),
    };
  }

  @override
  AvatarRequest reset(AvatarRequest request) {
    const defaults = GenomeSettings();
    return switch (id) {
      'request.seed' => request.copyWith(seed: 'avatar-default'),
      'settings.presentation' => request.copyWith(
          settings: request.settings.copyWith(presentation: defaults.presentation),
        ),
      'settings.bias' => request.copyWith(
          settings: request.settings.copyWith(bias: defaults.bias),
        ),
      'settings.age' => request.copyWith(
          settings: request.settings.copyWith(age: defaults.age),
        ),
      'settings.fantasy' => request.copyWith(
          settings: request.settings.copyWith(fantasy: defaults.fantasy),
        ),
      'settings.symmetry' => request.copyWith(
          settings: request.settings.copyWith(symmetry: defaults.symmetry),
        ),
      'request.phase' => request.copyWith(phase: 0),
      'request.guardEnabled' => request.copyWith(guardEnabled: true),
      'rendering.size' => request.copyWith(
          rendering: request.rendering.copyWith(size: 48),
        ),
      'rendering.detailLevel' => request.copyWith(
          rendering: request.rendering.copyWith(
            detailLevel: AvatarDetailLevel.enhanced,
          ),
        ),
      'rendering.lightingDirection' => request.copyWith(
          rendering: request.rendering.copyWith(
            lightingDirection: AvatarLightingDirection.upperLeft,
          ),
        ),
      'rendering.shadingStrength' => request.copyWith(
          rendering: request.rendering.copyWith(shadingStrength: 2),
        ),
      'rendering.animateBackground' => request.copyWith(
          rendering: request.rendering.copyWith(animateBackground: true),
        ),
      'rendering.reducedMotion' => request.copyWith(
          rendering: request.rendering.copyWith(reducedMotion: false),
        ),
      _ => throw StateError('Unknown request binding: $id'),
    };
  }
}

final class CatalogPropertyBinding extends AvatarPropertyBinding {
  const CatalogPropertyBinding(this.definition);

  final ParameterDefinition definition;

  @override
  String get id => definition.id;
  @override
  String get label => definition.label;
  @override
  String get group => definition.group;
  @override
  String get category => definition.category;
  @override
  String get path => 'overrides.$id';
  @override
  EditorBindingTarget get target => EditorBindingTarget.override;
  @override
  EditorFieldKind get kind => switch (definition.kind) {
        ParameterKind.range => EditorFieldKind.range,
        ParameterKind.select => EditorFieldKind.select,
      };
  @override
  int? get min => definition.min;
  @override
  int? get max => definition.max;
  @override
  int get step => definition.step;
  @override
  List<EditorFieldOption> get options => definition.options
      .map((option) => EditorFieldOption(value: option.value, label: option.label))
      .toList(growable: false);

  @override
  Object? read(AvatarRequest request) => request.overrides[id];

  @override
  bool accepts(Object? value) => value != null && definition.accepts(value);

  @override
  AvatarRequest write(AvatarRequest request, Object? value) {
    if (!accepts(value)) {
      throw ArgumentError.value(value, id, 'Value is not accepted by the catalog.');
    }
    return request.copyWith(
      overrides: <String, Object>{...request.overrides, id: value!},
    );
  }

  @override
  AvatarRequest reset(AvatarRequest request) => request.copyWith(
        overrides: <String, Object>{
          for (final entry in request.overrides.entries)
            if (entry.key != id) entry.key: entry.value,
        },
      );
}

/// Metadata-driven replacement for runtime reflection.
///
/// Dart mirrors are unavailable in Flutter AOT. This registry exposes every
/// editable request property and every catalog field through one binding API,
/// so the server and UI never maintain a second handwritten parameter list.
final class AvatarPropertyRegistry {
  AvatarPropertyRegistry({ParameterCatalog? catalog})
      : catalog = catalog ?? ParameterCatalog.v41,
        requestBindings = _requestBindings(),
        catalogBindings = (catalog ?? ParameterCatalog.v41)
            .fields
            .map(CatalogPropertyBinding.new)
            .toList(growable: false) {
    bindings = <AvatarPropertyBinding>[
      ...requestBindings,
      ...catalogBindings,
    ];
    bindingById = <String, AvatarPropertyBinding>{
      for (final binding in bindings) binding.id: binding,
    };
  }

  final ParameterCatalog catalog;
  final List<RequestPropertyBinding> requestBindings;
  final List<CatalogPropertyBinding> catalogBindings;
  late final List<AvatarPropertyBinding> bindings;
  late final Map<String, AvatarPropertyBinding> bindingById;

  static List<RequestPropertyBinding> _requestBindings() =>
      const <RequestPropertyBinding>[
        RequestPropertyBinding(
          id: 'request.seed',
          label: 'Genom / seed',
          group: 'global',
          category: 'identity',
          kind: EditorFieldKind.text,
          target: EditorBindingTarget.request,
        ),
        RequestPropertyBinding(
          id: 'settings.presentation',
          label: 'Prezentacja',
          group: 'global',
          category: 'identity',
          kind: EditorFieldKind.select,
          target: EditorBindingTarget.settings,
          options: <EditorFieldOption>[
            EditorFieldOption(value: 'neutral', label: 'Neutralna'),
            EditorFieldOption(value: 'masculine', label: 'Męska'),
            EditorFieldOption(value: 'feminine', label: 'Żeńska'),
          ],
        ),
        RequestPropertyBinding(
          id: 'settings.bias',
          label: 'Bias prezentacji',
          group: 'global',
          category: 'identity',
          kind: EditorFieldKind.range,
          target: EditorBindingTarget.settings,
          min: -100,
          max: 100,
        ),
        RequestPropertyBinding(
          id: 'settings.age',
          label: 'Wiek wizualny',
          group: 'global',
          category: 'identity',
          kind: EditorFieldKind.range,
          target: EditorBindingTarget.settings,
          min: 0,
          max: 100,
        ),
        RequestPropertyBinding(
          id: 'settings.fantasy',
          label: 'Poziom fantasy',
          group: 'global',
          category: 'identity',
          kind: EditorFieldKind.select,
          target: EditorBindingTarget.settings,
          options: <EditorFieldOption>[
            EditorFieldOption(value: 'none', label: 'Brak'),
            EditorFieldOption(value: 'subtle', label: 'Subtelny'),
            EditorFieldOption(value: 'moderate', label: 'Umiarkowany'),
            EditorFieldOption(value: 'strong', label: 'Silny'),
          ],
        ),
        RequestPropertyBinding(
          id: 'settings.symmetry',
          label: 'Symetria',
          group: 'global',
          category: 'identity',
          kind: EditorFieldKind.boolean,
          target: EditorBindingTarget.settings,
        ),
        RequestPropertyBinding(
          id: 'request.phase',
          label: 'Faza animacji',
          group: 'global',
          category: 'runtime',
          kind: EditorFieldKind.integer,
          target: EditorBindingTarget.request,
          min: 0,
          max: 1000000,
        ),
        RequestPropertyBinding(
          id: 'request.guardEnabled',
          label: 'Guard / walidacja',
          group: 'global',
          category: 'runtime',
          kind: EditorFieldKind.boolean,
          target: EditorBindingTarget.request,
        ),
        RequestPropertyBinding(
          id: 'rendering.size',
          label: 'Rozdzielczość renderu',
          group: 'global',
          category: 'rendering',
          kind: EditorFieldKind.select,
          target: EditorBindingTarget.request,
          options: <EditorFieldOption>[
            EditorFieldOption(value: 48, label: '48 × 48 · klasyczna'),
            EditorFieldOption(value: 64, label: '64 × 64 · czytelna'),
            EditorFieldOption(value: 80, label: '80 × 80 · szczegółowa'),
            EditorFieldOption(value: 96, label: '96 × 96 · maksymalna'),
          ],
        ),
        RequestPropertyBinding(
          id: 'rendering.detailLevel',
          label: 'Poziom detalu',
          group: 'global',
          category: 'rendering',
          kind: EditorFieldKind.select,
          target: EditorBindingTarget.request,
          options: <EditorFieldOption>[
            EditorFieldOption(value: 'basic', label: 'Podstawowy'),
            EditorFieldOption(value: 'enhanced', label: 'Rozszerzony'),
            EditorFieldOption(value: 'rich', label: 'Bogaty'),
          ],
        ),
        RequestPropertyBinding(
          id: 'rendering.lightingDirection',
          label: 'Kierunek światła',
          group: 'global',
          category: 'rendering',
          kind: EditorFieldKind.select,
          target: EditorBindingTarget.request,
          options: <EditorFieldOption>[
            EditorFieldOption(value: 'upperLeft', label: 'Góra-lewo'),
            EditorFieldOption(value: 'frontal', label: 'Frontalne'),
            EditorFieldOption(value: 'upperRight', label: 'Góra-prawo'),
          ],
        ),
        RequestPropertyBinding(
          id: 'rendering.shadingStrength',
          label: 'Siła cieniowania',
          group: 'global',
          category: 'rendering',
          kind: EditorFieldKind.range,
          target: EditorBindingTarget.request,
          min: 0,
          max: 3,
        ),
        RequestPropertyBinding(
          id: 'rendering.animateBackground',
          label: 'Animowane tło',
          group: 'global',
          category: 'rendering',
          kind: EditorFieldKind.boolean,
          target: EditorBindingTarget.request,
        ),
        RequestPropertyBinding(
          id: 'rendering.reducedMotion',
          label: 'Ogranicz ruch',
          group: 'global',
          category: 'rendering',
          kind: EditorFieldKind.boolean,
          target: EditorBindingTarget.request,
        ),
      ];

  Map<String, Object?> schemaToJson() => <String, Object?>{
        'schemaVersion': 1,
        'groups': const <Map<String, String>>[
          <String, String>{'id': 'global', 'label': 'Ustawienia globalne'},
          <String, String>{'id': 'anatomy', 'label': 'Anatomia'},
          <String, String>{'id': 'details', 'label': 'Szczegóły'},
          <String, String>{'id': 'colors', 'label': 'Kolory'},
          <String, String>{'id': 'wearables', 'label': 'Ubiór i dodatki'},
          <String, String>{'id': 'effects', 'label': 'Efekty i tło'},
        ],
        'requestFields': requestBindings
            .map((binding) => binding.toJson())
            .toList(growable: false),
        'categories': catalog.categories
            .map(
              (category) => <String, Object>{
                'id': category.id,
                'label': category.label,
                'group': category.group,
                'fields': catalogBindings
                    .where((binding) => binding.category == category.id)
                    .map((binding) => binding.toJson())
                    .toList(growable: false),
                'presets': category.presets,
              },
            )
            .toList(growable: false),
        'wholePresets': <String, Object>{
          for (final entry in catalog.wholePresets.entries)
            entry.key: entry.value.toJson(),
        },
        'bindingCount': bindings.length,
        'catalogFieldCount': catalog.fieldCount,
      };

  Map<String, Object?> stateToJson(
    AvatarRequest request,
    AvatarGenome genome,
  ) {
    final state = <String, Object?>{};
    for (final binding in requestBindings) {
      state[binding.id] = <String, Object?>{
        'value': binding.read(request),
        'resolvedValue': binding.read(request),
        'source': 'request',
        'isOverridden': false,
        'isLocked': false,
      };
    }
    for (final binding in catalogBindings) {
      final id = binding.id;
      final categoryLock = request.lockedCategories[binding.category];
      final isParameterLocked = request.lockedParameters.containsKey(id);
      final isCategoryLocked = categoryLock?.containsKey(id) ?? false;
      state[id] = <String, Object?>{
        'value': request.overrides[id] ?? genome.values[id],
        'overrideValue': request.overrides[id],
        'resolvedValue': genome.values[id],
        'source': genome.sources[id]?.source ?? 'unknown',
        'isOverridden': request.overrides.containsKey(id),
        'isLocked': isParameterLocked || isCategoryLocked,
        'lockSource': isParameterLocked
            ? 'parameter'
            : isCategoryLocked
                ? 'category'
                : null,
      };
    }
    return state;
  }
}

final class AvatarRequestBinder {
  AvatarRequestBinder({AvatarPropertyRegistry? registry})
      : registry = registry ?? AvatarPropertyRegistry();

  final AvatarPropertyRegistry registry;

  AvatarRequest setValue(AvatarRequest request, String id, Object? value) {
    final binding = _binding(id);
    return binding.write(request, value);
  }

  AvatarRequest resetValue(AvatarRequest request, String id) {
    return _binding(id).reset(request);
  }

  AvatarRequest lockValue(
    AvatarRequest request,
    String id,
    Object value,
  ) {
    final binding = _binding(id);
    if (binding is! CatalogPropertyBinding || !binding.accepts(value)) {
      throw ArgumentError.value(id, 'id', 'Only catalog fields can be locked.');
    }
    return request.copyWith(
      lockedParameters: <String, Object>{
        ...request.lockedParameters,
        id: value,
      },
    );
  }

  AvatarRequest unlockValue(AvatarRequest request, String id) =>
      request.copyWith(
        lockedParameters: <String, Object>{
          for (final entry in request.lockedParameters.entries)
            if (entry.key != id) entry.key: entry.value,
        },
      );

  AvatarPropertyBinding _binding(String id) {
    final binding = registry.bindingById[id];
    if (binding == null) {
      throw ArgumentError.value(id, 'id', 'Unknown property binding.');
    }
    return binding;
  }
}
