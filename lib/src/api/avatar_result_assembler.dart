import '../constraints/validation.dart';
import '../graph/rig_layout_snapshot_builder.dart';
import '../quality/avatar_metrics_analyzer.dart';
import '../rendering/resolution_renderer.dart';
import '../rendering/rig_clip_pipeline.dart';
import 'avatar_request.dart';
import 'avatar_result.dart';

final class AvatarResultAssembler {
  const AvatarResultAssembler({
    required this.resolutionRenderer,
    this.metricsAnalyzer = const AvatarMetricsAnalyzer(),
    this.layoutBuilder = const RigLayoutSnapshotBuilder(),
  });

  final ResolutionAwareRenderer resolutionRenderer;
  final AvatarMetricsAnalyzer metricsAnalyzer;
  final RigLayoutSnapshotBuilder layoutBuilder;

  AvatarResult assemble({
    required RigPreparedAvatar prepared,
    required RigPipelineFrame frame,
    required AvatarRequest request,
  }) {
    final image = resolutionRenderer.render(
      source: frame.image,
      layers: frame.state.layers,
      palette: prepared.palette,
      settings: request.rendering,
      phase: frame.phase,
    );
    final result = AvatarResult(
      genome: prepared.genome,
      layout: layoutBuilder.build(prepared.layout, frame),
      palette: prepared.palette,
      image: image,
      layers: frame.state.layers,
      validation: frame.validation,
      metrics: metricsAnalyzer.analyze(
        image,
        frame.state,
        prepared.palette,
        request.rendering,
      ),
      imageHash: image.hashWithPalette(prepared.palette.colors),
      effectiveAdjustments: _effectiveAdjustments(request, prepared),
    );
    _enforceQualityGate(request, result);
    return result;
  }

  List<EffectiveAdjustment> _effectiveAdjustments(
    AvatarRequest request,
    RigPreparedAvatar prepared,
  ) {
    final requested = <String, Object>{...request.overrides};
    for (final values in request.lockedCategories.values) {
      requested.addAll(values);
    }
    requested.addAll(request.lockedParameters);

    final output = <EffectiveAdjustment>[];
    for (final entry in requested.entries) {
      final effective = prepared.genome.values[entry.key];
      if (effective == null || effective == entry.value) continue;
      output.add(EffectiveAdjustment(
        field: entry.key,
        requested: entry.value,
        effective: effective,
        reason: prepared.genome.sources[entry.key]?.source ?? 'effectiveGenome',
      ));
    }
    output.sort((a, b) => a.field.compareTo(b.field));
    return List.unmodifiable(output);
  }

  void _enforceQualityGate(AvatarRequest request, AvatarResult result) {
    if (!request.guardEnabled) return;
    final hardIds = result.validation.entries
        .where((entry) =>
            entry.status == ValidationStatus.violation &&
            entry.severity == ValidationSeverity.hard)
        .map((entry) => entry.id)
        .toList(growable: false);
    if (hardIds.isNotEmpty) {
      throw StateError(
        'Avatar quality gate rejected result: ${hardIds.join(', ')}',
      );
    }
  }
}
