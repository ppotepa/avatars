import '../api/avatar_request.dart';
import '../api/avatar_version.dart';
import '../catalog/parameter_catalog.dart';
import '../constraints/validation.dart';
import '../random/random_stream.dart';
import '../util/math_utils.dart';
import 'avatar_genome_model.dart';
import 'genome_generator.dart';

/// Defines a complete, world-aware probability distribution for backgrounds.
///
/// Every catalog option always receives a positive base weight. World themes
/// only increase preferred options; they never make another option unreachable.
final class BackgroundDiversityPolicy {
  const BackgroundDiversityPolicy();

  static const Map<String, Set<String>> preferredByWorld =
      <String, Set<String>>{
    'modern': <String>{
      'solid',
      'blockGradient',
      'verticalSplit',
      'horizontalSplit',
      'checker',
      'dots',
      'sunset',
      'night',
      'rainCity',
    },
    'fantasy': <String>{
      'forest',
      'dungeon',
      'magicAura',
      'flames',
      'night',
      'factionSymbol',
    },
    'magical': <String>{
      'magicAura',
      'forest',
      'space',
      'night',
      'factionSymbol',
    },
    'scienceFiction': <String>{
      'spaceship',
      'space',
      'terminal',
      'laboratory',
      'pixelNoise',
    },
    'cyberpunk': <String>{
      'neonCity',
      'terminal',
      'rainCity',
      'laboratory',
      'pixelNoise',
    },
    'postApocalyptic': <String>{
      'flames',
      'solid',
      'pixelNoise',
      'sunset',
      'factionSymbol',
    },
    'historical': <String>{
      'solid',
      'sunset',
      'forest',
      'factionSymbol',
    },
    'military': <String>{
      'solid',
      'checker',
      'rainCity',
      'factionSymbol',
    },
    'horror': <String>{
      'night',
      'dungeon',
      'forest',
      'pixelNoise',
    },
    'royal': <String>{
      'solid',
      'factionSymbol',
      'sunset',
    },
  };

  Map<String, double> weights(
    ParameterDefinition field,
    String world,
  ) {
    final preferred = preferredByWorld[world] ?? const <String>{};
    return <String, double>{
      for (final option in field.options)
        option.value: preferred.contains(option.value) ? 6 : 1,
    };
  }

  String choose(
    ParameterDefinition field,
    String world,
    RandomStream random,
  ) {
    final distribution = weights(field, world);
    return random.weightedPick(<WeightedValue<String>>[
      for (final option in field.options)
        WeightedValue<String>(option.value, distribution[option.value]!),
    ]);
  }
}

/// Post-processes the stable V4.1 planner to expand reachable combinations.
final class DiversityGenomeGenerator implements GenomeGenerator {
  DiversityGenomeGenerator({
    ParameterCatalog? catalog,
    BackgroundDiversityPolicy? backgroundPolicy,
  })  : catalog = catalog ?? ParameterCatalog.v41,
        backgroundPolicy =
            backgroundPolicy ?? const BackgroundDiversityPolicy(),
        _base = V41GenomeGenerator(catalog: catalog ?? ParameterCatalog.v41);

  final ParameterCatalog catalog;
  final BackgroundDiversityPolicy backgroundPolicy;
  final V41GenomeGenerator _base;

  static const Set<String> _optional = <String>{
    'v4.headwear', 'v4.eyewear', 'v4.faceMask', 'v4.earJewelry',
    'v4.facePiercing', 'v4.neckJewelry', 'v4.armor', 'v4.cape',
    'v4.mouthProp', 'v4.shoulderProp', 'v4.cybernetics', 'v4.scar',
    'v4.marking', 'v4.effect', 'v4.aura',
  };

  @override
  AvatarGenome generate(AvatarRequest request, ConstraintEngine guard) {
    final base = _base.generate(request, guard);
    final values = <String, Object>{...base.values};
    final sources = <String, GenomeValueSource>{...base.sources};
    final root = RandomStream(
      fnv1a32('${AvatarGenomeVersion.generator}:diversity:${request.seed}'),
    );

    bool automatic(String id) => (sources[id]?.priority ?? 1) < 3;
    void setAuto(String id, Object value, String reason) {
      if (!automatic(id)) return;
      final field = catalog.fieldById[id]!;
      if (!field.accepts(value)) return;
      values[id] = value;
      sources[id] = GenomeValueSource(
        source: reason,
        priority: 1,
        category: field.category,
      );
    }

    final mode = values['v4.randomMode']! as String;
    final complexity = values['v4.complexity']! as int;

    if (complexity < 10) {
      for (final id in _optional) setAuto(id, 'none', 'minimalComplexity');
    }

    _selectBackground(values, sources, root, automatic, setAuto);
    _coordinateAnimation(values, sources, root, automatic, setAuto);

    if (mode == 'diverse' || mode == 'chaotic') {
      for (final field in catalog.fields.where(
        (field) => field.kind == ParameterKind.range && automatic(field.id),
      )) {
        final current = values[field.id];
        if (current is! int) continue;
        final chance = mode == 'chaotic' ? 0.38 : 0.16;
        if (!root.fork('range.${field.id}').nextBool(chance)) continue;
        final next = root.fork('range-value.${field.id}').nextInt(
          field.min!,
          field.max!,
        );
        setAuto(field.id, next, 'expandedRange');
      }
    }

    return AvatarGenome(
      seed: base.seed,
      generatorVersion: AvatarGenomeVersion.generator,
      profile: base.profile,
      values: values,
      sources: sources,
    );
  }

  void _selectBackground(
    Map<String, Object> values,
    Map<String, GenomeValueSource> sources,
    RandomStream root,
    bool Function(String id) automatic,
    void Function(String id, Object value, String reason) setAuto,
  ) {
    if (!automatic('v4.background')) return;
    final field = catalog.fieldById['v4.background']!;
    final world = values['v4.worldStyle']! as String;
    setAuto(
      'v4.background',
      backgroundPolicy.choose(
        field,
        world,
        root.fork('complete-background'),
      ),
      'completeBackgroundPool',
    );
  }

  void _coordinateAnimation(
    Map<String, Object> values,
    Map<String, GenomeValueSource> sources,
    RandomStream root,
    bool Function(String id) automatic,
    void Function(String id, Object value, String reason) setAuto,
  ) {
    if (!automatic('v4.animation')) return;
    final candidates = <String>['blink', 'lookAround', 'idle'];
    if (values['v4.mouthProp'] == 'cigarette' ||
        values['v4.mouthProp'] == 'cigar' ||
        values['v4.mouthProp'] == 'pipe') {
      candidates.add('smoke');
    }
    if (values['v4.earJewelry'] != 'none' ||
        values['v4.neckJewelry'] != 'none') {
      candidates.add('jewelrySwing');
    }
    if (values['v4.aura'] != 'none') candidates.add('auraPulse');
    if (values['v4.effect'] != 'none') candidates.add('particles');
    if (values['hair.lengthStyle'] != 'none') candidates.add('hairWind');
    setAuto(
      'v4.animation',
      root.fork('compatible-animation').pick(candidates),
      'compatibleAnimation',
    );
  }
}
