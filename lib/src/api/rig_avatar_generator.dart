import '../catalog/parameter_catalog.dart';
import '../constraints/avatar_validator.dart';
import '../genome/diversity_genome_generator.dart';
import '../genome/genome_generator.dart';
import '../geometry/avatar_layout.dart';
import '../graph/avatar_graph.dart';
import '../palette/avatar_palette.dart';
import '../pixels/indexed_image.dart';
import '../pixels/pixel_mask.dart';
import '../rendering/render_model.dart';
import '../rendering/resolution_renderer.dart';
import '../rendering/rig_clip_pipeline.dart';
import '../util/math_utils.dart';
import 'avatar_request.dart';
import 'avatar_result.dart';

/// Public generator backed exclusively by the hierarchical rig clip pipeline.
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
  })  : catalog = catalog ?? ParameterCatalog.v41,
        genomeService = genomeService ??
            DiversityGenomeGenerator(catalog: catalog ?? ParameterCatalog.v41),
        layoutResolver = layoutResolver ?? const V41LayoutResolver(),
        paletteFactory = paletteFactory ?? const V41PaletteFactory(),
        compositor = compositor ?? const IndexedAvatarCompositor(),
        resolutionRenderer =
            resolutionRenderer ?? const ResolutionAwareRenderer(),
        validator = validator ?? const V41AvatarValidator(),
        pipeline = pipeline ??
            RigClipPipeline(
              genomeGenerator: genomeService ??
                  DiversityGenomeGenerator(
                    catalog: catalog ?? ParameterCatalog.v41,
                  ),
              layoutResolver: layoutResolver ?? const V41LayoutResolver(),
              paletteFactory: paletteFactory ?? const V41PaletteFactory(),
              compositor: compositor ?? const IndexedAvatarCompositor(),
              validator: validator ?? const V41AvatarValidator(),
            );

  final ParameterCatalog catalog;
  final GenomeGenerator genomeService;
  final LayoutResolver layoutResolver;
  final PaletteFactory paletteFactory;
  final AvatarCompositor compositor;
  final ResolutionAwareRenderer resolutionRenderer;
  final AvatarValidator validator;
  final RigClipPipeline pipeline;

  AvatarResult generate(AvatarRequest request) {
    _validate(request);
    final clip = pipeline.renderSingle(request);
    return _result(clip.prepared, clip.frames.single, request.rendering);
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
      frames: List.unmodifiable(<AvatarResult>[
        for (final frame in clip.frames)
          _result(clip.prepared, frame, request.rendering),
      ]),
      frameDuration: frameDuration,
      loop: loop,
    );
  }

  AvatarResult _result(
    RigPreparedAvatar prepared,
    RigPipelineFrame frame,
    AvatarRenderSettings rendering,
  ) {
    final image = resolutionRenderer.render(
      source: frame.image,
      layers: frame.state.layers,
      palette: prepared.palette,
      settings: rendering,
      phase: frame.phase,
    );
    final layout = _layoutWithRig(prepared.layout, frame);
    return AvatarResult(
      genome: prepared.genome,
      layout: layout,
      palette: prepared.palette,
      image: image,
      layers: List.unmodifiable(frame.state.layers),
      validation: frame.validation,
      metrics: _metrics(image, frame.state, prepared.palette, rendering),
      imageHash: image.hashWithPalette(prepared.palette.colors),
    );
  }

  AvatarLayout _layoutWithRig(AvatarLayout source, RigPipelineFrame frame) {
    final graph = AvatarGraph();
    for (final entry in source.graph.nodes.entries) {
      graph.addValue(
        entry.key,
        entry.value.type,
        entry.value.value,
        meta: entry.value.meta,
      );
    }
    for (final edge in source.graph.edges) {
      graph.addEdge(edge.from, edge.to, edge.relation);
    }
    final rig = frame.state.buildRigGraph();
    for (final node in rig.nodes) {
      graph.addValue(
        'rig.${node.id}',
        'rigNode',
        <String, Object?>{
          ...node.toJson(),
          'transform': frame.state.nodeTransforms[node.id]?.toJson(),
        },
      );
      if (node.parentId != null) {
        graph.addEdge(
          'rig.${node.parentId}',
          'rig.${node.id}',
          'parentOf',
        );
      }
    }
    graph
      ..addValue('rig.camera', 'clipCamera', frame.camera.toJson())
      ..addValue(
        'rig.motion',
        'motionSample',
        frame.state.metadata['motionSample'],
      )
      ..addValue(
        'rig.overscan',
        'overscan',
        frame.state.metadata['overscan'],
      )
      ..addValue('rig.hair', 'secondaryRig', frame.state.metadata['hairRig'])
      ..addValue(
        'rig.jewelry',
        'constraintRig',
        frame.state.metadata['jewelryRig'],
      )
      ..addValue(
        'rig.companion',
        'articulatedRig',
        frame.state.metadata['companionRig'],
      )
      ..addValue('rig.back', 'secondaryRig', frame.state.metadata['backRig']);
    return AvatarLayout(
      values: source.values,
      landmarks: source.landmarks,
      slots: source.slots,
      graph: graph,
    );
  }

  void _validate(AvatarRequest request) {
    if (request.seed.isEmpty) {
      throw ArgumentError.value(request.seed, 'seed', 'Seed must not be empty.');
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

  AvatarMetrics _metrics(
    IndexedImage image,
    AvatarRenderState state,
    AvatarPalette palette,
    AvatarRenderSettings rendering,
  ) {
    final occupied = PixelMask(width: image.width, height: image.height);
    for (var y = 0; y < image.height; y++) {
      for (var x = 0; x < image.width; x++) {
        if (image.get(x, y) != image.transparentIndex) occupied.set(x, y);
      }
    }
    final components = occupied.connectedComponents();
    final isolated = components.where((component) => component.length == 1).length;
    final visibility = analyzeRenderVisibility(state.layers);
    final eyeRatio = visibility.visibleRatio('eyes');
    final mouthRatio = visibility.visibleRatio('mouth');
    final eyeContrast = _contrastScore(
      palette.colors[palette.role('skinBase')],
      palette.colors[palette.role('irisBase')],
    );
    final scleraContrast = _contrastScore(
      palette.colors[palette.role('skinBase')],
      palette.colors[palette.role('sclera')],
    );
    final eyeScore = eyeContrast > scleraContrast
        ? eyeContrast
        : scleraContrast;
    final silhouetteScore = _contrastScore(
      palette.colors[palette.role('outline')],
      palette.colors[palette.role('bg')],
    );
    final densityScore = clampInt(
      100 - isolated * 800 ~/ (occupied.count == 0 ? 1 : occupied.count),
      0,
      100,
    );
    final faceScore = clampInt(
      (((eyeRatio * .7 + mouthRatio * .3) * 100) * .75 +
              eyeScore * .25)
          .round(),
      0,
      100,
    );
    return AvatarMetrics(
      usedColorCount: image.usedColorCount,
      occupiedPixelCount: occupied.count,
      isolatedPixelCount: isolated,
      connectedComponentCount: components.length,
      layerCount: state.layers.length,
      visibility: visibility,
      faceReadabilityScore: faceScore,
      canvasWidth: image.width,
      canvasHeight: image.height,
      detailLevel: rendering.detailLevel.name,
      eyeContrastScore: eyeScore,
      silhouetteContrastScore: silhouetteScore,
      visualDensityScore: densityScore,
    );
  }

  int _contrastScore(int first, int second) {
    double luma(int rgba) {
      final red = (rgba >> 24) & 0xff;
      final green = (rgba >> 16) & 0xff;
      final blue = (rgba >> 8) & 0xff;
      return red * .2126 + green * .7152 + blue * .0722;
    }

    return clampInt(
      ((luma(first) - luma(second)).abs() / 1.8).round(),
      0,
      100,
    );
  }
}
