import '../api/avatar_generator.dart';
import '../api/avatar_lock_service.dart';
import '../api/avatar_preset_service.dart';
import '../api/avatar_request.dart';
import '../api/avatar_result.dart';
import '../api/avatar_version.dart';
import '../catalog/parameter_catalog.dart';
import '../serialization/avatar_codec.dart';
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
  const AvatarEditorResponse({
    required this.request,
    required this.result,
    required this.svg,
    required this.propertyState,
  });

  final AvatarRequest request;
  final AvatarResult result;
  final String svg;
  final Map<String, Object?> propertyState;

  Map<String, Object?> toJson({bool includePixels = false}) =>
      <String, Object?>{
        'request': request.toJson(),
        'imageHash': result.imageHash,
        'genome': result.genome.toJson(),
        'result': result.toJson(includePixels: includePixels),
        'svg': svg,
        'validation': result.validation.toJson(),
        'properties': propertyState,
      };
}

final class AvatarAnimationPreviewResponse {
  const AvatarAnimationPreviewResponse({
    required this.request,
    required this.animation,
    required this.frameDuration,
    required this.frames,
  });

  final AvatarRequest request;
  final AvatarAnimation animation;
  final Duration frameDuration;
  final List<Map<String, Object?>> frames;

  Map<String, Object?> toJson({bool includePixels = false}) =>
      <String, Object?>{
        'request': request.toJson(),
        'frameDurationMs': frameDuration.inMilliseconds,
        'loop': animation.loop,
        'frameCount': frames.length,
        'frames': frames,
      };
}

final class AvatarAnimationClipFrame {
  const AvatarAnimationClipFrame({
    required this.phase,
    required this.imageHash,
    required this.svg,
    required this.nodeTransforms,
  });

  final int phase;
  final String imageHash;
  final String svg;
  final Map<String, Object?> nodeTransforms;

  Map<String, Object?> toJson() => <String, Object?>{
        'phase': phase,
        'imageHash': imageHash,
        'svg': svg,
        'nodeTransforms': nodeTransforms,
      };
}

final class AvatarAnimationClipVariant {
  const AvatarAnimationClipVariant({
    required this.id,
    required this.seedPhase,
    required this.frames,
  });

  final String id;
  final int seedPhase;
  final List<AvatarAnimationClipFrame> frames;

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'seedPhase': seedPhase,
        'frames': frames.map((frame) => frame.toJson()).toList(growable: false),
      };
}

final class AvatarAnimationClipResponse {
  const AvatarAnimationClipResponse({
    required this.id,
    required this.label,
    required this.effectiveId,
    required this.frameDuration,
    required this.loop,
    required this.variants,
    required this.quality,
    required this.tags,
    this.fallbackReason,
  });

  final String id;
  final String label;
  final String effectiveId;
  final Duration frameDuration;
  final bool loop;
  final List<AvatarAnimationClipVariant> variants;
  final AvatarAnimationClipQuality quality;
  final List<String> tags;
  final String? fallbackReason;

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'label': label,
        'effectiveId': effectiveId,
        'frameDurationMs': frameDuration.inMilliseconds,
        'loop': loop,
        'fallbackReason': fallbackReason,
        'quality': quality.toJson(),
        'tags': tags,
        'variants':
            variants.map((variant) => variant.toJson()).toList(growable: false),
      };
}

final class AvatarAnimationClipQuality {
  const AvatarAnimationClipQuality({
    required this.uniqueFrameCount,
    required this.averageChangedPixels,
    required this.maxChangedPixels,
    required this.isMeaningful,
  });

  final int uniqueFrameCount;
  final double averageChangedPixels;
  final int maxChangedPixels;
  final bool isMeaningful;

  Map<String, Object?> toJson() => <String, Object?>{
        'uniqueFrameCount': uniqueFrameCount,
        'averageChangedPixels': averageChangedPixels,
        'maxChangedPixels': maxChangedPixels,
        'isMeaningful': isMeaningful,
      };
}

final class AvatarAnimationProfile {
  const AvatarAnimationProfile({
    required this.eyesVisible,
    required this.browsVisible,
    required this.mouthVisible,
    required this.eyewearVisible,
    required this.faceMaskVisible,
    required this.headwearVisible,
    required this.cyberVisible,
    required this.jewelryVisible,
    required this.shoulderPropVisible,
    required this.auraVisible,
    required this.effectVisible,
    required this.faceExpressiveVisible,
    required this.faceMostlyOccluded,
  });

  final bool eyesVisible;
  final bool browsVisible;
  final bool mouthVisible;
  final bool eyewearVisible;
  final bool faceMaskVisible;
  final bool headwearVisible;
  final bool cyberVisible;
  final bool jewelryVisible;
  final bool shoulderPropVisible;
  final bool auraVisible;
  final bool effectVisible;
  final bool faceExpressiveVisible;
  final bool faceMostlyOccluded;

  Map<String, Object?> toJson() => <String, Object?>{
        'eyesVisible': eyesVisible,
        'browsVisible': browsVisible,
        'mouthVisible': mouthVisible,
        'eyewearVisible': eyewearVisible,
        'faceMaskVisible': faceMaskVisible,
        'headwearVisible': headwearVisible,
        'cyberVisible': cyberVisible,
        'jewelryVisible': jewelryVisible,
        'shoulderPropVisible': shoulderPropVisible,
        'auraVisible': auraVisible,
        'effectVisible': effectVisible,
        'faceExpressiveVisible': faceExpressiveVisible,
        'faceMostlyOccluded': faceMostlyOccluded,
      };
}

final class AvatarAnimationBundleResponse {
  const AvatarAnimationBundleResponse({
    required this.request,
    required this.baseSvg,
    required this.profile,
    required this.defaultAnimationId,
    required this.clips,
    required this.renderGraph,
  });

  final AvatarRequest request;
  final String baseSvg;
  final AvatarAnimationProfile profile;
  final String defaultAnimationId;
  final List<AvatarAnimationClipResponse> clips;
  final Map<String, Object?> renderGraph;

  Map<String, Object?> toJson() => <String, Object?>{
        'request': request.toJson(),
        'baseSvg': baseSvg,
        'renderGraph': renderGraph,
        'defaultAnimationId': defaultAnimationId,
        'profile': profile.toJson(),
        'clips': clips.map((clip) => clip.toJson()).toList(growable: false),
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
    final resolvedCatalog = catalog ?? ParameterCatalog.v41;
    final resolvedRegistry =
        registry ?? AvatarPropertyRegistry(catalog: resolvedCatalog);
    return AvatarEditorService._(
      catalog: resolvedCatalog,
      generator: generator ?? AvatarGenerator(catalog: resolvedCatalog),
      registry: resolvedRegistry,
      binder: binder ?? AvatarRequestBinder(registry: resolvedRegistry),
      requestValidator: requestValidator ??
          AvatarRequestValidator(
            catalog: resolvedCatalog,
            registry: resolvedRegistry,
          ),
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

  /// New editor sessions start in idle. Other reactions are selected by the
  /// player and persisted as request overrides, never randomly assigned.
  AvatarRequest get defaultRequest => const AvatarRequest(
        seed: 'avatar-default',
        overrides: <String, Object>{'v4.animation': 'idle'},
      );

  Map<String, Object?> schemaToJson() => <String, Object?>{
        ...registry.schemaToJson(),
        'requestSchemaVersion': AvatarGenomeVersion.requestSchema,
        'resultSchemaVersion': AvatarGenomeVersion.resultSchema,
        'generatorVersion': AvatarGenomeVersion.generator,
        'catalogVersion': AvatarGenomeVersion.catalog,
      };

  AvatarEditorResponse generate(
    AvatarRequest initialRequest, {
    List<AvatarEditorAction> actions = const <AvatarEditorAction>[],
    int svgScale = 8,
  }) {
    final request = applyActions(initialRequest, actions: actions);
    final result = generator.generate(request);
    final svg = AvatarSvgCodec(scale: svgScale).encode(result);
    return AvatarEditorResponse(
      request: request,
      result: result,
      svg: svg,
      propertyState: registry.stateToJson(request, result.genome),
    );
  }

  AvatarAnimation generatePreviewAnimation(
    AvatarRequest initialRequest, {
    List<AvatarEditorAction> actions = const <AvatarEditorAction>[],
    int frameCount = 4,
    int phaseStep = 2,
    Duration frameDuration = const Duration(milliseconds: 125),
  }) {
    final request = applyActions(initialRequest, actions: actions);
    final safeFrameCount = frameCount.clamp(1, 16);
    final safePhaseStep = phaseStep.clamp(1, 8);
    final frames = <AvatarResult>[];
    for (var index = 0; index < safeFrameCount; index++) {
      final phase = request.phase + index * safePhaseStep;
      final frameRequest = request.copyWith(phase: phase);
      frames.add(generator.generate(frameRequest));
    }
    return AvatarAnimation(
      frames: frames,
      frameDuration: frameDuration,
    );
  }

  AvatarAnimationPreviewResponse generateAnimationPreview(
    AvatarRequest initialRequest, {
    List<AvatarEditorAction> actions = const <AvatarEditorAction>[],
    int svgScale = 8,
    int frameCount = 4,
    int phaseStep = 2,
  }) {
    final request = applyActions(initialRequest, actions: actions);
    final safePhaseStep = phaseStep.clamp(1, 8);
    final animation = generatePreviewAnimation(
      request,
      frameCount: frameCount,
      phaseStep: safePhaseStep,
    );
    final frames = <Map<String, Object?>>[];
    for (var index = 0; index < animation.frames.length; index++) {
      final phase = request.phase + index * safePhaseStep;
      final result = animation.frames[index];
      frames.add(<String, Object?>{
        'phase': phase,
        'imageHash': result.imageHash,
        'svg': AvatarSvgCodec(scale: svgScale).encode(result),
        'result': result.toJson(includePixels: false),
      });
    }
    return AvatarAnimationPreviewResponse(
      request: request,
      animation: animation,
      frameDuration: animation.frameDuration,
      frames: frames,
    );
  }

  AvatarAnimationBundleResponse generateAnimationBundle(
    AvatarRequest initialRequest, {
    List<AvatarEditorAction> actions = const <AvatarEditorAction>[],
    int svgScale = 8,
  }) {
    final response = generate(
      initialRequest,
      actions: actions,
      svgScale: svgScale,
    );
    final profile = _profileFor(response.result);
    final animationField = registry.bindingById['v4.animation'];
    final options = animationField?.options ?? const <EditorFieldOption>[];
    final clips = <AvatarAnimationClipResponse>[];
    for (final option in options) {
      final id = option.value.toString();
      if (id == 'none') continue;
      clips.add(
        _buildClip(
          response.request,
          profile: profile,
          animationId: id,
          label: option.label,
          svgScale: svgScale,
        ),
      );
    }
    return AvatarAnimationBundleResponse(
      request: response.request,
      baseSvg: response.svg,
      profile: profile,
      defaultAnimationId: 'idle',
      clips: clips,
      renderGraph: response.result.renderGraph.toJson(),
    );
  }

  /// Generates only the requested player clip.
  ///
  /// The editor uses this path to keep seed changes responsive. Building every
  /// clip eagerly is intentionally reserved for exports and saved bundles.
  AvatarAnimationBundleResponse generateAnimationClip(
    AvatarRequest initialRequest, {
    required String animationId,
    List<AvatarEditorAction> actions = const <AvatarEditorAction>[],
    int svgScale = 8,
  }) {
    final response = generate(
      initialRequest,
      actions: actions,
      svgScale: svgScale,
    );
    final profile = _profileFor(response.result);
    final animationField = registry.bindingById['v4.animation'];
    final options = animationField?.options ?? const <EditorFieldOption>[];
    final matchingOptions = options.where(
      (option) =>
          option.value.toString() == animationId && animationId != 'none',
    );
    if (matchingOptions.isEmpty) {
      throw ArgumentError.value(
        animationId,
        'animationId',
        'Unknown or non-renderable animation.',
      );
    }
    final option = matchingOptions.first;
    return AvatarAnimationBundleResponse(
      request: response.request,
      baseSvg: response.svg,
      profile: profile,
      defaultAnimationId: 'idle',
      clips: <AvatarAnimationClipResponse>[
        _buildClip(
          response.request,
          profile: profile,
          animationId: animationId,
          label: option.label,
          svgScale: svgScale,
        ),
      ],
      renderGraph: response.result.renderGraph.toJson(),
    );
  }

  AvatarRequest applyActions(
    AvatarRequest initialRequest, {
    List<AvatarEditorAction> actions = const <AvatarEditorAction>[],
  }) {
    requestValidator.validate(initialRequest);
    var request = initialRequest;
    AvatarResult? current;

    AvatarResult resolve() => current ??= generator.generate(request);
    void invalidate() => current = null;

    for (final action in actions) {
      switch (action.operation) {
        case 'set':
          request = binder.setValue(
              request, _required(action.id, 'id'), action.value);
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
    return request;
  }

  T _required<T>(T? value, String name) {
    if (value == null) {
      throw ArgumentError.notNull(name);
    }
    return value;
  }

  AvatarAnimationClipResponse _buildClip(
    AvatarRequest request, {
    required AvatarAnimationProfile profile,
    required String animationId,
    required String label,
    required int svgScale,
  }) {
    var recipe = _resolveRecipe(
      request,
      profile: profile,
      animationId: animationId,
    );
    var materialized = _materializeClip(
      request,
      animationId: animationId,
      recipe: recipe,
      svgScale: svgScale,
    );
    if (!materialized.quality.isMeaningful) {
      recipe = _boostRecipe(recipe, profile: profile);
      materialized = _materializeClip(
        request,
        animationId: animationId,
        recipe: recipe,
        svgScale: svgScale,
      );
    }
    if (!materialized.quality.isMeaningful) {
      final fallbackRecipe = _qualityFallbackRecipe(
        recipe,
        profile: profile,
      );
      if (fallbackRecipe != null) {
        recipe = fallbackRecipe;
        materialized = _materializeClip(
          request,
          animationId: animationId,
          recipe: recipe,
          svgScale: svgScale,
        );
      }
    }
    return AvatarAnimationClipResponse(
      id: animationId,
      label: label,
      effectiveId: recipe.effectiveAnimationId,
      frameDuration: recipe.frameDuration,
      loop: true,
      variants: materialized.variants,
      quality: materialized.quality,
      tags: recipe.tags,
      fallbackReason: recipe.fallbackReason,
    );
  }

  AvatarRequest _requestForRecipe(
    AvatarRequest request,
    _AnimationRecipe recipe, {
    required int seedPhase,
  }) {
    return request.copyWith(
      phase: seedPhase,
      overrides: <String, Object>{
        ...request.overrides,
        'v4.animation': recipe.effectiveAnimationId,
        'v4.animationSpeed': recipe.speed,
        'v4.animationAmplitude': recipe.amplitude,
      },
    );
  }

  _AnimationRecipe _resolveRecipe(
    AvatarRequest request, {
    required AvatarAnimationProfile profile,
    required String animationId,
  }) {
    var effectiveAnimationId = animationId;
    String? fallbackReason;
    final tags = <String>[];
    var speed = switch (animationId) {
      'talking' || 'laughing' || 'celebration' => 4,
      'sleeping' => 2,
      _ => 3,
    };
    var amplitude = switch (animationId) {
      'laughing' || 'celebration' || 'scared' || 'surprised' => 3,
      'sleeping' => 1,
      _ => 2,
    };
    var frameCount = switch (animationId) {
      'idle' => 18,
      'talking' || 'laughing' => 16,
      'sleeping' => 14,
      _ => 12,
    };
    var phaseStep = switch (animationId) {
      'laughing' || 'scared' || 'celebration' => 1,
      'idle' => 2,
      _ => 2,
    };
    var variantCount = animationId == 'idle' ? 4 : 1;

    if (profile.faceMostlyOccluded &&
        <String>{
          'talking',
          'laughing',
          'happy',
          'sad',
          'angry',
          'hurt',
          'thinking',
          'confused',
          'surprised',
          'scared',
        }.contains(animationId)) {
      fallbackReason = 'faceOccludedEnhanced';
      if (profile.cyberVisible || profile.eyewearVisible) {
        tags.add('gear-reactive');
      }
      if (profile.auraVisible || profile.effectVisible) {
        tags.add('fx-reactive');
      }
      if (profile.jewelryVisible || profile.shoulderPropVisible) {
        tags.add('prop-reactive');
      }
      if (!profile.cyberVisible &&
          !profile.eyewearVisible &&
          !profile.auraVisible &&
          !profile.effectVisible &&
          !profile.jewelryVisible &&
          !profile.shoulderPropVisible) {
        tags.add('body-reactive');
      }
      frameCount = 14;
      phaseStep = 1;
      speed = 4;
      amplitude = 3;
      variantCount = 1;
    }

    if (animationId == 'idle') {
      tags.add('ambient');
      if (profile.faceMostlyOccluded) tags.add('adaptive-idle');
    }
    if (profile.mouthVisible) tags.add('mouth');
    if (profile.eyesVisible || profile.browsVisible) tags.add('face');
    if (profile.eyewearVisible || profile.headwearVisible) tags.add('headgear');
    if (profile.shoulderPropVisible) tags.add('companion');
    if (profile.auraVisible || profile.effectVisible) tags.add('fx');
    return _AnimationRecipe(
      effectiveAnimationId: effectiveAnimationId,
      frameCount: frameCount,
      frameDuration: const Duration(milliseconds: 125),
      phaseStep: phaseStep,
      variantCount: variantCount,
      phaseSeedOffset: switch (animationId) {
        'idle' => 0,
        'sleeping' => 9,
        'talking' => 17,
        'laughing' => 23,
        _ => animationId.length * 11,
      },
      variantPhaseStride: 37,
      speed: speed,
      amplitude: amplitude,
      fallbackReason: fallbackReason,
      tags: tags.toSet().toList(growable: false),
    );
  }

  _MaterializedClip _materializeClip(
    AvatarRequest request, {
    required String animationId,
    required _AnimationRecipe recipe,
    required int svgScale,
  }) {
    final variants = <AvatarAnimationClipVariant>[];
    final results = <AvatarResult>[];
    for (var variantIndex = 0;
        variantIndex < recipe.variantCount;
        variantIndex++) {
      final seedPhase = request.phase +
          recipe.phaseSeedOffset +
          variantIndex * recipe.variantPhaseStride;
      final variantRequest = _requestForRecipe(
        request,
        recipe,
        seedPhase: seedPhase,
      );
      final animation = generator.generateAnimation(
        variantRequest,
        frameCount: recipe.frameCount,
        phaseStep: recipe.phaseStep,
        frameDuration: recipe.frameDuration,
      );
      final frames = <AvatarAnimationClipFrame>[];
      for (var index = 0; index < recipe.frameCount; index++) {
        final phase = seedPhase + index * recipe.phaseStep;
        final result = animation.frames[index];
        results.add(result);
        frames.add(
          AvatarAnimationClipFrame(
            phase: phase,
            imageHash: result.imageHash,
            svg: AvatarSvgCodec(scale: svgScale).encode(result),
            nodeTransforms: <String, Object?>{
              for (final node in result.renderGraph.nodes)
                if (!node.localTransform.isIdentity)
                  node.id: node.localTransform.toJson(),
            },
          ),
        );
      }
      variants.add(
        AvatarAnimationClipVariant(
          id: '${animationId}_v${variantIndex + 1}',
          seedPhase: seedPhase,
          frames: frames,
        ),
      );
    }
    return _MaterializedClip(
      variants: variants,
      quality: _scoreClipQuality(results, recipe: recipe),
    );
  }

  AvatarAnimationClipQuality _scoreClipQuality(
    List<AvatarResult> frames, {
    required _AnimationRecipe recipe,
  }) {
    if (frames.isEmpty) {
      return const AvatarAnimationClipQuality(
        uniqueFrameCount: 0,
        averageChangedPixels: 0,
        maxChangedPixels: 0,
        isMeaningful: false,
      );
    }
    final uniqueFrameCount =
        frames.map((frame) => frame.imageHash).toSet().length;
    final changedPixels = <int>[];
    for (var index = 1; index < frames.length; index++) {
      changedPixels.add(_changedPixels(frames[index - 1], frames[index]));
    }
    final maxChangedPixels = changedPixels.isEmpty
        ? 0
        : changedPixels.reduce((a, b) => a > b ? a : b);
    final averageChangedPixels = changedPixels.isEmpty
        ? 0.0
        : changedPixels.reduce((a, b) => a + b) / changedPixels.length;
    final minUnique = recipe.effectiveAnimationId == 'idle' ? 2 : 3;
    final minAverage = recipe.effectiveAnimationId == 'idle' ? 2.0 : 4.0;
    final minMax = recipe.effectiveAnimationId == 'idle' ? 4 : 8;
    return AvatarAnimationClipQuality(
      uniqueFrameCount: uniqueFrameCount,
      averageChangedPixels: averageChangedPixels,
      maxChangedPixels: maxChangedPixels,
      isMeaningful: uniqueFrameCount >= minUnique &&
          (averageChangedPixels >= minAverage || maxChangedPixels >= minMax),
    );
  }

  int _changedPixels(AvatarResult previous, AvatarResult next) {
    final previousPixels = previous.image.indices;
    final nextPixels = next.image.indices;
    var changed = 0;
    for (var index = 0;
        index < previousPixels.length && index < nextPixels.length;
        index++) {
      if (previousPixels[index] != nextPixels[index]) changed++;
    }
    return changed;
  }

  _AnimationRecipe _boostRecipe(
    _AnimationRecipe recipe, {
    required AvatarAnimationProfile profile,
  }) {
    return recipe.copyWith(
      speed: recipe.speed >= 6 ? 6 : recipe.speed + 1,
      amplitude: recipe.amplitude >= 4 ? 4 : recipe.amplitude + 1,
      phaseStep: recipe.phaseStep <= 1 ? 1 : recipe.phaseStep - 1,
      variantCount: recipe.variantCount < 2 && profile.faceMostlyOccluded
          ? 2
          : recipe.variantCount,
      tags: <String>{...recipe.tags, 'quality-boosted'}.toList(growable: false),
    );
  }

  _AnimationRecipe? _qualityFallbackRecipe(
    _AnimationRecipe recipe, {
    required AvatarAnimationProfile profile,
  }) {
    return recipe.copyWith(
      frameCount: recipe.frameCount < 16 ? 16 : recipe.frameCount,
      phaseStep: 1,
      speed: 5,
      amplitude: 4,
      variantCount: recipe.variantCount < (profile.faceMostlyOccluded ? 3 : 2)
          ? (profile.faceMostlyOccluded ? 3 : 2)
          : recipe.variantCount,
      fallbackReason: recipe.fallbackReason == null
          ? 'lowVisibleMotionEnhanced'
          : '${recipe.fallbackReason}+lowVisibleMotionEnhanced',
      tags: <String>{...recipe.tags, 'quality-rescue'}.toList(growable: false),
    );
  }

  AvatarAnimationProfile _profileFor(AvatarResult result) {
    double ratioFor(String prefix) {
      var source = 0;
      var visible = 0;
      for (final layer in result.layers) {
        if (!layer.id.startsWith(prefix)) continue;
        source += layer.sourcePixelCount ?? layer.mask.count;
        visible += layer.visiblePixelCount ?? layer.mask.count;
      }
      if (source <= 0) return 0;
      return visible / source;
    }

    bool hasValue(String id) => result.genome.values[id] != null;
    bool notNone(String id) => result.genome.values[id]?.toString() != 'none';
    final eyesVisible = ratioFor('eyes.') >= 0.25;
    final browsVisible = ratioFor('brows') >= 0.25;
    final mouthVisible = ratioFor('mouth.') >= 0.25;
    final eyewearVisible =
        notNone('v4.eyewear') && ratioFor('eyewear.') >= 0.18;
    final faceMaskVisible =
        notNone('v4.faceMask') && ratioFor('faceMask.') >= 0.18;
    final headwearVisible =
        notNone('v4.headwear') && ratioFor('headwear.') >= 0.18;
    final cyberVisible =
        notNone('v4.cybernetics') && ratioFor('cyber.') >= 0.18;
    final jewelryVisible =
        (notNone('v4.earJewelry') || notNone('v4.neckJewelry')) &&
            ratioFor('jewelry.') >= 0.12;
    final shoulderPropVisible =
        notNone('v4.shoulderProp') && ratioFor('shoulderProp.') >= 0.12;
    final auraVisible = notNone('v4.aura') && ratioFor('aura.') >= 0.1;
    final effectVisible = notNone('v4.effect') && ratioFor('effect.') >= 0.08;
    final expressiveRequested = (hasValue('eyes.shape') &&
            result.genome.values['eyes.shape']?.toString() != 'none') ||
        (hasValue('mouth.shape') &&
            result.genome.values['mouth.shape']?.toString() != 'none') ||
        (hasValue('brows.shape') &&
            result.genome.values['brows.shape']?.toString() != 'none');
    final faceExpressiveVisible =
        expressiveRequested && (eyesVisible || browsVisible || mouthVisible);
    final faceMostlyOccluded = !faceExpressiveVisible &&
        (faceMaskVisible || headwearVisible || eyewearVisible || cyberVisible);
    return AvatarAnimationProfile(
      eyesVisible: eyesVisible,
      browsVisible: browsVisible,
      mouthVisible: mouthVisible,
      eyewearVisible: eyewearVisible,
      faceMaskVisible: faceMaskVisible,
      headwearVisible: headwearVisible,
      cyberVisible: cyberVisible,
      jewelryVisible: jewelryVisible,
      shoulderPropVisible: shoulderPropVisible,
      auraVisible: auraVisible,
      effectVisible: effectVisible,
      faceExpressiveVisible: faceExpressiveVisible,
      faceMostlyOccluded: faceMostlyOccluded,
    );
  }
}

final class _AnimationRecipe {
  const _AnimationRecipe({
    required this.effectiveAnimationId,
    required this.frameCount,
    required this.frameDuration,
    required this.phaseStep,
    required this.variantCount,
    required this.phaseSeedOffset,
    required this.variantPhaseStride,
    required this.speed,
    required this.amplitude,
    required this.tags,
    this.fallbackReason,
  });

  final String effectiveAnimationId;
  final int frameCount;
  final Duration frameDuration;
  final int phaseStep;
  final int variantCount;
  final int phaseSeedOffset;
  final int variantPhaseStride;
  final int speed;
  final int amplitude;
  final String? fallbackReason;
  final List<String> tags;

  _AnimationRecipe copyWith({
    String? effectiveAnimationId,
    int? frameCount,
    Duration? frameDuration,
    int? phaseStep,
    int? variantCount,
    int? phaseSeedOffset,
    int? variantPhaseStride,
    int? speed,
    int? amplitude,
    String? fallbackReason,
    List<String>? tags,
  }) {
    return _AnimationRecipe(
      effectiveAnimationId: effectiveAnimationId ?? this.effectiveAnimationId,
      frameCount: frameCount ?? this.frameCount,
      frameDuration: frameDuration ?? this.frameDuration,
      phaseStep: phaseStep ?? this.phaseStep,
      variantCount: variantCount ?? this.variantCount,
      phaseSeedOffset: phaseSeedOffset ?? this.phaseSeedOffset,
      variantPhaseStride: variantPhaseStride ?? this.variantPhaseStride,
      speed: speed ?? this.speed,
      amplitude: amplitude ?? this.amplitude,
      fallbackReason: fallbackReason ?? this.fallbackReason,
      tags: tags ?? this.tags,
    );
  }
}

final class _MaterializedClip {
  const _MaterializedClip({
    required this.variants,
    required this.quality,
  });

  final List<AvatarAnimationClipVariant> variants;
  final AvatarAnimationClipQuality quality;
}
