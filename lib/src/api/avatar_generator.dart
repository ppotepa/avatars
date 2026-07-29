import '../catalog/parameter_catalog.dart';
import '../constraints/avatar_validator.dart';
import '../constraints/validation.dart';
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
import '../rendering/render_model.dart';
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
        AnatomyRenderer(),
        ArmorRenderer(),
        FaceRenderer(),
        HairRenderer(),
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
    AvatarValidator? validator,
  })  : catalog = catalog ?? ParameterCatalog.v41,
        genomeService = genomeService ??
            V41GenomeGenerator(catalog: catalog ?? ParameterCatalog.v41),
        layoutResolver = layoutResolver ?? const V41LayoutResolver(),
        paletteFactory = paletteFactory ?? const V41PaletteFactory(),
        renderer = renderer ?? CompositeAvatarRenderer(),
        compositor = compositor ?? const IndexedAvatarCompositor(),
        validator = validator ?? const V41AvatarValidator();

  final ParameterCatalog catalog;
  final GenomeGenerator genomeService;
  final LayoutResolver layoutResolver;
  final PaletteFactory paletteFactory;
  final AvatarRenderer renderer;
  final AvatarCompositor compositor;
  final AvatarValidator validator;

  AvatarResult generate(AvatarRequest request) {
    if (request.seed.isEmpty) {
      throw ArgumentError.value(request.seed, 'seed', 'Seed must not be empty.');
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
    );
    final state = renderer.render(context);
    final image = compositor.compose(state.layers);
    validator.validate(state, image, guard);
    final metrics = _metrics(image, state);
    return AvatarResult(
      genome: genome,
      layout: layout,
      palette: palette,
      image: image,
      layers: List.unmodifiable(state.layers),
      validation: guard.report(),
      metrics: metrics,
      imageHash: image.hash,
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

  AvatarMetrics _metrics(IndexedImage image, AvatarRenderState state) {
    final occupied = PixelMask();
    for (var y = 0; y < image.height; y++) {
      for (var x = 0; x < image.width; x++) {
        if (image.get(x, y) != image.transparentIndex) occupied.set(x, y);
      }
    }
    var isolated = 0;
    for (final component in occupied.connectedComponents()) {
      if (component.length == 1) isolated++;
    }
    return AvatarMetrics(
      usedColorCount: image.usedColorCount,
      occupiedPixelCount: occupied.count,
      isolatedPixelCount: isolated,
      connectedComponentCount: occupied.connectedComponents().length,
      layerCount: state.layers.length,
    );
  }
}
