import 'dart:typed_data';

typedef BatchArtifactClock = DateTime Function();

final class BatchArtifactStore {
  BatchArtifactStore({
    this.ttl = const Duration(minutes: 10),
    this.capacity = 2,
    BatchArtifactClock? clock,
  }) : _clock = clock ?? DateTime.now {
    if (capacity < 1) {
      throw ArgumentError.value(capacity, 'capacity', 'Must be positive.');
    }
    if (ttl <= Duration.zero) {
      throw ArgumentError.value(ttl, 'ttl', 'Must be positive.');
    }
  }

  final Duration ttl;
  final int capacity;
  final BatchArtifactClock _clock;
  final Map<String, BatchArtifact> _artifacts = <String, BatchArtifact>{};
  int _sequence = 0;

  int get length {
    purgeExpired();
    return _artifacts.length;
  }

  String put({
    required Uint8List png,
    required Map<String, Object?> manifest,
  }) {
    purgeExpired();
    final now = _clock().toUtc();
    final columns = manifest['columns'] as int? ?? 0;
    final rows = manifest['rows'] as int? ?? 0;
    final id = '${now.microsecondsSinceEpoch}-${_sequence++}-${columns}x$rows';
    _artifacts[id] = BatchArtifact(
      png: png,
      manifest: manifest,
      createdAt: now,
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
    final now = _clock().toUtc();
    final expired = <String>[
      for (final entry in _artifacts.entries)
        if (now.difference(entry.value.createdAt) > ttl) entry.key,
    ];
    for (final id in expired) {
      _artifacts.remove(id);
    }
  }

  void clear() {
    _artifacts.clear();
    _sequence = 0;
  }
}

final class BatchArtifact {
  BatchArtifact({
    required Uint8List png,
    required Map<String, Object?> manifest,
    required this.createdAt,
  })  : _png = Uint8List.fromList(png),
        manifest = _freezeMap(manifest);

  final Uint8List _png;
  final Map<String, Object?> manifest;
  final DateTime createdAt;

  Uint8List get png => Uint8List.fromList(_png);
}

Map<String, Object?> _freezeMap(Map<String, Object?> source) =>
    Map<String, Object?>.unmodifiable(<String, Object?>{
      for (final entry in source.entries)
        entry.key: _freezeValue(entry.value),
    });

Object? _freezeValue(Object? value) {
  if (value is Map) {
    return Map<String, Object?>.unmodifiable(<String, Object?>{
      for (final entry in value.entries)
        entry.key.toString(): _freezeValue(entry.value),
    });
  }
  if (value is List) {
    return List<Object?>.unmodifiable(value.map(_freezeValue));
  }
  if (value is Set) {
    return Set<Object?>.unmodifiable(value.map(_freezeValue));
  }
  if (value is Uint8List) {
    return Uint8List.fromList(value);
  }
  return value;
}
