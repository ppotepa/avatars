import '../util/deep_freeze.dart';

final class GenomeValueSource {
  const GenomeValueSource({
    required this.source,
    required this.priority,
    required this.category,
  });

  factory GenomeValueSource.fromJson(Map<String, Object?> json) =>
      GenomeValueSource(
        source: json['source']! as String,
        priority: (json['priority']! as num).toInt(),
        category: json['category']! as String,
      );

  final String source;
  final int priority;
  final String category;

  Map<String, Object> toJson() => <String, Object>{
        'source': source,
        'priority': priority,
        'category': category,
      };
}

/// Fully resolved, platform-independent genome of an avatar.
final class AvatarGenome {
  AvatarGenome({
    required this.seed,
    required this.generatorVersion,
    required this.profile,
    required Map<String, Object> values,
    required Map<String, GenomeValueSource> sources,
  })  : values = deepFreezeObjectMap(values),
        sources = Map<String, GenomeValueSource>.unmodifiable(
          Map<String, GenomeValueSource>.of(sources),
        );

  factory AvatarGenome.fromJson(Map<String, Object?> json) {
    final rawSources = json['sources'] as Map? ?? const <String, Object?>{};
    return AvatarGenome(
      seed: json['seed']! as String,
      generatorVersion: json['generatorVersion']! as String,
      profile: json['profile']! as String,
      values: <String, Object>{
        for (final entry in (json['values']! as Map).entries)
          entry.key.toString(): entry.value as Object,
      },
      sources: <String, GenomeValueSource>{
        for (final entry in rawSources.entries)
          entry.key.toString(): GenomeValueSource.fromJson(
            Map<String, Object?>.from(entry.value as Map),
          ),
      },
    );
  }

  final String seed;
  final String generatorVersion;
  final String profile;
  final Map<String, Object> values;
  final Map<String, GenomeValueSource> sources;

  int integer(String id, [int fallback = 0]) {
    final value = values[id];
    return value is num ? value.toInt() : fallback;
  }

  String string(String id, [String fallback = 'none']) {
    final value = values[id];
    return value is String ? value : fallback;
  }

  bool boolean(String id, [bool fallback = false]) {
    final value = values[id];
    return value is bool ? value : fallback;
  }

  Object? operator [](String id) => values[id];

  AvatarGenome copyWithValues(Map<String, Object> changed) => AvatarGenome(
        seed: seed,
        generatorVersion: generatorVersion,
        profile: profile,
        values: <String, Object>{...values, ...changed},
        sources: sources,
      );

  Map<String, Object?> toJson() => <String, Object?>{
        'seed': seed,
        'generatorVersion': generatorVersion,
        'profile': profile,
        'values': values,
        'sources': <String, Object>{
          for (final entry in sources.entries) entry.key: entry.value.toJson(),
        },
      };
}
