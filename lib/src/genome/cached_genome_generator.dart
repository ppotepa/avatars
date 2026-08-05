import 'dart:convert';

import '../api/avatar_request.dart';
import '../api/avatar_version.dart';
import '../constraints/validation.dart';
import 'avatar_genome_model.dart';
import 'genome_generator.dart';

final class CachedGenomeGenerator implements GenomeGenerator {
  CachedGenomeGenerator({required this.delegate, this.capacity = 32})
      : assert(capacity >= 0);

  final GenomeGenerator delegate;
  final int capacity;
  final Map<String, _GenomeCacheEntry> _cache =
      <String, _GenomeCacheEntry>{};

  int get length => _cache.length;
  void clear() => _cache.clear();

  @override
  AvatarGenome generate(AvatarRequest request, ConstraintEngine guard) {
    final key = _key(request);
    final cached = _cache.remove(key);
    if (cached != null) {
      _cache[key] = cached;
      guard.recordAll(cached.entries);
      return cached.genome;
    }

    final localGuard = ConstraintEngine();
    final genome = delegate.generate(request, localGuard);
    final entry = _GenomeCacheEntry(
      genome: genome,
      entries: List<ValidationEntry>.unmodifiable(localGuard.entries),
    );
    guard.recordAll(entry.entries);
    if (capacity > 0) {
      _cache[key] = entry;
      while (_cache.length > capacity) {
        _cache.remove(_cache.keys.first);
      }
    }
    return genome;
  }

  String _key(AvatarRequest request) {
    final json = Map<String, Object>.from(request.toJson())
      ..remove('rendering')
      ..remove('phase')
      ..remove('guardEnabled');
    return jsonEncode(<String, Object>{
      'generatorVersion': AvatarGenomeVersion.generator,
      'request': json,
    });
  }
}

final class _GenomeCacheEntry {
  const _GenomeCacheEntry({required this.genome, required this.entries});

  final AvatarGenome genome;
  final List<ValidationEntry> entries;
}
