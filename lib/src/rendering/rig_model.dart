import '../geometry/pixel_rect.dart';
import '../geometry/point.dart';

/// Semantic paint order for the actor and scene.
enum RenderSlot {
  background,
  auraBack,
  capeHairBack,
  rearArms,
  torsoClothing,
  armor,
  neck,
  head,
  face,
  facialHair,
  hairFront,
  headwear,
  eyewear,
  faceMask,
  frontArms,
  shoulderCompanion,
  mouthProp,
  emotionEffects,
  foreground,
}

final class RigTransform {
  const RigTransform({
    this.dx = 0,
    this.dy = 0,
    this.rotationDegrees = 0,
    this.pivotX,
    this.pivotY,
  });

  final int dx;
  final int dy;
  final int rotationDegrees;
  final int? pivotX;
  final int? pivotY;

  static const identity = RigTransform();

  bool get isIdentity => dx == 0 && dy == 0 && rotationDegrees == 0;

  RigTransform compose(RigTransform child) => RigTransform(
        dx: dx + child.dx,
        dy: dy + child.dy,
        rotationDegrees: rotationDegrees + child.rotationDegrees,
        pivotX: child.pivotX ?? pivotX,
        pivotY: child.pivotY ?? pivotY,
      );

  RigTransform copyWith({
    int? dx,
    int? dy,
    int? rotationDegrees,
    int? pivotX,
    int? pivotY,
  }) =>
      RigTransform(
        dx: dx ?? this.dx,
        dy: dy ?? this.dy,
        rotationDegrees: rotationDegrees ?? this.rotationDegrees,
        pivotX: pivotX ?? this.pivotX,
        pivotY: pivotY ?? this.pivotY,
      );

  Map<String, Object?> toJson() => <String, Object?>{
        'dx': dx,
        'dy': dy,
        'rotationDegrees': rotationDegrees,
        if (pivotX != null) 'pivotX': pivotX,
        if (pivotY != null) 'pivotY': pivotY,
      };
}

final class RigAnchor {
  const RigAnchor({
    required this.id,
    required this.nodeId,
    required this.localPosition,
  });

  final String id;
  final String nodeId;
  final PixelPoint localPosition;

  Map<String, Object> toJson() => <String, Object>{
        'id': id,
        'nodeId': nodeId,
        'localPosition': localPosition.toJson(),
      };
}

final class RigNode {
  const RigNode({
    required this.id,
    required this.parentId,
    required this.slot,
    this.anchorId,
    this.restTransform = RigTransform.identity,
    this.bounds,
    this.tags = const <String>{},
  });

  final String id;
  final String? parentId;
  final RenderSlot slot;
  final String? anchorId;
  final RigTransform restTransform;
  final PixelRect? bounds;
  final Set<String> tags;

  RigNode copyWith({
    String? parentId,
    RenderSlot? slot,
    String? anchorId,
    RigTransform? restTransform,
    PixelRect? bounds,
    Set<String>? tags,
  }) =>
      RigNode(
        id: id,
        parentId: parentId ?? this.parentId,
        slot: slot ?? this.slot,
        anchorId: anchorId ?? this.anchorId,
        restTransform: restTransform ?? this.restTransform,
        bounds: bounds ?? this.bounds,
        tags: tags ?? this.tags,
      );

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'parentId': parentId,
        'slot': slot.name,
        'anchorId': anchorId,
        'restTransform': restTransform.toJson(),
        'bounds': bounds?.toJson(),
        'tags': tags.toList(growable: false)..sort(),
      };
}

enum RigConstraintKind {
  fixedDistance,
  attach,
  limitRotation,
  keepInsideCanvas,
}

final class RigConstraint {
  const RigConstraint({
    required this.id,
    required this.kind,
    required this.nodeIds,
    this.anchorIds = const <String>[],
    this.minimum,
    this.maximum,
    this.stiffness = 1,
  });

  final String id;
  final RigConstraintKind kind;
  final List<String> nodeIds;
  final List<String> anchorIds;
  final double? minimum;
  final double? maximum;
  final double stiffness;

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'kind': kind.name,
        'nodeIds': nodeIds,
        'anchorIds': anchorIds,
        if (minimum != null) 'minimum': minimum,
        if (maximum != null) 'maximum': maximum,
        'stiffness': stiffness,
      };
}

final class RigPose {
  RigPose([Map<String, RigTransform>? transforms])
      : transforms = <String, RigTransform>{...?transforms};

  final Map<String, RigTransform> transforms;

  RigTransform transformFor(String nodeId) =>
      transforms[nodeId] ?? RigTransform.identity;

  void set(String nodeId, RigTransform transform) {
    transforms[nodeId] = transform;
  }

  RigPose clone() => RigPose(transforms);

  Map<String, Object> toJson() => <String, Object>{
        for (final entry in transforms.entries)
          entry.key: entry.value.toJson(),
      };
}

final class RigGraph {
  RigGraph({
    required Iterable<RigNode> nodes,
    Iterable<RigAnchor> anchors = const <RigAnchor>[],
    Iterable<RigConstraint> constraints = const <RigConstraint>[],
  })  : nodes = List<RigNode>.unmodifiable(nodes),
        anchors = List<RigAnchor>.unmodifiable(anchors),
        constraints = List<RigConstraint>.unmodifiable(constraints) {
    validate();
  }

  final List<RigNode> nodes;
  final List<RigAnchor> anchors;
  final List<RigConstraint> constraints;

  late final Map<String, RigNode> byId = <String, RigNode>{
    for (final node in nodes) node.id: node,
  };
  late final Map<String, RigAnchor> anchorById = <String, RigAnchor>{
    for (final anchor in anchors) anchor.id: anchor,
  };

  void validate() {
    final ids = <String>{};
    for (final node in nodes) {
      if (!ids.add(node.id)) {
        throw StateError('Duplicate rig node "${node.id}".');
      }
    }
    for (final node in nodes) {
      if (node.parentId != null && !ids.contains(node.parentId)) {
        throw StateError(
          'Rig node "${node.id}" references missing parent "${node.parentId}".',
        );
      }
      final seen = <String>{node.id};
      var parent = node.parentId;
      while (parent != null) {
        if (!seen.add(parent)) {
          throw StateError('Cycle in rig graph at "${node.id}".');
        }
        parent = nodes.where((candidate) => candidate.id == parent).firstOrNull?.parentId;
      }
    }
    final anchorIds = <String>{};
    for (final anchor in anchors) {
      if (!anchorIds.add(anchor.id)) {
        throw StateError('Duplicate rig anchor "${anchor.id}".');
      }
      if (!ids.contains(anchor.nodeId)) {
        throw StateError(
          'Rig anchor "${anchor.id}" references missing node "${anchor.nodeId}".',
        );
      }
    }
  }

  List<RigNode> descendantsOf(String nodeId, {bool includeSelf = true}) {
    if (!byId.containsKey(nodeId)) {
      throw StateError('Unknown rig node "$nodeId".');
    }
    final ids = <String>{if (includeSelf) nodeId};
    var changed = true;
    while (changed) {
      changed = false;
      for (final node in nodes) {
        if (node.parentId != null &&
            (node.parentId == nodeId || ids.contains(node.parentId)) &&
            ids.add(node.id)) {
          changed = true;
        }
      }
    }
    return <RigNode>[
      for (final node in nodes)
        if (ids.contains(node.id)) node,
    ];
  }

  List<String> topologicalOrder() {
    final result = <String>[];
    final visited = <String>{};
    void visit(String id) {
      if (!visited.add(id)) return;
      final parent = byId[id]!.parentId;
      if (parent != null) visit(parent);
      result.add(id);
    }

    for (final node in nodes) visit(node.id);
    return result;
  }

  RigTransform worldTransform(String nodeId, RigPose pose) {
    final node = byId[nodeId];
    if (node == null) throw StateError('Unknown rig node "$nodeId".');
    final chain = <RigNode>[];
    RigNode? current = node;
    while (current != null) {
      chain.add(current);
      current = current.parentId == null ? null : byId[current.parentId!];
    }
    var result = RigTransform.identity;
    for (final item in chain.reversed) {
      result = result.compose(item.restTransform).compose(pose.transformFor(item.id));
    }
    return result;
  }

  PixelPoint worldAnchor(String anchorId, RigPose pose) {
    final anchor = anchorById[anchorId];
    if (anchor == null) throw StateError('Unknown rig anchor "$anchorId".');
    final transform = worldTransform(anchor.nodeId, pose);
    return PixelPoint(
      anchor.localPosition.x + transform.dx,
      anchor.localPosition.y + transform.dy,
    );
  }

  Map<String, Object> toJson() => <String, Object>{
        'nodes': nodes.map((node) => node.toJson()).toList(growable: false),
        'anchors': anchors.map((anchor) => anchor.toJson()).toList(growable: false),
        'constraints': constraints
            .map((constraint) => constraint.toJson())
            .toList(growable: false),
      };
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }
}
