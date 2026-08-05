import 'dart:async';
import 'dart:io';

import 'package:avatar_genome/avatar_genome_io.dart';
import 'package:avatar_genome/avatar_genome_server.dart';

import 'avatar_editor_server.dart' as legacy;

Future<void> main(List<String> arguments) async {
  final config = ServerConfig.fromArguments(arguments);
  final root = _projectRoot(arguments);
  final application = legacy.AvatarEditorHttpApplication(
    projectRoot: root,
    service: AvatarEditorService(),
  );
  final origins = OriginPolicy(allowedOrigins: config.allowedOrigins);
  final server = await HttpServer.bind(config.address, config.port);

  stdout.writeln('Avatar Genome Editor (secure)');
  stdout.writeln('Project root: ${root.path}');
  stdout.writeln('Open http://${config.host}:${server.port}');

  await for (final request in server) {
    unawaited(_handle(request, application, config, origins));
  }
}

Future<void> _handle(
  HttpRequest request,
  legacy.AvatarEditorHttpApplication application,
  ServerConfig config,
  OriginPolicy origins,
) async {
  final origin = request.headers.value(HttpHeaders.originHeader);
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
  await application.handle(request);
}

Directory _projectRoot(List<String> arguments) {
  final index = arguments.indexOf('--root');
  if (index >= 0 && index + 1 < arguments.length) {
    return Directory(arguments[index + 1]).absolute;
  }
  return Directory.current.absolute;
}
