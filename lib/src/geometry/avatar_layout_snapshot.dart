import '../graph/avatar_graph.dart';
import 'avatar_layout.dart';

AvatarLayout snapshotAvatarLayout(AvatarLayout source) {
  final graph = AvatarGraph();
  for (final entry in source.graph.nodes.entries) {
    final node = entry.value;
    graph.addValue(
      entry.key,
      node.type,
      snapshotValue(node.value),
      meta: Map<String, Object?>.unmodifiable(
        snapshotObjectMap(node.meta),
      ),
    );
  }
  for (final edge in source.graph.edges) {
    graph.addEdge(edge.from, edge.to, edge.relation);
  }

  return AvatarLayout(
    values: Map<String, Object>.unmodifiable(<String, Object>{
      for (final entry in source.values.entries)
        entry.key: snapshotValue(entry.value) as Object,
    }),
    landmarks: Map.unmodifiable(source.landmarks),
    slots: Map<String, AvatarSlot>.unmodifiable(<String, AvatarSlot>{
      for (final entry in source.slots.entries)
        entry.key: AvatarSlot(
          anchor: entry.value.anchor,
          bounds: entry.value.bounds,
          acceptedCategories:
              List<String>.unmodifiable(entry.value.acceptedCategories),
        ),
    }),
    graph: graph,
  );
}

Map<String, Object?> snapshotObjectMap(Map<String, Object?> source) =>
    <String, Object?>{
      for (final entry in source.entries)
        entry.key: snapshotValue(entry.value),
    };

Object? snapshotValue(Object? value) {
  if (value is Map) {
    return Map<String, Object?>.unmodifiable(<String, Object?>{
      for (final entry in value.entries)
        entry.key.toString(): snapshotValue(entry.value),
    });
  }
  if (value is List) {
    return List<Object?>.unmodifiable(value.map(snapshotValue));
  }
  if (value is Set) {
    return Set<Object?>.unmodifiable(value.map(snapshotValue));
  }
  return value;
}
