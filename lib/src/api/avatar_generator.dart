import '../catalog/parameter_catalog.dart';
import '../constraints/avatar_request_validator.dart';
import '../constraints/avatar_validator.dart';
import '../genome/cached_genome_generator.dart';
import '../genome/genome_generator.dart';
import '../geometry/avatar_layout.dart';
import '../geometry/cached_layout_resolver.dart';
import '../palette/avatar_palette.dart';
import '../rendering/camera_sampling_policy.dart';
import '../rendering/render_model.dart';
import '../rendering/resolution_renderer.dart';
import '../rendering/rig_clip_pipeline.dart';
import '../util/stable_fingerprint.dart';
import 'avatar_request.dart';
import 'avatar_result.dart';
import 'avatar_version.dart';
import 'rig_avatar_generator.dart';

/// Stable public entry point for deterministic avatar generation.
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
  })  : _delegate = RigAvatarGenerator(
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
            AvatarRequestValidator(catalog: catalog ?? ParameterCatalog.current) {
    if (cacheCapacity < 0) {
      throw ArgumentError.value(
        cacheCapacity,
        'cacheCapacity',
        'Must not be negative.',
      );
    }
  }

  final RigAvatarGenerator _delegate;
  final AvatarRequestValidator requestValidator;
  final CameraSamplingPolicy cameraSamplingPolicy;
  final int cacheCapacity;
  final Map<String, AvatarResult> _resultCache = <String, AvatarResult>{};
  int _cacheHits = 0;
  int _cacheMisses = 0;

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
  int get cacheHits => _cacheHits;
  int get cacheMisses => _cacheMisses;

  AvatarResult generate(AvatarRequest request) {
    final snapshot = request.frozenCopy();
    requestValidator.validate(snapshot);
    final plan = cameraSamplingPolicy.plan(snapshot);
    final key = _cacheKey(snapshot, plan);
    final cached = _resultCache.remove(key);
    if (cached != null) {
      _cacheHits++;
      _resultCache[key] = cached;
      return cached;
    }

    _cacheMisses++;
    final result = _delegate.generate(snapshot);
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

  void clearCache() {
    _resultCache.clear();
    _cacheHits = 0;
    _cacheMisses = 0;
    final genome = genomeService;
    if (genome is CachedGenomeGenerator) genome.clear();
    final layout = layoutResolver;
    if (layout is CachedLayoutResolver) layout.clear();
    pipeline.cameraCache.clear();
  }

  String _cacheKey(AvatarRequest request, CameraSamplePlan plan) =>
      stableFingerprint(<String, Object?>{
        'generatorVersion': AvatarGenomeVersion.generator,
        'catalogVersion': AvatarGenomeVersion.catalog,
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
