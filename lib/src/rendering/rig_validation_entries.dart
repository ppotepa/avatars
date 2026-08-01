import '../constraints/validation.dart';
import '../pixels/pixel_mask.dart';
import 'clip_camera.dart';
import 'render_model.dart';
import 'rig_model.dart';

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
    if (camera.safetyCoverage < .55) {
      entries.add(_soft(
        'rig.camera.safetyCoverage',
        'Less than 55% of extended wearable bounds are visible.',
        before: camera.safetyCoverage,
        after: .55,
      ));
    }
    if (camera.criticalCoverage < .999) {
      entries.add(_hard(
        'rig.camera.criticalCoverage',
        'Active hands, face or companion root are outside the viewport.',
        before: camera.criticalCoverage,
        after: .999,
      ));
    }

    final clipping = state.metadata['preCameraClipping'];
    if (clipping is Map && clipping['hasPossibleClipping'] == true) {
      entries.add(_soft(
        'rig.canvas.preCameraClipping',
        'Actor pixels touch the overscan boundary before camera cropping.',
        before: <String, Object?>{
          'edgePixels': clipping['edgePixels'],
          'nodes': clipping['nodes'],
        },
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

    final wearableDiagnostics = state.metadata['wearableAttachments'];
    if (wearableDiagnostics is Map) {
      final fallback =
          (wearableDiagnostics['fallbackLayerCount'] as num?)?.toInt() ?? 0;
      if (fallback > 0) {
        entries.add(_soft(
          'rig.wearables.fallbackBinding',
          'Wearable layers still rely on prefix fallback instead of explicit attachment metadata.',
          before: wearableDiagnostics['fallbackLayers'],
          after: 0,
        ));
      }
    }

    final orphaned = state.layers
        .where((layer) =>
            (layer.meta.containsKey('wearableOwner') ||
                layer.meta.containsKey('attachmentKind') ||
                layer.meta.containsKey('attachmentTarget')) &&
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

    final slotConflicts = <String>[];
    for (final layer in state.layers) {
      final group = layer.meta['occlusionGroup']?.toString();
      if (group == null) continue;
      final expected = switch (group) {
        'backgroundBase' => RenderSlot.background,
        'backgroundDetail' => RenderSlot.backgroundDetail,
        'atmosphereBack' => RenderSlot.atmosphereBack,
        'bodyBack' => RenderSlot.capeHairBack,
        'rearArm' => RenderSlot.rearArms,
        'bodyFront' => RenderSlot.frontArms,
        'earBack' => RenderSlot.earJewelryBack,
        'earFront' => RenderSlot.earJewelryFront,
        'faceFront' => RenderSlot.faceMask,
        'effectFront' => RenderSlot.foreground,
        _ => layer.slot,
      };
      if (layer.slot != expected) slotConflicts.add(layer.id);
    }
    if (slotConflicts.isNotEmpty) {
      entries.add(_soft(
        'rig.layers.occlusionSlot',
        'Layer occlusion groups disagree with their render slots.',
        before: slotConflicts,
      ));
    }

    final actor = _union(state.layers.where(_actorLayer));
    final face = _union(state.layers.where(_faceLayer));
    final actorBounds = actor.bounds;
    if (actorBounds != null) {
      final oneBitComponents = actor.connectedComponents().length;
      if (oneBitComponents > 5) {
        entries.add(_soft(
          'readability.silhouette.components',
          'The one-bit actor silhouette is fragmented into too many components.',
          before: oneBitComponents,
          after: 5,
        ));
      }
      final down24 = _downsample(actor, 24);
      final down12 = _downsample(actor, 12);
      final components24 = down24.connectedComponents().length;
      final components12 = down12.connectedComponents().length;
      if (components24 > 5 || components12 > 4) {
        entries.add(_soft(
          'readability.downscale',
          'The actor loses silhouette coherence when reduced to icon size.',
          before: <String, int>{
            '24pxComponents': components24,
            '12pxComponents': components12,
          },
        ));
      }
    }

    final faceBounds = face.bounds;
    if (faceBounds != null) {
      final faceArea = faceBounds.width * faceBounds.height;
      final faceRatio = faceArea == 0 ? 0 : face.count / faceArea;
      if (faceRatio < .38) {
        entries.add(_soft(
          'readability.face.occlusion',
          'The visible face region is too sparse for reliable expression reading.',
          before: faceRatio,
          after: .38,
        ));
      }
    }

    return List.unmodifiable(entries);
  }

  PixelMask _union(Iterable<RenderLayer> layers) {
    PixelMask? output;
    for (final layer in layers) {
      output = output == null ? layer.mask.clone() : output.union(layer.mask);
    }
    return output ?? PixelMask();
  }

  bool _actorLayer(RenderLayer layer) =>
      !<RenderSlot>{
        RenderSlot.background,
        RenderSlot.backgroundDetail,
        RenderSlot.atmosphereBack,
        RenderSlot.auraBack,
        RenderSlot.emotionEffects,
        RenderSlot.foreground,
      }.contains(layer.slot) &&
      layer.nodeId != 'atmosphere' &&
      layer.nodeId != 'foreground' &&
      layer.nodeId != 'sceneSymbols' &&
      layer.nodeId != 'background';

  bool _faceLayer(RenderLayer layer) => <String>{
        'head',
        'face',
        'eyes',
        'brows',
        'mouth',
        'leftEar',
        'rightEar',
        'facialHair',
        'hairFront',
      }.contains(layer.nodeId);

  PixelMask _downsample(PixelMask source, int size) {
    final output = PixelMask(width: size, height: size);
    for (var y = 0; y < size; y++) {
      final top = y * source.height ~/ size;
      final bottom = ((y + 1) * source.height ~/ size)
          .clamp(top + 1, source.height)
          .toInt();
      for (var x = 0; x < size; x++) {
        final left = x * source.width ~/ size;
        final right = ((x + 1) * source.width ~/ size)
            .clamp(left + 1, source.width)
            .toInt();
        var occupied = 0;
        var total = 0;
        for (var sy = top; sy < bottom; sy++) {
          for (var sx = left; sx < right; sx++) {
            total++;
            if (source.get(sx, sy) != 0) occupied++;
          }
        }
        if (occupied * 2 >= total) output.set(x, y);
      }
    }
    return output;
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

  ValidationEntry _hard(
    String id,
    String reason, {
    Object? before,
    Object? after,
  }) =>
      ValidationEntry(
        id: id,
        status: ValidationStatus.violation,
        severity: ValidationSeverity.hard,
        reason: reason,
        before: before,
        after: after,
      );
}
