import '../geometry/avatar_layout.dart';
import '../geometry/point.dart';
import 'canonical_rig.dart';
import 'render_model.dart';
import 'rig_anchor_resolver.dart';
import 'rig_model.dart';

/// Builds the executable graph used by animation after geometry is embedded on
/// the overscan canvas.
///
/// Renderer-defined parents always win over canonical defaults. This is
/// required for asymmetric attachments such as a companion placed on the right
/// shoulder.
final class RuntimeRigBuilder {
  const RuntimeRigBuilder();

  RigGraph build(
    AvatarLayout layout,
    AvatarRenderState state, {
    required int offsetX,
    required int offsetY,
  }) {
    final resolved = const RigAnchorResolver().resolve(layout, state);
    final anchors = <RigAnchor>[
      for (final anchor in resolved)
        RigAnchor(
          id: anchor.id,
          nodeId: anchor.nodeId,
          localPosition: anchor.localPosition.translate(offsetX, offsetY),
        ),
    ];
    final byAnchor = <String, RigAnchor>{
      for (final anchor in anchors) anchor.id: anchor,
    };

    final nodeIds = <String>{
      'scene',
      'actor',
      ...state.layers.map((layer) => layer.nodeId),
      ...state.nodeParents.keys,
      ...state.nodeAnchors.keys,
    };
    var added = true;
    while (added) {
      added = false;
      for (final id in nodeIds.toList(growable: false)) {
        final parent = state.nodeParents.containsKey(id)
            ? state.nodeParents[id]
            : CanonicalRig.parents[id];
        if (parent != null && nodeIds.add(parent)) added = true;
      }
    }

    RenderSlot slotFor(String id) {
      final own = state.layers
          .where((layer) => layer.nodeId == id)
          .toList(growable: false);
      if (own.isNotEmpty) {
        own.sort((a, b) => a.slot.index.compareTo(b.slot.index));
        return own.first.slot;
      }
      return CanonicalRig.slotFor(id);
    }

    final nodes = <RigNode>[
      for (final id in nodeIds)
        RigNode(
          id: id,
          parentId: state.nodeParents.containsKey(id)
              ? state.nodeParents[id]
              : CanonicalRig.parents[id],
          slot: slotFor(id),
          anchorId: state.nodeAnchors[id],
          restTransform: RigTransform.identity,
          bounds: _boundsFor(state, id),
        ),
    ];

    final constraints = <RigConstraint>[];

    void attach(
      String id,
      String parentNode,
      String childNode,
      String parentAnchor,
      String childAnchor,
    ) {
      if (!nodeIds.contains(parentNode) || !nodeIds.contains(childNode)) return;
      if (!byAnchor.containsKey(parentAnchor) ||
          !byAnchor.containsKey(childAnchor)) return;
      constraints.add(RigConstraint(
        id: id,
        kind: RigConstraintKind.attach,
        nodeIds: <String>[parentNode, childNode],
        anchorIds: <String>[parentAnchor, childAnchor],
        stiffness: 1,
      ));
    }

    attach(
      'neck-to-head',
      'neck',
      'head',
      'neck.top',
      'head.neckJoint',
    );

    // Every explicit renderer attachment receives a child-side root at the
    // same rest-canvas point. The solver can then preserve the attachment after
    // parent and child animation transforms diverge.
    for (final entry in state.nodeAnchors.entries) {
      final target = byAnchor[entry.value];
      if (target == null || !nodeIds.contains(entry.key)) continue;
      final childAnchorId = '${entry.key}.root';
      if (!byAnchor.containsKey(childAnchorId)) {
        final child = RigAnchor(
          id: childAnchorId,
          nodeId: entry.key,
          localPosition: target.localPosition,
        );
        anchors.add(child);
        byAnchor[childAnchorId] = child;
      }
      constraints.add(RigConstraint(
        id: 'attach.${entry.key}',
        kind: RigConstraintKind.attach,
        nodeIds: <String>[target.nodeId, entry.key],
        anchorIds: <String>[target.id, childAnchorId],
        stiffness: 1,
      ));
    }

    _addChainConstraints(nodeIds, anchors, byAnchor, constraints);

    return RigGraph(
      nodes: nodes,
      anchors: anchors,
      constraints: constraints,
    );
  }

  void _addChainConstraints(
    Set<String> nodeIds,
    List<RigAnchor> anchors,
    Map<String, RigAnchor> byAnchor,
    List<RigConstraint> constraints,
  ) {
    void ensureAnchor(String id, String nodeId, PixelPoint point) {
      if (byAnchor.containsKey(id) || !nodeIds.contains(nodeId)) return;
      final anchor = RigAnchor(id: id, nodeId: nodeId, localPosition: point);
      anchors.add(anchor);
      byAnchor[id] = anchor;
    }

    final leftClavicle = byAnchor['leftClavicle'];
    final rightClavicle = byAnchor['rightClavicle'];
    if (leftClavicle != null && rightClavicle != null) {
      final center = PixelPoint(
        (leftClavicle.localPosition.x + rightClavicle.localPosition.x) ~/ 2,
        (leftClavicle.localPosition.y + rightClavicle.localPosition.y) ~/ 2 + 8,
      );
      ensureAnchor('pendant.center', 'pendant', center);
      if (nodeIds.contains('pendant')) {
        constraints
          ..add(RigConstraint(
            id: 'necklace-left-length',
            kind: RigConstraintKind.fixedDistance,
            nodeIds: const <String>['torso', 'pendant'],
            anchorIds: const <String>['leftClavicle', 'pendant.center'],
            minimum: 8,
            maximum: 18,
            stiffness: .7,
          ))
          ..add(RigConstraint(
            id: 'necklace-right-length',
            kind: RigConstraintKind.fixedDistance,
            nodeIds: const <String>['torso', 'pendant'],
            anchorIds: const <String>['rightClavicle', 'pendant.center'],
            minimum: 8,
            maximum: 18,
            stiffness: .7,
          ));
      }
    }

    void seam(
      String id,
      String firstNode,
      String secondNode,
      String anchorId,
      PixelPoint? point,
    ) {
      if (point == null ||
          !nodeIds.contains(firstNode) ||
          !nodeIds.contains(secondNode)) return;
      final first = '$anchorId.first';
      final second = '$anchorId.second';
      ensureAnchor(first, firstNode, point);
      ensureAnchor(second, secondNode, point);
      constraints.add(RigConstraint(
        id: id,
        kind: RigConstraintKind.attach,
        nodeIds: <String>[firstNode, secondNode],
        anchorIds: <String>[first, second],
        stiffness: 1,
      ));
    }

    final hairRoot = byAnchor['hair.rootCenter']?.localPosition;
    seam(
      'hair-root-middle',
      'hairBackRoot',
      'hairBackMiddle',
      'hair.root.middle',
      hairRoot,
    );
    seam(
      'hair-middle-tip',
      'hairBackMiddle',
      'hairBackTips',
      'hair.middle.tip',
      hairRoot?.translate(0, 7),
    );

    seam(
      'cape-left-root',
      'leftShoulder',
      'capeLeftRoot',
      'cape.left.attach',
      byAnchor['cape.leftRoot']?.localPosition,
    );
    seam(
      'cape-right-root',
      'rightShoulder',
      'capeRightRoot',
      'cape.right.attach',
      byAnchor['cape.rightRoot']?.localPosition,
    );
  }

  dynamic _boundsFor(AvatarRenderState state, String nodeId) {
    dynamic result;
    for (final layer in state.layers.where((layer) => layer.nodeId == nodeId)) {
      final current = layer.mask.bounds;
      if (current == null) continue;
      if (result == null) {
        result = current;
      } else {
        final left = result.left < current.left ? result.left : current.left;
        final top = result.top < current.top ? result.top : current.top;
        final right = result.right > current.right ? result.right : current.right;
        final bottom = result.bottom > current.bottom
            ? result.bottom
            : current.bottom;
        result = result.copyWith(
          x: left,
          y: top,
          width: right - left + 1,
          height: bottom - top + 1,
        );
      }
    }
    return result;
  }
}
