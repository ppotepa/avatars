import 'dart:io';

import 'package:test/test.dart';

void main() {
  final bootstrap = File('bin/avatar_editor_server.dart').readAsStringSync();
  final application =
      File('lib/src/server/legacy_http_application.dart').readAsStringSync();

  test('default bootstrap applies secure server policies', () {
    expect(bootstrap, contains('ServerConfig.fromArguments'));
    expect(bootstrap, contains('OriginPolicy'));
    expect(bootstrap, contains('authorizesSave'));
    expect(bootstrap, contains('--allow-remote'));
  });

  test('server exposes compact player assets', () {
    expect(application, contains("'/player.js' => 'player.js'"));
    expect(application, contains("'/player.css' => 'player.css'"));
    expect(application, contains("'app.js' || 'player.js'"));
    expect(application, contains("'styles.css' || 'player.css'"));
  });

  test('server exposes one-request animation clip endpoint', () {
    expect(application, contains("path == '/api/animation/clip'"));
    expect(application, contains("'frameCount': frameCount"));
    expect(application, contains("'frameDurationMs': frameDurationMs"));
    expect(application, contains("'frames': <Object>["));
    expect(application,
        contains("'svg': codec.encode(animation.frames[index])"));
  });
}
