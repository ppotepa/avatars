import '../geometry/avatar_layout.dart';
import '../graph/avatar_graph.dart';
import '../rendering/rig_clip_pipeline.dart';

final class RigLayoutSnapshotBuilder {
  const RigLayoutSnapshotBuilder();

  AvatarLayout build(AvatarLayout source, RigPipelineFrame frame) {
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

    final unparented = <String>[
      for (final node in rig.nodes)
        if (node.id != 'scene' &&
            node.id != 'background' &&
            node.parentId == null)
          node.id,
    ]..sort();
    final wearableNodes = frame.state.layers
        .where((layer) =>
            layer.meta.containsKey('wearableOwner') ||
            layer.meta.containsKey('attachmentKind'))
        .map((layer) => layer.nodeId)
        .toSet()
        .toList(growable: false)
      ..sort();
    final constraintQuality = frame.state.metadata['rigConstraintQuality'] ??
        const <String, Object>{};
    final visualNoise =
        frame.state.metadata['visualNoise'] ?? const <String, Object>{};

    graph
      ..addValue('rig.camera', 'clipCamera', frame.camera.toJson())
      ..addValue(
        'rig.preCameraClipping',
        'preCameraClipping',
        frame.state.metadata['preCameraClipping'],
      )
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
      ..addValue(
        'rig.anchors',
        'rigAnchors',
        frame.state.metadata['rigAnchors'],
      )
      ..addValue(
        'rig.constraints',
        'rigConstraints',
        frame.state.metadata['rigConstraints'],
      )
      ..addValue(
        'rig.constraintQuality',
        'rigConstraintQuality',
        constraintQuality,
      )
      ..addValue(
        'rig.worldTransforms',
        'rigWorldTransforms',
        frame.state.metadata['rigWorldTransforms'],
      )
      ..addValue(
        'rig.visualNoise',
        'sceneVisualNoise',
        visualNoise,
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
      ..addValue(
        'rig.shoulderObject',
        'rigidAttachment',
        frame.state.metadata['shoulderObjectRig'],
      )
      ..addValue('rig.back', 'secondaryRig', frame.state.metadata['backRig'])
      ..addValue('rig.seams', 'rigSeams', frame.state.metadata['rigSeams'])
      ..addValue('rig.arms', 'articulatedRig', frame.state.metadata['armRig'])
      ..addValue('rig.rain', 'weatherField', frame.state.metadata['rainField'])
      ..addValue(
        'rig.worldSmoke',
        'worldEmitter',
        frame.state.metadata['worldSmokeEmitter'],
      )
      ..addValue(
        'rig.cameraCache',
        'cacheDiagnostic',
        frame.state.metadata['cameraCache'],
      )
      ..addValue(
        'rig.quality',
        'rigQuality',
        <String, Object>{
          'unparentedNodes': unparented,
          'wearableNodes': wearableNodes,
          'actorOccupancy': frame.camera.actorOccupancy,
          'safetyCoverage': frame.camera.safetyCoverage,
          'cameraScale': frame.camera.scale,
          'layerCount': frame.state.layers.length,
          'constraintQuality': constraintQuality,
          'visualNoise': visualNoise,
        },
      );
    return AvatarLayout(
      values: source.values,
      landmarks: source.landmarks,
      slots: source.slots,
      graph: graph,
    );
  }
}
