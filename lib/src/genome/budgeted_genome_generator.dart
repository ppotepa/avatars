import '../api/avatar_request.dart';
import '../catalog/parameter_catalog.dart';
import '../constraints/validation.dart';
import '../quality/scene_visual_noise.dart';
import '../random/random_stream.dart';
import '../util/math_utils.dart';
import 'avatar_genome_model.dart';
import 'diversity_genome_generator.dart';
import 'genome_generator.dart';

/// Decorates the complete diversity generator with a final scene-noise pass.
///
/// The pass runs after overrides, presets, world composition and chaotic range
/// expansion, so no later stage can reactivate a second full-screen channel.
final class BudgetedGenomeGenerator implements GenomeGenerator {
  BudgetedGenomeGenerator({
    ParameterCatalog? catalog,
    GenomeGenerator? base,
  })  : catalog = catalog ?? ParameterCatalog.v41,
        base = base ??
            DiversityGenomeGenerator(catalog: catalog ?? ParameterCatalog.v41);

  final ParameterCatalog catalog;
  final GenomeGenerator base;

  @override
  AvatarGenome generate(AvatarRequest request, ConstraintEngine guard) {
    final generated = base.generate(request, guard);
    final values = <String, Object>{...generated.values};
    final sources = <String, GenomeValueSource>{...generated.sources};
    _resolveConflicts(values, sources);
    SceneVisualNoise.enforce(
      values: values,
      sources: sources,
      catalog: catalog,
      random: RandomStream(
        fnv1a32('${generated.generatorVersion}:${generated.seed}:scene-budget'),
      ),
    );

    return AvatarGenome(
      seed: generated.seed,
      generatorVersion: generated.generatorVersion,
      profile: generated.profile,
      values: values,
      sources: sources,
    );
  }

  void _resolveConflicts(
    Map<String, Object> values,
    Map<String, GenomeValueSource> sources,
  ) {
    final active = SceneVisualNoise.activeChannels(values);
    if (active.length <= 1) return;
    active.sort((a, b) {
      final sourcePriority = (sources[b]?.priority ?? 1)
          .compareTo(sources[a]?.priority ?? 1);
      if (sourcePriority != 0) return sourcePriority;
      return _semanticPriority(b).compareTo(_semanticPriority(a));
    });
    final winner = active.first;
    for (final id in active.skip(1)) {
      final field = catalog.fieldById[id];
      if (field == null || !field.accepts('none')) continue;
      final previous = sources[id];
      values[id] = 'none';
      sources[id] = GenomeValueSource(
        source: 'sceneChannelConflict:$winner',
        priority: previous?.priority ?? 1,
        category: field.category,
      );
    }
  }

  int _semanticPriority(String id) => switch (id) {
        'v4.weather' => 6,
        'v4.cosmicLayer' => 5,
        'v4.ambientOverlay' => 4,
        'v4.backFlames' => 3,
        'v4.effect' => 2,
        'v4.backgroundEvent' => 1,
        _ => 0,
      };
}
