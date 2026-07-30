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
    'elfShort',
    'elfMedium',
    'elfLong',
    'elfUp',
    'elfSide',
    'goblin',
    'fairy',
    'bat',
    'cat',
    'fox',
    'rabbit',
    'demon',
    'fin',
    'mechanical',
  };

  static const Set<String> _identity = <String>{
    'v4.worldStyle',
    'v4.archetype',
    'v4.randomMode',
    'v4.morphology',
  };

  static const Set<String> _closedHelmets = <String>{
    'helmetKnightClosed',
    'helmetFuturistic',
    'spaceHelmet',
    'motorcycleHelmet',
    'tacticalHelmet',
    'diverHelmet',
    'demonHelmet',
    'ceremonialHelmet',
    'robotHelmet',
  };

  static const Set<String> _fullFaceMasks = <String>{
    'gasMask',
    'robotMask',
    'hockeyMask',
    'balaclava',
    'demonMask',
  };

  static const Map<String, Map<String, Object>> _archetypes =
      <String, Map<String, Object>>{
    'knight': <String, Object>{
      'v4.headwear': 'helmetKnightOpen',
      'v4.armor': 'plateArmor',
      'v4.cape': 'shortCape',
    },
    'wanderingMage': <String, Object>{
      'v4.headwear': 'wizardHat',
      'v4.armor': 'wizardRobe',
      'v4.aura': 'magic',
    },
    'rogue': <String, Object>{
      'v4.headwear': 'hood',
      'v4.armor': 'leatherArmor',
      'v4.cape': 'loweredHood',
    },
    'pirateCaptain': <String, Object>{
      'v4.headwear': 'pirateHat',
      'v4.eyewear': 'eyePatchLeft',
      'v4.armor': 'pirateCoat',
      'v4.shoulderProp': 'parrot',
    },
    'cowboy': <String, Object>{
      'v4.headwear': 'cowboyHat',
      'v4.armor': 'cowboyVest',
      'v4.mouthProp': 'grassBlade',
    },
    'soldier': <String, Object>{
      'v4.headwear': 'tacticalHelmet',
      'v4.armor': 'uniform',
      'v4.cape': 'backpack',
    },
    'streetHacker': <String, Object>{
      'v4.eyewear': 'cyberVisor',
      'v4.cybernetics': 'templeImplant',
      'v4.armor': 'jacket',
      'v4.background': 'neonCity',
    },
    'scientist': <String, Object>{
      'v4.eyewear': 'rectGlasses',
      'v4.armor': 'labCoat',
      'v4.background': 'laboratory',
    },
    'mechanic': <String, Object>{
      'v4.eyewear': 'weldingGoggles',
      'v4.armor': 'apron',
      'v4.shoulderProp': 'radio',
    },
    'spacePilot': <String, Object>{
      'v4.headwear': 'spaceHelmet',
      'v4.armor': 'spaceArmor',
      'v4.background': 'spaceship',
    },
    'monarch': <String, Object>{
      'v4.headwear': 'crown',
      'v4.armor': 'ceremonialArmor',
      'v4.neckJewelry': 'royalMedallion',
    },
    'priest': <String, Object>{
      'v4.armor': 'priestRobe',
      'v4.neckJewelry': 'medallion',
      'v4.aura': 'holy',
    },
    'barbarian': <String, Object>{
      'v4.armor': 'leatherArmor',
      'v4.cape': 'furCollar',
      'v4.scar': 'eyeSlash',
    },
    'forestElf': <String, Object>{
      'v4.headwear': 'wreath',
      'v4.cape': 'longCape',
      'v4.background': 'forest',
      'v4.aura': 'soft',
    },
    'goblinMechanic': <String, Object>{
      'v4.eyewear': 'weldingGoggles',
      'v4.armor': 'apron',
      'v4.shoulderProp': 'shoulderRobot',
    },
    'robot': <String, Object>{
      'v4.morphology': 'construct',
      'v4.headwear': 'robotHelmet',
      'v4.armor': 'mechanicalArmor',
      'v4.cybernetics': 'halfFace',
    },
    'mutant': <String, Object>{
      'v4.armor': 'scrapArmor',
      'v4.cybernetics': 'cheekPlate',
      'v4.marking': 'geometric',
    },
    'vampire': <String, Object>{
      'v4.armor': 'blazer',
      'v4.cape': 'longCape',
      'v4.aura': 'dark',
    },
    'zombie': <String, Object>{
      'v4.morphology': 'undead',
      'v4.armor': 'scrapArmor',
      'v4.scar': 'stitches',
      'v4.effect': 'ash',
    },
    'detective': <String, Object>{
      'v4.headwear': 'fedora',
      'v4.armor': 'coat',
      'v4.mouthProp': 'cigarette',
    },
    'musician': <String, Object>{
      'v4.eyewear': 'narrowShades',
      'v4.armor': 'jacket',
      'v4.mouthProp': 'instrumentMouthpiece',
    },
    'doctor': <String, Object>{
      'v4.armor': 'labCoat',
      'v4.faceMask': 'surgicalMask',
    },
    'chef': <String, Object>{
      'v4.headwear': 'chefHat',
      'v4.armor': 'apron',
    },
    'miner': <String, Object>{
      'v4.headwear': 'minerHelmet',
      'v4.armor': 'jumpsuit',
      'v4.shoulderProp': 'flashlight',
    },
    'diver': <String, Object>{
      'v4.headwear': 'diverHelmet',
      'v4.armor': 'jumpsuit',
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
        throw ArgumentError.value(
            value, field.id, 'Value is outside the catalog.');
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
        boost(const <String>[
          'broad',
          'massive',
          'muscular',
          'compact',
          'shortWide'
        ], -bias * 0.08);
        boost(const <String>['slim', 'petite', 'tallNarrow'], bias * 0.07);
        break;
      case 'shoulders.shape':
        boost(const <String>['broad', 'muscular', 'angular', 'straight'],
            -bias * 0.08);
        boost(const <String>['delicate', 'rounded', 'sloping', 'narrow'],
            bias * 0.08);
        break;
      case 'head.shape':
        boost(const <String>[
          'square',
          'wideJaw',
          'angular',
          'rectangular',
          'strongChin'
        ], -bias * 0.07);
        boost(const <String>['heart', 'softOval', 'oval', 'invertedTriangle'],
            bias * 0.07);
        if (age < 20) boost(const <String>['round', 'softOval'], 8);
        break;
      case 'ears.shape':
        for (final key in weights.keys.toList()) {
          if (_fantasyEars.contains(key)) {
            weights[key] = weights[key]! *
                switch (fantasy) {
                  0 => 0.02,
                  1 => 0.25,
                  2 => 0.7,
                  _ => 1.6,
                };
          }
        }
        break;
      case 'eyes.shape':
        boost(const <String>['deepSet', 'narrow', 'realistic', 'rectangular'],
            -bias * 0.035);
        boost(const <String>['almond', 'upturned', 'cartoon', 'wide', 'oval'],
            bias * 0.05);
        if (age < 18) boost(const <String>['cartoon', 'round', 'wide'], 10);
        if (age > 70)
          boost(const <String>['narrow', 'deepSet', 'realistic'], 10);
        if (fantasy > 1)
          boost(
              const <String>['solidBlack', 'robotic', 'vertical', 'triangular'],
              8);
        break;
      case 'eyes.lashes':
        boost(const <String>['long', 'outerLong', 'stylized', 'upper'],
            bias * 0.11);
        boost(const <String>['none', 'single', 'short'], -bias * 0.05);
        break;
      case 'brows.shape':
        boost(const <String>['thick', 'veryThick', 'bushy', 'angular'],
            -bias * 0.08);
        boost(const <String>['thin', 'veryThin', 'rounded', 'highArch'],
            bias * 0.07);
        break;
      case 'nose.shape':
        boost(const <String>['wide', 'hooked', 'largeTip', 'square', 'long'],
            -bias * 0.05);
        boost(const <String>['button', 'smallTip', 'narrow', 'upturned'],
            bias * 0.05);
        if (age > 70) boost(const <String>['long', 'hooked', 'largeTip'], 8);
        break;
      case 'mouth.shape':
        boost(const <String>[
          'full',
          'cupid',
          'lowerFull',
          'upperFull',
          'twoTone'
        ], bias * 0.07);
        boost(const <String>['line', 'thin', 'wideLine'], -bias * 0.04);
        break;
      case 'hair.lengthStyle':
        boost(const <String>['none', 'shaved', 'veryShort', 'short'],
            -bias * 0.04 + age * 0.025);
        boost(const <String>['jaw', 'neck', 'shoulder', 'belowShoulder'],
            bias * 0.055 - age * 0.018);
        break;
      case 'hair.balding':
        if (age < 25) {
          boost(weights.keys.where((key) => key != 'none' && key != 'shaved'),
              -9);
        }
        if (age > 50) {
          boost(const <String>[
            'slightRecession',
            'temples',
            'deepTemples',
            'crownThin',
            'tonsure',
            'frontal',
            'frontCrown',
            'sidesOnly'
          ], (age - 45) * 0.18 - bias * 0.03);
        }
        break;
      case 'facialHair.style':
        boost(weights.keys.where((key) => key != 'none'),
            -bias * 0.11 + (age - 20) * 0.035);
        if (bias > 40) boost(weights.keys.where((key) => key != 'none'), -8);
        break;
      case 'fantasy.hornStyle':
      case 'fantasy.antennaStyle':
        for (final key in weights.keys.toList()) {
          if (key != 'none') {
            weights[key] = weights[key]! *
                switch (fantasy) {
                  0 => 0.01,
                  1 => 0.35,
                  2 => 0.8,
                  _ => 1.7,
                };
          }
        }
        break;
      case 'fantasy.marking':
        for (final key in weights.keys.toList()) {
          if (key != 'none') {
            weights[key] = weights[key]! *
                switch (fantasy) {
                  0 => 0.03,
                  1 => 0.4,
                  2 => 1,
                  _ => 1.8,
                };
          }
        }
        break;
      case 'skin.detail':
        if (age > 60)
          boost(const <String>[
            'foreheadWrinkles',
            'underEyeWrinkles',
            'cheekLines',
            'underEyeShadow'
          ], 10);
        if (fantasy > 1)
          boost(const <String>['mechanicalJoints', 'scales', 'spots'], 7);
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
    if (profile == 'compact' &&
        <String>['head.height', 'neck.length', 'body.heightBias']
            .contains(field.id)) add(-2);
    if (profile == 'compact' &&
        <String>['head.width', 'body.width', 'shoulders.width']
            .contains(field.id)) add(1);
    if (profile == 'elongated' &&
        <String>['head.height', 'neck.length', 'nose.length']
            .contains(field.id)) add(2);
    if (profile == 'elongated' && field.id == 'head.width') add(-1);
    if (profile == 'broad' &&
        <String>[
          'head.width',
          'head.jawWidth',
          'body.width',
          'shoulders.width',
          'neck.widthBottom'
        ].contains(field.id)) add(2);
    if (profile == 'soft' &&
        <String>[
          'head.roundness',
          'cheeks.roundness',
          'mouth.lowerLipThickness'
        ].contains(field.id)) add(1);
    if (profile == 'angular' &&
        <String>['head.angularity', 'head.jawWidth', 'shoulders.width']
            .contains(field.id)) add(1);
    if (<String>[
      'head.jawWidth',
      'head.chinWidth',
      'neck.widthTop',
      'neck.widthBottom',
      'shoulders.width',
      'body.mass'
    ].contains(field.id)) add(-bias / 55);
    if (<String>[
      'eyes.width',
      'eyes.height',
      'mouth.upperLipThickness',
      'mouth.lowerLipThickness',
      'cheeks.roundness',
      'hair.volumeSides'
    ].contains(field.id)) add(bias / 70);
    if (field.id == 'hair.recession')
      add((age - 40).clamp(0, 100) / 18 - bias / 80);
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
    const wearFields = <String>[
      'v4.headwear',
      'v4.eyewear',
      'v4.faceMask',
      'v4.earJewelry',
      'v4.facePiercing',
      'v4.neckJewelry',
      'v4.armor',
      'v4.cape',
      'v4.mouthProp',
      'v4.shoulderProp',
      'v4.cybernetics',
      'v4.scar',
      'v4.marking',
      'v4.effect',
      'v4.aura',
    ];
    final wearRng = root.fork('v41.wear-composition');
    // A full costume is deliberately exceptional: exactly one deterministic
    // stream position out of 30,000 unlocks every accessory family.
    final fullWear = wearRng.nextInt(0, 29999) == 0;
    var occlusion = const _OcclusionState();
    final selectedWear = <String, String>{};
    for (final id in wearFields) {
      final value = values[id]?.toString() ?? 'none';
      if (!canAuto(id) && value != 'none') {
        selectedWear[id] = value;
        occlusion = occlusion.add(_occlusionProfile(id, value));
      } else if (canAuto(id)) {
        setAuto(id, 'none', 'compositionBudget', 1);
      }
    }

    String chooseWear(String id) {
      final field = catalog.fieldById[id]!;
      return _featureChoice(
        field,
        root.fork('v41.feature.$id'),
        world,
        archetype,
        mode,
        values['v4.rarityBias']! as int,
      );
    }

    if (fullWear) {
      for (final id in wearFields) {
        if (!canAuto(id)) continue;
        final value = chooseWear(id);
        setAuto(id, value, 'fullWear', 1);
        selectedWear[id] = value;
      }
    } else {
      final remaining = wearFields.where(canAuto).toList();
      var stage = selectedWear.length;
      while (remaining.isNotEmpty && stage < 5) {
        final continuation =
            _nextWearChance(stage, mode, complexity).clamp(0.0, 1.0);
        if (wearRng.nextDouble() > continuation) break;

        String? acceptedId;
        String? acceptedValue;
        _OcclusionState? acceptedState;
        final candidates = remaining.toList();
        while (candidates.isNotEmpty && acceptedId == null) {
          final index = wearRng.nextInt(0, candidates.length - 1);
          final id = candidates.removeAt(index);
          final value = chooseWear(id);
          if (!_wearCompatible(id, value, selectedWear)) continue;
          final proposed = occlusion.add(_occlusionProfile(id, value));
          final acceptance = _occlusionAcceptance(proposed.score);
          if (wearRng.nextDouble() <= acceptance) {
            acceptedId = id;
            acceptedValue = value;
            acceptedState = proposed;
          }
        }
        if (acceptedId == null ||
            acceptedValue == null ||
            acceptedState == null) {
          break;
        }
        setAuto(acceptedId, acceptedValue, 'occlusionBudget', 1);
        selectedWear[acceptedId] = acceptedValue;
        occlusion = acceptedState;
        remaining.remove(acceptedId);
        stage++;
      }
    }

    if (canAuto('v4.background')) {
      final backgrounds = <String, List<String>>{
        'modern': <String>[
          'solid',
          'blockGradient',
          'verticalSplit',
          'night',
          'rainCity'
        ],
        'fantasy': <String>[
          'forest',
          'dungeon',
          'magicAura',
          'flames',
          'night'
        ],
        'magical': <String>['magicAura', 'forest', 'space', 'night'],
        'scienceFiction': <String>[
          'spaceship',
          'space',
          'terminal',
          'laboratory'
        ],
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

  double _nextWearChance(int stage, String mode, int complexity) {
    const base = <double>[0.78, 0.48, 0.12, 0.02, 0.002];
    if (stage >= base.length) return 0;
    final modeMultiplier = switch (mode) {
      'minimal' => 0.62,
      'natural' => 0.88,
      'diverse' => 1.06,
      'stylized' => 1.08,
      'fantasy' || 'scifi' => 1.12,
      'rareHeavy' => 1.35,
      'chaotic' => 1.5,
      _ => 1.0,
    };
    final complexityMultiplier = 0.85 + complexity / 300;
    return base[stage] * modeMultiplier * complexityMultiplier;
  }

  double _occlusionAcceptance(double score) {
    if (score <= 20) return 1;
    if (score <= 35) return 0.75;
    if (score <= 50) return 0.35;
    if (score <= 65) return 0.10;
    if (score <= 80) return 0.02;
    if (score <= 90) return 0.002;
    return 0;
  }

  String _wearFamily(String id) => switch (id) {
        'v4.headwear' => 'head',
        'v4.eyewear' || 'v4.faceMask' => 'face',
        'v4.earJewelry' || 'v4.facePiercing' || 'v4.neckJewelry' => 'jewelry',
        'v4.armor' || 'v4.cape' => 'torso',
        'v4.mouthProp' || 'v4.shoulderProp' => 'props',
        'v4.cybernetics' || 'v4.scar' || 'v4.marking' => 'marks',
        'v4.effect' || 'v4.aura' => 'effects',
        _ => id,
      };

  bool _wearCompatible(
    String id,
    String value,
    Map<String, String> selected,
  ) {
    final family = _wearFamily(id);
    if (selected.keys.any((other) => _wearFamily(other) == family)) {
      return false;
    }
    final headwear = id == 'v4.headwear' ? value : selected['v4.headwear'];
    final mask = id == 'v4.faceMask' ? value : selected['v4.faceMask'];
    final eyewear = id == 'v4.eyewear' ? value : selected['v4.eyewear'];
    if (headwear != null && _closedHelmets.contains(headwear)) {
      if (mask != null || eyewear != null) return false;
    }
    if (mask != null && _fullFaceMasks.contains(mask) && eyewear != null) {
      return false;
    }
    final armor = id == 'v4.armor' ? value : selected['v4.armor'];
    final cape = id == 'v4.cape' ? value : selected['v4.cape'];
    final shoulder =
        id == 'v4.shoulderProp' ? value : selected['v4.shoulderProp'];
    if (armor != null &&
        _isHeavyArmor(armor) &&
        cape != null &&
        shoulder != null) {
      return false;
    }
    return true;
  }

  bool _isHeavyArmor(String value) => <String>{
        'plateArmor',
        'samuraiArmor',
        'spaceArmor',
        'mechanicalArmor',
        'scrapArmor',
        'tacticalVest',
      }.contains(value);

  _OcclusionProfile _occlusionProfile(String id, String value) {
    if (id == 'v4.headwear') {
      if (_closedHelmets.contains(value)) {
        return const _OcclusionProfile(
            face: 55, eyes: 60, head: 95, silhouette: 70);
      }
      final large = <String>{
        'wizardHat',
        'cowboyHat',
        'topHat',
        'chefHat',
        'hornedCrown',
        'hoodedCowl',
        'veil',
      }.contains(value);
      return _OcclusionProfile(
          head: large ? 72 : 48, silhouette: large ? 65 : 34);
    }
    if (id == 'v4.eyewear') {
      return const _OcclusionProfile(face: 18, eyes: 75, head: 5);
    }
    if (id == 'v4.faceMask') {
      return _fullFaceMasks.contains(value)
          ? const _OcclusionProfile(
              face: 86, eyes: 32, head: 38, silhouette: 18)
          : const _OcclusionProfile(face: 55, eyes: 6, head: 18);
    }
    if (id == 'v4.earJewelry') {
      return const _OcclusionProfile(face: 3, head: 8, silhouette: 4);
    }
    if (id == 'v4.facePiercing') {
      return const _OcclusionProfile(face: 7, eyes: 2);
    }
    if (id == 'v4.neckJewelry') {
      return const _OcclusionProfile(torso: 12, silhouette: 3);
    }
    if (id == 'v4.armor') {
      return _isHeavyArmor(value)
          ? const _OcclusionProfile(torso: 82, arms: 55, silhouette: 56)
          : const _OcclusionProfile(torso: 48, arms: 24, silhouette: 25);
    }
    if (id == 'v4.cape') {
      return const _OcclusionProfile(torso: 32, arms: 16, silhouette: 72);
    }
    if (id == 'v4.mouthProp') {
      return const _OcclusionProfile(face: 13, silhouette: 7);
    }
    if (id == 'v4.shoulderProp') {
      const companions = <String>{
        'cat',
        'parrot',
        'smallDragon',
        'ghost',
        'insect',
        'shoulderRobot',
      };
      return companions.contains(value)
          ? const _OcclusionProfile(torso: 25, arms: 38, silhouette: 76)
          : const _OcclusionProfile(torso: 24, arms: 28, silhouette: 36);
    }
    if (id == 'v4.cybernetics') {
      return const _OcclusionProfile(face: 27, eyes: 16, head: 20);
    }
    if (id == 'v4.scar' || id == 'v4.marking') {
      return const _OcclusionProfile(face: 8, torso: 4);
    }
    if (id == 'v4.aura') {
      return const _OcclusionProfile(silhouette: 28);
    }
    if (id == 'v4.effect') {
      return const _OcclusionProfile(silhouette: 16);
    }
    return const _OcclusionProfile();
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
        'modern': 22,
        'fantasy': 13,
        'scienceFiction': 11,
        'cyberpunk': 12,
        'steampunk': 7,
        'postApocalyptic': 7,
        'historical': 7,
        'military': 6,
        'magical': 5,
        'horror': 4,
        'royal': 3,
        'mixed': 3,
      };
    } else if (field.id == 'v4.randomMode') {
      final world = values['v4.worldStyle'] as String? ?? 'modern';
      weights = <String, double>{
        'natural': 26,
        'diverse': 34,
        'stylized': 16,
        'fantasy': world == 'fantasy' || world == 'magical' ? 22 : 5,
        'scifi': world == 'scienceFiction' || world == 'cyberpunk' ? 22 : 5,
        'chaotic': 5,
        'rareHeavy': 7,
        'minimal': 8,
      };
    } else if (field.id == 'v4.morphology') {
      final world = values['v4.worldStyle'] as String? ?? 'modern';
      final archetype = values['v4.archetype'] as String? ?? 'auto';
      weights = <String, double>{
        'human': 62,
        'skull': world == 'horror' ? 12 : 4,
        'skeleton': world == 'fantasy' || world == 'horror' ? 10 : 2,
        'undead': archetype == 'zombie' || archetype == 'vampire' ? 14 : 4,
        'construct': archetype == 'robot' || world == 'scienceFiction' ? 14 : 3,
      };
    } else {
      final world = values['v4.worldStyle'] as String? ?? 'modern';
      weights = <String, double>{
        'auto': 8,
        'detective': 6,
        'musician': 5,
        'doctor': 4,
        'chef': 3,
        'scientist': 5,
        'mechanic': 5,
        'cowboy': 4,
        'soldier': 4,
        'miner': 3,
        'diver': 2,
      };
      if (world == 'fantasy' || world == 'magical') {
        weights.addAll(<String, double>{
          'knight': 10,
          'wanderingMage': 10,
          'rogue': 7,
          'barbarian': 7,
          'forestElf': 8,
          'goblinMechanic': 5,
          'priest': 5,
          'vampire': 4,
          'zombie': 3,
          'monarch': 4,
        });
      }
      if (world == 'scienceFiction' || world == 'cyberpunk') {
        weights.addAll(<String, double>{
          'streetHacker': 10,
          'spacePilot': 9,
          'robot': 7,
          'mutant': 5,
          'scientist': 7,
          'mechanic': 6,
          'soldier': 5,
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
        if (weights.containsKey(value))
          weights[value] = weights[value]! + amount;
      }
    }

    final fantasy =
        world == 'fantasy' || world == 'magical' || mode == 'fantasy';
    final scifi =
        world == 'scienceFiction' || world == 'cyberpunk' || mode == 'scifi';
    final historic = world == 'historical' || world == 'royal';
    switch (field.id) {
      case 'v4.headwear':
        boost(const <String>[
          'baseballCap',
          'beanie',
          'beret',
          'fedora',
          'winterHat',
          'headband'
        ], world == 'modern' ? 4 : 1);
        if (fantasy)
          boost(const <String>[
            'wizardHat',
            'hood',
            'crown',
            'tiara',
            'wreath',
            'helmetKnightOpen',
            'helmetNorse',
            'helmetSamurai',
            'hornedHelmet'
          ], 6);
        if (scifi)
          boost(const <String>[
            'helmetFuturistic',
            'spaceHelmet',
            'tacticalHelmet',
            'robotHelmet',
            'motorcycleHelmet'
          ], 7);
        if (historic)
          boost(const <String>[
            'topHat',
            'fedora',
            'militaryCap',
            'pirateHat',
            'ceremonialHelmet'
          ], 4);
        for (final helmet in _closedHelmets) {
          if (weights.containsKey(helmet))
            weights[helmet] = weights[helmet]! * 0.32;
        }
        break;
      case 'v4.eyewear':
        boost(const <String>[
          'roundGlasses',
          'ovalGlasses',
          'squareGlasses',
          'rectGlasses',
          'thinFrames',
          'rimless',
          'halfFrames'
        ], 4);
        if (scifi)
          boost(const <String>[
            'cyberVisor',
            'monoVisor',
            'targetingLens',
            'mirrorShades',
            'weldingGoggles'
          ], 8);
        if (historic || archetype == 'pirateCaptain')
          boost(const <String>[
            'monocleLeft',
            'monocleRight',
            'eyePatchLeft',
            'eyePatchRight'
          ], 5);
        break;
      case 'v4.faceMask':
        if (world == 'modern')
          boost(const <String>['surgicalMask', 'faceBandana', 'scarfMask'], 3);
        if (fantasy || historic)
          boost(const <String>[
            'ninjaMask',
            'demonMask',
            'venetianMask',
            'theaterMask',
            'ceremonialMask'
          ], 5);
        if (scifi || world == 'postApocalyptic')
          boost(
              const <String>['respirator', 'gasMask', 'robotMask', 'halfMask'],
              7);
        for (final mask in _fullFaceMasks) {
          if (weights.containsKey(mask)) weights[mask] = weights[mask]! * 0.4;
        }
        break;
      case 'v4.armor':
        if (world == 'modern')
          boost(const <String>[
            'tshirt',
            'shirt',
            'hoodie',
            'jacket',
            'vest',
            'coat',
            'sweater',
            'turtleneck',
            'blazer',
            'uniform',
            'apron',
            'labCoat'
          ], 4);
        if (fantasy || historic)
          boost(const <String>[
            'leatherArmor',
            'chainmail',
            'plateArmor',
            'samuraiArmor',
            'gladiatorArmor',
            'wizardRobe',
            'priestRobe',
            'pirateCoat'
          ], 7);
        if (scifi || world == 'postApocalyptic')
          boost(const <String>[
            'mechanicalArmor',
            'spaceArmor',
            'jumpsuit',
            'scrapArmor'
          ], 8);
        break;
      case 'v4.cape':
        if (fantasy || historic)
          boost(const <String>[
            'shortCape',
            'longCape',
            'furCollar',
            'quiver',
            'swordBack'
          ], 5);
        if (scifi || world == 'postApocalyptic')
          boost(const <String>[
            'backpack',
            'mechanicalTubes',
            'energyRifleBack',
            'mechanicalWings'
          ], 6);
        break;
      case 'v4.cybernetics':
        if (scifi) boost(options, 3);
        break;
      case 'v4.effect':
        boost(const <String>['rain', 'snow', 'dust', 'leaves'], 3);
        if (fantasy)
          boost(const <String>['magicParticles', 'embers', 'fire'], 6);
        if (scifi)
          boost(
              const <String>['glitch', 'electricity', 'sparks', 'hologram'], 7);
        break;
      case 'v4.aura':
        if (fantasy)
          boost(const <String>['soft', 'holy', 'fire', 'ice', 'magic', 'runic'],
              6);
        if (scifi) boost(const <String>['electric', 'holographic'], 7);
        break;
      case 'v4.mouthProp':
        boost(
            const <String>['toothpick', 'lollipop', 'grassBlade', 'flower'], 3);
        if (fantasy || historic) boost(const <String>['pipe', 'rose'], 4);
        if (scifi) boost(const <String>['cyberCable'], 7);
        break;
      case 'v4.shoulderProp':
        boost(const <String>['parrot', 'cat', 'flowerBundle', 'radio'], 3);
        if (fantasy)
          boost(
              const <String>['smallDragon', 'ghost', 'skull', 'energyOrb'], 6);
        if (scifi)
          boost(const <String>['shoulderRobot', 'radio', 'flashlight'], 7);
        const companions = <String>{
          'cat',
          'parrot',
          'smallDragon',
          'ghost',
          'insect',
          'shoulderRobot',
        };
        final companionChance = switch (mode) {
          'natural' => 2,
          'diverse' => 4,
          'stylized' => 3,
          'fantasy' => 6,
          'scifi' => 5,
          'rareHeavy' => 10,
          'chaotic' => 12,
          'minimal' => 0.5,
          _ => 2,
        };
        final allowCompanion =
            rng.nextInt(0, 9999) < (companionChance * 100).round();
        for (final companion in companions) {
          if (!weights.containsKey(companion)) continue;
          weights[companion] = allowCompanion
              ? weights[companion]! * 18
              : weights[companion]! * 0.002;
        }
        break;
    }
    if (mode == 'rareHeavy') {
      for (final option in options)
        weights[option] = weights[option]! + rarity / 35;
    }
    if (mode == 'natural' &&
        <String>['v4.cybernetics', 'v4.aura'].contains(field.id)) {
      for (final option in options) weights[option] = weights[option]! * 0.35;
    }
    return rng.weightedPick(<WeightedValue<String>>[
      for (final option in options)
        WeightedValue<String>(
            option, clampDouble(weights[option]!, 0.05, 1000)),
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
        guard.violation(id, '$reason Manual value was preserved.',
            severity: ValidationSeverity.soft);
        return;
      }
      values[id] = guard.correct(id, before, next, reason);
    }

    void bound(String id, int min, int max, String reason) {
      final value = values[id]! as int;
      set(id, clampInt(value, min, max), reason);
    }

    bound('head.topWidth', 8, values['head.width']! as int,
        'Cranium width fits head.');
    bound('head.templeWidth', 10, values['head.width']! as int,
        'Temple width fits head.');
    bound('head.cheekWidth', 12, (values['head.width']! as int) + 1,
        'Cheek width fits head.');
    bound('head.jawWidth', 8, values['head.cheekWidth']! as int,
        'Jaw fits cheeks.');
    bound(
        'head.chinWidth', 3, values['head.jawWidth']! as int, 'Chin fits jaw.');
    bound(
        'neck.widthTop',
        4,
        clampInt((values['head.jawWidth']! as int) - 2, 4, 50),
        'Neck fits jaw.');
    bound(
        'neck.widthBottom',
        values['neck.widthTop']! as int,
        clampInt((values['shoulders.width']! as int) - 8, 4, 14),
        'Neck fits shoulders.');
    final eyeMax = clampInt(
        ((values['head.cheekWidth']! as int) -
                (values['eyes.spacing']! as int) -
                4) ~/
            2,
        1,
        7);
    bound('eyes.width', 1, eyeMax, 'Eyes fit the face.');
    final spacingMax = clampInt(
        (values['head.cheekWidth']! as int) -
            2 * (values['eyes.width']! as int) -
            3,
        2,
        20);
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
    bound('brows.thickness', 0, (values['brows.height']! as int) <= 1 ? 2 : 3,
        'Brows stay above eyes.');
    bound(
        'nose.width',
        1,
        clampInt((values['eyes.spacing']! as int) - 1, 1, 20),
        'Nose fits between eyes.');
    bound('nose.bridgeWidth', 0, values['nose.width']! as int,
        'Bridge fits nose.');
    bound('nose.tipWidth', 1, (values['nose.width']! as int) + 1,
        'Tip fits nose.');
    bound(
        'mouth.width',
        2,
        clampInt((values['head.jawWidth']! as int) - 2, 2, 20),
        'Mouth fits jaw.');
    bound('mouth.height', 1, 3, 'Mouth fits lower face.');

    if (<String>['fullBald', 'sidesOnly', 'tuft']
        .contains(values['hair.balding'])) {
      if (values['hair.balding'] != 'tuft')
        set('hair.fringe', 'none', 'Balding removes fringe.');
      set('hair.parting', 'none', 'Balding removes parting.');
    }
    if (values['hair.balding'] == 'fullBald') {
      set('hair.lengthStyle', 'none', 'Full baldness removes hair length.');
      set('hair.length', 0, 'Full baldness removes back mass.');
      set('hair.volumeTop', 0, 'Full baldness removes top volume.');
    }
    if (values['hair.lengthStyle'] == 'none' &&
        values['hair.balding'] == 'none') {
      set('hair.balding', 'fullBald',
          'No hair is represented by full baldness.');
    }
    if (request.settings.fantasy == FantasyLevel.none &&
        _fantasyEars.contains(values['ears.shape'])) {
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
        'head.asymmetry',
        'ears.asymmetry',
        'eyes.asymmetry',
        'brows.asymmetry',
        'nose.asymmetry',
        'mouth.asymmetry',
        'shoulders.asymmetry',
        'fantasy.hornAsymmetry',
        'v4.accessoryAsymmetry',
      ]) {
        set(id, 0, 'Symmetry removes automatic asymmetry.');
      }
    }
  }
}

final class _OcclusionProfile {
  const _OcclusionProfile({
    this.face = 0,
    this.eyes = 0,
    this.head = 0,
    this.torso = 0,
    this.arms = 0,
    this.silhouette = 0,
  });

  final double face;
  final double eyes;
  final double head;
  final double torso;
  final double arms;
  final double silhouette;
}

final class _OcclusionState {
  const _OcclusionState({
    this.face = 0,
    this.eyes = 0,
    this.head = 0,
    this.torso = 0,
    this.arms = 0,
    this.silhouette = 0,
    this.overlapPenalty = 0,
  });

  final double face;
  final double eyes;
  final double head;
  final double torso;
  final double arms;
  final double silhouette;
  final double overlapPenalty;

  double get score {
    final weighted = face * 2.0 +
        eyes * 2.5 +
        head * 1.3 +
        torso +
        arms * 0.8 +
        silhouette * 1.5;
    return clampDouble(weighted / 9.1 + overlapPenalty, 0, 100);
  }

  _OcclusionState add(_OcclusionProfile next) {
    double union(double current, double addition) =>
        current + (100 - current) * addition / 100;
    double overlap(double current, double addition, double weight) {
      final shared = current < addition ? current : addition;
      return shared * weight * 0.035;
    }

    final penalty = overlapPenalty +
        overlap(face, next.face, 2.0) +
        overlap(eyes, next.eyes, 2.5) +
        overlap(head, next.head, 1.3) +
        overlap(torso, next.torso, 1.0) +
        overlap(arms, next.arms, 0.8) +
        overlap(silhouette, next.silhouette, 1.5);
    return _OcclusionState(
      face: union(face, next.face),
      eyes: union(eyes, next.eyes),
      head: union(head, next.head),
      torso: union(torso, next.torso),
      arms: union(arms, next.arms),
      silhouette: union(silhouette, next.silhouette),
      overlapPenalty: penalty,
    );
  }
}
