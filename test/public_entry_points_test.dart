import 'package:avatar_genome/avatar_genome.dart' as core;
import 'package:avatar_genome/avatar_genome_advanced.dart' as advanced;
import 'package:avatar_genome/avatar_genome_editor.dart' as editor;
import 'package:avatar_genome/avatar_genome_io.dart' as io;
import 'package:avatar_genome/avatar_genome_server.dart' as server;
import 'package:test/test.dart';

void main() {
  test('public entry points expose their intended contracts', () {
    expect(core.AvatarGenerator, isNotNull);
    expect(advanced.RigClipPipeline, isNotNull);
    expect(advanced.SplitExtendedAtmosphereRenderer, isNotNull);
    expect(editor.AvatarEditorService, isNotNull);
    expect(io.AvatarPngCodec, isNotNull);
    expect(server.ServerRequestHandler, isNotNull);
    expect(server.BatchArtifactStore, isNotNull);
    expect(server.StoredZipEncoder, isNotNull);
  });
}
