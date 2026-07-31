import 'dart:io';

import 'package:test/test.dart';

void main() {
  final server = File('bin/avatar_editor_server.dart').readAsStringSync();

  test('server exposes compact player assets', () {
    expect(server, contains("'/player.js' => 'player.js'"));
    expect(server, contains("'/player.css' => 'player.css'"));
    expect(server, contains("'app.js' || 'player.js'"));
    expect(server, contains("'styles.css' || 'player.css'"));
  });

  test('server exposes one-request animation clip endpoint', () {
    expect(server, contains("path == '/api/animation/clip'"));
    expect(server, contains("'frameCount': frameCount"));
    expect(server, contains("'frameDurationMs': frameDurationMs"));
    expect(server, contains("'frames': <Object>["));
    expect(server, contains("'svg': codec.encode(animation.frames[index])"));
  });
}
