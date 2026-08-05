import 'dart:convert';

import '../constraints/validation.dart';
import '../genome/avatar_genome_model.dart';
import 'avatar_layout.dart';

final class CachedLayoutResolver implements LayoutResolver {
  CachedLayoutResolver({required this.delegate, this.capacity = 32})
      : assert(capacity >= 0);

  final LayoutResolver delegate;
  final int capacity;
  final Map<String, _LayoutCacheEntry> _cache =
      <String, _LayoutCacheEntry>{};

  int get length => _cache.length;
  void clear() => _cache.clear();

  @override
  AvatarLayout resolve(AvatarGenome genome, ConstraintEngine guard) {
    final key = jsonEncode(genome.toJson());
    final cached = _cache.remove(key);
    if (cached != null) {
      _cache[key] = cached;
      guard.recordAll(cached.entries);
      return cached.layout;
    }

    final localGuard = ConstraintEngine();
    final layout = delegate.resolve(genome, localGuard);
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
    return layout;
  }
}

final class _LayoutCacheEntry {
  const _LayoutCacheEntry({required this.layout, required this.entries});

  final AvatarLayout layout;
  final List<ValidationEntry> entries;
}
