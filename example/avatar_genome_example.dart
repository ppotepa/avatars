import 'dart:io';

import 'package:avatar_genome/avatar_genome_io.dart';

Future<void> main() async {
  final generator = AvatarGenerator();
  const request = AvatarRequest(
    seed: 'player-42',
    settings: GenomeSettings(
      presentation: AvatarPresentation.neutral,
      fantasy: FantasyLevel.moderate,
    ),
  );

  final avatar = generator.generate(request);
  final animation = generator.generateAnimation(request, frameCount: 8);

  await Directory('build/example').create(recursive: true);
  await File('build/example/avatar.png').writeAsBytes(
    const AvatarPngCodec(scale: 8).encode(avatar),
  );
  await File('build/example/avatar.svg').writeAsString(
    const AvatarSvgCodec(scale: 8, includeMetadata: true).encode(avatar),
  );
  await File('build/example/avatar.json').writeAsString(
    const AvatarJsonCodec().encode(avatar),
  );
  await File('build/example/avatar-sprite-sheet.png').writeAsBytes(
    const AvatarSpriteSheetCodec(columns: 4, scale: 4).encode(animation),
  );

  stdout.writeln('Genome fields: ${avatar.genome.values.length}');
  stdout.writeln('Image hash: ${avatar.imageHash}');
  stdout.writeln('Validation passed: ${avatar.validation.isValid}');
}
