import 'dart:async';
import 'dart:io';

import 'package:avatar_genome/avatar_genome_io.dart';
import 'package:avatar_genome/avatar_genome_server.dart';
import 'package:avatar_genome/src/server/legacy_http_application.dart'
    as application;

Future<void> main(List<String> arguments) async {
  if (arguments.contains('--help') || arguments.contains('-h')) {
    stdout.writeln('''
Avatar Genome local editor server.

Usage:
  dart run bin/avatar_editor_server.dart [options]

Options:
  --host <address>       Bind address. Default: 127.0.0.1
  --port <number>        Port. Default: 8080
  --root <path>          Project root containing web/ and output/.
  --allow-remote         Permit non-loopback bind addresses.
  --allow-origin <url>   Add a browser origin to the CORS allowlist.
  --enable-save          Enable POST /api/save.
  --save-token <token>   Required save token, minimum 16 characters.
  -h, --help             Show this help.
''');
    return;
  }

  final config = ServerConfig.fromArguments(arguments);
  final root = _projectRoot(arguments);
  final service = AvatarEditorService();
  final app = application.AvatarEditorHttpApplication(
    projectRoot: root,
    service: service,
  );
  final batches = BatchHttpController(service: service);
  final origins = OriginPolicy(allowedOrigins: config.allowedOrigins);
  final server = await HttpServer.bind(config.address, config.port);

  stdout.writeln('Avatar Genome Editor');
  stdout.writeln('Project root: ${root.path}');
  stdout.writeln('Open http://${config.host}:${server.port}');

  await for (final request in server) {
    unawaited(_handle(request, app, batches, config, origins));
  }
}

Future<void> _handle(
  HttpRequest request,
  application.AvatarEditorHttpApplication app,
  BatchHttpController batches,
  ServerConfig config,
  OriginPolicy origins,
) async {
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
  await app.handle(request);
}

Directory _projectRoot(List<String> arguments) {
  final index = arguments.indexOf('--root');
  if (index >= 0 && index + 1 < arguments.length) {
    return Directory(arguments[index + 1]).absolute;
  }
  return Directory.current.absolute;
}
