import 'dart:typed_data';

import 'package:avatar_genome/avatar_genome_server.dart';
import 'package:avatar_genome/src/server/stored_zip_encoder.dart';
import 'package:test/test.dart';

void main() {
  test('artifact store evicts the oldest entry at capacity', () {
    final store = BatchArtifactStore(capacity: 1);
    final first = store.put(
      png: Uint8List.fromList(<int>[1]),
      manifest: <String, Object?>{'columns': 1, 'rows': 1},
    );
    final second = store.put(
      png: Uint8List.fromList(<int>[2]),
      manifest: <String, Object?>{'columns': 1, 'rows': 1},
    );

    expect(store.get(first), isNull);
    expect(store.get(second)?.png, <int>[2]);
    expect(store.length, 1);
  });

  test('artifact store expires entries after TTL', () async {
    final store = BatchArtifactStore(
      ttl: const Duration(milliseconds: 1),
      capacity: 2,
    );
    final id = store.put(
      png: Uint8List.fromList(<int>[1]),
      manifest: <String, Object?>{'columns': 1, 'rows': 1},
    );

    await Future<void>.delayed(const Duration(milliseconds: 5));
    expect(store.get(id), isNull);
  });

  test('stored ZIP encoder emits local and end records', () {
    final zip = StoredZipEncoder.encode(<String, Uint8List>{
      'avatar.json': Uint8List.fromList(<int>[1, 2, 3]),
    });

    expect(zip.sublist(0, 4), <int>[0x50, 0x4b, 0x03, 0x04]);
    expect(
      zip.sublist(zip.length - 22, zip.length - 18),
      <int>[0x50, 0x4b, 0x05, 0x06],
    );
  });
}
