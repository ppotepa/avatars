import '../pixels/indexed_image.dart';

/// Small deterministic LRU cache for expensive destination-grid detail passes.
/// Cached images are cloned on read/write so callers cannot mutate shared state.
final class ResolutionRenderCache {
  ResolutionRenderCache({this.capacity = 24});

  final int capacity;
  final Map<String, IndexedImage> _entries = <String, IndexedImage>{};
  final List<String> _lru = <String>[];

  int get length => _entries.length;

  IndexedImage? get(String key) {
    final image = _entries[key];
    if (image == null) return null;
    _lru
      ..remove(key)
      ..add(key);
    return image.clone();
  }

  void put(String key, IndexedImage image) {
    _entries[key] = image.clone();
    _lru
      ..remove(key)
      ..add(key);
    while (_lru.length > capacity) {
      final removed = _lru.removeAt(0);
      _entries.remove(removed);
    }
  }

  void clear() {
    _entries.clear();
    _lru.clear();
  }
}
