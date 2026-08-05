import 'dart:convert';

import '../catalog/parameter_catalog.dart';
import '../constraints/avatar_request_validator.dart';
import '../constraints/avatar_validator.dart';
import '../genome/genome_generator.dart';
import '../geometry/avatar_layout.dart';
import '../palette/avatar_palette.dart';
import '../rendering/camera_sampling_policy.dart';
import '../rendering/render_model.dart';
import '../rendering/resolution_renderer.dart';
import '../rendering/rig_clip_pipeline.dart';
import 'avatar_request.dart';
import 'avatar_result.dart';
import 'avatar_version.dart';
import 'rig_avatar_generator.dart' as rig;

/// Compatibility entry point delegating to the hierarchical rig generator.
final class AvatarGenerator {
  AvatarGenerator({
    ParameterCatalog? catalog,
    GenomeGenerator? genomeService,
    LayoutResolver? layoutResolver,
    PaletteFactory? paletteFactory,
    AvatarCompositor? compositor,
    ResolutionAwareRenderer? resolutionRenderer,
    AvatarValidator? validator,
    RigClipPipeline? pipeline,
    List<AvatarPartRenderer>? parts,
    AvatarRequestValidator? requestValidator,
    this.cameraSamplingPolicy = const CameraSamplingPolicy(),
    this.cacheCapacity = 32,
  })  : assert(cacheCapacity >= 0),
        _delegate = rig.AvatarGenerator(
          catalog: catalog,
          genomeService: genomeService,
          layoutResolver: layoutResolver,
          paletteFactory: paletteFactory,
          compositor: compositor,
          resolutionRenderer: resolutionRenderer,
          validator: validator,
          pipeline: pipeline,
          parts: parts,
        ),
        requestValidator = requestValidator ??
            AvatarRequestValidator(catalog: catalog ?? ParameterCatalog.current);

  final rig.AvatarGenerator _delegate;
  final AvatarRequestValidator requestValidator;
  final CameraSamplingPolicy cameraSamplingPolicy;
  final int cacheCapacity;
  final Map<String, AvatarResult> _resultCache = <String, AvatarResult>{};

  ParameterCatalog get catalog => _delegate.catalog;
  GenomeGenerator get genomeService => _delegate.genomeService;
  LayoutResolver get layoutResolver => _delegate.layoutResolver;
  PaletteFactory get paletteFactory => _delegate.paletteFactory;
  AvatarCompositor get compositor => _delegate.compositor;
  ResolutionAwareRenderer get resolutionRenderer =>
      _delegate.resolutionRenderer;
  AvatarValidator get validator => _delegate.validator;
  RigClipPipeline get pipeline => _delegate.pipeline;
  int get cachedResultCount => _resultCache.length;

  AvatarResult generate(AvatarRequest request) {
    final snapshot = request.frozenCopy();
    requestValidator.validate(snapshot);
    final plan = cameraSamplingPolicy.plan(snapshot);
    final key = _cacheKey(snapshot, plan);
    final cached = _resultCache.remove(key);
    if (cached != null) {
      _resultCache[key] = cached;
      return cached;
    }

    late final AvatarResult result;
    if (plan.isSingleFrame && snapshot.phase == 0) {
      result = _delegate
          .generateAnimation(
            snapshot,
            frameCount: 1,
            frameDuration: Duration.zero,
            loop: false,
          )
          .frames.single;
    } else if (snapshot.phase >= 16) {
      result = _delegate
          .generateAnimation(
            snapshot,
            frameCount: snapshot.phase + 1,
            frameDuration: Duration.zero,
            loop: false,
          )
          .frames[snapshot.phase];
    } else {
      result = _delegate.generate(snapshot);
    }
    _store(key, result);
    return result;
  }

  AvatarAnimation generateAnimation(
    AvatarRequest request, {
    int frameCount = 8,
    Duration frameDuration = const Duration(milliseconds: 120),
    bool loop = true,
  }) {
    final snapshot = request.frozenCopy();
    requestValidator.validate(snapshot);
    return _delegate.generateAnimation(
      snapshot,
      frameCount: frameCount,
      frameDuration: frameDuration,
      loop: loop,
    );
  }

  void clearCache() => _resultCache.clear();

  String _cacheKey(AvatarRequest request, CameraSamplePlan plan) =>
      jsonEncode(<String, Object?>{
        'generatorVersion': AvatarGenomeVersion.generator,
        'cameraPolicyVersion': plan.policyVersion,
        'cameraPhases': plan.phases,
        'request': request.toJson(),
      });

  void _store(String key, AvatarResult result) {
    if (cacheCapacity == 0) return;
    _resultCache[key] = result;
    while (_resultCache.length > cacheCapacity) {
      _resultCache.remove(_resultCache.keys.first);
    }
  }
}
