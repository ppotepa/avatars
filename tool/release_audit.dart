import 'dart:convert';
import 'dart:io';

import 'package:avatar_genome/avatar_genome.dart';

const _expectedPackageVersion = '2.0.0-rc.2';
const _expectedGeneratorVersion = '4.7.0-dart.2';
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
  final serverApplication =
      File('lib/src/server/legacy_http_application.dart').readAsStringSync();
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
  if (!manifest.contains(
    '$_expectedCategories` categories / `$_expectedFields` fields',
  )) {
    failures.add('PROJECT_MANIFEST.md catalog counts are stale.');
  }

  if (coreEntryPoint.contains('dart:io')) {
    failures.add('Core entry point must not import dart:io.');
  }
  if (!ioEntryPoint.contains('avatar_genome.dart')) {
    failures.add('IO entry point must re-export the core API.');
  }
  for (final path in const <String>[
    'lib/avatar_genome_advanced.dart',
    'lib/avatar_genome_editor.dart',
    'lib/avatar_genome_server.dart',
    'test/fixtures/stable_contract_vectors.json',
    'docs/RELEASE_CHECKLIST.md',
    'lib/src/server/server_request_handler.dart',
    'lib/src/server/avatar_save_repository.dart',
  ]) {
    if (!File(path).existsSync()) failures.add('$path is missing.');
  }

  if (serverApplication.contains('Access-Control-Allow-Origin')) {
    failures.add('HTTP application must not own wildcard CORS headers.');
  }
  if (serverApplication.contains('_renderBatchPng') ||
      serverApplication.contains('_StoredZipEncoder')) {
    failures.add('HTTP application still contains legacy batch ownership.');
  }
  if (serverApplication.contains('error.toString()')) {
    failures.add('HTTP application may expose internal exception details.');
  }
  if (File('lib/src/rendering/exact_phase_pipeline.dart').existsSync()) {
    failures.add('Legacy exact-phase workaround must be removed.');
  }

  final sourceViolations = _scanSources();
  failures.addAll(sourceViolations);

  final contract = <String, Object?>{
    'packageVersion': packageVersion,
    'requestSchema': AvatarGenomeVersion.requestSchema,
    'resultSchema': AvatarGenomeVersion.resultSchema,
    'catalogVersion': AvatarGenomeVersion.catalog,
    'generatorVersion': AvatarGenomeVersion.generator,
    'paletteVersion': AvatarGenomeVersion.palette,
    'categoryCount': catalog.categoryCount,
    'fieldCount': catalog.fieldCount,
    'sourceViolations': sourceViolations,
    'failures': failures,
  };

  stdout.writeln(const JsonEncoder.withIndent('  ').convert(contract));
  if (failures.isNotEmpty) exitCode = 1;
}

List<String> _scanSources() {
  final failures = <String>[];
  final forbidden = <({RegExp pattern, String message})>[
    (
      pattern: RegExp(
        r'\bconst\s+(?:[A-Za-z_]\w*\s*=\s*)?AvatarRequest\s*\(',
      ),
      message: 'AvatarRequest must use its immutable runtime constructor.',
    ),
    (
      pattern: RegExp(r'\brig\.AvatarGenerator\s*\('),
      message: 'Use RigAvatarGenerator after the internal API rename.',
    ),
    (
      pattern: RegExp(r'phase\s*%\s*16'),
      message: 'Animation phases must not be truncated modulo 16.',
    ),
  ];

  for (final rootPath in const <String>[
    'lib',
    'bin',
    'test',
    'tool',
    'example',
    'benchmark',
  ]) {
    final root = Directory(rootPath);
    if (!root.existsSync()) continue;
    for (final entity in root.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final source = entity.readAsStringSync();
      for (final rule in forbidden) {
        if (rule.pattern.hasMatch(source)) {
          failures.add('${entity.path}: ${rule.message}');
        }
      }
    }
  }
  return failures;
}
