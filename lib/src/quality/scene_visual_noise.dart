import '../catalog/parameter_catalog.dart';
import '../genome/avatar_genome_model.dart';
import '../random/random_stream.dart';
import '../util/math_utils.dart';

final class SceneVisualBudgetReport {
  const SceneVisualBudgetReport({
    required this.targetScore,
    required this.finalScore,
    required this.activeChannel,
    required this.disabledChannels,
    required this.reducedFields,
  });

  final int targetScore;
  final int finalScore;
  final String? activeChannel;
  final List<String> disabledChannels;
  final Map<String, int> reducedFields;

  Map<String, Object?> toJson() => <String, Object?>{
        'targetScore': targetScore,
        'hardLimit': SceneVisualNoise.hardLimit,
        'finalScore': finalScore,
        'activeChannel': activeChannel,
        'disabledChannels': disabledChannels,
        'reducedFields': reducedFields,
      };
}

/// Shared visual-noise scoring and enforcement for full-scene effects.
abstract final class SceneVisualNoise {
  static const int hardLimit = 42;

  static const List<String> dominantFields = <String>[
    'v4.weather',
    'v4.cosmicLayer',
    'v4.backFlames',
    'v4.ambientOverlay',
    'v4.backgroundEvent',
    'v4.effect',
  ];

  static const List<String> softOverlayFields = <String>[
    'v4.symbolOverlay',
    'v4.aura',
    'v4.halo',
  ];

  static List<String> activeChannels(Map<String, Object> values) =>
      dominantFields
          .where((id) => (values[id] as String? ?? 'none') != 'none')
          .toList(growable: false);

  static int probabilisticTarget(
    Map<String, Object> values,
    RandomStream random,
  ) {
    final complexity = values['v4.complexity'] is num
        ? (values['v4.complexity']! as num).toInt()
        : 50;
    final mode = values['v4.randomMode'] as String? ?? 'balanced';
    final chaotic = mode == 'chaotic' || mode == 'rareHeavy';
    final base = 25 + complexity ~/ 12 + (chaotic ? 2 : 0);
    return clampInt(base + random.nextInt(-3, 3), 24, chaotic ? 40 : 38);
  }

  static int score(Map<String, Object> values) {
    var total = _backgroundCost(values['v4.background'] as String? ?? 'solid');
    final channel = activeChannels(values).firstOrNull;
    if (channel != null) total += _channelCost(channel, values);

    final symbol = values['v4.symbolOverlay'] as String? ?? 'none';
    if (symbol != 'none') {
      total += 4 + _int(values, 'v4.symbolDensity') * 2;
    }
    if ((values['v4.aura'] as String? ?? 'none') != 'none') total += 6;
    if ((values['v4.halo'] as String? ?? 'none') != 'none') total += 4;
    return clampInt(total, 0, 100);
  }

  static SceneVisualBudgetReport enforce({
    required Map<String, Object> values,
    required Map<String, GenomeValueSource> sources,
    required ParameterCatalog catalog,
    required RandomStream random,
  }) {
    final target = probabilisticTarget(values, random.fork('target'));
    final active = activeChannels(values);
    final disabled = <String>[];
    final reduced = <String, int>{};
    String? winner;

    if (active.isNotEmpty) {
      final highestPriority = active
          .map((id) => sources[id]?.priority ?? 1)
          .reduce((a, b) => a > b ? a : b);
      final finalists = active
          .where((id) => (sources[id]?.priority ?? 1) == highestPriority)
          .toList(growable: false);
      winner = finalists.length == 1
          ? finalists.single
          : random.fork('winner').weightedPick(<WeightedValue<String>>[
              for (final id in finalists)
                WeightedValue<String>(id, _channelSelectionWeight(id)),
            ]);
      for (final id in active) {
        if (id == winner) continue;
        _assign(values, sources, catalog, id, 'none', 'sceneVisualNoiseBudget');
        disabled.add(id);
      }
    }

    if (winner != null) {
      for (final entry in _densityCaps(winner).entries) {
        final current = _int(values, entry.key);
        if (current > entry.value) {
          _assign(
            values,
            sources,
            catalog,
            entry.key,
            entry.value,
            'sceneVisualNoiseDensityCap',
          );
          reduced[entry.key] = entry.value;
        }
      }

      final reducible = _reducibleDensityFields(winner);
      var cursor = 0;
      while (score(values) > target && reducible.isNotEmpty && cursor < 64) {
        final id = reducible[cursor % reducible.length];
        final current = _int(values, id);
        if (current > 1) {
          _assign(
            values,
            sources,
            catalog,
            id,
            current - 1,
            'sceneVisualNoiseTarget',
          );
          reduced[id] = current - 1;
        }
        cursor++;
        if (reducible.every((id) => _int(values, id) <= 1)) break;
      }
    }

    if (score(values) > hardLimit) {
      final soft = softOverlayFields
          .where((id) => (values[id] as String? ?? 'none') != 'none')
          .toList()
        ..sort((a, b) {
          final priority = (sources[a]?.priority ?? 1)
              .compareTo(sources[b]?.priority ?? 1);
          return priority != 0 ? priority : a.compareTo(b);
        });
      for (final id in soft) {
        if (score(values) <= hardLimit) break;
        _assign(values, sources, catalog, id, 'none', 'sceneVisualNoiseHardLimit');
        disabled.add(id);
      }
    }

    if (score(values) > hardLimit && winner != null) {
      _assign(
        values,
        sources,
        catalog,
        winner,
        'none',
        'sceneVisualNoiseHardLimit',
      );
      disabled.add(winner);
      winner = null;
    }

    return SceneVisualBudgetReport(
      targetScore: target,
      finalScore: score(values),
      activeChannel: winner,
      disabledChannels: List.unmodifiable(disabled),
      reducedFields: Map.unmodifiable(reduced),
    );
  }

  static Map<String, int> _densityCaps(String channel) => switch (channel) {
        'v4.weather' => const <String, int>{
            'v4.weatherDensity': 4,
            'v4.weatherDepth': 2,
          },
        'v4.cosmicLayer' => const <String, int>{'v4.cosmicDensity': 3},
        'v4.backFlames' => const <String, int>{
            'v4.flameIntensity': 4,
            'v4.flameHeight': 5,
          },
        'v4.ambientOverlay' => const <String, int>{'v4.ambientDensity': 3},
        'v4.backgroundEvent' => const <String, int>{
            'v4.eventIntensity': 3,
            'v4.eventFrequency': 4,
          },
        'v4.effect' => const <String, int>{'v4.particleDensity': 3},
        _ => const <String, int>{},
      };

  static List<String> _reducibleDensityFields(String channel) =>
      _densityCaps(channel).keys.toList(growable: false);

  static int _channelCost(String channel, Map<String, Object> values) =>
      switch (channel) {
        'v4.weather' =>
          10 + _int(values, 'v4.weatherDensity') * 3 +
              _int(values, 'v4.weatherDepth'),
        'v4.cosmicLayer' => 9 + _int(values, 'v4.cosmicDensity') * 3,
        'v4.backFlames' =>
          10 + _int(values, 'v4.flameIntensity') * 3 +
              _int(values, 'v4.flameHeight') ~/ 2,
        'v4.ambientOverlay' => 8 + _int(values, 'v4.ambientDensity') * 3,
        'v4.backgroundEvent' =>
          7 + _int(values, 'v4.eventIntensity') * 3 +
              _int(values, 'v4.eventFrequency') ~/ 2,
        'v4.effect' => 8 + _int(values, 'v4.particleDensity') * 3,
        _ => 0,
      };

  static double _channelSelectionWeight(String channel) => switch (channel) {
        'v4.weather' => 5,
        'v4.cosmicLayer' => 4,
        'v4.ambientOverlay' => 3.5,
        'v4.backFlames' => 3,
        'v4.effect' => 2.5,
        'v4.backgroundEvent' => 2,
        _ => 1,
      };

  static int _backgroundCost(String style) {
    if (<String>{
      'solid',
      'blockGradient',
      'verticalSplit',
      'horizontalSplit',
    }.contains(style)) {
      return 4;
    }
    if (<String>{
      'checker',
      'dots',
      'sunset',
      'sunrise',
      'night',
      'forest',
      'oceanHorizon',
      'desertDunes',
      'snowMountains',
    }.contains(style)) {
      return 8;
    }
    if (<String>{
      'pixelNoise',
      'voidStatic',
      'dataGrid',
      'warpTunnel',
      'runeCircle',
      'portalRift',
      'astralPlane',
      'demonicGate',
      'factorySmoke',
      'foggyForest',
      'crystalCave',
      'libraryShelves',
      'cathedralWindow',
    }.contains(style)) {
      return 18;
    }
    return 12;
  }

  static int _int(Map<String, Object> values, String id) {
    final value = values[id];
    return value is num ? value.toInt() : 0;
  }

  static void _assign(
    Map<String, Object> values,
    Map<String, GenomeValueSource> sources,
    ParameterCatalog catalog,
    String id,
    Object value,
    String reason,
  ) {
    final field = catalog.fieldById[id];
    if (field == null || !field.accepts(value)) return;
    final previous = sources[id];
    values[id] = value;
    sources[id] = GenomeValueSource(
      source: reason,
      priority: previous?.priority ?? 1,
      category: field.category,
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }
}
