import '../api/avatar_request.dart';
import '../api/avatar_version.dart';
import '../constraints/validation.dart';
import '../util/stable_fingerprint.dart';
import 'avatar_genome_model.dart';
import 'genome_generator.dart';

final class CachedGenomeGenerator implements GenomeGenerator {
  CachedGenomeGenerator({required this.delegate, this.capacity = 32}) {
    if (capacity < 0) {
      throw ArgumentError.value(capacity, 'capacity', 'Must not be negative.');
    }
  }

  final GenomeGenerator delegate;
  final int capacity;
  final Map<String, _GenomeCacheEntry> _cache =
      <String, _GenomeCacheEntry>{};
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
  AvatarGenome generate(AvatarRequest request, ConstraintEngine guard) {
    final key = _key(request);
    final cached = _cache.remove(key);
    if (cached != null) {
      _hits++;
      _cache[key] = cached;
      guard.recordAll(cached.entries);
      return cached.genome;
    }

    _misses++;
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
    return stableFingerprint(<String, Object>{
      'generatorVersion': AvatarGenomeVersion.generator,
      'catalogVersion': AvatarGenomeVersion.catalog,
      'request': json,
    });
  }
}

final class _GenomeCacheEntry {
  const _GenomeCacheEntry({required this.genome, required this.entries});

  final AvatarGenome genome;
  final List<ValidationEntry> entries;
}
