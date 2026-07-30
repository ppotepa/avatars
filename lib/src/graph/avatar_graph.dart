final class GraphNode {
  GraphNode({
    required this.id,
    required this.type,
    this.value,
    this.dependencies = const <String>[],
    this.compute,
    this.meta = const <String, Object?>{},
  });

  final String id;
  final String type;
  Object? value;
  final List<String> dependencies;
  final Object? Function(Map<String, Object?> values)? compute;
  final Map<String, Object?> meta;

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'type': type,
        'value': value,
        'meta': meta,
      };
}

final class GraphEdge {
  const GraphEdge(
      {required this.from, required this.to, required this.relation});

  final String from;
  final String to;
  final String relation;

  Map<String, Object> toJson() =>
      <String, Object>{'from': from, 'to': to, 'relation': relation};
}

final class AvatarGraph {
  final Map<String, GraphNode> nodes = <String, GraphNode>{};
  final List<GraphEdge> edges = <GraphEdge>[];

  AvatarGraph addValue(
    String id,
    String type,
    Object? value, {
    Map<String, Object?> meta = const <String, Object?>{},
  }) {
    nodes[id] = GraphNode(id: id, type: type, value: value, meta: meta);
    return this;
  }

  AvatarGraph addDerived(
    String id,
    String type,
    List<String> dependencies,
    Object? Function(Map<String, Object?> values) compute, {
    Map<String, Object?> meta = const <String, Object?>{},
  }) {
    nodes[id] = GraphNode(
      id: id,
      type: type,
      dependencies: List.unmodifiable(dependencies),
      compute: compute,
      meta: meta,
    );
    for (final dependency in dependencies) {
      edges.add(GraphEdge(from: dependency, to: id, relation: 'dependsOn'));
    }
    return this;
  }

  AvatarGraph addEdge(String from, String to, String relation) {
    edges.add(GraphEdge(from: from, to: to, relation: relation));
    return this;
  }

  List<String> topologicalOrder() {
    final indegree = <String, int>{for (final id in nodes.keys) id: 0};
    for (final edge in edges) {
      if (indegree.containsKey(edge.from) && indegree.containsKey(edge.to)) {
        indegree[edge.to] = indegree[edge.to]! + 1;
      }
    }
    final queue = indegree.entries
        .where((entry) => entry.value == 0)
        .map((entry) => entry.key)
        .toList()
      ..sort();
    final order = <String>[];
    while (queue.isNotEmpty) {
      final id = queue.removeAt(0);
      order.add(id);
      for (final edge in edges.where((edge) => edge.from == id)) {
        if (!indegree.containsKey(edge.to)) continue;
        indegree[edge.to] = indegree[edge.to]! - 1;
        if (indegree[edge.to] == 0) {
          queue.add(edge.to);
          queue.sort();
        }
      }
    }
    if (order.length != nodes.length) {
      throw StateError('Cycle in avatar dependency graph.');
    }
    return order;
  }

  AvatarGraph evaluate() {
    for (final id in topologicalOrder()) {
      final node = nodes[id]!;
      if (node.compute == null) continue;
      node.value = node.compute!(<String, Object?>{
        for (final dependency in node.dependencies)
          dependency: nodes[dependency]?.value,
      });
    }
    return this;
  }

  Map<String, Object?> values() => <String, Object?>{
        for (final entry in nodes.entries) entry.key: entry.value.value
      };

  Map<String, Object> snapshot() => <String, Object>{
        'nodes': nodes.values.map((node) => node.toJson()).toList(),
        'edges': edges.map((edge) => edge.toJson()).toList(),
      };
}
