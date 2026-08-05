import 'dart:typed_data';

final class BatchArtifactStore {
  BatchArtifactStore({
    this.ttl = const Duration(minutes: 10),
    this.capacity = 2,
  }) {
    if (capacity < 1) {
      throw ArgumentError.value(capacity, 'capacity', 'Must be positive.');
    }
    if (ttl <= Duration.zero) {
      throw ArgumentError.value(ttl, 'ttl', 'Must be positive.');
    }
  }

  final Duration ttl;
  final int capacity;
  final Map<String, BatchArtifact> _artifacts = <String, BatchArtifact>{};

  int get length {
    purgeExpired();
    return _artifacts.length;
  }

  String put({
    required Uint8List png,
    required Map<String, Object?> manifest,
  }) {
    purgeExpired();
    final columns = manifest['columns'] as int? ?? 0;
    final rows = manifest['rows'] as int? ?? 0;
    final id = '${DateTime.now().microsecondsSinceEpoch}-${columns}x$rows';
    _artifacts[id] = BatchArtifact(
      png: Uint8List.fromList(png),
      manifest: Map<String, Object?>.unmodifiable(manifest),
      createdAt: DateTime.now().toUtc(),
    );
    while (_artifacts.length > capacity) {
      _artifacts.remove(_artifacts.keys.first);
    }
    return id;
  }

  BatchArtifact? get(String id) {
    purgeExpired();
    return _artifacts[id];
  }

  void purgeExpired() {
    final now = DateTime.now().toUtc();
    final expired = <String>[
      for (final entry in _artifacts.entries)
        if (now.difference(entry.value.createdAt) > ttl) entry.key,
    ];
    for (final id in expired) {
      _artifacts.remove(id);
    }
  }

  void clear() => _artifacts.clear();
}

final class BatchArtifact {
  BatchArtifact({
    required Uint8List png,
    required Map<String, Object?> manifest,
    required this.createdAt,
  })  : png = Uint8List.fromList(png),
        manifest = Map<String, Object?>.unmodifiable(manifest);

  final Uint8List png;
  final Map<String, Object?> manifest;
  final DateTime createdAt;
}
