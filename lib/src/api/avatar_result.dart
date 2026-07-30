import '../constraints/validation.dart';
import '../genome/avatar_genome_model.dart';
import '../geometry/avatar_layout.dart';
import '../palette/avatar_palette.dart';
import '../pixels/indexed_image.dart';
import '../rendering/render_model.dart';
import 'avatar_version.dart';

final class AvatarMetrics {
  const AvatarMetrics({
    required this.usedColorCount,
    required this.occupiedPixelCount,
    required this.isolatedPixelCount,
    required this.connectedComponentCount,
    required this.layerCount,
    required this.visibility,
    required this.faceReadabilityScore,
    this.canvasWidth = 48,
    this.canvasHeight = 48,
    this.detailLevel = 'enhanced',
    this.eyeContrastScore = 0,
    this.silhouetteContrastScore = 0,
    this.visualDensityScore = 100,
  });

  final int usedColorCount;
  final int occupiedPixelCount;
  final int isolatedPixelCount;
  final int connectedComponentCount;
  final int layerCount;
  final RenderVisibility visibility;
  final int faceReadabilityScore;
  final int canvasWidth;
  final int canvasHeight;
  final String detailLevel;
  final int eyeContrastScore;
  final int silhouetteContrastScore;
  final int visualDensityScore;

  Map<String, Object> toJson() => <String, Object>{
        'usedColorCount': usedColorCount,
        'occupiedPixelCount': occupiedPixelCount,
        'isolatedPixelCount': isolatedPixelCount,
        'connectedComponentCount': connectedComponentCount,
        'layerCount': layerCount,
        'visibility': visibility.toJson(),
        'faceReadabilityScore': faceReadabilityScore,
        'canvasWidth': canvasWidth,
        'canvasHeight': canvasHeight,
        'detailLevel': detailLevel,
        'eyeContrastScore': eyeContrastScore,
        'silhouetteContrastScore': silhouetteContrastScore,
        'visualDensityScore': visualDensityScore,
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
  });

  final AvatarGenome genome;
  final AvatarLayout layout;
  final AvatarPalette palette;
  final IndexedImage image;
  final List<RenderLayer> layers;
  final ValidationReport validation;
  final AvatarMetrics metrics;
  final String imageHash;

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
}
