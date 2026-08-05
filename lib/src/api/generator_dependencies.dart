import '../catalog/parameter_catalog.dart';
import '../constraints/avatar_validator.dart';
import '../genome/budgeted_genome_generator.dart';
import '../genome/design_intent_genome_generator.dart';
import '../genome/genome_generator.dart';
import '../geometry/avatar_layout.dart';
import '../palette/avatar_palette.dart';
import '../rendering/render_model.dart';
import '../rendering/resolution_renderer.dart';
import '../rendering/rig_clip_pipeline.dart';

/// One resolved dependency graph shared by the public fields and clip pipeline.
final class GeneratorDependencies {
  const GeneratorDependencies._({
    required this.catalog,
    required this.genomeService,
    required this.layoutResolver,
    required this.paletteFactory,
    required this.compositor,
    required this.resolutionRenderer,
    required this.validator,
    required this.pipeline,
  });

  final ParameterCatalog catalog;
  final GenomeGenerator genomeService;
  final LayoutResolver layoutResolver;
  final PaletteFactory paletteFactory;
  final AvatarCompositor compositor;
  final ResolutionAwareRenderer resolutionRenderer;
  final AvatarValidator validator;
  final RigClipPipeline pipeline;

  factory GeneratorDependencies.resolve({
    ParameterCatalog? catalog,
    GenomeGenerator? genomeService,
    LayoutResolver? layoutResolver,
    PaletteFactory? paletteFactory,
    AvatarCompositor? compositor,
    ResolutionAwareRenderer? resolutionRenderer,
    AvatarValidator? validator,
    RigClipPipeline? pipeline,
  }) {
    final resolvedCatalog = catalog ?? ParameterCatalog.current;
    if (pipeline != null) {
      final conflicting = <String>[
        if (genomeService != null) 'genomeService',
        if (layoutResolver != null) 'layoutResolver',
        if (paletteFactory != null) 'paletteFactory',
        if (compositor != null) 'compositor',
        if (validator != null) 'validator',
      ];
      if (conflicting.isNotEmpty) {
        throw ArgumentError(
          'A complete pipeline cannot be combined with pipeline-owned '
          'dependencies: ${conflicting.join(', ')}.',
        );
      }
      return GeneratorDependencies._(
        catalog: resolvedCatalog,
        genomeService: pipeline.genomeGenerator,
        layoutResolver: pipeline.layoutResolver,
        paletteFactory: pipeline.paletteFactory,
        compositor: pipeline.compositor,
        resolutionRenderer:
            resolutionRenderer ?? const ResolutionAwareRenderer(),
        validator: pipeline.validator,
        pipeline: pipeline,
      );
    }

    final resolvedGenome =
        genomeService ?? _defaultGenomeGenerator(resolvedCatalog);
    final resolvedLayout = layoutResolver ?? const V41LayoutResolver();
    final resolvedPalette = paletteFactory ?? const V41PaletteFactory();
    final resolvedCompositor = compositor ?? const IndexedAvatarCompositor();
    final resolvedValidator = validator ?? const V41AvatarValidator();
    final resolvedResolution =
        resolutionRenderer ?? const ResolutionAwareRenderer();
    final resolvedPipeline = RigClipPipeline(
      genomeGenerator: resolvedGenome,
      layoutResolver: resolvedLayout,
      paletteFactory: resolvedPalette,
      compositor: resolvedCompositor,
      validator: resolvedValidator,
    );

    return GeneratorDependencies._(
      catalog: resolvedCatalog,
      genomeService: resolvedGenome,
      layoutResolver: resolvedLayout,
      paletteFactory: resolvedPalette,
      compositor: resolvedCompositor,
      resolutionRenderer: resolvedResolution,
      validator: resolvedValidator,
      pipeline: resolvedPipeline,
    );
  }

  static GenomeGenerator _defaultGenomeGenerator(
    ParameterCatalog catalog,
  ) =>
      DesignIntentGenomeGenerator(
        BudgetedGenomeGenerator(catalog: catalog),
      );
}
