import '../api/avatar_generator.dart';
import '../api/avatar_lock_service.dart';
import '../api/avatar_preset_service.dart';
import '../api/avatar_request.dart';
import '../api/avatar_result.dart';
import '../api/avatar_version.dart';
import '../catalog/parameter_catalog.dart';
import '../serialization/avatar_codec.dart';
import '../util/deep_freeze.dart';
import 'avatar_property_binding.dart';
import 'avatar_request_validation.dart';

final class AvatarEditorAction {
  const AvatarEditorAction({
    required this.operation,
    this.id,
    this.value,
    this.category,
    this.preset,
  });

  factory AvatarEditorAction.fromJson(Map<String, Object?> json) =>
      AvatarEditorAction(
        operation: json['op']! as String,
        id: json['id'] as String?,
        value: json['value'],
        category: json['category'] as String?,
        preset: json['preset'] as String?,
      );

  final String operation;
  final String? id;
  final Object? value;
  final String? category;
  final String? preset;
}

final class AvatarEditorResponse {
  AvatarEditorResponse({
    required this.request,
    required this.result,
    required this.svg,
    required Map<String, Object?> propertyState,
  }) : propertyState = deepFreezeStringMap(propertyState);

  final AvatarRequest request;
  final AvatarResult result;
  final String svg;
  final Map<String, Object?> propertyState;

  Map<String, Object?> toJson({bool includePixels = false}) => <String, Object?>{
        'request': request.toJson(),
        'imageHash': result.imageHash,
        'genome': result.genome.toJson(),
        'result': result.toJson(includePixels: includePixels),
        'svg': svg,
        'validation': result.validation.toJson(),
        'properties': propertyState,
      };
}

/// Application service used by the HTTP adapter and reusable in tests/tools.
final class AvatarEditorService {
  factory AvatarEditorService({
    ParameterCatalog? catalog,
    AvatarGenerator? generator,
    AvatarPropertyRegistry? registry,
    AvatarRequestBinder? binder,
    AvatarRequestValidator? requestValidator,
    AvatarPresetService? presetService,
    AvatarLockService? lockService,
  }) {
    final resolvedCatalog = catalog ??
        generator?.catalog ??
        registry?.catalog ??
        binder?.registry.catalog ??
        requestValidator?.catalog ??
        presetService?.catalog ??
        lockService?.catalog ??
        ParameterCatalog.current;

    void requireCatalog(ParameterCatalog? candidate, String name) {
      if (candidate != null && !identical(candidate, resolvedCatalog)) {
        throw ArgumentError(
          '$name uses a different ParameterCatalog than the editor service.',
        );
      }
    }

    requireCatalog(generator?.catalog, 'generator');
    requireCatalog(registry?.catalog, 'registry');
    requireCatalog(binder?.registry.catalog, 'binder');
    requireCatalog(requestValidator?.catalog, 'requestValidator');
    requireCatalog(presetService?.catalog, 'presetService');
    requireCatalog(lockService?.catalog, 'lockService');

    final resolvedRegistry =
        registry ?? binder?.registry ?? AvatarPropertyRegistry(catalog: resolvedCatalog);
    if (binder != null && !identical(binder.registry, resolvedRegistry)) {
      throw ArgumentError(
        'binder and registry must reference the same AvatarPropertyRegistry.',
      );
    }

    return AvatarEditorService._(
      catalog: resolvedCatalog,
      generator: generator ?? AvatarGenerator(catalog: resolvedCatalog),
      registry: resolvedRegistry,
      binder: binder ?? AvatarRequestBinder(registry: resolvedRegistry),
      requestValidator: requestValidator ??
          AvatarRequestValidator(catalog: resolvedCatalog),
      presetService:
          presetService ?? AvatarPresetService(catalog: resolvedCatalog),
      lockService: lockService ?? AvatarLockService(catalog: resolvedCatalog),
    );
  }

  const AvatarEditorService._({
    required this.catalog,
    required this.generator,
    required this.registry,
    required this.binder,
    required this.requestValidator,
    required this.presetService,
    required this.lockService,
  });

  final ParameterCatalog catalog;
  final AvatarGenerator generator;
  final AvatarPropertyRegistry registry;
  final AvatarRequestBinder binder;
  final AvatarRequestValidator requestValidator;
  final AvatarPresetService presetService;
  final AvatarLockService lockService;

  AvatarRequest get defaultRequest => AvatarRequest(seed: 'avatar-default');

  Map<String, Object?> schemaToJson() => <String, Object?>{
        ...registry.schemaToJson(),
        'requestSchemaVersion': AvatarGenomeVersion.requestSchema,
        'resultSchemaVersion': AvatarGenomeVersion.resultSchema,
        'generatorVersion': AvatarGenomeVersion.generator,
        'catalogVersion': AvatarGenomeVersion.catalog,
      };

  AvatarRequest resolveRequest(
    AvatarRequest initialRequest, {
    List<AvatarEditorAction> actions = const <AvatarEditorAction>[],
  }) =>
      _applyActions(initialRequest, actions).request;

  AvatarEditorResponse generate(
    AvatarRequest initialRequest, {
    List<AvatarEditorAction> actions = const <AvatarEditorAction>[],
    int svgScale = 8,
  }) {
    if (svgScale < 1 || svgScale > 64) {
      throw ArgumentError.value(svgScale, 'svgScale', 'Must be between 1 and 64.');
    }
    final resolved = _applyActions(initialRequest, actions);
    final result = resolved.current ?? generator.generate(resolved.request);
    final svg = AvatarSvgCodec(scale: svgScale).encode(result);
    return AvatarEditorResponse(
      request: resolved.request,
      result: result,
      svg: svg,
      propertyState: registry.stateToJson(resolved.request, result.genome),
    );
  }

  ({AvatarRequest request, AvatarResult? current}) _applyActions(
    AvatarRequest initialRequest,
    List<AvatarEditorAction> actions,
  ) {
    requestValidator.validate(initialRequest);
    var request = initialRequest;
    AvatarResult? current;

    AvatarResult resolve() => current ??= generator.generate(request);
    void invalidate() => current = null;

    for (final action in actions) {
      switch (action.operation) {
        case 'set':
          request = binder.setValue(request, _required(action.id, 'id'), action.value);
          invalidate();
          break;
        case 'reset':
          request = binder.resetValue(request, _required(action.id, 'id'));
          invalidate();
          break;
        case 'lock':
          final id = _required(action.id, 'id');
          final value = action.value ?? resolve().genome.values[id];
          if (value == null) {
            throw ArgumentError.value(id, 'id', 'Cannot resolve a lock value.');
          }
          request = binder.lockValue(request, id, value);
          invalidate();
          break;
        case 'unlock':
          request = binder.unlockValue(request, _required(action.id, 'id'));
          invalidate();
          break;
        case 'wholePreset':
          request = presetService.applyWholePreset(
            request,
            _required(action.preset, 'preset'),
          );
          invalidate();
          break;
        case 'categoryPreset':
          request = presetService.applyCategoryPreset(
            request,
            _required(action.category, 'category'),
            _required(action.preset, 'preset'),
          );
          invalidate();
          break;
        case 'resetCategory':
          request = presetService.clearCategoryOverrides(
            request,
            _required(action.category, 'category'),
          );
          invalidate();
          break;
        case 'rerollCategory':
          request = presetService.rerollCategory(
            request,
            _required(action.category, 'category'),
          );
          invalidate();
          break;
        case 'lockCategory':
          request = lockService.lockCategory(
            request,
            resolve().genome,
            _required(action.category, 'category'),
          );
          invalidate();
          break;
        case 'unlockCategory':
          request = lockService.unlockCategory(
            request,
            _required(action.category, 'category'),
          );
          invalidate();
          break;
        case 'resetOverrides':
          request = request.copyWith(overrides: const <String, Object>{});
          invalidate();
          break;
        case 'resetLocks':
          request = request.copyWith(
            lockedParameters: const <String, Object>{},
            lockedCategories: const <String, Map<String, Object>>{},
          );
          invalidate();
          break;
        default:
          throw ArgumentError.value(
            action.operation,
            'op',
            'Unknown editor action.',
          );
      }
    }

    requestValidator.validate(request);
    return (request: request, current: current);
  }

  T _required<T>(T? value, String name) {
    if (value == null) {
      throw ArgumentError.notNull(name);
    }
    return value;
  }
}
