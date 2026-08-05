import 'dart:io';

import 'package:avatar_genome/avatar_genome.dart';
import 'package:avatar_genome/avatar_genome_server.dart';
import 'package:test/test.dart';

void main() {
  test('save repository sanitizes paths and writes a complete bundle', () async {
    final root = await Directory.systemTemp.createTemp('avatar-save-test-');
    try {
      final service = AvatarEditorService();
      final response = service.generate(
        AvatarRequest(seed: 'save-repository'),
      );
      final repository = AvatarSaveRepository(outputDirectory: root);
      final saved = await repository.save(
        '../unsafe/avatar',
        response,
        scale: 1,
      );

      expect(saved['id'], 'unsafe-avatar');
      final directory = Directory.fromUri(root.uri.resolve('unsafe-avatar/'));
      expect(directory.existsSync(), isTrue);
      for (final name in const <String>[
        'request.json',
        'avatar.json',
        'avatar.svg',
        'avatar.png',
      ]) {
        expect(File.fromUri(directory.uri.resolve(name)).existsSync(), isTrue);
      }
      expect(
        Directory.fromUri(root.parent.uri.resolve('unsafe/')).existsSync(),
        isFalse,
      );
    } finally {
      await root.delete(recursive: true);
    }
  });

  test('save repository validates export scale', () async {
    final root = await Directory.systemTemp.createTemp('avatar-save-scale-');
    try {
      final response = AvatarEditorService().generate(
        AvatarRequest(seed: 'save-scale'),
      );
      final repository = AvatarSaveRepository(outputDirectory: root);
      await expectLater(
        repository.save('avatar', response, scale: 0),
        throwsArgumentError,
      );
    } finally {
      await root.delete(recursive: true);
    }
  });
}
