import 'dart:collection';

import '../api/avatar_request.dart';
import '../api/avatar_version.dart';
import '../genome/avatar_genome_model.dart';
import '../util/stable_fingerprint.dart';
import 'clip_camera.dart';

/// Small in-memory LRU cache for clip-wide camera decisions.
final class ClipCameraCache {
  ClipCameraCache({this.capacity = 32}) {
    if (capacity < 0) {
      throw ArgumentError.value(capacity, 'capacity', 'Must not be negative.');
    }
  }

  final int capacity;
  final LinkedHashMap<String, ClipCamera> _entries =
      LinkedHashMap<String, ClipCamera>();
  int _hits = 0;
  int _misses = 0;

  String key({
    required AvatarGenome genome,
    required AvatarRenderSettings rendering,
    required int sampleCount,
  }) =>
      stableFingerprint(<String, Object>{
        'generator': AvatarGenomeVersion.generator,
        'catalog': AvatarGenomeVersion.catalog,
        'seed': genome.seed,
        'values': genome.values,
        'detailLevel': rendering.detailLevel.name,
        'lightingDirection': rendering.lightingDirection.name,
        'shadingStrength': rendering.shadingStrength,
        'animateBackground': rendering.animateBackground,
        'reducedMotion': rendering.reducedMotion,
        'sampleCount': sampleCount,
      });

  ClipCamera? get(String key) {
    final value = _entries.remove(key);
    if (value == null) {
      _misses++;
      return null;
    }
    _hits++;
    _entries[key] = value;
    return value;
  }

  void put(String key, ClipCamera value) {
    if (capacity == 0) return;
    _entries.remove(key);
    _entries[key] = value;
    while (_entries.length > capacity) {
      _entries.remove(_entries.keys.first);
    }
  }

  void clear() {
    _entries.clear();
    _hits = 0;
    _misses = 0;
  }

  int get length => _entries.length;
  int get hits => _hits;
  int get misses => _misses;
}
