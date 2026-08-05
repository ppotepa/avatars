import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('all local import export and part targets exist', () {
    final missing = <String>[];
    final directive = RegExp(r"(?:import|export|part)\s+'([^']+)'");

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
        for (final match in directive.allMatches(source)) {
          final target = match.group(1)!;
          final resolved = _resolve(entity, target);
          if (resolved != null && !resolved.existsSync()) {
            missing.add('${entity.path} -> $target');
          }
        }
      }
    }

    expect(missing, isEmpty, reason: missing.join('\n'));
  });
}

File? _resolve(File source, String target) {
  if (target.startsWith('dart:')) return null;
  const ownPackage = 'package:avatar_genome/';
  if (target.startsWith(ownPackage)) {
    return File('lib/${target.substring(ownPackage.length)}');
  }
  if (target.startsWith('package:')) return null;
  return File.fromUri(source.parent.uri.resolve(target));
}
