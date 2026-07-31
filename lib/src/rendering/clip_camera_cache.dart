import 'dart:collection';
import 'dart:convert';

import '../api/avatar_request.dart';
import '../genome/avatar_genome_model.dart';
import 'clip_camera.dart';

/// Small in-memory LRU cache for clip-wide camera decisions.
final class ClipCameraCache {
  ClipCameraCache({this.capacity = 32});

  final int capacity;
  final LinkedHashMap<String, ClipCamera> _entries =
      LinkedHashMap<String, ClipCamera>();

  String key({
    required AvatarGenome genome,
    required AvatarRenderSettings rendering,
    required int sampleCount,
  }) =>
      jsonEncode(<String, Object>{
        'generator': genome.generatorVersion,
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
    if (value != null) _entries[key] = value;
    return value;
  }

  void put(String key, ClipCamera value) {
    _entries.remove(key);
    _entries[key] = value;
    while (_entries.length > capacity) {
      _entries.remove(_entries.keys.first);
    }
  }

  int get length => _entries.length;
}
