import '../catalog/parameter_catalog.dart';
import '../constraints/avatar_validator.dart';
import '../constraints/validation.dart';
import '../genome/genome_generator.dart';
import '../geometry/avatar_layout.dart';
import '../geometry/pixel_rect.dart';
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
import '../rendering/parts/morphology_renderer.dart';
import '../rendering/parts/props_renderer.dart';
import '../rendering/render_model.dart';
import '../rendering/render_graph.dart';
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
        MorphologyRenderer(),
        HairRenderer(),
        AccessoriesRenderer(),
        PropsRenderer(),
        ForegroundEffectsRenderer(),
        AvatarMotionRenderer(),
      ];

  final List<AvatarPartRenderer> parts;

  @override
  AvatarRenderState render(AvatarRenderContext context) {
    final state = AvatarRenderState();
    var overscanActive = false;
    for (final part in parts) {
      if (part is AvatarMotionRenderer) {
        state.embedCanvas(width: 48, height: 54, offsetY: 3);
        overscanActive = true;
      }
      part.render(context, state);
      if (overscanActive) {
        state.embedCanvas(width: 48, height: 54, offsetY: 3);
      }
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
    return _present(
      _renderOverscan(request),
      const FrameFit(viewportY: 3, scale: 1, baseline: 50),
    );
  }

  _OverscanFrame _renderOverscan(AvatarRequest request) {
    if (request.seed.isEmpty) {
      throw ArgumentError.value(
          request.seed, 'seed', 'Seed must not be empty.');
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
    // Also supports custom renderer pipelines without AvatarMotionRenderer.
    state.embedCanvas(width: 48, height: 54, offsetY: 3);
    return _OverscanFrame(
      context: context,
      state: state,
      renderGraph: state.buildRenderGraph(viewportY: 3, baseline: 50),
    );
  }

  AvatarResult _present(_OverscanFrame frame, FrameFit fit) {
    final renderGraph = RenderGraph(
      nodes: frame.renderGraph.nodes,
      viewportY: fit.viewportY,
      fitScale: fit.scale,
      baseline: fit.baseline,
    );
    final layers = frame.state.layers.map((layer) {
      final worldLayer = _worldNodeIds.contains(layer.nodeId);
      var mask = layer.mask;
      if (!worldLayer && fit.scale != 1) {
        mask = mask.scaled(
          fit.scale,
          anchorX: 24,
          anchorY: fit.baseline,
        );
      }
      return _cropLayer(
        _layerWithMask(layer, mask),
        0,
        worldLayer ? 3 : fit.viewportY,
      );
    }).toList(growable: false);
    final image = compositor.compose(layers);
    frame.state.layers
      ..clear()
      ..addAll(layers);
    for (final entry in frame.state.masks.entries.toList(growable: false)) {
      final fitted = fit.scale == 1
          ? entry.value
          : entry.value.scaled(
              fit.scale,
              anchorX: 24,
              anchorY: fit.baseline,
            );
      frame.state.masks[entry.key] = _cropMask(fitted, 0, fit.viewportY);
    }
    validator.validate(frame.state, image, frame.context.guard);
    final metrics = _metrics(image, frame.state);
    return AvatarResult(
      genome: frame.context.genome,
      layout: frame.context.layout,
      palette: frame.context.palette,
      image: image,
      layers: List.unmodifiable(layers),
      validation: frame.context.guard.report(),
      metrics: metrics,
      imageHash: image.hash,
      renderGraph: renderGraph,
    );
  }

  RenderLayer _cropLayer(RenderLayer layer, int x, int y) {
    final mask = _cropMask(layer.mask, x, y);
    return RenderLayer(
      id: layer.id,
      z: layer.z,
      mask: mask,
      colorIndex: layer.colorIndex,
      nodeId: layer.nodeId,
      slot: layer.slot,
      localOrder: layer.localOrder,
      // Public-layer accounting describes the fitted 48x48 presentation.
      // The pre-fit geometry remains available in renderGraph node bounds.
      sourcePixelCount: mask.count,
      visiblePixelCount: layer.visiblePixelCount,
      meta: layer.meta,
    );
  }

  PixelMask _cropMask(PixelMask source, int x, int y) {
    final mask = PixelMask();
    for (var yy = 0; yy < 48; yy++) {
      for (var xx = 0; xx < 48; xx++) {
        if (source.get(x + xx, y + yy) != 0) mask.set(xx, yy);
      }
    }
    return mask;
  }

  RenderLayer _layerWithMask(RenderLayer layer, PixelMask mask) => RenderLayer(
        id: layer.id,
        z: layer.z,
        mask: mask,
        colorIndex: layer.colorIndex,
        nodeId: layer.nodeId,
        slot: layer.slot,
        localOrder: layer.localOrder,
        sourcePixelCount: layer.sourcePixelCount,
        visiblePixelCount: layer.visiblePixelCount,
        meta: layer.meta,
      );

  AvatarAnimation generateAnimation(
    AvatarRequest request, {
    int frameCount = 8,
    int phaseStep = 1,
    Duration frameDuration = const Duration(milliseconds: 125),
    bool loop = true,
  }) {
    if (frameCount < 1) {
      throw ArgumentError.value(frameCount, 'frameCount', 'Must be positive.');
    }
    if (phaseStep < 1) {
      throw ArgumentError.value(phaseStep, 'phaseStep', 'Must be positive.');
    }
    final rawFrames = List<_OverscanFrame>.generate(
      frameCount,
      (index) => _renderOverscan(
        request.copyWith(phase: request.phase + index * phaseStep),
      ),
      growable: false,
    );
    final fit = FrameFitter.fit(
      rawFrames.map((frame) => _actorBounds(frame.state.layers)),
    );
    final fittedFrames =
        rawFrames.map((frame) => _present(frame, fit)).toList(growable: false);
    return AvatarAnimation(
      frames: fittedFrames,
      frameDuration: frameDuration,
      loop: loop,
    );
  }

  PixelRect? _actorBounds(Iterable<RenderLayer> layers) {
    PixelRect? result;
    for (final layer in layers) {
      if (_worldNodeIds.contains(layer.nodeId)) {
        continue;
      }
      final bounds = layer.mask.bounds;
      if (bounds == null) continue;
      if (result == null) {
        result = bounds;
      } else {
        final left = result.left < bounds.left ? result.left : bounds.left;
        final top = result.top < bounds.top ? result.top : bounds.top;
        final right = result.right > bounds.right ? result.right : bounds.right;
        final bottom =
            result.bottom > bounds.bottom ? result.bottom : bounds.bottom;
        result = PixelRect(left, top, right - left + 1, bottom - top + 1);
      }
    }
    return result;
  }

  static const Set<String> _worldNodeIds = <String>{
    'background',
    'aura',
    'emotionEffects',
    'foreground',
  };

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
      fullyOccludedLayerCount: state.layers
          .where((layer) =>
              (layer.sourcePixelCount ?? layer.mask.count) > 0 &&
              (layer.visiblePixelCount ?? layer.mask.count) == 0)
          .length,
      skippedEmptyLayerCount:
          ((state.metadata['skippedEmptyLayers'] as List<Object?>?) ?? const [])
              .length,
    );
  }
}

final class _OverscanFrame {
  const _OverscanFrame({
    required this.context,
    required this.state,
    required this.renderGraph,
  });

  final AvatarRenderContext context;
  final AvatarRenderState state;
  final RenderGraph renderGraph;
}
