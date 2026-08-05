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
  final advancedEntryPoint =
      File('lib/avatar_genome_advanced.dart').readAsStringSync();
  final serverEntryPoint =
      File('lib/avatar_genome_server.dart').readAsStringSync();
  final serverApplication =
      File('lib/src/server/legacy_http_application.dart').readAsStringSync();
  final pipelineSource =
      File('lib/src/rendering/rig_clip_pipeline.dart').readAsStringSync();
  final dependencySource =
      File('lib/src/api/generator_dependencies.dart').readAsStringSync();
  final vectors = Map<String, Object?>.from(
    jsonDecode(
      File('test/fixtures/stable_contract_vectors.json').readAsStringSync(),
    ) as Map,
  );
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

  if (vectors['approved'] != true) {
    failures.add(
      'Golden vectors are not approved. Run '
      'dart run tool/update_contract_vectors.dart --approve after visual review.',
    );
  }
  for (final raw in vectors['vectors']! as List<Object?>) {
    final vector = Map<String, Object?>.from(raw! as Map);
    final expected = vector['expected'];
    if (expected is! Map) {
      failures.add('Golden vector ${vector['name']} has no expected output.');
      continue;
    }
    for (final field in const <String>[
      'imageHash',
      'genomeFingerprint',
      'usedColorCount',
      'layerCount',
      'correctionCount',
      'hardViolationCount',
    ]) {
      if (!expected.containsKey(field)) {
        failures.add('Golden vector ${vector['name']} misses $field.');
      }
    }
  }

  if (coreEntryPoint.contains('dart:io')) {
    failures.add('Core entry point must not import dart:io.');
  }
  if (!ioEntryPoint.contains('avatar_genome.dart')) {
    failures.add('IO entry point must re-export the core API.');
  }
  if (advancedEntryPoint.contains('exact_phase_pipeline.dart')) {
    failures.add('Advanced entry point exports the deleted exact-phase shim.');
  }
  if (!advancedEntryPoint.contains('extended_atmosphere_renderer.dart')) {
    failures.add('Advanced entry point does not expose the split atmosphere.');
  }
  if (!serverEntryPoint.contains('batch_artifact_store.dart') ||
      !serverEntryPoint.contains('stored_zip_encoder.dart')) {
    failures.add('Server entry point misses batch artifact components.');
  }

  for (final path in const <String>[
    'lib/avatar_genome_advanced.dart',
    'lib/avatar_genome_editor.dart',
    'lib/avatar_genome_server.dart',
    'test/fixtures/stable_contract_vectors.json',
    'docs/RELEASE_CHECKLIST.md',
    'lib/src/server/server_request_handler.dart',
    'lib/src/server/avatar_save_repository.dart',
    'lib/src/server/batch_artifact_store.dart',
    'lib/src/server/stored_zip_encoder.dart',
    'lib/src/util/deep_freeze.dart',
    'tool/update_contract_vectors.dart',
  ]) {
    if (!File(path).existsSync()) failures.add('$path is missing.');
  }

  for (final entryPoint in const <String>[
    'lib/avatar_genome.dart',
    'lib/avatar_genome_advanced.dart',
    'lib/avatar_genome_editor.dart',
    'lib/avatar_genome_io.dart',
    'lib/avatar_genome_server.dart',
  ]) {
    failures.addAll(_checkEntryPointExports(entryPoint));
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
  if (!pipelineSource.contains('SplitExtendedAtmosphereRenderer(),')) {
    failures.add('RigClipPipeline does not own the split atmosphere default.');
  }
  if (pipelineSource.contains('\n        ExtendedAtmosphereRenderer(),')) {
    failures.add('RigClipPipeline still defaults to legacy atmosphere.');
  }
  if (dependencySource.contains('part is ExtendedAtmosphereRenderer')) {
    failures.add('GeneratorDependencies still rewrites default renderer parts.');
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
    'goldenApproved': vectors['approved'],
    'sourceViolations': sourceViolations,
    'failures': failures,
  };

  stdout.writeln(const JsonEncoder.withIndent('  ').convert(contract));
  if (failures.isNotEmpty) exitCode = 1;
}

List<String> _checkEntryPointExports(String path) {
  final failures = <String>[];
  final file = File(path);
  final source = file.readAsStringSync();
  final expression = RegExp("export\\s+'([^']+)'");
  for (final match in expression.allMatches(source)) {
    final target = match.group(1)!;
    final exported = File.fromUri(file.parent.uri.resolve(target));
    if (!exported.existsSync()) {
      failures.add('$path exports missing file $target.');
    }
  }
  return failures;
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
      pattern: RegExp(r'\bconst\s+AvatarPalette\s*\('),
      message: 'AvatarPalette copies runtime color storage and is not const.',
    ),
    (
      pattern: RegExp(r'\bconst\s+ValidationReport\s*\('),
      message: 'ValidationReport owns an immutable runtime list and is not const.',
    ),
    (
      pattern: RegExp(r'\bconst\s+OriginPolicy\s*\('),
      message: 'OriginPolicy owns an immutable runtime allowlist and is not const.',
    ),
    (
      pattern: RegExp(r'\bconst\s+ServerConfig\s*\('),
      message: 'ServerConfig owns an immutable runtime allowlist and is not const.',
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
