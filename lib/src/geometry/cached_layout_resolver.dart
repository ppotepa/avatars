import '../constraints/validation.dart';
import '../genome/avatar_genome_model.dart';
import '../util/stable_fingerprint.dart';
import 'avatar_layout.dart';
import 'avatar_layout_snapshot.dart';

final class CachedLayoutResolver implements LayoutResolver {
  CachedLayoutResolver({required this.delegate, this.capacity = 32}) {
    if (capacity < 0) {
      throw ArgumentError.value(capacity, 'capacity', 'Must not be negative.');
    }
  }

  final LayoutResolver delegate;
  final int capacity;
  final Map<String, _LayoutCacheEntry> _cache =
      <String, _LayoutCacheEntry>{};
  int _hits = 0;
  int _misses = 0;

  int get length => _cache.length;
  int get hits => _hits;
  int get misses => _misses;

  void clear() {
    _cache.clear();
    _hits = 0;
    _misses = 0;
  }

  @override
  AvatarLayout resolve(AvatarGenome genome, ConstraintEngine guard) {
    final key = stableFingerprint(genome.toJson());
    final cached = _cache.remove(key);
    if (cached != null) {
      _hits++;
      _cache[key] = cached;
      guard.recordAll(cached.entries);
      return snapshotAvatarLayout(cached.layout);
    }

    _misses++;
    final localGuard = ConstraintEngine();
    final resolved = delegate.resolve(genome, localGuard);
    final layout = snapshotAvatarLayout(resolved);
    final entry = _LayoutCacheEntry(
      layout: layout,
      entries: List<ValidationEntry>.unmodifiable(localGuard.entries),
    );
    guard.recordAll(entry.entries);
    if (capacity > 0) {
      _cache[key] = entry;
      while (_cache.length > capacity) {
        _cache.remove(_cache.keys.first);
      }
    }
    return snapshotAvatarLayout(layout);
  }
}

final class _LayoutCacheEntry {
  const _LayoutCacheEntry({required this.layout, required this.entries});

  final AvatarLayout layout;
  final List<ValidationEntry> entries;
}
