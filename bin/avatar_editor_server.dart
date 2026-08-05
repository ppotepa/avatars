import 'dart:async';
import 'dart:io';

import 'package:avatar_genome/avatar_genome_editor.dart';
import 'package:avatar_genome/avatar_genome_io.dart';
import 'package:avatar_genome/avatar_genome_server.dart';

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
  final handler = ServerRequestHandler(
    application: AvatarEditorHttpApplication(
      projectRoot: root,
      service: service,
    ),
    batches: BatchHttpController(service: service),
    config: config,
    origins: OriginPolicy(allowedOrigins: config.allowedOrigins),
  );
  final server = await HttpServer.bind(config.address, config.port);

  stdout.writeln('Avatar Genome Editor');
  stdout.writeln('Project root: ${root.path}');
  final displayHost = config.host.contains(':')
      ? '[${config.host}]'
      : config.host;
  stdout.writeln('Open http://$displayHost:${server.port}');

  await for (final request in server) {
    unawaited(_dispatch(handler, request));
  }
}

Future<void> _dispatch(
  ServerRequestHandler handler,
  HttpRequest request,
) async {
  try {
    await handler.call(request);
  } catch (error, stackTrace) {
    stderr.writeln('Unhandled server dispatch error: $error\n$stackTrace');
    try {
      if (!request.response.headers.contentType.toString().contains('json')) {
        request.response.headers.contentType = ContentType.json;
      }
      request.response
        ..statusCode = HttpStatus.internalServerError
        ..write('{"error":"Internal server error"}');
      await request.response.close();
    } catch (_) {
      // The response may already have been committed or closed.
    }
  }
}

Directory _projectRoot(List<String> arguments) {
  final index = arguments.indexOf('--root');
  if (index >= 0 && index + 1 < arguments.length) {
    return Directory(arguments[index + 1]).absolute;
  }
  return Directory.current.absolute;
}
