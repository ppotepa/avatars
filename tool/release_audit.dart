import 'dart:convert';
import 'dart:io';

import 'package:avatar_genome/avatar_genome.dart';

void main() {
  final failures = <String>[];
  final pubspec = File('pubspec.yaml').readAsStringSync();
  final versionMatch = RegExp(r'^version:\s*(\S+)', multiLine: true)
      .firstMatch(pubspec);
  final packageVersion = versionMatch?.group(1);
  if (packageVersion == null) {
    failures.add('pubspec.yaml does not declare a package version.');
  }

  final catalog = ParameterCatalog.current;
  if (catalog.categoryCount != 30) {
    failures.add('Expected 30 categories, got ${catalog.categoryCount}.');
  }
  if (catalog.fieldCount != 275) {
    failures.add('Expected 275 fields, got ${catalog.fieldCount}.');
  }

  final contract = <String, Object?>{
    'packageVersion': packageVersion,
    'requestSchema': AvatarGenomeVersion.requestSchema,
    'resultSchema': AvatarGenomeVersion.resultSchema,
    'catalogVersion': AvatarGenomeVersion.catalog,
    'generatorVersion': AvatarGenomeVersion.generator,
    'paletteVersion': AvatarGenomeVersion.palette,
    'categoryCount': catalog.categoryCount,
    'fieldCount': catalog.fieldCount,
  };

  stdout.writeln(const JsonEncoder.withIndent('  ').convert(contract));
  if (failures.isNotEmpty) {
    for (final failure in failures) {
      stderr.writeln('- $failure');
    }
    exitCode = 1;
  }
}
