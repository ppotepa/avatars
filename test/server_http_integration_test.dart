import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:avatar_genome/avatar_genome.dart';
import 'package:avatar_genome/avatar_genome_server.dart';
import 'package:test/test.dart';

void main() {
  late Directory root;
  late HttpServer server;
  late StreamSubscription<HttpRequest> subscription;
  late Uri baseUri;

  setUpAll(() async {
    root = await Directory.systemTemp.createTemp('avatar-server-test-');
    final web = Directory.fromUri(root.uri.resolve('web/'));
    await web.create(recursive: true);
    await File.fromUri(web.uri.resolve('index.html')).writeAsString('ok');
    for (final name in <String>[
      'app.js',
      'player.js',
      'styles.css',
      'player.css',
    ]) {
      await File.fromUri(web.uri.resolve(name)).writeAsString('');
    }

    final service = AvatarEditorService();
    final handler = ServerRequestHandler(
      application: AvatarEditorHttpApplication(
        projectRoot: root,
        service: service,
      ),
      batches: BatchHttpController(
        service: service,
        policy: const BatchResourcePolicy(
          maxAvatarCount: 4,
          maxSheetBytes: 4 * 48 * 48 * 4,
          maxWorkers: 1,
        ),
      ),
      config: const ServerConfig(),
      origins: const OriginPolicy(),
    );
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    subscription = server.listen((request) {
      unawaited(handler.call(request));
    });
    baseUri = Uri.parse('http://127.0.0.1:${server.port}');
  });

  tearDownAll(() async {
    await subscription.cancel();
    await server.close(force: true);
    await root.delete(recursive: true);
  });

  test('health and catalog endpoints respond', () async {
    final health = await _request(baseUri.resolve('/api/health'));
    expect(health.status, HttpStatus.ok);
    expect(jsonDecode(utf8.decode(health.body)), containsPair('status', 'ok'));

    final catalog = await _request(baseUri.resolve('/api/catalog'));
    expect(catalog.status, HttpStatus.ok);
    expect(utf8.decode(catalog.body), contains('categories'));
  });

  test('avatar and animation endpoints generate results', () async {
    final request = AvatarRequest.frozen(seed: 'http-integration').toJson();
    final avatar = await _request(
      baseUri.resolve('/api/avatar'),
      method: 'POST',
      json: <String, Object?>{'request': request},
    );
    expect(avatar.status, HttpStatus.ok);
    expect(utf8.decode(avatar.body), contains('imageHash'));

    final animation = await _request(
      baseUri.resolve('/api/animation/clip'),
      method: 'POST',
      json: <String, Object?>{
        'request': request,
        'frameCount': 2,
        'frameDurationMs': 100,
      },
    );
    expect(animation.status, HttpStatus.ok);
    final payload = jsonDecode(utf8.decode(animation.body)) as Map;
    expect(payload['frameCount'], 2);
    expect(payload['frames'], hasLength(2));
  });

  test('origin and save policies reject unauthorized requests', () async {
    final forbiddenOrigin = await _request(
      baseUri.resolve('/api/avatar'),
      method: 'POST',
      headers: <String, String>{'origin': 'https://evil.example'},
      json: <String, Object?>{
        'request': AvatarRequest.frozen(seed: 'origin-test').toJson(),
      },
    );
    expect(forbiddenOrigin.status, HttpStatus.forbidden);

    final save = await _request(
      baseUri.resolve('/api/save'),
      method: 'POST',
      json: <String, Object?>{
        'request': AvatarRequest.frozen(seed: 'save-test').toJson(),
      },
    );
    expect(save.status, HttpStatus.forbidden);
  });

  test('batch endpoint retains manifest and zip artifacts', () async {
    final batch = await _request(
      baseUri.resolve('/api/export/batch-png'),
      method: 'POST',
      json: <String, Object?>{
        'request': AvatarRequest.frozen(seed: 'batch-http').toJson(),
        'columns': 1,
        'rows': 1,
      },
    );
    expect(batch.status, HttpStatus.ok);
    expect(batch.headers.contentType?.mimeType, 'image/png');
    final id = batch.headers.value('x-avatar-batch-id');
    expect(id, isNotNull);

    final manifest = await _request(
      baseUri.resolve('/api/export/batch-manifest?id=$id'),
    );
    expect(manifest.status, HttpStatus.ok);
    expect(utf8.decode(manifest.body), contains('avatarCount'));

    final zip = await _request(
      baseUri.resolve('/api/export/batch-zip?id=$id'),
    );
    expect(zip.status, HttpStatus.ok);
    expect(zip.headers.contentType?.mimeType, 'application/zip');
    expect(zip.body, isNotEmpty);
  });
}

Future<_HttpResponse> _request(
  Uri uri, {
  String method = 'GET',
  Map<String, String> headers = const <String, String>{},
  Map<String, Object?>? json,
}) async {
  final client = HttpClient();
  try {
    final request = await client.openUrl(method, uri);
    for (final entry in headers.entries) {
      request.headers.set(entry.key, entry.value);
    }
    if (json != null) {
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(json));
    }
    final response = await request.close();
    final body = <int>[];
    await for (final chunk in response) {
      body.addAll(chunk);
    }
    return _HttpResponse(
      status: response.statusCode,
      headers: response.headers,
      body: body,
    );
  } finally {
    client.close(force: true);
  }
}

final class _HttpResponse {
  const _HttpResponse({
    required this.status,
    required this.headers,
    required this.body,
  });

  final int status;
  final HttpHeaders headers;
  final List<int> body;
}
