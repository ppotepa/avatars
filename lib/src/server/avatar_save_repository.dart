import 'dart:convert';
import 'dart:io';

import '../editor/avatar_editor_service.dart';
import '../serialization/avatar_codec.dart';
import '../serialization/avatar_png_codec.dart';

final class AvatarSaveRepository {
  const AvatarSaveRepository({required this.outputDirectory});

  final Directory outputDirectory;

  Future<Map<String, Object>> save(
    String id,
    AvatarEditorResponse response, {
    required int scale,
  }) async {
    final directory = Directory.fromUri(outputDirectory.uri.resolve('$id/'));
    await directory.create(recursive: true);
    final pretty = const JsonEncoder.withIndent('  ');
    final files = <String, List<int>>{
      'request.json': utf8.encode(pretty.convert(response.request.toJson())),
      'avatar.json': utf8.encode(
        pretty.convert(response.result.toJson(includePixels: false)),
      ),
      'avatar.svg': utf8.encode(
        AvatarSvgCodec(
          scale: scale,
          includeMetadata: true,
        ).encode(response.result),
      ),
      'avatar.png': AvatarPngCodec(scale: scale).encode(response.result),
    };

    for (final entry in files.entries) {
      await _atomicWrite(
        File.fromUri(directory.uri.resolve(entry.key)),
        entry.value,
      );
    }

    return <String, Object>{
      'id': id,
      'imageHash': response.result.imageHash,
      'directory': 'output/avatars/$id',
      'files': files.keys.toList(growable: false),
    };
  }

  Future<void> _atomicWrite(File target, List<int> bytes) async {
    final temporary = File('${target.path}.tmp');
    await temporary.writeAsBytes(bytes, flush: true);
    if (await target.exists()) {
      await target.delete();
    }
    await temporary.rename(target.path);
  }
}
