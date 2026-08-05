import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:avatar_genome/avatar_genome_io.dart';

import 'avatar_save_repository.dart';

/// HTTP application for the local editor.
///
/// Batch endpoints are owned by [BatchHttpController] in the server bootstrap.
/// Origin and save authorization are enforced before this application is called.
final class AvatarEditorHttpApplication {
  AvatarEditorHttpApplication({
    required this.projectRoot,
    required this.service,
    AvatarSaveRepository? saveRepository,
    this.maxBodyBytes = 2 * 1024 * 1024,
  }) : saveRepository = saveRepository ??
            AvatarSaveRepository(
              outputDirectory: Directory.fromUri(
                projectRoot.uri.resolve('output/avatars/'),
              ),
            );

  final Directory projectRoot;
  final AvatarEditorService service;
  final AvatarSaveRepository saveRepository;
  final int maxBodyBytes;

  Future<void> handle(HttpRequest request) async {
    _applySecurityHeaders(request.response);
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
        final response = _generate(payload);
        await _json(
          request,
          response.toJson(
            includePixels: _boolOption(payload, 'includePixels') ?? false,
          ),
        );
        return;
      }
      if (request.method == 'POST' && path == '/api/animation/clip') {
        await _animationClip(request, await _readJson(request));
        return;
      }
      if (request.method == 'POST' && path == '/api/export/png') {
        final payload = await _readJson(request);
        final response = _generate(payload);
        final scale = _integerOption(
          payload,
          'scale',
          fallback: 8,
          min: 1,
          max: 64,
        );
        await _binary(
          request,
          AvatarPngCodec(scale: scale).encode(response.result),
          contentType: ContentType('image', 'png'),
          fileName: 'avatar-${response.result.imageHash}.png',
        );
        return;
      }
      if (request.method == 'POST' && path == '/api/export/svg') {
        final payload = await _readJson(request);
        final response = _generate(payload);
        final scale = _integerOption(
          payload,
          'scale',
          fallback: 8,
          min: 1,
          max: 64,
        );
        await _text(
          request,
          AvatarSvgCodec(
            scale: scale,
            includeMetadata: true,
          ).encode(response.result),
          contentType: ContentType('image', 'svg+xml', charset: 'utf-8'),
          fileName: 'avatar-${response.result.imageHash}.svg',
        );
        return;
      }
      if (request.method == 'POST' && path == '/api/export/spritesheet') {
        await _spriteSheet(request, await _readJson(request));
        return;
      }
      if (request.method == 'POST' && path == '/api/save') {
        final payload = await _readJson(request);
        final response = _generate(payload);
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
        await _json(
          request,
          await saveRepository.save(id, response, scale: scale),
        );
        return;
      }

      if (request.method == 'GET') {
        final fileName = switch (path) {
          '/' || '/index.html' => 'index.html',
          '/app.js' => 'app.js',
          '/player.js' => 'player.js',
          '/styles.css' => 'styles.css',
          '/player.css' => 'player.css',
          _ => null,
        };
        if (fileName != null) {
          await _serveStatic(request, fileName);
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
        request,
        HttpStatus.badRequest,
        'Invalid JSON',
        error.message,
      );
    } on ArgumentError catch (error) {
      await _error(
        request,
        HttpStatus.badRequest,
        'Invalid request',
        error.message?.toString() ?? 'The request is invalid.',
      );
    } on TypeError {
      await _error(
        request,
        HttpStatus.badRequest,
        'Invalid type',
        'The request contains a value of an invalid type.',
      );
    } catch (error, stackTrace) {
      stderr.writeln('Unhandled request error: $error\n$stackTrace');
      try {
        await _error(
          request,
          HttpStatus.internalServerError,
          'Internal server error',
          'The request could not be completed.',
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

  Future<void> _animationClip(
    HttpRequest request,
    Map<String, Object?> payload,
  ) async {
    final response = _generate(payload);
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
      response.request,
      frameCount: frameCount,
      frameDuration: Duration(milliseconds: frameDurationMs),
      loop: loop,
    );
    final codec = AvatarSvgCodec(scale: svgScale, includeMetadata: false);
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
  }

  Future<void> _spriteSheet(
    HttpRequest request,
    Map<String, Object?> payload,
  ) async {
    final response = _generate(payload);
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
      response.request,
      frameCount: frameCount,
      frameDuration: Duration(milliseconds: frameDurationMs),
    );
    await _binary(
      request,
      AvatarSpriteSheetCodec(columns: columns, scale: scale).encode(animation),
      contentType: ContentType('image', 'png'),
      fileName: 'avatar-${response.result.imageHash}-${frameCount}f.png',
    );
  }

  AvatarEditorResponse _generate(Map<String, Object?> payload) {
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
      'app.js' || 'player.js' =>
        ContentType('text', 'javascript', charset: 'utf-8'),
      'styles.css' || 'player.css' =>
        ContentType('text', 'css', charset: 'utf-8'),
      _ => ContentType.binary,
    };
    await request.response.addStream(file.openRead());
    await request.response.close();
  }

  Future<void> _json(
    HttpRequest request,
    Object value, {
    int statusCode = HttpStatus.ok,
  }) async {
    request.response
      ..statusCode = statusCode
      ..headers.contentType = ContentType.json
      ..write(jsonEncode(value));
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
        'content-disposition',
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
    request.response
      ..headers.contentType = contentType
      ..contentLength = value.length;
    if (fileName != null) {
      request.response.headers.set(
        'content-disposition',
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

  void _applySecurityHeaders(HttpResponse response) {
    response.headers
      ..set('cache-control', 'no-store')
      ..set('x-content-type-options', 'nosniff')
      ..set('x-frame-options', 'DENY')
      ..set('referrer-policy', 'no-referrer');
  }
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
  if (value < min || value > max) {
    throw ArgumentError.value(value, name, 'Must be between $min and $max.');
  }
  return value;
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
