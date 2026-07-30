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
      'solid', 'blockGradient', 'verticalSplit', 'horizontalSplit',
      'checker', 'dots', 'sunset', 'sunrise', 'citySkyline',
      'oceanHorizon', 'rainCity', 'libraryShelves',
    },
    'fantasy': <String>{
      'forest', 'dungeon', 'magicAura', 'flames', 'night',
      'factionSymbol', 'castleWall', 'runeCircle', 'floatingIslands',
      'crystalCave', 'demonicGate',
    },
    'magical': <String>{
      'magicAura', 'forest', 'space', 'night', 'factionSymbol',
      'runeCircle', 'portalRift', 'astralPlane', 'celestialHall',
    },
    'scienceFiction': <String>{
      'spaceship', 'space', 'terminal', 'laboratory', 'pixelNoise',
      'spaceStation', 'starshipBridge', 'dataGrid', 'warpTunnel',
      'alienPlanet',
    },
    'cyberpunk': <String>{
      'neonCity', 'terminal', 'rainCity', 'laboratory', 'pixelNoise',
      'citySkyline', 'dataGrid', 'voidStatic',
    },
    'postApocalyptic': <String>{
      'flames', 'solid', 'pixelNoise', 'sunset', 'factionSymbol',
      'volcanicSky', 'factorySmoke', 'deadForest', 'mistSwamp',
    },
    'historical': <String>{
      'solid', 'sunset', 'forest', 'factionSymbol', 'castleWall',
      'throneRoom', 'cathedralWindow', 'libraryShelves',
    },
    'military': <String>{
      'solid', 'checker', 'rainCity', 'factionSymbol', 'factorySmoke',
      'citySkyline',
    },
    'horror': <String>{
      'night', 'dungeon', 'forest', 'pixelNoise', 'graveyard',
      'bloodMoon', 'mistSwamp', 'deadForest', 'voidStatic',
    },
    'royal': <String>{
      'solid', 'factionSymbol', 'sunset', 'throneRoom',
      'cathedralWindow', 'celestialHall',
    },
  };

  Map<String, double> weights(
    ParameterDefinition field,
    String world,
  ) {
    final preferred = preferredByWorld[world] ?? const <String>{};
    return <String, double>{
      for (final option in field.options)
        option.value: preferred.contains(option.value) ? 7 : 1,
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

  static const Set<String> _v42Optional = <String>{
    'v4.halo',
    'v4.headAdornment',
    'v4.sideHeadFeature',
    'v4.creatureTrait',
    'v4.symbolOverlay',
    'v4.backAdornment',
    'v4.extraShoulderProp',
    'v4.relic',
    'v4.weather',
    'v4.backgroundEvent',
    'v4.cosmicLayer',
    'v4.backFlames',
    'v4.ambientOverlay',
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
      final field = catalog.fieldById[id];
      if (field == null || !field.accepts(value)) return;
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
      for (final id in _v42Optional) {
        setAuto(id, 'none', 'minimalComplexity');
      }
    }

    _selectBackground(values, root, automatic, setAuto);
    _coordinateAnimation(values, root, automatic, setAuto);
    _coordinateExpressions(request, values, root, automatic, setAuto);
    _composeV42Features(request, values, root, automatic, setAuto);

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

  void _coordinateExpressions(
    AvatarRequest request,
    Map<String, Object> values,
    RandomStream root,
    bool Function(String id) automatic,
    void Function(String id, Object value, String reason) setAuto,
  ) {
    if (automatic('v4.expression')) {
      final choices = <WeightedValue<String>>[
        const WeightedValue<String>('neutral', 16),
        const WeightedValue<String>('softSmile', 13),
        const WeightedValue<String>('smile', 10),
        const WeightedValue<String>('serious', 9),
        const WeightedValue<String>('confident', 7),
        const WeightedValue<String>('determined', 6),
        const WeightedValue<String>('suspicious', 4),
        const WeightedValue<String>('sleepy', 4),
        const WeightedValue<String>('surprised', 3),
        const WeightedValue<String>('mischievous', 3),
        const WeightedValue<String>('bigSmile', 3),
        const WeightedValue<String>('angry', 2),
        const WeightedValue<String>('sad', 2),
        const WeightedValue<String>('evilSmile', 1),
        const WeightedValue<String>('manic', 0.5),
      ];
      if (request.settings.presentation == AvatarPresentation.feminine) {
        choices
          ..add(const WeightedValue<String>('blushingHappy', 4))
          ..add(const WeightedValue<String>('shy', 3));
      }
      setAuto(
        'v4.expression',
        root.fork('v42.expression').weightedPick(choices),
        'coordinatedExpression',
      );
    }

    for (final id in const <String>[
      'v4.eyeExpression',
      'v4.browExpression',
      'v4.mouthExpression',
    ]) {
      setAuto(id, 'auto', 'expressionPreset');
    }

    final expression = values['v4.expression'] as String? ?? 'neutral';
    if (automatic('v4.emotionMark')) {
      var mark = 'none';
      if (expression == 'crying') mark = 'tearBoth';
      if (expression == 'blushingHappy' || expression == 'shy') {
        mark = 'blush';
      }
      if (expression == 'angry' || expression == 'furious') {
        mark = 'angerMark';
      }
      if (expression == 'sleepy') mark = 'sleepBubble';
      if (root.fork('v42.expression.mark').nextBool(0.12)) {
        mark = root.fork('v42.expression.mark.value').pick(<String>[
          'sparkleMarks',
          'heartMark',
          'cheekStars',
          'magicFreckles',
        ]);
      }
      setAuto('v4.emotionMark', mark, 'coordinatedExpressionMark');
    }

    if (automatic('v4.faceAnimation')) {
      var animation = 'none';
      if (<String>['laugh', 'openLaugh', 'manic'].contains(expression)) {
        animation = 'laugh';
      } else if (<String>[
        'smirkLeft', 'smirkRight', 'confident', 'mischievous', 'evilSmile',
      ].contains(expression)) {
        animation = 'smirk';
      } else if (<String>['angry', 'furious'].contains(expression)) {
        animation = 'angry';
      } else if (<String>['sleepy', 'tired'].contains(expression)) {
        animation = 'sleepy';
      } else if (<String>['surprised', 'shocked'].contains(expression)) {
        animation = 'surprised';
      } else if (<String>[
        'smile', 'bigSmile', 'blushingHappy',
      ].contains(expression)) {
        animation = 'happy';
      } else if (root.fork('v42.face.talk').nextBool(0.08)) {
        animation = 'talk';
      }
      setAuto('v4.faceAnimation', animation, 'compatibleFaceAnimation');
    }

    final faceAnimation = values['v4.faceAnimation'] as String? ?? 'none';
    if (faceAnimation == 'talk') {
      setAuto('v4.mouthMotionStyle', 'talkNormal', 'compatibleMouthMotion');
    } else if (faceAnimation == 'laugh') {
      setAuto('v4.mouthMotionStyle', 'laughLoop', 'compatibleMouthMotion');
    } else if (faceAnimation == 'sleepy') {
      setAuto('v4.mouthMotionStyle', 'breathLoop', 'compatibleMouthMotion');
    } else {
      setAuto('v4.mouthMotionStyle', 'none', 'compatibleMouthMotion');
    }
  }

  void _composeV42Features(
    AvatarRequest request,
    Map<String, Object> values,
    RandomStream root,
    bool Function(String id) automatic,
    void Function(String id, Object value, String reason) setAuto,
  ) {
    final complexity = values['v4.complexity']! as int;
    final mode = values['v4.randomMode']! as String;
    final world = values['v4.worldStyle']! as String;
    final fantasy = request.settings.fantasy.index;
    final chaotic = mode == 'chaotic' || mode == 'rareHeavy';
    final density = clampDouble(complexity / 100, 0, 1);

    bool chance(String namespace, double baseChance) =>
        root.fork('v42.$namespace').nextBool(clampDouble(
          baseChance + density * 0.35 + (chaotic ? 0.12 : 0),
          0,
          0.92,
        ));

    void optional(
      String id,
      bool enabled,
      Set<String> preferred,
      String namespace,
    ) {
      if (!automatic(id)) return;
      if (!enabled) {
        setAuto(id, 'none', 'v42CompositionBudget');
        return;
      }
      final field = catalog.fieldById[id]!;
      final choices = <WeightedValue<String>>[
        for (final option in field.options.where(
          (option) => option.value != 'none',
        ))
          WeightedValue<String>(
            option.value,
            preferred.contains(option.value) ? 7 : 1,
          ),
      ];
      if (choices.isNotEmpty) {
        setAuto(
          id,
          root.fork('v42.$namespace.value').weightedPick(choices),
          'v42WorldFeature',
        );
      }
    }

    final fantasyWorld = world == 'fantasy' || world == 'magical';
    final scifiWorld = world == 'scienceFiction' || world == 'cyberpunk';
    final horrorWorld = world == 'horror';
    final royalWorld = world == 'royal' || world == 'historical';

    optional(
      'v4.halo',
      chance('halo', 0.04 + fantasy * 0.05),
      fantasyWorld
          ? <String>{'runicHalo', 'holySpikes', 'flameHalo', 'cosmicHalo'}
          : scifiWorld
              ? <String>{
                  'mechanicalHalo', 'neonHalo', 'glitchHalo', 'electricHalo',
                }
              : royalWorld
                  ? <String>{'simpleRing', 'crownHalo', 'solarDisc'}
                  : horrorWorld
                      ? <String>{'brokenHalo', 'thornHalo', 'glitchHalo'}
                      : <String>{'thinHalo', 'simpleRing'},
      'halo',
    );
    optional(
      'v4.headAdornment',
      chance('headAdornment', 0.08),
      fantasyWorld
          ? <String>{'foreheadGem', 'sigil', 'runeStrip', 'moonCrescent'}
          : scifiWorld
              ? <String>{'mechanicalPlate', 'visorPlate', 'crackGlow'}
              : <String>{'bandageForehead', 'warPaintStripe', 'ritualDots'},
      'headAdornment',
    );
    optional(
      'v4.sideHeadFeature',
      chance('sideHeadFeature', 0.04 + fantasy * 0.03),
      scifiWorld
          ? <String>{'mechanicalPort', 'audioReceiver', 'orbitalNode'}
          : fantasyWorld
              ? <String>{
                  'finFrill', 'leafEarsAccent', 'featherTuft', 'smallHorns',
                }
              : <String>{'furTufts'},
      'sideHeadFeature',
    );
    optional(
      'v4.creatureTrait',
      chance('creatureTrait', fantasy == 0 ? 0.015 : 0.07 + fantasy * 0.03),
      fantasyWorld
          ? <String>{
              'fangs', 'whiskers', 'scales', 'crystalGrowth', 'glowVeins',
            }
          : horrorWorld
              ? <String>{
                  'fangs', 'voidCracks', 'stoneSkin', 'slimeDroplets',
                }
              : scifiWorld
                  ? <String>{'glowVeins', 'voidCracks'}
                  : <String>{'whiskers', 'catNose'},
      'creatureTrait',
    );
    optional(
      'v4.symbolOverlay',
      chance('symbolOverlay', 0.05),
      fantasyWorld
          ? <String>{'runes', 'magicCircle', 'glyphs', 'constellationLines'}
          : scifiWorld
              ? <String>{
                  'crosshair', 'targetLock', 'electroLines',
                  'warningTriangles',
                }
              : horrorWorld
                  ? <String>{'chains', 'thorns', 'spiral'}
                  : <String>{'stars', 'musicNotes', 'petalSwirls'},
      'symbolOverlay',
    );
    optional(
      'v4.backAdornment',
      chance('backAdornment', 0.05),
      fantasyWorld
          ? <String>{
              'wingsFeatherRoyal', 'wingsBatLarge', 'crystalClusterBack',
              'spiritRibbon',
            }
          : scifiWorld
              ? <String>{
                  'jetpackSmall', 'energyBackpack', 'wingsEnergy',
                  'wingsHologram',
                }
              : royalWorld
                  ? <String>{'bannerBack', 'capeRoyal', 'prayerScrollBack'}
                  : <String>{'capeTorn', 'boneSpineBack'},
      'backAdornment',
    );
    optional(
      'v4.extraShoulderProp',
      chance('companion', 0.045),
      fantasyWorld
          ? <String>{
              'owl', 'raven', 'mushroomBuddy', 'floatingSkull',
              'bookFamiliar',
            }
          : scifiWorld
              ? <String>{'miniDrone', 'starOrb'}
              : horrorWorld
                  ? <String>{'crow', 'bat', 'floatingSkull', 'candle'}
                  : <String>{'frog', 'cloudSpirit'},
      'companion',
    );
    optional(
      'v4.relic',
      chance('relic', 0.06),
      fantasyWorld
          ? <String>{
              'crystalPendant', 'sacredRelic', 'prayerBeads',
              'boneNecklace',
            }
          : scifiWorld
              ? <String>{'orbPendant', 'factionSeal', 'medalCluster'}
              : royalWorld
                  ? <String>{'amuletLarge', 'multipleChains', 'medalCluster'}
                  : <String>{'fangNecklace', 'voidLocket'},
      'relic',
    );

    optional(
      'v4.weather',
      chance('weather', 0.10),
      world == 'postApocalyptic'
          ? <String>{'ash', 'dust', 'embers', 'sandstorm'}
          : world == 'cyberpunk'
              ? <String>{'heavyRain', 'glitchNoise', 'sparks'}
              : fantasyWorld
                  ? <String>{
                      'petals', 'fireflies', 'magicDust', 'fallingLeaves',
                    }
                  : horrorWorld
                      ? <String>{'fog', 'mist', 'ash'}
                      : <String>{'rain', 'snow', 'lightDrizzle'},
      'weather',
    );
    optional(
      'v4.cosmicLayer',
      chance('cosmic', scifiWorld || fantasyWorld ? 0.09 : 0.025),
      scifiWorld
          ? <String>{
              'starsDense', 'nebula', 'planets', 'warpTunnel',
              'holographicStars',
            }
          : fantasyWorld
              ? <String>{
                  'auroraSky', 'moonAndStars', 'constellation',
                  'cosmicDust',
                }
              : <String>{'starsSparse', 'shootingStars'},
      'cosmic',
    );
    optional(
      'v4.backFlames',
      chance(
        'flames',
        world == 'postApocalyptic' || horrorWorld ? 0.09 : 0.025,
      ),
      horrorWorld
          ? <String>{'hellfire', 'smokeAndFire', 'ritualFire'}
          : scifiWorld
              ? <String>{'energyFire', 'blueFire'}
              : fantasyWorld
                  ? <String>{'ritualFire', 'greenFire', 'blueFire'}
                  : <String>{'smallFlames', 'torchGlow'},
      'flames',
    );
    optional(
      'v4.ambientOverlay',
      chance('ambient', 0.07),
      horrorWorld
          ? <String>{'deepFog', 'voidVeil', 'stormClouds'}
          : scifiWorld
              ? <String>{'neonMist', 'heatHaze', 'toxicCloud'}
              : fantasyWorld
                  ? <String>{'dreamHaze', 'holyLight', 'softFog'}
                  : <String>{'softFog', 'dustVeil', 'underwaterLight'},
      'ambient',
    );
    optional(
      'v4.backgroundEvent',
      chance('event', 0.035),
      world == 'cyberpunk'
          ? <String>{'neonFlicker', 'screenScan', 'alarmFlash'}
          : world == 'postApocalyptic'
              ? <String>{'fireBurst', 'lavaPulse', 'shadowSweep'}
              : fantasyWorld
                  ? <String>{'portalPulse', 'starTwinkleBurst', 'cometPass'}
                  : horrorWorld
                      ? <String>{
                          'lightningBranch', 'ghostPass', 'eclipsePulse',
                        }
                      : <String>{
                          'lightningFlash', 'sunPulse', 'moonGlow',
                        },
      'event',
    );

    final halo = values['v4.halo'] as String? ?? 'none';
    if (halo == 'none') {
      setAuto('v4.eventMotion', 'none', 'compatibleEventMotion');
    } else if (automatic('v4.eventMotion')) {
      setAuto(
        'v4.eventMotion',
        root.fork('v42.halo.motion').nextBool(0.55)
            ? 'haloPulse'
            : 'haloOrbit',
        'compatibleEventMotion',
      );
    }
  }
}
