import '../constraints/validation.dart';
import 'clip_camera.dart';
import 'render_model.dart';

/// Converts runtime quality diagnostics into non-breaking validation warnings.
final class RigValidationEntries {
  const RigValidationEntries();

  List<ValidationEntry> evaluate(
    AvatarRenderState state,
    ClipCamera camera,
  ) {
    final entries = <ValidationEntry>[];

    if (camera.actorOccupancy < .78) {
      entries.add(_soft(
        'rig.camera.occupancy',
        'Readable actor core occupies less than 78% of the viewport height.',
        before: camera.actorOccupancy,
      ));
    }
    if (camera.safetyCoverage < .15) {
      entries.add(_soft(
        'rig.camera.safetyCoverage',
        'Less than 15% of the extended wearable bounds are visible.',
        before: camera.safetyCoverage,
      ));
    }

    final quality = state.metadata['rigConstraintQuality'];
    if (quality is Map) {
      final attach = (quality['maxAttachError'] as num?)?.toDouble() ?? 0;
      final distance =
          (quality['maxDistanceViolation'] as num?)?.toDouble() ?? 0;
      if (attach > 1.01) {
        entries.add(_soft(
          'rig.constraints.attach',
          'A rig attachment deviates by more than one pixel.',
          before: attach,
        ));
      }
      if (distance > 1.01) {
        entries.add(_soft(
          'rig.constraints.distance',
          'A fixed-distance chain deviates by more than one pixel.',
          before: distance,
        ));
      }
    }

    final noise = state.metadata['visualNoise'];
    if (noise is Map) {
      final score = (noise['finalScore'] as num?)?.toInt() ?? 0;
      final limit = (noise['hardLimit'] as num?)?.toInt() ?? 42;
      if (score > limit) {
        entries.add(_soft(
          'scene.visualNoise',
          'Final scene visual-noise score exceeds its hard limit.',
          before: score,
          after: limit,
        ));
      }
      final active = (noise['activeChannelCount'] as num?)?.toInt() ?? 0;
      if (active > 1) {
        entries.add(_soft(
          'scene.effectChannels',
          'More than one dominant scene-effect channel remains after gating.',
          before: active,
          after: 1,
        ));
      }
    }

    final orphaned = state.layers
        .where((layer) =>
            (layer.meta.containsKey('wearableOwner') ||
                layer.meta.containsKey('attachmentKind')) &&
            layer.nodeId != 'actor' &&
            layer.nodeId != 'scene' &&
            !state.nodeParents.containsKey(layer.nodeId))
        .map((layer) => layer.nodeId)
        .toSet()
        .toList(growable: false)
      ..sort();
    if (orphaned.isNotEmpty) {
      entries.add(_soft(
        'rig.wearables.parent',
        'Wearable rig nodes are missing explicit parents: ${orphaned.join(', ')}.',
      ));
    }

    return List.unmodifiable(entries);
  }

  ValidationEntry _soft(
    String id,
    String reason, {
    Object? before,
    Object? after,
  }) =>
      ValidationEntry(
        id: id,
        status: ValidationStatus.violation,
        severity: ValidationSeverity.soft,
        reason: reason,
        before: before,
        after: after,
      );
}
