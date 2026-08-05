import 'dart:io';

import 'batch_http_controller.dart';
import 'legacy_http_application.dart';
import 'origin_policy.dart';
import 'server_config.dart';

final class ServerRequestHandler {
  ServerRequestHandler({
    required this.application,
    required this.batches,
    required this.config,
    required this.origins,
    this.maxConcurrentRequests = 32,
  }) {
    if (maxConcurrentRequests < 1) {
      throw ArgumentError.value(
        maxConcurrentRequests,
        'maxConcurrentRequests',
        'Must be positive.',
      );
    }
  }

  final AvatarEditorHttpApplication application;
  final BatchHttpController batches;
  final ServerConfig config;
  final OriginPolicy origins;
  final int maxConcurrentRequests;
  int _activeRequests = 0;

  int get activeRequests => _activeRequests;

  Future<void> call(HttpRequest request) async {
    if (_activeRequests >= maxConcurrentRequests) {
      request.response
        ..statusCode = HttpStatus.tooManyRequests
        ..headers.contentType = ContentType.json
        ..write('{"error":"Server busy"}');
      await request.response.close();
      return;
    }

    _activeRequests++;
    try {
      final origin = request.headers.value('origin');
      if (!origins.allows(request)) {
        request.response
          ..statusCode = HttpStatus.forbidden
          ..headers.contentType = ContentType.json
          ..write('{"error":"Forbidden origin"}');
        await request.response.close();
        return;
      }
      origins.apply(request.response, origin);

      if (request.uri.path == '/api/save' && !config.authorizesSave(request)) {
        request.response
          ..statusCode = HttpStatus.forbidden
          ..headers.contentType = ContentType.json
          ..write('{"error":"Disk writes are disabled or unauthorized"}');
        await request.response.close();
        return;
      }

      if (batches.handles(request)) {
        await batches.handle(request);
        return;
      }
      await application.handle(request);
    } finally {
      _activeRequests--;
    }
  }
}
