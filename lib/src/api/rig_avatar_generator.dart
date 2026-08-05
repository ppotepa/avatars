import '../catalog/parameter_catalog.dart';
import '../constraints/avatar_validator.dart';
import '../genome/genome_generator.dart';
import '../geometry/avatar_layout.dart';
import '../palette/avatar_palette.dart';
import '../rendering/exact_phase_pipeline.dart';
import '../rendering/render_model.dart';
import '../rendering/resolution_renderer.dart';
import '../rendering/rig_clip_pipeline.dart';
import 'avatar_request.dart';
import 'avatar_result.dart';
import 'avatar_result_assembler.dart';
import 'generator_dependencies.dart';

/// Internal generator backed exclusively by the hierarchical rig clip pipeline.
final class RigAvatarGenerator {
  factory RigAvatarGenerator({
    ParameterCatalog? catalog,
    GenomeGenerator? genomeService,
    LayoutResolver? layoutResolver,
    PaletteFactory? paletteFactory,
    AvatarCompositor? compositor,
    ResolutionAwareRenderer? resolutionRenderer,
    AvatarValidator? validator,
    RigClipPipeline? pipeline,
    List<AvatarPartRenderer>? parts,
  }) {
    final dependencies = GeneratorDependencies.resolve(
      catalog: catalog,
      genomeService: genomeService,
      layoutResolver: layoutResolver,
      paletteFactory: paletteFactory,
      compositor: compositor,
      resolutionRenderer: resolutionRenderer,
      validator: validator,
      pipeline: pipeline,
      parts: parts,
    );
    return RigAvatarGenerator._(dependencies);
  }

  RigAvatarGenerator._(GeneratorDependencies dependencies)
      : catalog = dependencies.catalog,
        genomeService = dependencies.genomeService,
        layoutResolver = dependencies.layoutResolver,
        paletteFactory = dependencies.paletteFactory,
        compositor = dependencies.compositor,
        resolutionRenderer = dependencies.resolutionRenderer,
        validator = dependencies.validator,
        pipeline = dependencies.pipeline,
        resultAssembler = AvatarResultAssembler(
          resolutionRenderer: dependencies.resolutionRenderer,
        );

  final ParameterCatalog catalog;
  final GenomeGenerator genomeService;
  final LayoutResolver layoutResolver;
  final PaletteFactory paletteFactory;
  final AvatarCompositor compositor;
  final ResolutionAwareRenderer resolutionRenderer;
  final AvatarValidator validator;
  final RigClipPipeline pipeline;
  final AvatarResultAssembler resultAssembler;

  AvatarResult generate(AvatarRequest request) {
    _validate(request);
    final clip = pipeline.renderExactSingle(request);
    return resultAssembler.assemble(
      prepared: clip.prepared,
      frame: clip.frames.single,
      request: request,
    );
  }

  AvatarAnimation generateAnimation(
    AvatarRequest request, {
    int frameCount = 8,
    Duration frameDuration = const Duration(milliseconds: 120),
    bool loop = true,
  }) {
    _validate(request);
    final clip = pipeline.renderClip(request, frameCount: frameCount);
    return AvatarAnimation(
      frames: <AvatarResult>[
        for (final frame in clip.frames)
          resultAssembler.assemble(
            prepared: clip.prepared,
            frame: frame,
            request: request,
          ),
      ],
      frameDuration: frameDuration,
      loop: loop,
    );
  }

  void _validate(AvatarRequest request) {
    if (request.seed.isEmpty) {
      throw ArgumentError.value(
        request.seed,
        'seed',
        'Seed must not be empty.',
      );
    }
    if (!AvatarRenderSettings.supportedSizes.contains(request.rendering.size)) {
      throw ArgumentError.value(
        request.rendering.size,
        'rendering.size',
        'Supported sizes are 48, 64, 80 and 96.',
      );
    }
    if (request.rendering.shadingStrength < 0 ||
        request.rendering.shadingStrength > 3) {
      throw ArgumentError.value(
        request.rendering.shadingStrength,
        'rendering.shadingStrength',
        'Must be between 0 and 3.',
      );
    }
  }
}
