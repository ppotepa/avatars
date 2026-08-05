import 'dart:convert';

import '../catalog/parameter_catalog.dart';
import '../constraints/avatar_request_validator.dart';
import '../constraints/avatar_validator.dart';
import '../genome/genome_generator.dart';
import '../geometry/avatar_layout.dart';
import '../palette/avatar_palette.dart';
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
    final snapshot = _snapshot(request);
    requestValidator.validate(snapshot);
    final key = _cacheKey(snapshot);
    final cached = _resultCache.remove(key);
    if (cached != null) {
      _resultCache[key] = cached;
      return cached;
    }

    final result = snapshot.phase < 16
        ? _delegate.generate(snapshot)
        : _delegate
            .generateAnimation(
              snapshot,
              frameCount: snapshot.phase + 1,
              frameDuration: Duration.zero,
              loop: false,
            )
            .frames[snapshot.phase];
    _store(key, result);
    return result;
  }

  AvatarAnimation generateAnimation(
    AvatarRequest request, {
    int frameCount = 8,
    Duration frameDuration = const Duration(milliseconds: 120),
    bool loop = true,
  }) {
    final snapshot = _snapshot(request);
    requestValidator.validate(snapshot);
    return _delegate.generateAnimation(
      snapshot,
      frameCount: frameCount,
      frameDuration: frameDuration,
      loop: loop,
    );
  }

  void clearCache() => _resultCache.clear();

  AvatarRequest _snapshot(AvatarRequest request) =>
      AvatarRequest.fromJson(request.toJson());

  String _cacheKey(AvatarRequest request) => jsonEncode(<String, Object?>{
        'generatorVersion': AvatarGenomeVersion.generator,
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
