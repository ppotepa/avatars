import '../constraints/validation.dart';
import '../genome/avatar_genome_model.dart';
import '../geometry/avatar_layout.dart';
import '../palette/avatar_palette.dart';
import '../pixels/indexed_image.dart';
import '../rendering/render_model.dart';
import '../rendering/render_graph.dart';
import 'avatar_version.dart';

final class AvatarMetrics {
  const AvatarMetrics({
    required this.usedColorCount,
    required this.occupiedPixelCount,
    required this.isolatedPixelCount,
    required this.connectedComponentCount,
    required this.layerCount,
    required this.fullyOccludedLayerCount,
    required this.skippedEmptyLayerCount,
  });

  final int usedColorCount;
  final int occupiedPixelCount;
  final int isolatedPixelCount;
  final int connectedComponentCount;
  final int layerCount;
  final int fullyOccludedLayerCount;
  final int skippedEmptyLayerCount;

  Map<String, Object> toJson() => <String, Object>{
        'usedColorCount': usedColorCount,
        'occupiedPixelCount': occupiedPixelCount,
        'isolatedPixelCount': isolatedPixelCount,
        'connectedComponentCount': connectedComponentCount,
        'layerCount': layerCount,
        'fullyOccludedLayerCount': fullyOccludedLayerCount,
        'skippedEmptyLayerCount': skippedEmptyLayerCount,
      };
}

final class AvatarResult {
  const AvatarResult({
    required this.genome,
    required this.layout,
    required this.palette,
    required this.image,
    required this.layers,
    required this.validation,
    required this.metrics,
    required this.imageHash,
    required this.renderGraph,
  });

  final AvatarGenome genome;
  final AvatarLayout layout;
  final AvatarPalette palette;
  final IndexedImage image;
  final List<RenderLayer> layers;
  final ValidationReport validation;
  final AvatarMetrics metrics;
  final String imageHash;
  final RenderGraph renderGraph;

  AvatarResult withRenderGraph(RenderGraph graph) => AvatarResult(
        genome: genome,
        layout: layout,
        palette: palette,
        image: image,
        layers: layers,
        validation: validation,
        metrics: metrics,
        imageHash: imageHash,
        renderGraph: graph,
      );

  AvatarResult withPresentation({
    required IndexedImage image,
    required List<RenderLayer> layers,
    RenderGraph? renderGraph,
  }) =>
      AvatarResult(
        genome: genome,
        layout: layout,
        palette: palette,
        image: image,
        layers: List<RenderLayer>.unmodifiable(layers),
        validation: validation,
        metrics: metrics,
        imageHash: image.hash,
        renderGraph: renderGraph ?? this.renderGraph,
      );

  Map<String, Object?> toJson({bool includePixels = true}) => <String, Object?>{
        'schemaVersion': AvatarGenomeVersion.resultSchema,
        'generatorVersion': genome.generatorVersion,
        'seed': genome.seed,
        'imageHash': imageHash,
        'genome': genome.toJson(),
        'landmarks': <String, Object?>{
          for (final entry in layout.landmarks.entries)
            entry.key: entry.value.toJson(),
        },
        'slots': <String, Object?>{
          for (final entry in layout.slots.entries)
            entry.key: entry.value.toJson(),
        },
        'graph': layout.graph.snapshot(),
        'renderGraph': renderGraph.toJson(),
        'palette': palette.toJson(),
        'layers': layers.map((layer) => layer.toJson()).toList(growable: false),
        'validation': validation.toJson(),
        'metrics': metrics.toJson(),
        if (includePixels) 'image': image.toJson(),
      };
}

final class AvatarAnimation {
  const AvatarAnimation({
    required this.frames,
    required this.frameDuration,
    this.loop = true,
  });

  final List<AvatarResult> frames;
  final Duration frameDuration;
  final bool loop;

  Duration get safeFrameDuration =>
      frameDuration < const Duration(milliseconds: 125)
          ? const Duration(milliseconds: 125)
          : frameDuration;

  Map<String, Object?> toJson({bool includePixels = true}) => <String, Object?>{
        'frameDurationMs': safeFrameDuration.inMilliseconds,
        'loop': loop,
        if (frames.isNotEmpty) 'renderGraph': frames.first.renderGraph.toJson(),
        'nodeTransforms': frames
            .map((frame) => <String, Object?>{
                  for (final node in frame.renderGraph.nodes)
                    if (!node.localTransform.isIdentity)
                      node.id: node.localTransform.toJson(),
                })
            .toList(growable: false),
        'frames': frames
            .map((frame) => frame.toJson(includePixels: includePixels))
            .toList(growable: false),
      };
}

/// Portable contract for a looping animation consumed by a feed or messenger.
/// The GIF itself is self-contained; this manifest provides playback and canvas
/// guarantees without requiring a consumer to inspect individual frames.
final class AvatarFeedManifest {
  AvatarFeedManifest.forGif({
    required AvatarAnimation animation,
    required this.animationId,
    this.fileName = 'avatar.gif',
    this.requestFileName = 'request.json',
    this.scale = 1,
  })  : assert(scale > 0),
        _animation = animation {
    if (animation.frames.isEmpty) {
      throw ArgumentError.value(animation, 'animation', 'Must have frames.');
    }
  }

  final AvatarAnimation _animation;
  final String animationId;
  final String fileName;
  final String requestFileName;
  final int scale;

  Map<String, Object> toJson() {
    final frames = _animation.frames;
    final first = frames.first.image;
    final frameDurationMs = _animation.safeFrameDuration.inMilliseconds;
    final opaque = frames.every((frame) => frame.image.indices
        .every((index) => index != frame.image.transparentIndex));
    final stableDimensions = frames.every(
      (frame) =>
          frame.image.width == first.width &&
          frame.image.height == first.height,
    );
    return <String, Object>{
      'schemaVersion': 1,
      'format': 'gif',
      'file': fileName,
      'requestFile': requestFileName,
      'animation': animationId,
      'frameCount': frames.length,
      'frameDurationMs': frameDurationMs,
      'fps': 1000 ~/ frameDurationMs,
      'loop': _animation.loop,
      'canvas': <String, Object>{
        'width': first.width * scale,
        'height': first.height * scale,
        'opaqueBackground': opaque,
        'stableDimensions': stableDimensions,
      },
      'feedSafe': opaque && stableDimensions,
    };
  }
}
