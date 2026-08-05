import 'dart:typed_data';

import '../constraints/validation.dart';
import '../genome/avatar_genome_model.dart';
import '../geometry/avatar_layout.dart';
import '../palette/avatar_palette.dart';
import '../pixels/indexed_image.dart';
import '../rendering/render_model.dart';
import '../rendering/resolution_renderer.dart';
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
    this.actorOccupiedPixelCount = 0,
    this.actorIsolatedPixelCount = 0,
    this.actorConnectedComponentCount = 0,
    this.actorWidthOccupancy = 0,
    this.actorHeightOccupancy = 0,
    this.actorAreaOccupancy = 0,
    this.faceHeightOccupancy = 0,
    this.sceneEffectPixelRatio = 0,
    this.nativeGeometryPixelCount = 0,
    this.nativeGeometryPixelRatio = 0,
    this.geometryProfile = 'canonical48',
  });

  final int usedColorCount;
  final int occupiedPixelCount;
  final int isolatedPixelCount;
  final int connectedComponentCount;
  final int actorOccupiedPixelCount;
  final int actorIsolatedPixelCount;
  final int actorConnectedComponentCount;
  final double actorWidthOccupancy;
  final double actorHeightOccupancy;
  final double actorAreaOccupancy;
  final double faceHeightOccupancy;
  final double sceneEffectPixelRatio;
  final int layerCount;
  final RenderVisibility visibility;
  final int faceReadabilityScore;
  final int canvasWidth;
  final int canvasHeight;
  final String detailLevel;
  final int eyeContrastScore;
  final int silhouetteContrastScore;
  final int visualDensityScore;
  final int nativeGeometryPixelCount;
  final double nativeGeometryPixelRatio;
  final String geometryProfile;

  AvatarMetrics withNativeGeometry(Map<String, Object> diagnostics) =>
      AvatarMetrics(
        usedColorCount: usedColorCount,
        occupiedPixelCount: occupiedPixelCount,
        isolatedPixelCount: isolatedPixelCount,
        connectedComponentCount: connectedComponentCount,
        actorOccupiedPixelCount: actorOccupiedPixelCount,
        actorIsolatedPixelCount: actorIsolatedPixelCount,
        actorConnectedComponentCount: actorConnectedComponentCount,
        actorWidthOccupancy: actorWidthOccupancy,
        actorHeightOccupancy: actorHeightOccupancy,
        actorAreaOccupancy: actorAreaOccupancy,
        faceHeightOccupancy: faceHeightOccupancy,
        sceneEffectPixelRatio: sceneEffectPixelRatio,
        layerCount: layerCount,
        visibility: visibility,
        faceReadabilityScore: faceReadabilityScore,
        canvasWidth: canvasWidth,
        canvasHeight: canvasHeight,
        detailLevel: detailLevel,
        eyeContrastScore: eyeContrastScore,
        silhouetteContrastScore: silhouetteContrastScore,
        visualDensityScore: visualDensityScore,
        nativeGeometryPixelCount:
            (diagnostics['nativeGeometryPixelCount'] as num?)?.toInt() ?? 0,
        nativeGeometryPixelRatio:
            (diagnostics['nativeGeometryPixelRatio'] as num?)?.toDouble() ?? 0,
        geometryProfile:
            diagnostics['geometryProfile']?.toString() ?? 'canonical48',
      );

  Map<String, Object> toJson() => <String, Object>{
        'usedColorCount': usedColorCount,
        'occupiedPixelCount': occupiedPixelCount,
        'isolatedPixelCount': isolatedPixelCount,
        'connectedComponentCount': connectedComponentCount,
        'actorOccupiedPixelCount': actorOccupiedPixelCount,
        'actorIsolatedPixelCount': actorIsolatedPixelCount,
        'actorConnectedComponentCount': actorConnectedComponentCount,
        'actorWidthOccupancy': actorWidthOccupancy,
        'actorHeightOccupancy': actorHeightOccupancy,
        'actorAreaOccupancy': actorAreaOccupancy,
        'faceHeightOccupancy': faceHeightOccupancy,
        'sceneEffectPixelRatio': sceneEffectPixelRatio,
        'layerCount': layerCount,
        'visibility': visibility.toJson(),
        'faceReadabilityScore': faceReadabilityScore,
        'canvasWidth': canvasWidth,
        'canvasHeight': canvasHeight,
        'detailLevel': detailLevel,
        'eyeContrastScore': eyeContrastScore,
        'silhouetteContrastScore': silhouetteContrastScore,
        'visualDensityScore': visualDensityScore,
        'nativeGeometryPixelCount': nativeGeometryPixelCount,
        'nativeGeometryPixelRatio': nativeGeometryPixelRatio,
        'geometryProfile': geometryProfile,
      };
}

final class EffectiveAdjustment {
  const EffectiveAdjustment({
    required this.field,
    required this.requested,
    required this.effective,
    required this.reason,
  });

  final String field;
  final Object requested;
  final Object effective;
  final String reason;

  Map<String, Object> toJson() => <String, Object>{
        'field': field,
        'requested': requested,
        'effective': effective,
        'reason': reason,
      };
}

final class AvatarResult {
  factory AvatarResult({
    required AvatarGenome genome,
    required AvatarLayout layout,
    required AvatarPalette palette,
    required IndexedImage image,
    required List<RenderLayer> layers,
    required ValidationReport validation,
    required AvatarMetrics metrics,
    String? imageHash,
    List<EffectiveAdjustment> effectiveAdjustments =
        const <EffectiveAdjustment>[],
  }) {
    final imageSnapshot = image.clone()..freeze();
    final paletteSnapshot = AvatarPalette(
      id: palette.id,
      colors: Uint32List.fromList(palette.colors),
      roles: Map<String, int>.unmodifiable(palette.roles),
    );
    final layerSnapshots = List<RenderLayer>.unmodifiable(<RenderLayer>[
      for (final layer in layers)
        RenderLayer(
          id: layer.id,
          z: layer.z,
          mask: layer.mask.clone()..freeze(),
          colorIndex: layer.colorIndex,
          nodeId: layer.nodeId,
          slot: layer.slot,
          localOrder: layer.localOrder,
          meta: Map<String, Object?>.unmodifiable(layer.meta),
        ),
    ]);
    final calculatedHash =
        imageSnapshot.hashWithPalette(paletteSnapshot.colors);
    if (imageHash != null && imageHash != calculatedHash) {
      throw ArgumentError.value(
        imageHash,
        'imageHash',
        'Image hash does not match the supplied image and palette.',
      );
    }
    return AvatarResult._(
      genome: genome,
      layout: layout,
      palette: paletteSnapshot,
      image: imageSnapshot,
      layers: layerSnapshots,
      validation: validation,
      metrics: metrics,
      imageHash: calculatedHash,
      effectiveAdjustments:
          List<EffectiveAdjustment>.unmodifiable(effectiveAdjustments),
    );
  }

  AvatarResult._({
    required this.genome,
    required this.layout,
    required this.palette,
    required this.image,
    required this.layers,
    required this.validation,
    required AvatarMetrics metrics,
    required this.imageHash,
    required this.effectiveAdjustments,
  })  : _metrics = metrics,
        _nativeGeometryDiagnostics = Map<String, Object>.unmodifiable(
          ResolutionAwareRenderer.diagnosticsFor(image, palette),
        );

  final AvatarGenome genome;
  final AvatarLayout layout;
  final AvatarPalette palette;
  final IndexedImage image;
  final List<RenderLayer> layers;
  final ValidationReport validation;
  final AvatarMetrics _metrics;
  final Map<String, Object> _nativeGeometryDiagnostics;
  final String imageHash;
  final List<EffectiveAdjustment> effectiveAdjustments;

  Map<String, Object> get nativeGeometryDiagnostics =>
      _nativeGeometryDiagnostics;

  AvatarMetrics get metrics =>
      _metrics.withNativeGeometry(_nativeGeometryDiagnostics);

  Map<String, Object?> toJson({bool includePixels = true}) => <String, Object?>{
        'schemaVersion': AvatarGenomeVersion.resultSchema,
        'generatorVersion': genome.generatorVersion,
        'seed': genome.seed,
        'imageHash': imageHash,
        'genome': genome.toJson(),
        'effectiveAdjustments': effectiveAdjustments
            .map((adjustment) => adjustment.toJson())
            .toList(growable: false),
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
  AvatarAnimation({
    required List<AvatarResult> frames,
    required this.frameDuration,
    this.loop = true,
  }) : frames = List<AvatarResult>.unmodifiable(frames);

  final List<AvatarResult> frames;
  final Duration frameDuration;
  final bool loop;
}
