import 'dart:convert';
import 'dart:io';

import 'package:avatar_genome/avatar_genome_io.dart';

Future<void> main(List<String> arguments) async {
  if (arguments.contains('--help') || arguments.contains('-h')) {
    _usage();
    return;
  }

  final seed = _value(arguments, '--seed') ??
      'avatar-${DateTime.now().microsecondsSinceEpoch}';
  final outputDirectory = Directory(_value(arguments, '--out') ?? 'build/avatar');
  final scale = int.tryParse(_value(arguments, '--scale') ?? '') ?? 8;
  final preset = _value(arguments, '--preset');
  final frames = int.tryParse(_value(arguments, '--frames') ?? '') ?? 0;

  var request = AvatarRequest(seed: seed);
  if (preset != null) {
    request = AvatarPresetService().applyWholePreset(request, preset);
  }

  final generator = AvatarGenerator();
  final result = generator.generate(request);
  await outputDirectory.create(recursive: true);
  await File('${outputDirectory.path}/avatar.png').writeAsBytes(
    AvatarPngCodec(scale: scale).encode(result),
  );
  await File('${outputDirectory.path}/avatar.svg').writeAsString(
    AvatarSvgCodec(scale: scale, includeMetadata: true).encode(result),
  );
  await File('${outputDirectory.path}/avatar.json').writeAsString(
    const JsonEncoder.withIndent('  ').convert(result.toJson()),
  );
  await File('${outputDirectory.path}/request.json').writeAsString(
    const JsonEncoder.withIndent('  ').convert(request.toJson()),
  );

  if (frames > 0) {
    final animation = generator.generateAnimation(request, frameCount: frames);
    await File('${outputDirectory.path}/avatar-sprite-sheet.png').writeAsBytes(
      AvatarSpriteSheetCodec(scale: scale).encode(animation),
    );
    await File('${outputDirectory.path}/avatar-sprite-sheet.json').writeAsString(
      const JsonEncoder.withIndent('  ').convert(
        AvatarSpriteSheetCodec(scale: scale).metadata(animation),
      ),
    );
  }

  stdout.writeln('Generated ${result.imageHash} from seed "$seed".');
  if (!result.validation.isValid) {
    stderr.writeln(
      'Guard reported ${result.validation.hardViolationCount} hard violations.',
    );
    exitCode = 2;
  }
}

String? _value(List<String> arguments, String name) {
  final index = arguments.indexOf(name);
  if (index < 0 || index + 1 >= arguments.length) return null;
  return arguments[index + 1];
}

void _usage() {
  stdout.writeln('''
Generate a deterministic Avatar Genome image.

Usage:
  dart run tool/generate.dart --seed player-42 [options]

Options:
  --seed <text>      Genome seed.
  --out <directory>  Output directory. Default: build/avatar
  --scale <integer>  PNG/SVG pixel scale. Default: 8
  --preset <id>      Whole-avatar preset from ParameterCatalog.v41.
  --frames <count>   Also export an animation sprite sheet.
  -h, --help         Show this help.
''');
}
