import 'package:avatar_genome/avatar_genome.dart' as core;
import 'package:avatar_genome/avatar_genome_advanced.dart' as advanced;
import 'package:avatar_genome/avatar_genome_editor.dart' as editor;
import 'package:test/test.dart';

void main() {
  test('public entry points expose their intended contracts', () {
    expect(core.AvatarGenerator, isNotNull);
    expect(advanced.RigClipPipeline, isNotNull);
    expect(editor.AvatarEditorService, isNotNull);
  });
}
