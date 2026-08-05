import 'dart:io';

import 'batch_http_controller.dart';
import 'legacy_http_application.dart';
import 'origin_policy.dart';
import 'server_config.dart';

final class ServerRequestHandler {
  const ServerRequestHandler({
    required this.application,
    required this.batches,
    required this.config,
    required this.origins,
  });

  final AvatarEditorHttpApplication application;
  final BatchHttpController batches;
  final ServerConfig config;
  final OriginPolicy origins;

  Future<void> call(HttpRequest request) async {
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
  }
}
