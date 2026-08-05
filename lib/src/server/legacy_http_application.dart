import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:avatar_genome/avatar_genome_io.dart';

Future<void> main(List<String> arguments) async {
  final config = ServerConfig.fromArguments(arguments);
  final root = _resolveProjectRoot(config.projectRoot);
  final app = AvatarEditorHttpApplication(
    projectRoot: root,
    service: AvatarEditorService(),
  );
  final server = await HttpServer.bind(config.host, config.port);

  stdout.writeln('Avatar Genome Editor');
  stdout.writeln('Project root: ${root.path}');
  stdout.writeln('Open http://${config.host}:${server.port}');

  await for (final request in server) {
    unawaited(app.handle(request));
  }
}

final class ServerConfig {
  const ServerConfig({
    required this.host,
    required this.port,
    this.projectRoot,
  });

  factory ServerConfig.fromArguments(List<String> arguments) {
    if (arguments.contains('--help') || arguments.contains('-h')) {
      stdout.writeln('''
Avatar Genome local editor server.

Usage:
  dart run bin/avatar_editor_server.dart [options]

Options:
  --host <address>  Bind address. Default: 127.0.0.1
  --port <number>   Port. Default: 8080
  --root <path>     Project root containing web/ and output/.
  -h, --help        Show this help.
''');
      exit(0);
    }
    final host = _argumentValue(arguments, '--host') ?? '127.0.0.1';
    final port =
        int.tryParse(_argumentValue(arguments, '--port') ?? '') ?? 8080;
    if (port < 0 || port > 65535) {
      throw ArgumentError.value(
        port,
        'port',
        'Port must be between 0 and 65535.',
      );
    }
    return ServerConfig(
      host: host,
      port: port,
      projectRoot: _argumentValue(arguments, '--root'),
    );
  }

  final String host;
  final int port;
  final String? projectRoot;
}

final class AvatarEditorHttpApplication {
  AvatarEditorHttpApplication({
    required this.projectRoot,
    required this.service,
  });

  static const int _maxBodyBytes = 2 * 1024 * 1024;
  static const int _maxBatchWorkers = 16;
  static const int _maxBatchManifests = 2;
  static const Duration _batchManifestTtl = Duration(minutes: 10);

  final Directory projectRoot;
  final AvatarEditorService service;
  final Map<String, Map<String, Object?>> _batchManifests =
      <String, Map<String, Object?>>{};
  final Map<String, Uint8List> _batchPngs = <String, Uint8List>{};
  final Map<String, DateTime> _batchManifestTimes = <String, DateTime>{};
  bool _batchActive = false;

  Directory get outputDirectory =>
      Directory.fromUri(projectRoot.uri.resolve('output/avatars/'));

  Future<void> handle(HttpRequest request) async {
    _commonHeaders(request.response);
    try {
      if (request.method == 'OPTIONS') {
        request.response.statusCode = HttpStatus.noContent;
        await request.response.close();
        return;
      }

      final path = request.uri.path;
      if (request.method == 'GET' && path == '/api/health') {
        await _json(request, <String, Object>{
          'status': 'ok',
          'generatorVersion': AvatarGenomeVersion.generator,
          'catalogVersion': AvatarGenomeVersion.catalog,
          'fieldCount': service.catalog.fieldCount,
        });
        return;
      }
      if (request.method == 'GET' && path == '/api/catalog') {
        await _json(request, service.schemaToJson());
        return;
      }
      if (request.method == 'GET' && path == '/api/default-request') {
        await _json(request, service.defaultRequest.toJson());
        return;
      }
      if (request.method == 'GET' && path == '/api/export/batch-manifest') {
        final id = request.uri.queryParameters['id'];
        final manifest = id == null ? null : _batchManifests[id];
        if (id != null && manifest != null) {
          final created = _batchManifestTimes[id];
          if (created == null ||
              DateTime.now().toUtc().difference(created) > _batchManifestTtl) {
            _batchManifests.remove(id);
            _batchPngs.remove(id);
            _batchManifestTimes.remove(id);
          }
        }
        final currentManifest = id == null ? null : _batchManifests[id];
        if (currentManifest == null) {
          await _error(
            request,
            HttpStatus.notFound,
            'Batch manifest not found',
            'The batch id is missing, expired, or unknown.',
          );
          return;
        }
        await _json(request, currentManifest);
        return;
      }
      if (request.method == 'GET' && path == '/api/export/batch-zip') {
        final id = request.uri.queryParameters['id'];
        final manifest = id == null ? null : _batchManifests[id];
        final png = id == null ? null : _batchPngs[id];
        final created = id == null ? null : _batchManifestTimes[id];
        final expired = created == null ||
            DateTime.now().toUtc().difference(created) > _batchManifestTtl;
        if (id == null || manifest == null || png == null || expired) {
          if (id != null) {
            _batchManifests.remove(id);
            _batchPngs.remove(id);
            _batchManifestTimes.remove(id);
          }
          await _error(
            request,
            HttpStatus.notFound,
            'Batch archive not found',
            'The batch id is missing, expired, or unknown.',
          );
          return;
        }
        final columns = manifest['columns'] as int;
        final rows = manifest['rows'] as int;
        final baseName = 'avatar-batch-${columns}x$rows';
        final zip = _StoredZipEncoder.encode(<String, Uint8List>{
          '$baseName.png': png,
          '$baseName.json': Uint8List.fromList(
            utf8.encode(const JsonEncoder.withIndent('  ').convert(manifest)),
          ),
        });
        await _binary(
          request,
          zip,
          contentType: ContentType('application', 'zip'),
          fileName: '$baseName.zip',
        );
        return;
      }
      if (request.method == 'POST' && path == '/api/avatar') {
        final payload = await _readJson(request);
        final editorResponse = _generateFromPayload(payload);
        final includePixels = _boolOption(payload, 'includePixels') ?? false;
        await _json(
          request,
          editorResponse.toJson(includePixels: includePixels),
        );
        return;
      }
      if (request.method == 'POST' && path == '/api/animation/clip') {
        final payload = await _readJson(request);
        final editorResponse = _generateFromPayload(payload);
        final frameCount = _integerOption(
          payload,
          'frameCount',
          fallback: 16,
          min: 1,
          max: 64,
        );
        final frameDurationMs = _integerOption(
          payload,
          'frameDurationMs',
          fallback: 140,
          min: 16,
          max: 2000,
        );
        final svgScale = _integerOption(
          payload,
          'svgScale',
          fallback: 1,
          min: 1,
          max: 16,
        );
        final loop = _boolOption(payload, 'loop') ?? true;
        final animation = service.generator.generateAnimation(
          editorResponse.request,
          frameCount: frameCount,
          frameDuration: Duration(milliseconds: frameDurationMs),
          loop: loop,
        );
        final codec = AvatarSvgCodec(
          scale: svgScale,
          includeMetadata: false,
        );
        await _json(request, <String, Object>{
          'frameCount': frameCount,
          'frameDurationMs': frameDurationMs,
          'loop': loop,
          'width': animation.frames.first.image.width,
          'height': animation.frames.first.image.height,
          'frames': <Object>[
            for (var index = 0; index < animation.frames.length; index++)
              <String, Object>{
                'index': index,
                'phase': index,
                'imageHash': animation.frames[index].imageHash,
                'svg': codec.encode(animation.frames[index]),
              },
          ],
        });
        return;
      }
      if (request.method == 'POST' && path == '/api/export/png') {
        final payload = await _readJson(request);
        final editorResponse = _generateFromPayload(payload);
        final scale = _integerOption(
          payload,
          'scale',
          fallback: 8,
          min: 1,
          max: 64,
        );
        final bytes =
            AvatarPngCodec(scale: scale).encode(editorResponse.result);
        await _binary(
          request,
          bytes,
          contentType: ContentType('image', 'png'),
          fileName: 'avatar-${editorResponse.result.imageHash}.png',
        );
        return;
      }
      if (request.method == 'POST' && path == '/api/export/batch-png') {
        if (_batchActive) {
          await _error(request, HttpStatus.tooManyRequests, 'Batch busy',
              'Another batch is already running.');
          return;
        }
        final payload = await _readJson(request);
        final columns = _integerOption(
          payload,
          'columns',
          fallback: 16,
          min: 1,
          max: 256,
        );
        final rows = _integerOption(
          payload,
          'rows',
          fallback: 16,
          min: 1,
          max: 256,
        );
        final total = columns * rows;
        if (total > 4096) {
          throw ArgumentError.value(
              total, 'columns/rows', 'Batch limit is 4096 avatars.');
        }
        _batchActive = true;
        late final ({Uint8List png, Map<String, Object?> manifest}) batch;
        try {
          batch = await _renderBatchPng(
            payload,
            columns: columns,
            rows: rows,
          );
        } finally {
          _batchActive = false;
        }
        final batchId =
            '${DateTime.now().microsecondsSinceEpoch}-${columns}x$rows';
        _batchManifests[batchId] = batch.manifest;
        _batchPngs[batchId] = batch.png;
        _batchManifestTimes[batchId] = DateTime.now().toUtc();
        while (_batchManifests.length > _maxBatchManifests) {
          final oldest = _batchManifests.keys.first;
          _batchManifests.remove(oldest);
          _batchPngs.remove(oldest);
          _batchManifestTimes.remove(oldest);
        }
        request.response.headers.set('X-Avatar-Batch-Id', batchId);
        await _binary(
          request,
          batch.png,
          contentType: ContentType('image', 'png'),
          fileName: 'avatar-batch-${columns}x$rows.png',
        );
        return;
      }
      if (request.method == 'POST' && path == '/api/export/svg') {
        final payload = await _readJson(request);
        final editorResponse = _generateFromPayload(payload);
        final scale = _integerOption(
          payload,
          'scale',
          fallback: 8,
          min: 1,
          max: 64,
        );
        final svg = AvatarSvgCodec(
          scale: scale,
          includeMetadata: true,
        ).encode(editorResponse.result);
        await _text(
          request,
          svg,
          contentType: ContentType('image', 'svg+xml', charset: 'utf-8'),
          fileName: 'avatar-${editorResponse.result.imageHash}.svg',
        );
        return;
      }
      if (request.method == 'POST' && path == '/api/export/spritesheet') {
        final payload = await _readJson(request);
        final editorResponse = _generateFromPayload(payload);
        final frameCount = _integerOption(
          payload,
          'frameCount',
          fallback: 16,
          min: 1,
          max: 64,
        );
        final frameDurationMs = _integerOption(
          payload,
          'frameDurationMs',
          fallback: 140,
          min: 16,
          max: 2000,
        );
        final columns = _integerOption(
          payload,
          'columns',
          fallback: 4,
          min: 1,
          max: 16,
        );
        final scale = _integerOption(
          payload,
          'scale',
          fallback: 1,
          min: 1,
          max: 16,
        );
        final animation = service.generator.generateAnimation(
          editorResponse.request,
          frameCount: frameCount,
          frameDuration: Duration(milliseconds: frameDurationMs),
        );
        final bytes = AvatarSpriteSheetCodec(
          columns: columns,
          scale: scale,
        ).encode(animation);
        await _binary(
          request,
          bytes,
          contentType: ContentType('image', 'png'),
          fileName:
              'avatar-${editorResponse.result.imageHash}-${frameCount}f.png',
        );
        return;
      }
      if (request.method == 'POST' && path == '/api/save') {
        final payload = await _readJson(request);
        final response = _generateFromPayload(payload);
        final id = _safeId(
          payload['id'] as String? ?? response.result.imageHash,
        );
        final scale = _integerOption(
          payload,
          'scale',
          fallback: 8,
          min: 1,
          max: 64,
        );
        final saved = await _saveAvatar(id, response, scale: scale);
        await _json(request, saved);
        return;
      }

      if (request.method == 'GET') {
        final file = switch (path) {
          '/' || '/index.html' => 'index.html',
          '/app.js' => 'app.js',
          '/player.js' => 'player.js',
          '/styles.css' => 'styles.css',
          '/player.css' => 'player.css',
          _ => null,
        };
        if (file != null) {
          await _serveStatic(request, file);
          return;
        }
        if (path == '/favicon.ico') {
          request.response.statusCode = HttpStatus.noContent;
          await request.response.close();
          return;
        }
      }

      await _error(
        request,
        HttpStatus.notFound,
        'Not found',
        'No route for ${request.method} ${request.uri.path}.',
      );
    } on AvatarRequestValidationException catch (error) {
      await _json(request, error.toJson(), statusCode: HttpStatus.badRequest);
    } on FormatException catch (error) {
      await _error(
          request, HttpStatus.badRequest, 'Invalid JSON', error.message);
    } on ArgumentError catch (error) {
      await _error(
        request,
        HttpStatus.badRequest,
        'Invalid request',
        error.message?.toString() ?? error.toString(),
      );
    } on TypeError catch (error) {
      await _error(
          request, HttpStatus.badRequest, 'Invalid type', error.toString());
    } catch (error, stackTrace) {
      stderr.writeln('Unhandled request error: $error\n$stackTrace');
      try {
        await _error(
          request,
          HttpStatus.internalServerError,
          'Internal server error',
          error.toString(),
        );
      } catch (_) {
        try {
          await request.response.close();
        } catch (_) {
          // The response may already be closed.
        }
      }
    }
  }

  AvatarEditorResponse _generateFromPayload(Map<String, Object?> payload) {
    final requestJson = payload['request'] is Map
        ? Map<String, Object?>.from(payload['request']! as Map)
        : payload;
    final avatarRequest = AvatarRequest.fromJson(requestJson);
    final actions = (payload['actions'] as List<Object?>? ?? const <Object?>[])
        .map(
          (value) => AvatarEditorAction.fromJson(
            Map<String, Object?>.from(value! as Map),
          ),
        )
        .toList(growable: false);
    final svgScale = _integerOption(
      payload,
      'svgScale',
      fallback: 8,
      min: 1,
      max: 64,
    );
    return service.generate(
      avatarRequest,
      actions: actions,
      svgScale: svgScale,
    );
  }

  Future<({Uint8List png, Map<String, Object?> manifest})> _renderBatchPng(
    Map<String, Object?> payload, {
    required int columns,
    required int rows,
  }) async {
    final rawRequest = payload['request'] is Map
        ? Map<String, Object?>.from(payload['request']! as Map)
        : Map<String, Object?>.from(payload);
    final rendering = rawRequest['rendering'] is Map
        ? Map<String, Object?>.from(rawRequest['rendering']! as Map)
        : <String, Object?>{};
    rendering['size'] = 48;
    rawRequest['rendering'] = rendering;
    final seed = payload['seed'] as String? ??
        rawRequest['seed'] as String? ??
        'avatar-batch';
    final total = columns * rows;
    final workers = Platform.numberOfProcessors
        .clamp(1, _maxBatchWorkers)
        .clamp(1, total)
        .toInt();
    final shardSize = (total / workers).ceil();
    final shards = <Future<_BatchShard>>[];
    for (var start = 0; start < total; start += shardSize) {
      shards.add(Isolate.run(() => _renderBatchShard(<String, Object?>{
            'request': rawRequest,
            'seed': seed,
            'columns': columns,
            'start': start,
            'end': (start + shardSize).clamp(0, total),
          })));
    }
    final rgba = Uint8List(columns * 48 * rows * 48 * 4);
    final sheetWidth = columns * 48;
    final completedShards = await Future.wait(shards);
    final avatars = <Map<String, Object?>>[];
    for (final shard in completedShards) {
      final pixels = shard.pixels.materialize().asUint8List();
      avatars.addAll(shard.metadata);
      for (var offset = 0; offset < shard.count; offset++) {
        final index = shard.start + offset;
        final x = (index % columns) * 48;
        final y = (index ~/ columns) * 48;
        final sourceStart = offset * 48 * 48 * 4;
        for (var row = 0; row < 48; row++) {
          final source = sourceStart + row * 48 * 4;
          final target = ((y + row) * sheetWidth + x) * 4;
          rgba.setRange(target, target + 48 * 4, pixels, source);
        }
      }
    }
    avatars.sort(
      (left, right) =>
          (left['index']! as int).compareTo(right['index']! as int),
    );
    return (
      png: AvatarPngCodec.encodeRgba(
        rgba,
        width: sheetWidth,
        height: rows * 48,
      ),
      manifest: <String, Object?>{
        'schemaVersion': 1,
        'generatedAt': DateTime.now().toUtc().toIso8601String(),
        'generatorVersion': AvatarGenomeVersion.generator,
        'baseSeed': seed,
        'tileSize': 48,
        'columns': columns,
        'rows': rows,
        'avatarCount': total,
        'sheetWidth': sheetWidth,
        'sheetHeight': rows * 48,
        'workerCount': workers,
        'baseRequest': rawRequest,
        'avatars': avatars,
      },
    );
  }

  Future<Map<String, Object>> _saveAvatar(
    String id,
    AvatarEditorResponse response, {
    required int scale,
  }) async {
    final directory = Directory.fromUri(outputDirectory.uri.resolve('$id/'));
    await directory.create(recursive: true);
    final pretty = const JsonEncoder.withIndent('  ');
    final requestFile = File.fromUri(directory.uri.resolve('request.json'));
    final resultFile = File.fromUri(directory.uri.resolve('avatar.json'));
    final svgFile = File.fromUri(directory.uri.resolve('avatar.svg'));
    final pngFile = File.fromUri(directory.uri.resolve('avatar.png'));

    await requestFile.writeAsString(pretty.convert(response.request.toJson()));
    await resultFile.writeAsString(
      pretty.convert(response.result.toJson(includePixels: false)),
    );
    await svgFile.writeAsString(
      AvatarSvgCodec(
        scale: scale,
        includeMetadata: true,
      ).encode(response.result),
    );
    await pngFile.writeAsBytes(
      AvatarPngCodec(scale: scale).encode(response.result),
    );

    return <String, Object>{
      'id': id,
      'imageHash': response.result.imageHash,
      'directory': 'output/avatars/$id',
      'files': const <String>[
        'request.json',
        'avatar.json',
        'avatar.svg',
        'avatar.png',
      ],
    };
  }

  Future<Map<String, Object?>> _readJson(HttpRequest request) async {
    final declaredLength = request.contentLength;
    if (declaredLength > _maxBodyBytes) {
      throw const FormatException('Request body is too large.');
    }
    final bytes = BytesBuilder(copy: false);
    await for (final chunk in request) {
      bytes.add(chunk);
      if (bytes.length > _maxBodyBytes) {
        throw const FormatException('Request body is too large.');
      }
    }
    final raw = utf8.decode(bytes.takeBytes());
    if (raw.trim().isEmpty) {
      throw const FormatException('Request body must contain JSON.');
    }
    final value = jsonDecode(raw);
    if (value is! Map) {
      throw const FormatException('Top-level JSON value must be an object.');
    }
    return Map<String, Object?>.from(value);
  }

  Future<void> _serveStatic(HttpRequest request, String name) async {
    final file = File.fromUri(projectRoot.uri.resolve('web/$name'));
    if (!await file.exists()) {
      await _error(
        request,
        HttpStatus.notFound,
        'Missing static file',
        'The web/$name file does not exist.',
      );
      return;
    }
    request.response.headers.contentType = switch (name) {
      'index.html' => ContentType.html,
      'app.js' ||
      'player.js' =>
        ContentType('text', 'javascript', charset: 'utf-8'),
      'styles.css' ||
      'player.css' =>
        ContentType('text', 'css', charset: 'utf-8'),
      _ => ContentType.binary,
    };
    request.response.headers.set(HttpHeaders.cacheControlHeader, 'no-store');
    await request.response.addStream(file.openRead());
    await request.response.close();
  }

  Future<void> _json(
    HttpRequest request,
    Object value, {
    int statusCode = HttpStatus.ok,
  }) async {
    request.response.statusCode = statusCode;
    request.response.headers.contentType = ContentType.json;
    request.response.write(jsonEncode(value));
    await request.response.close();
  }

  Future<void> _text(
    HttpRequest request,
    String value, {
    required ContentType contentType,
    String? fileName,
  }) async {
    request.response.headers.contentType = contentType;
    if (fileName != null) {
      request.response.headers.set(
        'Content-Disposition',
        'attachment; filename="$fileName"',
      );
    }
    request.response.write(value);
    await request.response.close();
  }

  Future<void> _binary(
    HttpRequest request,
    Uint8List value, {
    required ContentType contentType,
    String? fileName,
  }) async {
    request.response.headers.contentType = contentType;
    request.response.contentLength = value.length;
    if (fileName != null) {
      request.response.headers.set(
        'Content-Disposition',
        'attachment; filename="$fileName"',
      );
    }
    request.response.add(value);
    await request.response.close();
  }

  Future<void> _error(
    HttpRequest request,
    int statusCode,
    String error,
    String message,
  ) =>
      _json(
        request,
        <String, Object>{'error': error, 'message': message},
        statusCode: statusCode,
      );

  void _commonHeaders(HttpResponse response) {
    response.headers.set(HttpHeaders.cacheControlHeader, 'no-store');
    response.headers.set('X-Content-Type-Options', 'nosniff');
    response.headers.set('Access-Control-Allow-Origin', '*');
    response.headers.set(
      'Access-Control-Allow-Headers',
      'Content-Type',
    );
    response.headers.set(
      'Access-Control-Allow-Methods',
      'GET, POST, OPTIONS',
    );
  }
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

_BatchShard _renderBatchShard(Map<String, Object?> job) {
  final start = job['start']! as int;
  final end = job['end']! as int;
  final requestJson = Map<String, Object?>.from(job['request']! as Map);
  final seed = job['seed']! as String;
  final generator = AvatarGenerator();
  final codec = const AvatarRgbaCodec();
  final output = Uint8List((end - start) * 48 * 48 * 4);
  final metadata = <Map<String, Object?>>[];
  for (var index = start; index < end; index++) {
    final current = Map<String, Object?>.from(requestJson)
      ..['seed'] = '$seed-${index.toRadixString(36)}';
    final result = generator.generate(AvatarRequest.fromJson(current));
    metadata.add(<String, Object?>{
      'index': index,
      'row': index ~/ (job['columns'] as int? ?? 1),
      'column': index % (job['columns'] as int? ?? 1),
      'seed': current['seed'],
      'imageHash': result.imageHash,
      'request': current,
      'genome': result.genome.toJson(),
      'validation': result.validation.toJson(),
      'metrics': result.metrics.toJson(),
      'effectiveAdjustments': result.effectiveAdjustments
          .map((adjustment) => adjustment.toJson())
          .toList(growable: false),
    });
    output.setRange(
      (index - start) * 48 * 48 * 4,
      (index - start + 1) * 48 * 48 * 4,
      codec.encode(result),
    );
  }
  return _BatchShard(
    start: start,
    count: end - start,
    pixels: TransferableTypedData.fromList(<Uint8List>[output]),
    metadata: metadata,
  );
}

final class _StoredZipEncoder {
  static Uint8List encode(Map<String, Uint8List> files) {
    final output = BytesBuilder(copy: false);
    final central = BytesBuilder(copy: false);
    var offset = 0;
    for (final entry in files.entries) {
      final name = Uint8List.fromList(utf8.encode(entry.key));
      final data = entry.value;
      final crc = _crc32(data);
      final local = BytesBuilder(copy: false)
        ..add(_u32(0x04034b50))
        ..add(_u16(20))
        ..add(_u16(0))
        ..add(_u16(0))
        ..add(_u16(0))
        ..add(_u16(0))
        ..add(_u32(crc))
        ..add(_u32(data.length))
        ..add(_u32(data.length))
        ..add(_u16(name.length))
        ..add(_u16(0))
        ..add(name)
        ..add(data);
      final localBytes = local.takeBytes();
      output.add(localBytes);

      central
        ..add(_u32(0x02014b50))
        ..add(_u16(20))
        ..add(_u16(20))
        ..add(_u16(0))
        ..add(_u16(0))
        ..add(_u16(0))
        ..add(_u16(0))
        ..add(_u32(crc))
        ..add(_u32(data.length))
        ..add(_u32(data.length))
        ..add(_u16(name.length))
        ..add(_u16(0))
        ..add(_u16(0))
        ..add(_u16(0))
        ..add(_u16(0))
        ..add(_u32(0))
        ..add(_u32(offset))
        ..add(name);
      offset += localBytes.length;
    }
    final centralBytes = central.takeBytes();
    output
      ..add(centralBytes)
      ..add(_u32(0x06054b50))
      ..add(_u16(0))
      ..add(_u16(0))
      ..add(_u16(files.length))
      ..add(_u16(files.length))
      ..add(_u32(centralBytes.length))
      ..add(_u32(offset))
      ..add(_u16(0));
    return output.takeBytes();
  }

  static Uint8List _u16(int value) {
    final bytes = Uint8List(2);
    ByteData.sublistView(bytes).setUint16(0, value, Endian.little);
    return bytes;
  }

  static Uint8List _u32(int value) {
    final bytes = Uint8List(4);
    ByteData.sublistView(bytes).setUint32(0, value, Endian.little);
    return bytes;
  }

  static int _crc32(Uint8List bytes) {
    var crc = 0xffffffff;
    for (final byte in bytes) {
      crc ^= byte;
      for (var bit = 0; bit < 8; bit++) {
        crc = (crc & 1) == 0 ? crc >>> 1 : (crc >>> 1) ^ 0xedb88320;
      }
    }
    return (crc ^ 0xffffffff) & 0xffffffff;
  }
}

Directory _resolveProjectRoot(String? explicitPath) {
  if (explicitPath != null) {
    return Directory(explicitPath).absolute;
  }
  final current = Directory.current.absolute;
  if (File.fromUri(current.uri.resolve('web/index.html')).existsSync()) {
    return current;
  }
  final scriptFile = File.fromUri(Platform.script);
  final candidate = scriptFile.parent.parent.absolute;
  if (File.fromUri(candidate.uri.resolve('web/index.html')).existsSync()) {
    return candidate;
  }
  return current;
}

String? _argumentValue(List<String> arguments, String name) {
  final index = arguments.indexOf(name);
  if (index < 0 || index + 1 >= arguments.length) return null;
  return arguments[index + 1];
}

int _integerOption(
  Map<String, Object?> payload,
  String name, {
  required int fallback,
  required int min,
  required int max,
}) {
  final raw = payload[name];
  final value = raw is num ? raw.toInt() : fallback;
  return value.clamp(min, max).toInt();
}

bool? _boolOption(Map<String, Object?> payload, String name) {
  final value = payload[name];
  return value is bool ? value : null;
}

String _safeId(String value) {
  final normalized = value
      .trim()
      .replaceAll(RegExp(r'[^a-zA-Z0-9._-]+'), '-')
      .replaceAll(RegExp(r'-+'), '-')
      .replaceAll(RegExp(r'^[-.]+|[-.]+$'), '');
  if (normalized.isEmpty) return 'avatar';
  return normalized.length <= 80 ? normalized : normalized.substring(0, 80);
}
