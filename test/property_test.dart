import 'package:avatar_genome/avatar_genome.dart';
import 'package:test/test.dart';

void main() {
  test('a broad deterministic seed sample stays within core invariants', () {
    final generator = AvatarGenerator();
    final hashes = <String>{};
    for (var index = 0; index < 256; index++) {
      final result = generator.generate(
        AvatarRequest(
          seed: 'property-$index',
          settings: GenomeSettings(
            fantasy: FantasyLevel.values[index % FantasyLevel.values.length],
            symmetry: index.isEven,
          ),
        ),
      );
      hashes.add(result.imageHash);
      expect(result.image.usedColorCount, lessThanOrEqualTo(32));
      expect(result.image.indices.length, 2304);
      expect(result.layout.landmarks, isNotEmpty);
      expect(result.layers, isNotEmpty);
      expect(result.validation.isValid, isTrue);
      expect(
        result.validation.entries
            .where((entry) => entry.id.startsWith('empty.'))
            .isEmpty,
        isTrue,
      );
      for (final slot in result.layout.slots.values) {
        final bounds = slot.bounds;
        if (bounds == null) continue;
        expect(bounds.x, inInclusiveRange(0, 47));
        expect(bounds.y, inInclusiveRange(0, 47));
        expect(bounds.width, inInclusiveRange(1, 48));
        expect(bounds.height, inInclusiveRange(1, 48));
        expect(bounds.right, lessThanOrEqualTo(47));
        expect(bounds.bottom, lessThanOrEqualTo(47));
      }
    }
    expect(hashes.length, greaterThan(240));
  });

  test('new morphology and accessory families remain distinct and renderable',
      () {
    final generator = AvatarGenerator();
    final profiles = <String>[
      'human',
      'skull',
      'skeleton',
      'undead',
      'construct'
    ];
    final profileHashes = <String>{};
    for (final profile in profiles) {
      final result = generator.generate(AvatarRequest(
        seed: 'profile-$profile',
        overrides: <String, Object>{'v4.morphology': profile},
      ));
      profileHashes.add(result.imageHash);
      if (profile != 'human') {
        expect(result.layers.any((layer) => layer.id == 'morphology.plate'),
            isTrue);
      }
      expect(result.validation.isValid, isTrue);
    }
    expect(profileHashes.length, profiles.length);

    const masks = <String>[
      'skullPlate',
      'boneJaw',
      'plagueMask',
      'oniMask',
      'porcelainMask',
    ];
    final maskHashes = <String>{};
    for (final mask in masks) {
      final result = generator.generate(AvatarRequest(
        seed: 'mask-$mask',
        overrides: <String, Object>{'v4.faceMask': mask},
      ));
      maskHashes.add(result.imageHash);
      expect(result.validation.isValid, isTrue);
    }
    expect(maskHashes.length, masks.length);
  });

  test('occlusion budget keeps ordinary wear readable and full wear rare', () {
    final generator = AvatarGenerator();
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
    const companionValues = <String>{
      'cat',
      'parrot',
      'smallDragon',
      'ghost',
      'insect',
      'shoulderRobot',
    };
    const closedHelmets = <String>{
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
    var atMostTwo = 0;
    var companions = 0;
    for (var index = 0; index < 1000; index++) {
      final result = generator.generate(AvatarRequest(
        seed: 'wear-distribution-$index',
        overrides: const <String, Object>{
          'v4.archetype': 'auto',
          'v4.randomMode': 'natural',
        },
      ));
      final active = wearFields
          .where((id) => result.genome.values[id]?.toString() != 'none')
          .length;
      if (active <= 2) atMostTwo++;
      if (companionValues
          .contains(result.genome.values['v4.shoulderProp']?.toString())) {
        companions++;
      }
      if (closedHelmets
          .contains(result.genome.values['v4.headwear']?.toString())) {
        expect(result.genome.values['v4.eyewear'], 'none');
        expect(result.genome.values['v4.faceMask'], 'none');
      }
    }
    expect(atMostTwo, greaterThan(930));
    expect(companions, lessThan(30));

    String? fullWearSeed;
    for (var index = 0; index < 300000; index++) {
      final seed = 'full-wear-$index';
      final stream = RandomStream(
        _testFnv1a32('${AvatarGenomeVersion.generator}:$seed'),
      ).fork('v41.wear-composition');
      if (stream.nextInt(0, 29999) == 0) {
        fullWearSeed = seed;
        break;
      }
    }
    expect(fullWearSeed, isNotNull);
    final full = generator.generate(AvatarRequest(
      seed: fullWearSeed!,
      overrides: const <String, Object>{'v4.archetype': 'auto'},
    ));
    expect(
      full.genome.sources.values.where((source) => source.source == 'fullWear'),
      isNotEmpty,
    );
  });
}

int _testFnv1a32(String text) {
  var hash = 0x811c9dc5;
  for (final codeUnit in text.codeUnits) {
    hash ^= codeUnit;
    hash = (hash * 0x01000193) & 0xffffffff;
  }
  return hash & 0xffffffff;
}
