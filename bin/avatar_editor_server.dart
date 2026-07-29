import 'dart:async';
import 'dart:convert';
import 'dart:io';
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
    final port = int.tryParse(_argumentValue(arguments, '--port') ?? '') ?? 8080;
    if (port < 0 || port > 65535) {
      throw ArgumentError.value(port, 'port', 'Port must be between 0 and 65535.');
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

  final Directory projectRoot;
  final AvatarEditorService service;

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
      if (request.method == 'POST' && path == '/api/export/png') {
        final payload = await _readJson(request);
        final editorResponse = _generateFromPayload(payload);
        final scale = _integerOption(payload, 'scale', fallback: 8, min: 1, max: 64);
        final bytes = AvatarPngCodec(scale: scale).encode(editorResponse.result);
        await _binary(
          request,
          bytes,
          contentType: ContentType('image', 'png'),
          fileName: 'avatar-${editorResponse.result.imageHash}.png',
        );
        return;
      }
      if (request.method == 'POST' && path == '/api/export/svg') {
        final payload = await _readJson(request);
        final editorResponse = _generateFromPayload(payload);
        final scale = _integerOption(payload, 'scale', fallback: 8, min: 1, max: 64);
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
      if (request.method == 'POST' && path == '/api/save') {
        final payload = await _readJson(request);
        final response = _generateFromPayload(payload);
        final id = _safeId(payload['id'] as String? ?? response.result.imageHash);
        final scale = _integerOption(payload, 'scale', fallback: 8, min: 1, max: 64);
        final saved = await _saveAvatar(id, response, scale: scale);
        await _json(request, saved);
        return;
      }

      if (request.method == 'GET') {
        final file = switch (path) {
          '/' || '/index.html' => 'index.html',
          '/app.js' => 'app.js',
          '/styles.css' => 'styles.css',
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
      await _error(request, HttpStatus.badRequest, 'Invalid JSON', error.message);
    } on ArgumentError catch (error) {
      await _error(
        request,
        HttpStatus.badRequest,
        'Invalid request',
        error.message?.toString() ?? error.toString(),
      );
    } on TypeError catch (error) {
      await _error(request, HttpStatus.badRequest, 'Invalid type', error.toString());
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
        .map((value) => AvatarEditorAction.fromJson(
              Map<String, Object?>.from(value! as Map),
            ))
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
      AvatarSvgCodec(scale: scale, includeMetadata: true).encode(response.result),
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
      'app.js' => ContentType('text', 'javascript', charset: 'utf-8'),
      'styles.css' => ContentType('text', 'css', charset: 'utf-8'),
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
