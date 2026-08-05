import 'dart:convert';
import 'dart:io';

import 'package:avatar_genome/avatar_genome.dart';

const _expectedPackageVersion = '2.0.0-rc.1';
const _expectedGeneratorVersion = '4.7.0-dart.1';
const _expectedCatalogVersion = '4.4';
const _expectedRequestSchema = 1;
const _expectedResultSchema = 2;
const _expectedCategories = 30;
const _expectedFields = 275;

void main() {
  final failures = <String>[];
  final pubspec = File('pubspec.yaml').readAsStringSync();
  final changelog = File('CHANGELOG.md').readAsStringSync();
  final manifest = File('PROJECT_MANIFEST.md').readAsStringSync();
  final coreEntryPoint = File('lib/avatar_genome.dart').readAsStringSync();
  final ioEntryPoint = File('lib/avatar_genome_io.dart').readAsStringSync();
  final packageVersion = RegExp(r'^version:\s*(\S+)', multiLine: true)
      .firstMatch(pubspec)
      ?.group(1);

  void expectEqual(Object? actual, Object expected, String label) {
    if (actual != expected) {
      failures.add('$label: expected $expected, got $actual.');
    }
  }

  expectEqual(packageVersion, _expectedPackageVersion, 'Package version');
  expectEqual(
    AvatarGenomeVersion.generator,
    _expectedGeneratorVersion,
    'Generator version',
  );
  expectEqual(
    AvatarGenomeVersion.catalog,
    _expectedCatalogVersion,
    'Catalog version',
  );
  expectEqual(
    AvatarGenomeVersion.requestSchema,
    _expectedRequestSchema,
    'Request schema',
  );
  expectEqual(
    AvatarGenomeVersion.resultSchema,
    _expectedResultSchema,
    'Result schema',
  );

  final catalog = ParameterCatalog.current;
  expectEqual(catalog.categoryCount, _expectedCategories, 'Category count');
  expectEqual(catalog.fieldCount, _expectedFields, 'Field count');

  if (!changelog.contains('## $_expectedPackageVersion')) {
    failures.add('CHANGELOG.md has no $_expectedPackageVersion section.');
  }
  if (!manifest.contains('Package version: `$_expectedPackageVersion`')) {
    failures.add('PROJECT_MANIFEST.md package version is stale.');
  }
  if (!manifest.contains('Generator version: `$_expectedGeneratorVersion`')) {
    failures.add('PROJECT_MANIFEST.md generator version is stale.');
  }
  if (!manifest.contains('Catalog version: `$_expectedCatalogVersion`')) {
    failures.add('PROJECT_MANIFEST.md catalog version is stale.');
  }
  if (!manifest.contains('$_expectedCategories` categories / `$_expectedFields` fields')) {
    failures.add('PROJECT_MANIFEST.md catalog counts are stale.');
  }

  if (coreEntryPoint.contains("dart:io")) {
    failures.add('Core entry point must not import dart:io.');
  }
  if (!ioEntryPoint.contains("avatar_genome.dart")) {
    failures.add('IO entry point must re-export the core API.');
  }
  if (!File('lib/avatar_genome_advanced.dart').existsSync()) {
    failures.add('Advanced API entry point is missing.');
  }
  if (!File('lib/avatar_genome_editor.dart').existsSync()) {
    failures.add('Editor API entry point is missing.');
  }
  if (!File('lib/avatar_genome_server.dart').existsSync()) {
    failures.add('Server API entry point is missing.');
  }
  if (!File('test/fixtures/stable_contract_vectors.json').existsSync()) {
    failures.add('Stable contract vectors are missing.');
  }
  if (!File('docs/RELEASE_CHECKLIST.md').existsSync()) {
    failures.add('Release checklist is missing.');
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
    'failures': failures,
  };

  stdout.writeln(const JsonEncoder.withIndent('  ').convert(contract));
  if (failures.isNotEmpty) {
    exitCode = 1;
  }
}
