import '../geometry/pixel_rect.dart';

/// Stable semantic paint order. Numeric layer depths are derived from this
/// list and are intentionally not accepted as the source of truth.
abstract final class RenderSlots {
  static const List<String> order = <String>[
    'background',
    'aura-back',
    'cape/hair-back',
    'rear-arms',
    'torso/clothing',
    'armor',
    'neck',
    'head',
    'face',
    'facial-hair',
    'hair-front',
    'headwear',
    'eyewear',
    'face-mask',
    'front-arms/hands',
    'shoulder-companion',
    'mouth-prop',
    'emotion-effects',
    'foreground',
  ];

  static int indexOf(String slot) {
    final index = order.indexOf(slot);
    if (index < 0) {
      throw ArgumentError.value(slot, 'slot', 'Unknown render slot.');
    }
    return index;
  }

  static int compatibilityZ(String slot, int localOrder) =>
      indexOf(slot) * 1000 + localOrder;
}

final class NodeTransform {
  const NodeTransform({
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

  static const NodeTransform identity = NodeTransform();

  NodeTransform operator +(NodeTransform other) => NodeTransform(
        dx: dx + other.dx,
        dy: dy + other.dy,
        rotationDegrees: rotationDegrees + other.rotationDegrees,
        pivotX: other.pivotX ?? pivotX,
        pivotY: other.pivotY ?? pivotY,
      );

  bool get isIdentity => dx == 0 && dy == 0 && rotationDegrees == 0;

  Map<String, Object?> toJson() => <String, Object?>{
        'dx': dx,
        'dy': dy,
        'rotationDegrees': rotationDegrees,
        if (pivotX != null) 'pivotX': pivotX,
        if (pivotY != null) 'pivotY': pivotY,
      };
}

final class RenderNode {
  const RenderNode({
    required this.id,
    required this.parentId,
    required this.slot,
    required this.anchor,
    this.localTransform = NodeTransform.identity,
    this.bounds,
    this.tags = const <String>{},
  });

  final String id;
  final String? parentId;
  final String slot;
  final String anchor;
  final NodeTransform localTransform;
  final PixelRect? bounds;
  final Set<String> tags;

  RenderNode copyWith({
    NodeTransform? localTransform,
    PixelRect? bounds,
  }) =>
      RenderNode(
        id: id,
        parentId: parentId,
        slot: slot,
        anchor: anchor,
        localTransform: localTransform ?? this.localTransform,
        bounds: bounds ?? this.bounds,
        tags: tags,
      );

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'parentId': parentId,
        'slot': slot,
        'anchor': anchor,
        'localTransform': localTransform.toJson(),
        'bounds': bounds?.toJson(),
        'tags': tags.toList(growable: false)..sort(),
      };
}

final class RenderGraph {
  RenderGraph({
    required Iterable<RenderNode> nodes,
    this.canvasWidth = 48,
    this.canvasHeight = 54,
    this.viewportX = 0,
    this.viewportY = 3,
    this.viewportWidth = 48,
    this.viewportHeight = 48,
    this.fitScale = 1,
    this.baseline = 47,
  }) : nodes = List<RenderNode>.unmodifiable(nodes) {
    validate();
  }

  final int canvasWidth;
  final int canvasHeight;
  final int viewportX;
  final int viewportY;
  final int viewportWidth;
  final int viewportHeight;
  final double fitScale;
  final int baseline;
  final List<RenderNode> nodes;

  Map<String, RenderNode> get byId =>
      <String, RenderNode>{for (final node in nodes) node.id: node};

  NodeTransform worldTransform(String nodeId) {
    final lookup = byId;
    var current = lookup[nodeId];
    if (current == null) {
      throw StateError('Unknown render node "$nodeId".');
    }
    var result = NodeTransform.identity;
    while (current != null) {
      result = current.localTransform + result;
      current = current.parentId == null ? null : lookup[current.parentId!];
    }
    return result;
  }

  void validate() {
    final lookup = <String, RenderNode>{};
    for (final node in nodes) {
      if (lookup.containsKey(node.id)) {
        throw StateError('Duplicate render node "${node.id}".');
      }
      RenderSlots.indexOf(node.slot);
      lookup[node.id] = node;
    }
    for (final node in nodes) {
      if (node.parentId != null && !lookup.containsKey(node.parentId)) {
        throw StateError(
            'Orphan render node "${node.id}": "${node.parentId}".');
      }
      final seen = <String>{node.id};
      var parent = node.parentId;
      while (parent != null) {
        if (!seen.add(parent)) {
          throw StateError('Cycle in render graph at "${node.id}".');
        }
        parent = lookup[parent]?.parentId;
      }
      if (node.parentId != null &&
          RenderSlots.indexOf(node.slot) <
              RenderSlots.indexOf(lookup[node.parentId]!.slot) &&
          !node.tags.contains('may-paint-behind-parent')) {
        throw StateError(
            'Node "${node.id}" paints behind its parent without permission.');
      }
    }
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'canvas': <String, int>{
          'width': canvasWidth,
          'height': canvasHeight,
        },
        'viewport': <String, int>{
          'x': viewportX,
          'y': viewportY,
          'width': viewportWidth,
          'height': viewportHeight,
        },
        'fitScale': fitScale,
        'baseline': baseline,
        'slotOrder': RenderSlots.order,
        'nodes': nodes.map((node) => node.toJson()).toList(growable: false),
        'relations': nodes
            .where((node) => node.parentId != null)
            .map((node) =>
                <String, String>{'parent': node.parentId!, 'child': node.id})
            .toList(growable: false),
      };
}

final class FrameFit {
  const FrameFit({
    required this.viewportY,
    required this.scale,
    required this.baseline,
  });

  final int viewportY;
  final double scale;
  final int baseline;
}

/// Computes one camera for the complete clip. Coordinates are first embedded
/// in the 48x54 overscan canvas with a three-pixel top gutter.
abstract final class FrameFitter {
  static FrameFit fit(Iterable<PixelRect?> actorBounds) {
    var top = 54;
    var bottom = -1;
    for (final bounds in actorBounds) {
      if (bounds == null) continue;
      if (bounds.top < top) top = bounds.top;
      if (bounds.bottom > bottom) bottom = bounds.bottom;
    }
    if (bottom < top) {
      return const FrameFit(viewportY: 3, scale: 1, baseline: 50);
    }
    final height = bottom - top + 1;
    if (height <= 48) {
      final minimumY = bottom - 47;
      final viewportY = minimumY.clamp(0, 6);
      return FrameFit(viewportY: viewportY, scale: 1, baseline: 50);
    }
    final scale = 46 / height;
    const baseline = 50;
    final scaledBottom = baseline + ((bottom - baseline) * scale).round();
    return FrameFit(
      viewportY: (scaledBottom - 47).clamp(0, 6),
      scale: scale,
      baseline: baseline,
    );
  }
}
