import 'dart:convert';
import 'dart:io';

import 'package:avatar_genome/avatar_genome.dart';
import 'package:avatar_genome/src/util/math_utils.dart';
import 'package:avatar_genome/src/util/stable_fingerprint.dart';

void main(List<String> arguments) {
  final approve = arguments.contains('--approve');
  final file = File('test/fixtures/stable_contract_vectors.json');
  final root = Map<String, Object?>.from(
    jsonDecode(file.readAsStringSync()) as Map,
  );
  final generator = AvatarGenerator(cacheCapacity: 0);
  final vectors = <Object?>[];

  for (final raw in root['vectors']! as List<Object?>) {
    final vector = Map<String, Object?>.from(raw! as Map);
    final request = AvatarRequest.fromJson(
      Map<String, Object?>.from(vector['request']! as Map),
    );
    final result = generator.generate(request);
    vectors.add(<String, Object?>{
      'name': vector['name'],
      'request': request.toJson(),
      'expected': <String, Object?>{
        'imageHash': result.imageHash,
        'genomeFingerprint': hash48(
          utf8.encode(stableFingerprint(result.genome.toJson())),
        ),
        'usedColorCount': result.image.usedColorCount,
        'layerCount': result.layers.length,
        'correctionCount': result.validation.correctionCount,
        'hardViolationCount': result.validation.hardViolationCount,
      },
    });
  }

  final updated = <String, Object?>{
    'packageVersion': '2.0.0-rc.2',
    'generatorVersion': AvatarGenomeVersion.generator,
    'catalogVersion': AvatarGenomeVersion.catalog,
    'requestSchema': AvatarGenomeVersion.requestSchema,
    'resultSchema': AvatarGenomeVersion.resultSchema,
    'approved': approve,
    'vectors': vectors,
  };
  file.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(updated)}\n',
  );
  stdout.writeln(
    approve
        ? 'Updated and approved ${vectors.length} contract vectors.'
        : 'Updated ${vectors.length} vectors without approval. Re-run with --approve after visual review.',
  );
}
