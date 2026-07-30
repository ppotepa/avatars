import '../api/avatar_request.dart';
import '../api/avatar_version.dart';
import '../catalog/parameter_catalog.dart';
import '../constraints/validation.dart';
import '../random/random_stream.dart';
import '../util/math_utils.dart';
import 'avatar_genome_model.dart';

abstract interface class GenomeGenerator {
  AvatarGenome generate(AvatarRequest request, ConstraintEngine guard);
}

final class V41GenomeGenerator implements GenomeGenerator {
  V41GenomeGenerator({ParameterCatalog? catalog})
      : catalog = catalog ?? ParameterCatalog.v41;

  static const String generatorVersion = AvatarGenomeVersion.generator;
  final ParameterCatalog catalog;

  static const Set<String> _fantasyEars = <String>{
    'elfShort', 'elfMedium', 'elfLong', 'elfUp', 'elfSide', 'goblin',
    'fairy', 'bat', 'cat', 'fox', 'rabbit', 'demon', 'fin', 'mechanical',
  };

  static const Set<String> _identity = <String>{
    'v4.worldStyle', 'v4.archetype', 'v4.randomMode',
  };

  static const Set<String> _optional = <String>{
    'v4.headwear', 'v4.eyewear', 'v4.faceMask', 'v4.earJewelry',
    'v4.facePiercing', 'v4.neckJewelry', 'v4.armor', 'v4.cape',
    'v4.mouthProp', 'v4.shoulderProp', 'v4.cybernetics', 'v4.scar',
    'v4.marking', 'v4.effect', 'v4.aura',
  };

  static const Set<String> _closedHelmets = <String>{
    'helmetKnightClosed', 'helmetFuturistic', 'spaceHelmet',
    'motorcycleHelmet', 'tacticalHelmet', 'diverHelmet', 'demonHelmet',
    'ceremonialHelmet', 'robotHelmet',
  };

  static const Set<String> _fullFaceMasks = <String>{
    'gasMask', 'robotMask', 'hockeyMask', 'balaclava', 'demonMask',
  };

  static const Map<String, Map<String, Object>> _archetypes =
      <String, Map<String, Object>>{
    'knight': <String, Object>{
      'v4.headwear': 'helmetKnightOpen', 'v4.armor': 'plateArmor',
      'v4.cape': 'shortCape',
    },
    'wanderingMage': <String, Object>{
      'v4.headwear': 'wizardHat', 'v4.armor': 'wizardRobe',
      'v4.aura': 'magic',
    },
    'rogue': <String, Object>{
      'v4.headwear': 'hood', 'v4.armor': 'leatherArmor',
      'v4.cape': 'loweredHood',
    },
    'pirateCaptain': <String, Object>{
      'v4.headwear': 'pirateHat', 'v4.eyewear': 'eyePatchLeft',
      'v4.armor': 'pirateCoat', 'v4.shoulderProp': 'parrot',
    },
    'cowboy': <String, Object>{
      'v4.headwear': 'cowboyHat', 'v4.armor': 'cowboyVest',
      'v4.mouthProp': 'grassBlade',
    },
    'soldier': <String, Object>{
      'v4.headwear': 'tacticalHelmet', 'v4.armor': 'uniform',
      'v4.cape': 'backpack',
    },
    'streetHacker': <String, Object>{
      'v4.eyewear': 'cyberVisor', 'v4.cybernetics': 'templeImplant',
      'v4.armor': 'jacket', 'v4.background': 'neonCity',
    },
    'scientist': <String, Object>{
      'v4.eyewear': 'rectGlasses', 'v4.armor': 'labCoat',
      'v4.background': 'laboratory',
    },
    'mechanic': <String, Object>{
      'v4.eyewear': 'weldingGoggles', 'v4.armor': 'apron',
      'v4.shoulderProp': 'radio',
    },
    'spacePilot': <String, Object>{
      'v4.headwear': 'spaceHelmet', 'v4.armor': 'spaceArmor',
      'v4.background': 'spaceship',
    },
    'monarch': <String, Object>{
      'v4.headwear': 'crown', 'v4.armor': 'ceremonialArmor',
      'v4.neckJewelry': 'royalMedallion',
    },
    'priest': <String, Object>{
      'v4.armor': 'priestRobe', 'v4.neckJewelry': 'medallion',
      'v4.aura': 'holy',
    },
    'barbarian': <String, Object>{
      'v4.armor': 'leatherArmor', 'v4.cape': 'furCollar',
      'v4.scar': 'eyeSlash',
    },
    'forestElf': <String, Object>{
      'v4.headwear': 'wreath', 'v4.cape': 'longCape',
      'v4.background': 'forest', 'v4.aura': 'soft',
    },
    'goblinMechanic': <String, Object>{
      'v4.eyewear': 'weldingGoggles', 'v4.armor': 'apron',
      'v4.shoulderProp': 'shoulderRobot',
    },
    'robot': <String, Object>{
      'v4.headwear': 'robotHelmet', 'v4.armor': 'mechanicalArmor',
      'v4.cybernetics': 'halfFace',
    },
    'mutant': <String, Object>{
      'v4.armor': 'scrapArmor', 'v4.cybernetics': 'cheekPlate',
      'v4.marking': 'geometric',
    },
    'vampire': <String, Object>{
      'v4.armor': 'blazer', 'v4.cape': 'longCape', 'v4.aura': 'dark',
    },
    'zombie': <String, Object>{
      'v4.armor': 'scrapArmor', 'v4.scar': 'stitches', 'v4.effect': 'ash',
    },
    'detective': <String, Object>{
      'v4.headwear': 'fedora', 'v4.armor': 'coat',
      'v4.mouthProp': 'cigarette',
    },
    'musician': <String, Object>{
      'v4.eyewear': 'narrowShades', 'v4.armor': 'jacket',
      'v4.mouthProp': 'instrumentMouthpiece',
    },
    'doctor': <String, Object>{
      'v4.armor': 'labCoat', 'v4.faceMask': 'surgicalMask',
    },
    'chef': <String, Object>{
      'v4.headwear': 'chefHat', 'v4.armor': 'apron',
    },
    'miner': <String, Object>{
      'v4.headwear': 'minerHelmet', 'v4.armor': 'jumpsuit',
      'v4.shoulderProp': 'flashlight',
    },
    'diver': <String, Object>{
      'v4.headwear': 'diverHelmet', 'v4.armor': 'jumpsuit',
      'v4.effect': 'bubbles',
    },
  };

  @override
  AvatarGenome generate(AvatarRequest request, ConstraintEngine guard) {
    final root = RandomStream(fnv1a32('$generatorVersion:${request.seed}'));
    final profile = root.fork('profile').weightedPick(<WeightedValue<String>>[
      const WeightedValue<String>('compact', 12),
      const WeightedValue<String>('balanced', 32),
      const WeightedValue<String>('elongated', 15),
      const WeightedValue<String>('broad', 15),
      const WeightedValue<String>('angular', 12),
      const WeightedValue<String>('soft', 14),
    ]);
    final values = <String, Object>{};
    final sources = <String, GenomeValueSource>{};

    for (final field in catalog.fields) {
      final lockedCategory = request.lockedCategories[field.category];
      Object value;
      String source;
      int priority;
      if (request.lockedParameters.containsKey(field.id)) {
        value = request.lockedParameters[field.id]!;
        source = 'lockedParameter';
        priority = 5;
      } else if (lockedCategory?.containsKey(field.id) ?? false) {
        value = lockedCategory![field.id]!;
        source = 'lockedCategory';
        priority = 5;
      } else if (request.overrides.containsKey(field.id)) {
        value = request.overrides[field.id]!;
        source = 'manual';
        priority = 4;
      } else {
        final nonce = request.categoryNonces[field.category] ?? 0;
        final rng = root.fork('${field.category}:$nonce:${field.id}');
        value = field.kind == ParameterKind.range
            ? _autoNumber(field, rng, request.settings, profile)
            : _weightedOption(field, rng, request.settings);
        source = 'auto';
        priority = 1;
      }
      if (!field.accepts(value)) {
        throw ArgumentError.value(value, field.id, 'Value is outside the catalog.');
      }
      values[field.id] = value;
      sources[field.id] = GenomeValueSource(
        source: source,
        priority: priority,
        category: field.category,
      );
    }

    _planV4(request, root, values, sources);
    _postProcess(request, values, sources, guard);
    return AvatarGenome(
      seed: request.seed,
      generatorVersion: generatorVersion,
      profile: profile,
      values: values,
      sources: sources,
    );
  }

  int _effectiveBias(GenomeSettings settings) => clampInt(
        settings.bias +
            switch (settings.presentation) {
              AvatarPresentation.masculine => -40,
              AvatarPresentation.feminine => 40,
              AvatarPresentation.neutral => 0,
            },
        -100,
        100,
      );

  Object _weightedOption(
    ParameterDefinition field,
    RandomStream rng,
    GenomeSettings settings,
  ) {
    final bias = _effectiveBias(settings);
    final age = settings.age;
    final fantasy = settings.fantasy.index;
    final weights = <String, double>{
      for (final option in field.options) option.value: 10,
    };
    void boost(Iterable<String> options, double amount) {
      for (final option in options) {
        if (weights.containsKey(option)) {
          weights[option] = clampDouble(weights[option]! + amount, 0.1, 1000);
        }
      }
    }

    switch (field.id) {
      case 'body.type':
        boost(const <String>['broad', 'massive', 'muscular', 'compact', 'shortWide'], -bias * 0.08);
        boost(const <String>['slim', 'petite', 'tallNarrow'], bias * 0.07);
        break;
      case 'shoulders.shape':
        boost(const <String>['broad', 'muscular', 'angular', 'straight'], -bias * 0.08);
        boost(const <String>['delicate', 'rounded', 'sloping', 'narrow'], bias * 0.08);
        break;
      case 'head.shape':
        boost(const <String>['square', 'wideJaw', 'angular', 'rectangular', 'strongChin'], -bias * 0.07);
        boost(const <String>['heart', 'softOval', 'oval', 'invertedTriangle'], bias * 0.07);
        if (age < 20) boost(const <String>['round', 'softOval'], 8);
        break;
      case 'ears.shape':
        for (final key in weights.keys.toList()) {
          if (_fantasyEars.contains(key)) {
            weights[key] = weights[key]! * switch (fantasy) {
              0 => 0.02, 1 => 0.25, 2 => 0.7, _ => 1.6,
            };
          }
        }
        break;
      case 'eyes.shape':
        boost(const <String>['deepSet', 'narrow', 'realistic', 'rectangular'], -bias * 0.035);
        boost(const <String>['almond', 'upturned', 'cartoon', 'wide', 'oval'], bias * 0.05);
        if (age < 18) boost(const <String>['cartoon', 'round', 'wide'], 10);
        if (age > 70) boost(const <String>['narrow', 'deepSet', 'realistic'], 10);
        if (fantasy > 1) boost(const <String>['solidBlack', 'robotic', 'vertical', 'triangular'], 8);
        break;
      case 'eyes.lashes':
        boost(const <String>['long', 'outerLong', 'stylized', 'upper'], bias * 0.11);
        boost(const <String>['none', 'single', 'short'], -bias * 0.05);
        break;
      case 'brows.shape':
        boost(const <String>['thick', 'veryThick', 'bushy', 'angular'], -bias * 0.08);
        boost(const <String>['thin', 'veryThin', 'rounded', 'highArch'], bias * 0.07);
        break;
      case 'nose.shape':
        boost(const <String>['wide', 'hooked', 'largeTip', 'square', 'long'], -bias * 0.05);
        boost(const <String>['button', 'smallTip', 'narrow', 'upturned'], bias * 0.05);
        if (age > 70) boost(const <String>['long', 'hooked', 'largeTip'], 8);
        break;
      case 'mouth.shape':
        boost(const <String>['full', 'cupid', 'lowerFull', 'upperFull', 'twoTone'], bias * 0.07);
        boost(const <String>['line', 'thin', 'wideLine'], -bias * 0.04);
        break;
      case 'hair.lengthStyle':
        boost(const <String>['none', 'shaved', 'veryShort', 'short'], -bias * 0.04 + age * 0.025);
        boost(const <String>['jaw', 'neck', 'shoulder', 'belowShoulder'], bias * 0.055 - age * 0.018);
        break;
      case 'hair.balding':
        if (age < 25) {
          boost(weights.keys.where((key) => key != 'none' && key != 'shaved'), -9);
        }
        if (age > 50) {
          boost(const <String>['slightRecession', 'temples', 'deepTemples', 'crownThin', 'tonsure', 'frontal', 'frontCrown', 'sidesOnly'], (age - 45) * 0.18 - bias * 0.03);
        }
        break;
      case 'facialHair.style':
        boost(weights.keys.where((key) => key != 'none'), -bias * 0.11 + (age - 20) * 0.035);
        if (bias > 40) boost(weights.keys.where((key) => key != 'none'), -8);
        break;
      case 'fantasy.hornStyle':
      case 'fantasy.antennaStyle':
        for (final key in weights.keys.toList()) {
          if (key != 'none') {
            weights[key] = weights[key]! * switch (fantasy) {
              0 => 0.01, 1 => 0.35, 2 => 0.8, _ => 1.7,
            };
          }
        }
        break;
      case 'fantasy.marking':
        for (final key in weights.keys.toList()) {
          if (key != 'none') {
            weights[key] = weights[key]! * switch (fantasy) {
              0 => 0.03, 1 => 0.4, 2 => 1, _ => 1.8,
            };
          }
        }
        break;
      case 'skin.detail':
        if (age > 60) boost(const <String>['foreheadWrinkles', 'underEyeWrinkles', 'cheekLines', 'underEyeShadow'], 10);
        if (fantasy > 1) boost(const <String>['mechanicalJoints', 'scales', 'spots'], 7);
        break;
    }
    return rng.weightedPick(<WeightedValue<String>>[
      for (final option in field.options)
        WeightedValue<String>(option.value, weights[option.value]!),
    ]);
  }

  int _autoNumber(
    ParameterDefinition field,
    RandomStream rng,
    GenomeSettings settings,
    String profile,
  ) {
    var value = rng.nextInt(field.autoMin!, field.autoMax!);
    final bias = _effectiveBias(settings);
    final age = settings.age;
    void add(num amount) => value += amount.round();
    if (profile == 'compact' && <String>['head.height', 'neck.length', 'body.heightBias'].contains(field.id)) add(-2);
    if (profile == 'compact' && <String>['head.width', 'body.width', 'shoulders.width'].contains(field.id)) add(1);
    if (profile == 'elongated' && <String>['head.height', 'neck.length', 'nose.length'].contains(field.id)) add(2);
    if (profile == 'elongated' && field.id == 'head.width') add(-1);
    if (profile == 'broad' && <String>['head.width', 'head.jawWidth', 'body.width', 'shoulders.width', 'neck.widthBottom'].contains(field.id)) add(2);
    if (profile == 'soft' && <String>['head.roundness', 'cheeks.roundness', 'mouth.lowerLipThickness'].contains(field.id)) add(1);
    if (profile == 'angular' && <String>['head.angularity', 'head.jawWidth', 'shoulders.width'].contains(field.id)) add(1);
    if (<String>['head.jawWidth', 'head.chinWidth', 'neck.widthTop', 'neck.widthBottom', 'shoulders.width', 'body.mass'].contains(field.id)) add(-bias / 55);
    if (<String>['eyes.width', 'eyes.height', 'mouth.upperLipThickness', 'mouth.lowerLipThickness', 'cheeks.roundness', 'hair.volumeSides'].contains(field.id)) add(bias / 70);
    if (field.id == 'hair.recession') add((age - 40).clamp(0, 100) / 18 - bias / 80);
    if (field.id == 'hair.grayingAmount') add((age - 45).clamp(0, 100) / 15);
    if (field.id == 'skin.detailDensity' && age > 55) add(1);
    if (field.id == 'eyes.width' && age < 18) add(1);
    if (field.id == 'nose.length' && age > 65) add(1);
    return clampInt(value, field.min!, field.max!);
  }

  void _planV4(
    AvatarRequest request,
    RandomStream root,
    Map<String, Object> values,
    Map<String, GenomeValueSource> sources,
  ) {
    bool canAuto(String id) => (sources[id]?.priority ?? 1) < 3;
    void setAuto(String id, Object value, String source, int priority) {
      final currentPriority = sources[id]?.priority ?? 0;
      if (!canAuto(id) || currentPriority > priority) return;
      values[id] = value;
      final field = catalog.fieldById[id]!;
      sources[id] = GenomeValueSource(
        source: source,
        priority: priority,
        category: field.category,
      );
    }

    for (final id in _identity) {
      if (!canAuto(id)) continue;
      final field = catalog.fieldById[id]!;
      final rng = root.fork('v41.identity.$id');
      setAuto(id, _identityChoice(field, rng, values), 'seedIdentity', 1);
    }
    final world = values['v4.worldStyle']! as String;
    final mode = values['v4.randomMode']! as String;
    final archetype = values['v4.archetype']! as String;

    final preset = _archetypes[archetype];
    if (preset != null) {
      for (final entry in preset.entries) {
        setAuto(entry.key, entry.value, 'archetype', 2);
      }
    }

    final complexity = values['v4.complexity']! as int;
    final budget = switch (mode) {
      'minimal' => 1 + complexity ~/ 35,
      'natural' => 1 + complexity ~/ 24,
      'chaotic' => 3 + complexity ~/ 15,
      'rareHeavy' => 2 + complexity ~/ 18,
      _ => 1 + complexity ~/ 20,
    };
    final groups = <String, List<String>>{
      'head': <String>['v4.headwear'],
      'face': <String>['v4.eyewear', 'v4.faceMask'],
      'jewelry': <String>['v4.earJewelry', 'v4.facePiercing', 'v4.neckJewelry'],
      'armor': <String>['v4.armor', 'v4.cape'],
      'props': <String>['v4.mouthProp', 'v4.shoulderProp'],
      'marks': <String>['v4.cybernetics', 'v4.scar', 'v4.marking'],
      'effects': <String>['v4.effect', 'v4.aura'],
    };
    final available = groups.keys.toList();
    final selected = <String>{};
    final groupRng = root.fork('v41.groups');
    while (available.isNotEmpty && selected.length < clampInt(budget, 0, 7)) {
      final index = groupRng.nextInt(0, available.length - 1);
      selected.add(available.removeAt(index));
    }
    for (final entry in groups.entries) {
      final automatic = entry.value.where(canAuto).toList(growable: false);
      if (!selected.contains(entry.key)) {
        for (final id in automatic) {
          setAuto(id, 'none', 'compositionBudget', 1);
        }
        continue;
      }
      final fixedActive = entry.value.where((id) =>
          !canAuto(id) && values[id] != 'none').length;
      final maximumActive = switch (entry.key) {
        'jewelry' => complexity >= 70 ? 2 : 1,
        'armor' || 'effects' => complexity >= 85 ? 2 : 1,
        _ => 1,
      };
      final remainingSlots =
          clampInt(maximumActive - fixedActive, 0, automatic.length);
      final candidates = automatic.toList();
      final active = <String>{};
      final memberRng = root.fork('v41.group.${entry.key}');
      while (candidates.isNotEmpty && active.length < remainingSlots) {
        active.add(candidates.removeAt(
          memberRng.nextInt(0, candidates.length - 1),
        ));
      }
      for (final id in automatic) {
        if (!active.contains(id)) {
          setAuto(id, 'none', 'saliencyBudget', 1);
          continue;
        }
        final field = catalog.fieldById[id]!;
        final rng = root.fork('v41.feature.$id');
        setAuto(
          id,
          _featureChoice(field, rng, world, archetype, mode,
              values['v4.rarityBias']! as int),
          'seedFeature',
          1,
        );
      }
    }

    if (canAuto('v4.background')) {
      final backgrounds = <String, List<String>>{
        'modern': <String>['solid', 'blockGradient', 'verticalSplit', 'night', 'rainCity'],
        'fantasy': <String>['forest', 'dungeon', 'magicAura', 'flames', 'night'],
        'magical': <String>['magicAura', 'forest', 'space', 'night'],
        'scienceFiction': <String>['spaceship', 'space', 'terminal', 'laboratory'],
        'cyberpunk': <String>['neonCity', 'terminal', 'rainCity', 'laboratory'],
        'postApocalyptic': <String>['rust', 'dust', 'flames', 'solid'],
      };
      final candidates = backgrounds[world] ??
          <String>['solid', 'blockGradient', 'horizontalSplit', 'checker'];
      final valid = candidates
          .where((value) => catalog.fieldById['v4.background']!.options
              .any((option) => option.value == value))
          .toList();
      if (valid.isNotEmpty) {
        setAuto('v4.background', root.fork('v41.background').pick(valid),
            'seedBackground', 1);
      }
    }

    if (_closedHelmets.contains(values['v4.headwear'])) {
      setAuto('v4.eyewear', 'none', 'conflict', 2);
      setAuto('v4.earJewelry', 'none', 'conflict', 2);
    }
    if (_fullFaceMasks.contains(values['v4.faceMask'])) {
      setAuto('v4.mouthProp', 'none', 'conflict', 2);
      setAuto('v4.facePiercing', 'none', 'conflict', 2);
    }
    if (values['v4.faceMask'] != 'none') {
      setAuto('v4.mouthProp', 'none', 'conflict', 2);
    }
  }

  String _identityChoice(
    ParameterDefinition field,
    RandomStream rng,
    Map<String, Object> values,
  ) {
    final options = field.options.map((option) => option.value).toList();
    Map<String, double> weights;
    if (field.id == 'v4.worldStyle') {
      weights = <String, double>{
        'modern': 22, 'fantasy': 13, 'scienceFiction': 11,
        'cyberpunk': 12, 'steampunk': 7, 'postApocalyptic': 7,
        'historical': 7, 'military': 6, 'magical': 5, 'horror': 4,
        'royal': 3, 'mixed': 3,
      };
    } else if (field.id == 'v4.randomMode') {
      final world = values['v4.worldStyle'] as String? ?? 'modern';
      weights = <String, double>{
        'natural': 26, 'diverse': 34, 'stylized': 16,
        'fantasy': world == 'fantasy' || world == 'magical' ? 22 : 5,
        'scifi': world == 'scienceFiction' || world == 'cyberpunk' ? 22 : 5,
        'chaotic': 5, 'rareHeavy': 7, 'minimal': 8,
      };
    } else {
      final world = values['v4.worldStyle'] as String? ?? 'modern';
      weights = <String, double>{
        'auto': 8, 'detective': 6, 'musician': 5, 'doctor': 4,
        'chef': 3, 'scientist': 5, 'mechanic': 5, 'cowboy': 4,
        'soldier': 4, 'miner': 3, 'diver': 2,
      };
      if (world == 'fantasy' || world == 'magical') {
        weights.addAll(<String, double>{
          'knight': 10, 'wanderingMage': 10, 'rogue': 7,
          'barbarian': 7, 'forestElf': 8, 'goblinMechanic': 5,
          'priest': 5, 'vampire': 4, 'zombie': 3, 'monarch': 4,
        });
      }
      if (world == 'scienceFiction' || world == 'cyberpunk') {
        weights.addAll(<String, double>{
          'streetHacker': 10, 'spacePilot': 9, 'robot': 7,
          'mutant': 5, 'scientist': 7, 'mechanic': 6, 'soldier': 5,
        });
      }
    }
    return rng.weightedPick(<WeightedValue<String>>[
      for (final option in options)
        WeightedValue<String>(option, weights[option] ?? 1),
    ]);
  }

  String _featureChoice(
    ParameterDefinition field,
    RandomStream rng,
    String world,
    String archetype,
    String mode,
    int rarity,
  ) {
    final options = field.options
        .map((option) => option.value)
        .where((value) => value != 'none' && value != 'auto')
        .toList();
    if (options.isEmpty) return 'none';
    final weights = <String, double>{for (final option in options) option: 1};
    void boost(Iterable<String> values, double amount) {
      for (final value in values) {
        if (weights.containsKey(value)) weights[value] = weights[value]! + amount;
      }
    }
    final fantasy = world == 'fantasy' || world == 'magical' || mode == 'fantasy';
    final scifi = world == 'scienceFiction' || world == 'cyberpunk' || mode == 'scifi';
    final historic = world == 'historical' || world == 'royal';
    switch (field.id) {
      case 'v4.headwear':
        boost(const <String>['baseballCap', 'beanie', 'beret', 'fedora', 'winterHat', 'headband'], world == 'modern' ? 4 : 1);
        if (fantasy) boost(const <String>['wizardHat', 'hood', 'crown', 'tiara', 'wreath', 'helmetKnightOpen', 'helmetNorse', 'helmetSamurai', 'hornedHelmet'], 6);
        if (scifi) boost(const <String>['helmetFuturistic', 'spaceHelmet', 'tacticalHelmet', 'robotHelmet', 'motorcycleHelmet'], 7);
        if (historic) boost(const <String>['topHat', 'fedora', 'militaryCap', 'pirateHat', 'ceremonialHelmet'], 4);
        for (final helmet in _closedHelmets) {
          if (weights.containsKey(helmet)) weights[helmet] = weights[helmet]! * 0.32;
        }
        break;
      case 'v4.eyewear':
        boost(const <String>['roundGlasses', 'ovalGlasses', 'squareGlasses', 'rectGlasses', 'thinFrames', 'rimless', 'halfFrames'], 4);
        if (scifi) boost(const <String>['cyberVisor', 'monoVisor', 'targetingLens', 'mirrorShades', 'weldingGoggles'], 8);
        if (historic || archetype == 'pirateCaptain') boost(const <String>['monocleLeft', 'monocleRight', 'eyePatchLeft', 'eyePatchRight'], 5);
        break;
      case 'v4.faceMask':
        if (world == 'modern') boost(const <String>['surgicalMask', 'faceBandana', 'scarfMask'], 3);
        if (fantasy || historic) boost(const <String>['ninjaMask', 'demonMask', 'venetianMask', 'theaterMask', 'ceremonialMask'], 5);
        if (scifi || world == 'postApocalyptic') boost(const <String>['respirator', 'gasMask', 'robotMask', 'halfMask'], 7);
        for (final mask in _fullFaceMasks) {
          if (weights.containsKey(mask)) weights[mask] = weights[mask]! * 0.4;
        }
        break;
      case 'v4.armor':
        if (world == 'modern') boost(const <String>['tshirt', 'shirt', 'hoodie', 'jacket', 'vest', 'coat', 'sweater', 'turtleneck', 'blazer', 'uniform', 'apron', 'labCoat'], 4);
        if (fantasy || historic) boost(const <String>['leatherArmor', 'chainmail', 'plateArmor', 'samuraiArmor', 'gladiatorArmor', 'wizardRobe', 'priestRobe', 'pirateCoat'], 7);
        if (scifi || world == 'postApocalyptic') boost(const <String>['mechanicalArmor', 'spaceArmor', 'jumpsuit', 'scrapArmor'], 8);
        break;
      case 'v4.cape':
        if (fantasy || historic) boost(const <String>['shortCape', 'longCape', 'furCollar', 'quiver', 'swordBack'], 5);
        if (scifi || world == 'postApocalyptic') boost(const <String>['backpack', 'mechanicalTubes', 'energyRifleBack', 'mechanicalWings'], 6);
        break;
      case 'v4.cybernetics':
        if (scifi) boost(options, 3);
        break;
      case 'v4.effect':
        boost(const <String>['rain', 'snow', 'dust', 'leaves'], 3);
        if (fantasy) boost(const <String>['magicParticles', 'embers', 'fire'], 6);
        if (scifi) boost(const <String>['glitch', 'electricity', 'sparks', 'hologram'], 7);
        break;
      case 'v4.aura':
        if (fantasy) boost(const <String>['soft', 'holy', 'fire', 'ice', 'magic', 'runic'], 6);
        if (scifi) boost(const <String>['electric', 'holographic'], 7);
        break;
      case 'v4.mouthProp':
        boost(const <String>['toothpick', 'lollipop', 'grassBlade', 'flower'], 3);
        if (fantasy || historic) boost(const <String>['pipe', 'rose'], 4);
        if (scifi) boost(const <String>['cyberCable'], 7);
        break;
      case 'v4.shoulderProp':
        boost(const <String>['parrot', 'cat', 'flowerBundle', 'radio'], 3);
        if (fantasy) boost(const <String>['smallDragon', 'ghost', 'skull', 'energyOrb'], 6);
        if (scifi) boost(const <String>['shoulderRobot', 'radio', 'flashlight'], 7);
        break;
    }
    if (mode == 'rareHeavy') {
      for (final option in options) weights[option] = weights[option]! + rarity / 35;
    }
    if (mode == 'natural' && <String>['v4.cybernetics', 'v4.aura'].contains(field.id)) {
      for (final option in options) weights[option] = weights[option]! * 0.35;
    }
    return rng.weightedPick(<WeightedValue<String>>[
      for (final option in options)
        WeightedValue<String>(option, clampDouble(weights[option]!, 0.05, 1000)),
    ]);
  }

  void _postProcess(
    AvatarRequest request,
    Map<String, Object> values,
    Map<String, GenomeValueSource> sources,
    ConstraintEngine guard,
  ) {
    void set(String id, Object next, String reason) {
      final before = values[id]!;
      if (before == next) return;
      final priority = sources[id]?.priority ?? 1;
      if (priority >= 4) {
        guard.violation(id, '$reason Manual value was preserved.', severity: ValidationSeverity.soft);
        return;
      }
      values[id] = guard.correct(id, before, next, reason);
    }
    void bound(String id, int min, int max, String reason) {
      final value = values[id]! as int;
      set(id, clampInt(value, min, max), reason);
    }

    bound('head.topWidth', 8, values['head.width']! as int, 'Cranium width fits head.');
    bound('head.templeWidth', 10, values['head.width']! as int, 'Temple width fits head.');
    bound('head.cheekWidth', 12, (values['head.width']! as int) + 1, 'Cheek width fits head.');
    bound('head.jawWidth', 8, values['head.cheekWidth']! as int, 'Jaw fits cheeks.');
    bound('head.chinWidth', 3, values['head.jawWidth']! as int, 'Chin fits jaw.');
    bound('neck.widthTop', 4, clampInt((values['head.jawWidth']! as int) - 2, 4, 50), 'Neck fits jaw.');
    bound('neck.widthBottom', values['neck.widthTop']! as int,
        clampInt((values['shoulders.width']! as int) - 8, 4, 14), 'Neck fits shoulders.');
    final eyeMax = clampInt(((values['head.cheekWidth']! as int) -
                (values['eyes.spacing']! as int) - 4) ~/ 2, 1, 7);
    bound('eyes.width', 1, eyeMax, 'Eyes fit the face.');
    final spacingMax = clampInt((values['head.cheekWidth']! as int) -
            2 * (values['eyes.width']! as int) - 3, 2, 20);
    bound('eyes.spacing', 2, spacingMax, 'Eye spacing fits face.');
    if ((values['eyes.width']! as int) <= 2) {
      bound('eyes.height', 1, 2, 'Small eyes use compact height.');
      bound('eyes.irisSize', 0, 1, 'Iris fits small eye.');
      bound('eyes.pupilSize', 1, 1, 'Pupil fits small eye.');
      bound('eyes.lidThickness', 0, 1, 'Lid fits small eye.');
      bound('eyes.lashLength', 0, 1, 'Lashes fit small eye.');
    }
    if (values['eyes.shape'] == 'dot') {
      set('eyes.height', 1, 'Dot eyes are one pixel high.');
      set('eyes.scleraVisibility', 0, 'Dot eyes have no sclera.');
      set('eyes.eyelid', 'none', 'Dot eyes have no eyelid.');
    }
    bound('brows.thickness', 0, (values['brows.height']! as int) <= 1 ? 2 : 3, 'Brows stay above eyes.');
    bound('nose.width', 1, clampInt((values['eyes.spacing']! as int) - 1, 1, 20), 'Nose fits between eyes.');
    bound('nose.bridgeWidth', 0, values['nose.width']! as int, 'Bridge fits nose.');
    bound('nose.tipWidth', 1, (values['nose.width']! as int) + 1, 'Tip fits nose.');
    bound('mouth.width', 2, clampInt((values['head.jawWidth']! as int) - 2, 2, 20), 'Mouth fits jaw.');
    bound('mouth.height', 1, 3, 'Mouth fits lower face.');

    if (<String>['fullBald', 'sidesOnly', 'tuft'].contains(values['hair.balding'])) {
      if (values['hair.balding'] != 'tuft') set('hair.fringe', 'none', 'Balding removes fringe.');
      set('hair.parting', 'none', 'Balding removes parting.');
    }
    if (values['hair.balding'] == 'fullBald') {
      set('hair.lengthStyle', 'none', 'Full baldness removes hair length.');
      set('hair.length', 0, 'Full baldness removes back mass.');
      set('hair.volumeTop', 0, 'Full baldness removes top volume.');
    }
    if (values['hair.lengthStyle'] == 'none' && values['hair.balding'] == 'none') {
      set('hair.balding', 'fullBald', 'No hair is represented by full baldness.');
    }
    if (request.settings.fantasy == FantasyLevel.none && _fantasyEars.contains(values['ears.shape'])) {
      set('ears.shape', 'humanOval', 'Realistic mode replaces fantasy ears.');
    }
    if (request.settings.fantasy == FantasyLevel.none) {
      set('fantasy.hornStyle', 'none', 'Realistic mode removes horns.');
      set('fantasy.antennaStyle', 'none', 'Realistic mode removes antennae.');
    }
    if (values['facialHair.style'] == 'none') {
      set('facialHair.density', 0, 'No facial hair has zero density.');
    }
    if (request.settings.symmetry) {
      for (final id in const <String>[
        'head.asymmetry', 'ears.asymmetry', 'eyes.asymmetry',
        'brows.asymmetry', 'nose.asymmetry', 'mouth.asymmetry',
        'shoulders.asymmetry', 'fantasy.hornAsymmetry',
        'v4.accessoryAsymmetry',
      ]) {
        set(id, 0, 'Symmetry removes automatic asymmetry.');
      }
    }
  }
}
