import '../util/deep_freeze.dart';

final class GraphNode {
  GraphNode({
    required this.id,
    required this.type,
    Object? value,
    List<String> dependencies = const <String>[],
    this.compute,
    Map<String, Object?> meta = const <String, Object?>{},
  })  : _value = value,
        dependencies = List<String>.unmodifiable(dependencies),
        _meta = Map<String, Object?>.of(meta);

  final String id;
  final String type;
  Object? _value;
  final List<String> dependencies;
  final Object? Function(Map<String, Object?> values)? compute;
  Map<String, Object?> _meta;
  bool _frozen = false;

  Object? get value => _value;
  Map<String, Object?> get meta => Map<String, Object?>.unmodifiable(_meta);
  bool get isFrozen => _frozen;

  set value(Object? next) {
    if (_frozen) {
      throw StateError('GraphNode is frozen.');
    }
    _value = next;
  }

  GraphNode freeze() {
    if (_frozen) return this;
    _value = deepFreezeValue(_value);
    _meta = deepFreezeStringMap(_meta);
    _frozen = true;
    return this;
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'type': type,
        'value': _value,
        'meta': _meta,
      };
}

final class GraphEdge {
  const GraphEdge({required this.from, required this.to, required this.relation});

  final String from;
  final String to;
  final String relation;

  Map<String, Object> toJson() =>
      <String, Object>{'from': from, 'to': to, 'relation': relation};
}

final class AvatarGraph {
  final Map<String, GraphNode> _nodes = <String, GraphNode>{};
  final List<GraphEdge> _edges = <GraphEdge>[];
  bool _frozen = false;

  Map<String, GraphNode> get nodes => _frozen
      ? Map<String, GraphNode>.unmodifiable(_nodes)
      : _nodes;
  List<GraphEdge> get edges =>
      _frozen ? List<GraphEdge>.unmodifiable(_edges) : _edges;
  bool get isFrozen => _frozen;

  AvatarGraph freeze() {
    if (_frozen) return this;
    for (final node in _nodes.values) {
      node.freeze();
    }
    _frozen = true;
    return this;
  }

  AvatarGraph addValue(
    String id,
    String type,
    Object? value, {
    Map<String, Object?> meta = const <String, Object?>{},
  }) {
    _ensureMutable();
    _nodes[id] = GraphNode(id: id, type: type, value: value, meta: meta);
    return this;
  }

  AvatarGraph addDerived(
    String id,
    String type,
    List<String> dependencies,
    Object? Function(Map<String, Object?> values) compute, {
    Map<String, Object?> meta = const <String, Object?>{},
  }) {
    _ensureMutable();
    _nodes[id] = GraphNode(
      id: id,
      type: type,
      dependencies: dependencies,
      compute: compute,
      meta: meta,
    );
    for (final dependency in dependencies) {
      _edges.add(GraphEdge(from: dependency, to: id, relation: 'dependsOn'));
    }
    return this;
  }

  AvatarGraph addEdge(String from, String to, String relation) {
    _ensureMutable();
    _edges.add(GraphEdge(from: from, to: to, relation: relation));
    return this;
  }

  List<String> topologicalOrder() {
    final indegree = <String, int>{for (final id in _nodes.keys) id: 0};
    for (final edge in _edges) {
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
      for (final edge in _edges.where((edge) => edge.from == id)) {
        if (!indegree.containsKey(edge.to)) continue;
        indegree[edge.to] = indegree[edge.to]! - 1;
        if (indegree[edge.to] == 0) {
          queue.add(edge.to);
          queue.sort();
        }
      }
    }
    if (order.length != _nodes.length) {
      throw StateError('Cycle in avatar dependency graph.');
    }
    return order;
  }

  AvatarGraph evaluate() {
    _ensureMutable();
    for (final id in topologicalOrder()) {
      final node = _nodes[id]!;
      if (node.compute == null) continue;
      node.value = node.compute!(<String, Object?>{
        for (final dependency in node.dependencies)
          dependency: _nodes[dependency]?.value,
      });
    }
    return this;
  }

  Map<String, Object?> values() => <String, Object?>{
        for (final entry in _nodes.entries) entry.key: entry.value.value,
      };

  Map<String, Object> snapshot() => <String, Object>{
        'nodes': _nodes.values.map((node) => node.toJson()).toList(),
        'edges': _edges.map((edge) => edge.toJson()).toList(),
      };

  void _ensureMutable() {
    if (_frozen) {
      throw StateError('AvatarGraph is frozen.');
    }
  }
}
