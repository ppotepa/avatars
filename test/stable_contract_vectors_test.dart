import 'dart:convert';
import 'dart:io';

import 'package:avatar_genome/avatar_genome.dart';
import 'package:test/test.dart';

void main() {
  final fixture = Map<String, Object?>.from(
    jsonDecode(
      File('test/fixtures/stable_contract_vectors.json').readAsStringSync(),
    ) as Map,
  );

  test('contract metadata matches the runtime', () {
    expect(fixture['generatorVersion'], AvatarGenomeVersion.generator);
    expect(fixture['catalogVersion'], AvatarGenomeVersion.catalog);
    expect(fixture['requestSchema'], AvatarGenomeVersion.requestSchema);
    expect(fixture['resultSchema'], AvatarGenomeVersion.resultSchema);
    expect(ParameterCatalog.current.categoryCount, 30);
    expect(ParameterCatalog.current.fieldCount, 275);
  });

  for (final raw in fixture['vectors']! as List<Object?>) {
    final vector = Map<String, Object?>.from(raw! as Map);
    test('stable vector ${vector['name']}', () {
      final request = AvatarRequest.fromJson(
        Map<String, Object?>.from(vector['request']! as Map),
      );
      final generator = AvatarGenerator(cacheCapacity: 0);
      final first = generator.generate(request);
      final second = generator.generate(
        AvatarRequest.fromJson(request.toJson()),
      );

      expect(second.imageHash, first.imageHash);
      expect(second.genome.toJson(), first.genome.toJson());
      expect(second.image.indices, first.image.indices);
      expect(first.image.width, request.rendering.size);
      expect(first.image.height, request.rendering.size);
      expect(first.imageHash, hasLength(12));
    });
  }

  test('phase vectors agree with one generated clip', () {
    final generator = AvatarGenerator(cacheCapacity: 0);
    final base = AvatarRequest(seed: 'contract-phase');
    final clip = generator.generateAnimation(base, frameCount: 20);
    for (final phase in <int>[1, 15, 16, 19]) {
      final direct = generator.generate(base.copyWith(phase: phase));
      expect(direct.imageHash, clip.frames[phase].imageHash, reason: 'phase $phase');
    }
  });
}
