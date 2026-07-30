import '../catalog/parameter_catalog.dart';
import '../constraints/avatar_validator.dart';
import '../constraints/validation.dart';
import '../genome/diversity_genome_generator.dart';
import '../genome/genome_generator.dart';
import '../geometry/avatar_layout.dart';
import '../palette/avatar_palette.dart';
import '../pixels/indexed_image.dart';
import '../pixels/pixel_mask.dart';
import '../rendering/parts/accessories_renderer.dart';
import '../rendering/parts/animation_renderer.dart';
import '../rendering/parts/anatomy_renderer.dart';
import '../rendering/parts/armor_renderer.dart';
import '../rendering/parts/background_renderer.dart';
import '../rendering/parts/face_renderer.dart';
import '../rendering/parts/hair_renderer.dart';
import '../rendering/parts/props_renderer.dart';
import '../rendering/parts/v42_features_renderer.dart';
import '../rendering/parts/v42_motion_renderer.dart';
import '../rendering/parts/v42_scenic_light_renderer.dart';
import '../rendering/render_model.dart';
import '../rendering/resolution_renderer.dart';
import 'avatar_request.dart';
import 'avatar_result.dart';

abstract interface class AvatarRenderer {
  AvatarRenderState render(AvatarRenderContext context);
}

final class CompositeAvatarRenderer implements AvatarRenderer {
  CompositeAvatarRenderer({List<AvatarPartRenderer>? parts})
      : parts = List.unmodifiable(parts ?? defaultParts);

  static List<AvatarPartRenderer> get defaultParts =>
      const <AvatarPartRenderer>[
        BackgroundRenderer(),
        ExtendedAtmosphereRenderer(),
        ExtendedScenicLightRenderer(),
        AnatomyRenderer(),
        ArmorRenderer(),
        FaceRenderer(),
        ExpressionRenderer(),
        ExpressiveMotionOverlayRenderer(),
        HairRenderer(),
        ExtendedAdornmentRenderer(),
        AccessoriesRenderer(),
        PropsRenderer(),
        AvatarMotionRenderer(),
        ForegroundEffectsRenderer(),
      ];

  final List<AvatarPartRenderer> parts;

  @override
  AvatarRenderState render(AvatarRenderContext context) {
    final state = AvatarRenderState();
    for (final part in parts) {
      part.render(context, state);
    }
    return state;
  }
}

final class AvatarGenerator {
  AvatarGenerator({
    ParameterCatalog? catalog,
    GenomeGenerator? genomeService,
    LayoutResolver? layoutResolver,
    PaletteFactory? paletteFactory,
    AvatarRenderer? renderer,
    AvatarCompositor? compositor,
    ResolutionAwareRenderer? resolutionRenderer,
    AvatarValidator? validator,
  })  : catalog = catalog ?? ParameterCatalog.v41,
        genomeService = genomeService ??
            DiversityGenomeGenerator(catalog: catalog ?? ParameterCatalog.v41),
        layoutResolver = layoutResolver ?? const V41LayoutResolver(),
        paletteFactory = paletteFactory ?? const V41PaletteFactory(),
        renderer = renderer ?? CompositeAvatarRenderer(),
        compositor = compositor ?? const IndexedAvatarCompositor(),
        resolutionRenderer =
            resolutionRenderer ?? const ResolutionAwareRenderer(),
        validator = validator ?? const V41AvatarValidator();

  final ParameterCatalog catalog;
  final GenomeGenerator genomeService;
  final LayoutResolver layoutResolver;
  final PaletteFactory paletteFactory;
  final AvatarRenderer renderer;
  final AvatarCompositor compositor;
  final ResolutionAwareRenderer resolutionRenderer;
  final AvatarValidator validator;

  AvatarResult generate(AvatarRequest request) {
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
    final guard = ConstraintEngine(enabled: request.guardEnabled);
    final genome = genomeService.generate(request, guard);
    final layout = layoutResolver.resolve(genome, guard);
    final palette = paletteFactory.create(genome);
    final context = AvatarRenderContext(
      genome: genome,
      layout: layout,
      palette: palette,
      guard: guard,
      phase: request.phase,
      rendering: request.rendering,
    );
    final state = renderer.render(context);
    final canonicalImage = compositor.compose(state.layers);
    validator.validate(state, canonicalImage, guard);
    final image = resolutionRenderer.render(
      source: canonicalImage,
      layers: state.layers,
      palette: palette,
      settings: request.rendering,
      phase: request.phase,
    );
    final metrics = _metrics(image, state, palette, request.rendering);
    return AvatarResult(
      genome: genome,
      layout: layout,
      palette: palette,
      image: image,
      layers: List.unmodifiable(state.layers),
      validation: guard.report(),
      metrics: metrics,
      imageHash: image.hashWithPalette(palette.colors),
    );
  }

  AvatarAnimation generateAnimation(
    AvatarRequest request, {
    int frameCount = 8,
    Duration frameDuration = const Duration(milliseconds: 120),
    bool loop = true,
  }) {
    if (frameCount < 1) {
      throw ArgumentError.value(frameCount, 'frameCount', 'Must be positive.');
    }
    return AvatarAnimation(
      frames: List<AvatarResult>.generate(
        frameCount,
        (index) => generate(request.copyWith(phase: index)),
        growable: false,
      ),
      frameDuration: frameDuration,
      loop: loop,
    );
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
    var isolated = 0;
    for (final component in occupied.connectedComponents()) {
      if (component.length == 1) isolated++;
    }
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
    final eyeContrastScore = eyeContrast > scleraContrast
        ? eyeContrast
        : scleraContrast;
    final silhouetteContrastScore = _contrastScore(
      palette.colors[palette.role('outline')],
      palette.colors[palette.role('bg')],
    );
    final visualDensityScore = clampInt(
      (100 - isolated * 800 ~/ (occupied.count == 0 ? 1 : occupied.count)),
      0,
      100,
    );
    final visibilityScore = (eyeRatio * .7 + mouthRatio * .3) * 100;
    final faceReadability = clampInt(
      (visibilityScore * .75 + eyeContrastScore * .25).round(),
      0,
      100,
    );
    return AvatarMetrics(
      usedColorCount: image.usedColorCount,
      occupiedPixelCount: occupied.count,
      isolatedPixelCount: isolated,
      connectedComponentCount: occupied.connectedComponents().length,
      layerCount: state.layers.length,
      visibility: visibility,
      faceReadabilityScore: faceReadability,
      canvasWidth: image.width,
      canvasHeight: image.height,
      detailLevel: rendering.detailLevel.name,
      eyeContrastScore: eyeContrastScore,
      silhouetteContrastScore: silhouetteContrastScore,
      visualDensityScore: visualDensityScore,
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
        ((luma(first) - luma(second)).abs() / 1.8).round(), 0, 100);
  }
}
