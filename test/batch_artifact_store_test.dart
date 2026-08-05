import 'dart:typed_data';

import 'package:avatar_genome/avatar_genome_server.dart';
import 'package:test/test.dart';

void main() {
  test('artifact store emits unique ids and evicts the oldest entry', () {
    final now = DateTime.utc(2026, 8, 5);
    final store = BatchArtifactStore(capacity: 1, clock: () => now);
    final first = store.put(
      png: Uint8List.fromList(<int>[1]),
      manifest: <String, Object?>{'columns': 1, 'rows': 1},
    );
    final second = store.put(
      png: Uint8List.fromList(<int>[2]),
      manifest: <String, Object?>{'columns': 1, 'rows': 1},
    );

    expect(second, isNot(first));
    expect(store.get(first), isNull);
    expect(store.get(second)?.png, <int>[2]);
    expect(store.length, 1);
  });

  test('artifact store expires entries using the injected clock', () {
    var now = DateTime.utc(2026, 8, 5);
    final store = BatchArtifactStore(
      ttl: const Duration(milliseconds: 1),
      capacity: 2,
      clock: () => now,
    );
    final id = store.put(
      png: Uint8List.fromList(<int>[1]),
      manifest: <String, Object?>{'columns': 1, 'rows': 1},
    );

    now = now.add(const Duration(milliseconds: 2));
    expect(store.get(id), isNull);
  });

  test('artifact snapshots do not expose caller-owned buffers', () {
    final png = Uint8List.fromList(<int>[1, 2]);
    final avatars = <Object?>[<String, Object?>{'index': 0}];
    final store = BatchArtifactStore();
    final id = store.put(
      png: png,
      manifest: <String, Object?>{
        'columns': 1,
        'rows': 1,
        'avatars': avatars,
      },
    );

    png[0] = 9;
    (avatars.single! as Map<String, Object?>)['index'] = 9;
    final artifact = store.get(id)!;
    final exposed = artifact.png..[0] = 8;

    expect(artifact.png, <int>[1, 2]);
    expect((artifact.manifest['avatars']! as List).single, <String, Object?>{'index': 0});
    expect(exposed, <int>[8, 2]);
    expect(() => (artifact.manifest['avatars']! as List).clear(), throwsUnsupportedError);
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
