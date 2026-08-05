import 'dart:typed_data';

import '../constraints/validation.dart';
import '../geometry/avatar_layout.dart';
import '../graph/avatar_graph.dart';
import '../palette/avatar_palette.dart';

AvatarPalette snapshotPalette(AvatarPalette source) => AvatarPalette(
      id: source.id,
      colors: Uint32List.fromList(source.colors),
      roles: Map<String, int>.unmodifiable(source.roles),
    );

ValidationReport snapshotValidation(ValidationReport source) =>
    ValidationReport(List<ValidationEntry>.unmodifiable(source.entries));

AvatarLayout snapshotLayout(AvatarLayout source) {
  final graph = AvatarGraph();
  for (final entry in source.graph.nodes.entries) {
    final node = entry.value;
    graph.addValue(
      entry.key,
      node.type,
      _snapshotValue(node.value),
      meta: Map<String, Object?>.unmodifiable(_snapshotMap(node.meta)),
    );
  }
  for (final edge in source.graph.edges) {
    graph.addEdge(edge.from, edge.to, edge.relation);
  }

  return AvatarLayout(
    values: Map<String, Object>.unmodifiable(<String, Object>{
      for (final entry in source.values.entries)
        entry.key: _snapshotValue(entry.value) as Object,
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

Map<String, Object?> _snapshotMap(Map<String, Object?> source) =>
    <String, Object?>{
      for (final entry in source.entries)
        entry.key: _snapshotValue(entry.value),
    };

Object? _snapshotValue(Object? value) {
  if (value is Map) {
    return Map<String, Object?>.unmodifiable(<String, Object?>{
      for (final entry in value.entries)
        entry.key.toString(): _snapshotValue(entry.value),
    });
  }
  if (value is List) {
    return List<Object?>.unmodifiable(value.map(_snapshotValue));
  }
  if (value is Set) {
    return Set<Object?>.unmodifiable(value.map(_snapshotValue));
  }
  return value;
}
