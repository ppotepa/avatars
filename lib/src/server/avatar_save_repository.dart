import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../editor/avatar_editor_service.dart';
import '../serialization/avatar_codec.dart';
import '../serialization/avatar_png_codec.dart';

final class AvatarSaveRepository {
  AvatarSaveRepository({required this.outputDirectory});

  final Directory outputDirectory;
  final Map<String, Future<void>> _writeTails = <String, Future<void>>{};

  Future<Map<String, Object>> save(
    String id,
    AvatarEditorResponse response, {
    required int scale,
  }) {
    if (scale < 1 || scale > 64) {
      throw ArgumentError.value(scale, 'scale', 'Must be between 1 and 64.');
    }
    final safeId = sanitizeId(id);
    return _serialize(safeId, () => _saveBundle(
          safeId,
          response,
          scale: scale,
        ));
  }

  Future<Map<String, Object>> _saveBundle(
    String safeId,
    AvatarEditorResponse response, {
    required int scale,
  }) async {
    final directory = Directory.fromUri(outputDirectory.uri.resolve('$safeId/'));
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
      await _replaceFile(
        File.fromUri(directory.uri.resolve(entry.key)),
        entry.value,
      );
    }

    return <String, Object>{
      'id': safeId,
      'imageHash': response.result.imageHash,
      'directory': 'output/avatars/$safeId',
      'files': List<String>.unmodifiable(files.keys),
    };
  }

  String sanitizeId(String value) {
    final normalized = value
        .trim()
        .replaceAll(RegExp(r'[^a-zA-Z0-9._-]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^[-.]+|[-.]+$'), '');
    if (normalized.isEmpty) return 'avatar';
    return normalized.length <= 80 ? normalized : normalized.substring(0, 80);
  }

  Future<T> _serialize<T>(String id, Future<T> Function() action) async {
    final previous = _writeTails[id] ?? Future<void>.value();
    final completed = Completer<void>();
    final tail = completed.future;
    _writeTails[id] = tail;
    await previous;
    try {
      return await action();
    } finally {
      completed.complete();
      if (identical(_writeTails[id], tail)) {
        _writeTails.remove(id);
      }
    }
  }

  Future<void> _replaceFile(File target, List<int> bytes) async {
    final nonce = '${pid}-${DateTime.now().microsecondsSinceEpoch}';
    final temporary = File('${target.path}.$nonce.tmp');
    await temporary.writeAsBytes(bytes, flush: true);
    try {
      if (await target.exists()) {
        await target.delete();
      }
      await temporary.rename(target.path);
    } finally {
      if (await temporary.exists()) {
        await temporary.delete();
      }
    }
  }
}
