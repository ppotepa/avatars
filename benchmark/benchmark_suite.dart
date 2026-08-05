import 'dart:convert';
import 'dart:io';

import 'package:avatar_genome/avatar_genome.dart';

void main(List<String> arguments) {
  final jsonOutput = arguments.contains('--json');
  final generator = AvatarGenerator();
  final scenarios = <String, void Function()> {
    'static48UniqueSeeds': () {
      for (var index = 0; index < 100; index++) {
        generator.generate(AvatarRequest(seed: 'bench-48-$index'));
      }
    },
    'static96UniqueSeeds': () {
      for (var index = 0; index < 25; index++) {
        generator.generate(AvatarRequest(
          seed: 'bench-96-$index',
          rendering: const AvatarRenderSettings(size: 96),
        ));
      }
    },
    'animation16Frames': () {
      generator.generateAnimation(
        AvatarRequest(seed: 'bench-animation'),
        frameCount: 16,
      );
    },
  };

  for (final action in scenarios.values) {
    action();
  }

  final results = <Map<String, Object>>[];
  for (final entry in scenarios.entries) {
    final stopwatch = Stopwatch()..start();
    entry.value();
    stopwatch.stop();
    results.add(<String, Object>{
      'scenario': entry.key,
      'elapsedMicroseconds': stopwatch.elapsedMicroseconds,
      'dartVersion': Platform.version,
      'processors': Platform.numberOfProcessors,
    });
  }

  if (jsonOutput) {
    stdout.writeln(jsonEncode(results));
    return;
  }
  for (final result in results) {
    stdout.writeln(
      '${result['scenario']}: ${result['elapsedMicroseconds']} us',
    );
  }
}
