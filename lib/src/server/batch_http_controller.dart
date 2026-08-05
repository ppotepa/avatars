import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import '../api/avatar_request.dart';
import '../api/avatar_version.dart';
import '../editor/avatar_editor_service.dart';
import '../serialization/avatar_codec.dart';
import '../serialization/avatar_png_codec.dart';
import 'batch_resource_policy.dart';

final class BatchHttpController {
  BatchHttpController({
    required this.service,
    this.policy = const BatchResourcePolicy(),
    this.maxBodyBytes = 2 * 1024 * 1024,
  });

  final AvatarEditorService service;
  final BatchResourcePolicy policy;
  final int maxBodyBytes;
  bool _active = false;

  bool handles(HttpRequest request) =>
      request.method == 'POST' &&
      request.uri.path == '/api/export/batch-png';

  Future<void> handle(HttpRequest request) async {
    if (_active) {
      await _error(
        request,
        HttpStatus.tooManyRequests,
        'Batch busy',
        'Another batch is already running.',
      );
      return;
    }

    try {
      final payload = await _readJson(request);
      final columns = _integer(payload, 'columns', fallback: 16, min: 1, max: 256);
      final rows = _integer(payload, 'rows', fallback: 16, min: 1, max: 256);
      final plan = policy.plan(
        columns: columns,
        rows: rows,
        tileSize: 48,
        availableProcessors: Platform.numberOfProcessors,
      );
      final includeDiagnostics = payload['includeDiagnostics'] == true;

      _active = true;
      late final _BatchResponse batch;
      try {
        batch = await _render(
          payload,
          columns: columns,
          rows: rows,
          plan: plan,
          includeDiagnostics: includeDiagnostics,
        );
      } finally {
        _active = false;
      }

      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType('image', 'png')
        ..headers.set('X-Avatar-Batch-Plan', jsonEncode(plan.toJson()))
        ..headers.set(
          'X-Avatar-Batch-Manifest',
          base64Url.encode(utf8.encode(jsonEncode(batch.manifest))),
        )
        ..contentLength = batch.png.length
        ..add(batch.png);
      await request.response.close();
    } on FormatException catch (error) {
      _active = false;
      await _error(request, HttpStatus.badRequest, 'Invalid JSON', error.message);
    } on ArgumentError catch (error) {
      _active = false;
      await _error(
        request,
        HttpStatus.badRequest,
        'Invalid batch request',
        error.message?.toString() ?? error.toString(),
      );
    } catch (error, stackTrace) {
      _active = false;
      stderr.writeln('Unhandled batch error: $error\n$stackTrace');
      await _error(
        request,
        HttpStatus.internalServerError,
        'Internal server error',
        'The batch request could not be completed.',
      );
    }
  }

  Future<_BatchResponse> _render(
    Map<String, Object?> payload, {
    required int columns,
    required int rows,
    required BatchPlan plan,
    required bool includeDiagnostics,
  }) async {
    final rawRequest = payload['request'] is Map
        ? Map<String, Object?>.from(payload['request']! as Map)
        : Map<String, Object?>.from(payload);
    final rendering = rawRequest['rendering'] is Map
        ? Map<String, Object?>.from(rawRequest['rendering']! as Map)
        : <String, Object?>{};
    rendering['size'] = 48;
    rawRequest['rendering'] = rendering;
    rawRequest.remove('columns');
    rawRequest.remove('rows');
    rawRequest.remove('includeDiagnostics');
    final baseSeed = payload['seed'] as String? ??
        rawRequest['seed'] as String? ??
        'avatar-batch';

    final shardSize = (plan.avatarCount / plan.workerCount).ceil();
    final jobs = <Future<_BatchShard>>[];
    for (var start = 0; start < plan.avatarCount; start += shardSize) {
      jobs.add(Isolate.run(() => _renderShard(<String, Object?>{
            'request': rawRequest,
            'seed': baseSeed,
            'columns': columns,
            'start': start,
            'end': (start + shardSize).clamp(0, plan.avatarCount),
            'includeDiagnostics': includeDiagnostics,
          })));
    }

    final rgba = Uint8List(plan.rgbaBytes);
    final avatars = <Map<String, Object?>>[];
    for (final shard in await Future.wait(jobs)) {
      final pixels = shard.pixels.materialize().asUint8List();
      avatars.addAll(shard.metadata);
      for (var offset = 0; offset < shard.count; offset++) {
        final index = shard.start + offset;
        final targetX = (index % columns) * 48;
        final targetY = (index ~/ columns) * 48;
        final sourceStart = offset * 48 * 48 * 4;
        for (var row = 0; row < 48; row++) {
          final source = sourceStart + row * 48 * 4;
          final target = ((targetY + row) * plan.sheetWidth + targetX) * 4;
          rgba.setRange(target, target + 48 * 4, pixels, source);
        }
      }
    }
    avatars.sort(
      (left, right) =>
          (left['index']! as int).compareTo(right['index']! as int),
    );

    return _BatchResponse(
      png: AvatarPngCodec.encodeRgba(
        rgba,
        width: plan.sheetWidth,
        height: plan.sheetHeight,
      ),
      manifest: <String, Object?>{
        'schemaVersion': 2,
        'generatorVersion': AvatarGenomeVersion.generator,
        'baseSeed': baseSeed,
        'tileSize': 48,
        'columns': columns,
        'rows': rows,
        ...plan.toJson(),
        'includeDiagnostics': includeDiagnostics,
        'avatars': avatars,
      },
    );
  }

  Future<Map<String, Object?>> _readJson(HttpRequest request) async {
    if (request.contentLength > maxBodyBytes) {
      throw const FormatException('Request body is too large.');
    }
    final bytes = BytesBuilder(copy: false);
    await for (final chunk in request) {
      bytes.add(chunk);
      if (bytes.length > maxBodyBytes) {
        throw const FormatException('Request body is too large.');
      }
    }
    final raw = utf8.decode(bytes.takeBytes());
    if (raw.trim().isEmpty) {
      throw const FormatException('Request body must contain JSON.');
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw const FormatException('Top-level JSON value must be an object.');
    }
    return Map<String, Object?>.from(decoded);
  }

  int _integer(
    Map<String, Object?> payload,
    String name, {
    required int fallback,
    required int min,
    required int max,
  }) {
    final raw = payload[name];
    final value = raw is num ? raw.toInt() : fallback;
    if (value < min || value > max) {
      throw ArgumentError.value(value, name, 'Must be between $min and $max.');
    }
    return value;
  }

  Future<void> _error(
    HttpRequest request,
    int status,
    String error,
    String message,
  ) async {
    request.response
      ..statusCode = status
      ..headers.contentType = ContentType.json
      ..write(jsonEncode(<String, Object>{
        'error': error,
        'message': message,
      }));
    await request.response.close();
  }
}

final class _BatchResponse {
  const _BatchResponse({required this.png, required this.manifest});

  final Uint8List png;
  final Map<String, Object?> manifest;
}

final class _BatchShard {
  const _BatchShard({
    required this.start,
    required this.count,
    required this.pixels,
    required this.metadata,
  });

  final int start;
  final int count;
  final TransferableTypedData pixels;
  final List<Map<String, Object?>> metadata;
}

_BatchShard _renderShard(Map<String, Object?> job) {
  final start = job['start']! as int;
  final end = job['end']! as int;
  final columns = job['columns']! as int;
  final requestJson = Map<String, Object?>.from(job['request']! as Map);
  final seed = job['seed']! as String;
  final includeDiagnostics = job['includeDiagnostics'] == true;
  final service = AvatarEditorService();
  final rgbaCodec = const AvatarRgbaCodec();
  final output = Uint8List((end - start) * 48 * 48 * 4);
  final metadata = <Map<String, Object?>>[];

  for (var index = start; index < end; index++) {
    final current = Map<String, Object?>.from(requestJson)
      ..['seed'] = '$seed-${index.toRadixString(36)}';
    final result = service.generator.generate(AvatarRequest.fromJson(current));
    metadata.add(<String, Object?>{
      'index': index,
      'row': index ~/ columns,
      'column': index % columns,
      'seed': current['seed'],
      'imageHash': result.imageHash,
      if (includeDiagnostics) ...<String, Object?>{
        'request': current,
        'genome': result.genome.toJson(),
        'validation': result.validation.toJson(),
        'metrics': result.metrics.toJson(),
        'effectiveAdjustments': result.effectiveAdjustments
            .map((adjustment) => adjustment.toJson())
            .toList(growable: false),
      },
    });
    output.setRange(
      (index - start) * 48 * 48 * 4,
      (index - start + 1) * 48 * 48 * 4,
      rgbaCodec.encode(result),
    );
  }

  return _BatchShard(
    start: start,
    count: end - start,
    pixels: TransferableTypedData.fromList(<Uint8List>[output]),
    metadata: metadata,
  );
}
