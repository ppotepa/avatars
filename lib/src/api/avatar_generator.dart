import '../catalog/parameter_catalog.dart';
import '../constraints/avatar_validator.dart';
import '../genome/budgeted_genome_generator.dart';
import '../genome/genome_generator.dart';
import '../geometry/avatar_layout.dart';
import '../palette/avatar_palette.dart';
import '../rendering/render_model.dart';
import '../rendering/resolution_renderer.dart';
import '../rendering/rig_clip_pipeline.dart';
import 'avatar_request.dart';
import 'avatar_result.dart';
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
    Object? renderer,
  }) : _delegate = rig.AvatarGenerator(
          catalog: catalog,
          genomeService: genomeService ??
              BudgetedGenomeGenerator(
                catalog: catalog ?? ParameterCatalog.v41,
              ),
          layoutResolver: layoutResolver,
          paletteFactory: paletteFactory,
          compositor: compositor,
          resolutionRenderer: resolutionRenderer,
          validator: validator,
          pipeline: pipeline,
        );

  final rig.AvatarGenerator _delegate;

  ParameterCatalog get catalog => _delegate.catalog;
  GenomeGenerator get genomeService => _delegate.genomeService;
  LayoutResolver get layoutResolver => _delegate.layoutResolver;
  PaletteFactory get paletteFactory => _delegate.paletteFactory;
  AvatarCompositor get compositor => _delegate.compositor;
  ResolutionAwareRenderer get resolutionRenderer =>
      _delegate.resolutionRenderer;
  AvatarValidator get validator => _delegate.validator;
  RigClipPipeline get pipeline => _delegate.pipeline;

  AvatarResult generate(AvatarRequest request) => _delegate.generate(request);

  AvatarAnimation generateAnimation(
    AvatarRequest request, {
    int frameCount = 8,
    Duration frameDuration = const Duration(milliseconds: 120),
    bool loop = true,
  }) =>
      _delegate.generateAnimation(
        request,
        frameCount: frameCount,
        frameDuration: frameDuration,
        loop: loop,
      );
}
