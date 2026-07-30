import 'dart:io';

import 'package:avatar_genome/avatar_genome.dart';
import 'package:avatar_genome/avatar_genome_io.dart';

/// Generates deterministic contact sheets used to review hierarchical motion.
///
/// Companion rows contain, in order, idle, talking, celebration and sleeping.
/// Each clip contributes eight frames. The clothing sheet uses one eight-frame
/// celebration clip per seed and deliberately alternates extreme garments.
void main(List<String> arguments) {
  final output = Directory(
    arguments.isEmpty ? 'build/render-graph-matrix' : arguments.first,
  )..createSync(recursive: true);
  final generator = AvatarGenerator();

  const companions = <String>[
    'cat',
    'parrot',
    'smallDragon',
    'ghost',
    'insect',
    'shoulderRobot',
  ];
  const companionAnimations = <String>[
    'idle',
    'talking',
    'celebration',
    'sleeping',
  ];
  final companionFrames = <AvatarResult>[];
  for (final companion in companions) {
    for (final animation in companionAnimations) {
      companionFrames.addAll(
        generator
            .generateAnimation(
              AvatarRequest(
                seed: 'visual-companion-matrix',
                overrides: <String, Object>{
                  'v4.shoulderProp': companion,
                  'v4.propSide': 1,
                  'v4.animation': animation,
                  'body.armVisibility': 5,
                },
              ),
              frameCount: 8,
            )
            .frames,
      );
    }
  }
  final companionSheet = AvatarAnimation(
    frames: companionFrames,
    frameDuration: const Duration(milliseconds: 125),
  );
  File('${output.path}/companions.png').writeAsBytesSync(
    const AvatarSpriteSheetCodec(columns: 32, scale: 2).encode(companionSheet),
  );
  const cropX = 29;
  const cropY = 8;
  const cropWidth = 19;
  const cropHeight = 30;
  final closeups = IndexedImage(
    width: cropWidth * 32,
    height: cropHeight * companions.length,
  );
  for (var index = 0; index < companionFrames.length; index++) {
    final source = companionFrames[index].image;
    final column = index % 32;
    final row = index ~/ 32;
    for (var y = 0; y < cropHeight; y++) {
      for (var x = 0; x < cropWidth; x++) {
        closeups.setPixel(
          column * cropWidth + x,
          row * cropHeight + y,
          source.get(cropX + x, cropY + y),
        );
      }
    }
  }
  File('${output.path}/companion-closeups.png').writeAsBytesSync(
    const AvatarPngCodec().encodeImage(
      closeups,
      companionFrames.first.palette,
      scale: 4,
    ),
  );

  const armor = <String>[
    'shirt',
    'hoodie',
    'plateArmor',
    'samuraiArmor',
    'wizardRobe',
    'spaceArmor',
    'labCoat',
    'mechanicalArmor',
  ];
  for (var index = 0; index < 20; index++) {
    final animation = generator.generateAnimation(
      AvatarRequest(
        seed: 'visual-clothing-$index',
        overrides: <String, Object>{
          'v4.animation': 'celebration',
          'v4.armor': armor[index % armor.length],
          'body.armVisibility': 5,
          'v4.headwear': index.isEven ? 'wizardHat' : 'spaceHelmet',
          'v4.faceMask': index.isOdd ? 'gasMask' : 'none',
        },
      ),
      frameCount: 8,
    );
    File(
      '${output.path}/clothing-${index.toString().padLeft(2, '0')}.png',
    ).writeAsBytesSync(
      const AvatarSpriteSheetCodec(columns: 8, scale: 2).encode(animation),
    );
  }
}
