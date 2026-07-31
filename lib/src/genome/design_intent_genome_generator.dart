import '../api/avatar_request.dart';
import '../constraints/validation.dart';
import '../random/random_stream.dart';
import '../util/math_utils.dart';
import 'avatar_genome_model.dart';
import 'genome_generator.dart';

/// Applies a small coherent design grammar after the catalog generator has
/// resolved all fields. It only adjusts automatic values; manual overrides and
/// locks remain authoritative.
final class DesignIntentGenomeGenerator implements GenomeGenerator {
  DesignIntentGenomeGenerator(this.delegate);

  final GenomeGenerator delegate;

  @override
  AvatarGenome generate(AvatarRequest request, ConstraintEngine guard) {
    final base = delegate.generate(request, guard);
    final random = RandomStream(fnv1a32('design-intent:${base.seed}'));
    final silhouette = random.weightedPick(<WeightedValue<String>>[
      const WeightedValue('compact', 20),
      const WeightedValue('balanced', 38),
      const WeightedValue('tall', 16),
      const WeightedValue('heroic', 14),
      const WeightedValue('cute', 12),
    ]);
    final material = random.weightedPick(<WeightedValue<String>>[
      const WeightedValue('cloth', 28),
      const WeightedValue('leather', 18),
      const WeightedValue('metal', 20),
      const WeightedValue('organic', 18),
      const WeightedValue('cosmic', 16),
    ]);
    final contrastFocus = random.weightedPick(<WeightedValue<String>>[
      const WeightedValue('face', 52),
      const WeightedValue('silhouette', 30),
      const WeightedValue('accessory', 18),
    ]);

    final values = <String, Object>{...base.values};
    final sources = <String, GenomeValueSource>{...base.sources};

    void adjust(String id, int Function(int value) transform) {
      final source = sources[id];
      final value = values[id];
      if (source == null || source.priority > 1 || value is! num) return;
      final next = transform(value.toInt());
      if (next == value.toInt()) return;
      values[id] = next;
      sources[id] = GenomeValueSource(
        source: 'designIntent.$silhouette',
        priority: 2,
        category: source.category,
      );
    }

    switch (silhouette) {
      case 'compact':
        adjust('head.width', (v) => clampInt(v + 1, 17, 31));
        adjust('head.height', (v) => clampInt(v + 1, 18, 34));
        adjust('neck.length', (v) => clampInt(v - 1, 1, 8));
        adjust('torso.height', (v) => clampInt(v - 1, 7, 18));
        adjust('shoulders.width', (v) => clampInt(v + 1, 20, 48));
        break;
      case 'tall':
        adjust('head.width', (v) => clampInt(v - 1, 17, 31));
        adjust('neck.length', (v) => clampInt(v + 1, 1, 8));
        adjust('torso.height', (v) => clampInt(v + 2, 7, 18));
        adjust('shoulders.width', (v) => clampInt(v - 1, 20, 48));
        break;
      case 'heroic':
        adjust('shoulders.width', (v) => clampInt(v + 3, 20, 48));
        adjust('torso.widthTop', (v) => clampInt(v + 2, 20, 48));
        adjust('torso.widthBottom', (v) => clampInt(v - 1, 20, 48));
        adjust('head.jawWidth', (v) => clampInt(v + 1, 5, 31));
        break;
      case 'cute':
        adjust('head.width', (v) => clampInt(v + 2, 17, 31));
        adjust('eyes.width', (v) => clampInt(v + 1, 1, 12));
        adjust('eyes.height', (v) => clampInt(v + 1, 1, 8));
        adjust('head.chinDepth', (v) => clampInt(v - 1, 0, 8));
        adjust('shoulders.width', (v) => clampInt(v - 2, 20, 48));
        break;
    }

    if (contrastFocus == 'face') {
      adjust('v4.weatherDensity', (v) => clampInt(v - 2, 0, 8));
      adjust('v4.symbolDensity', (v) => clampInt(v - 2, 0, 8));
      adjust('v4.auraThickness', (v) => clampInt(v - 1, 0, 8));
    } else if (contrastFocus == 'accessory') {
      adjust('v4.weatherDensity', (v) => clampInt(v - 1, 0, 8));
      adjust('v4.haloGlow', (v) => clampInt(v + 1, 0, 8));
    }

    if (material == 'metal') {
      adjust('clothing.shadowStrength', (v) => clampInt(v + 1, 0, 4));
    } else if (material == 'cloth') {
      adjust('clothing.shadowStrength', (v) => clampInt(v - 1, 0, 4));
    } else if (material == 'organic') {
      adjust('skin.highlightStrength', (v) => clampInt(v - 1, 0, 4));
    }

    return AvatarGenome(
      seed: base.seed,
      generatorVersion: base.generatorVersion,
      profile: base.profile,
      values: values,
      sources: sources,
    );
  }
}
