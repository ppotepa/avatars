import 'dart:io';

import 'package:test/test.dart';

void main() {
  final index = File('web/index.html').readAsStringSync();
  final app = File('web/app.js').readAsStringSync();
  final player = File('web/player.js').readAsStringSync();

  test('media transport exposes complete fixed controls', () {
    for (final id in const <String>[
      'frame-start-button',
      'frame-rewind-button',
      'frame-previous-button',
      'animate-button',
      'animation-stop-button',
      'frame-next-button',
      'frame-forward-button',
      'frame-end-button',
      'animation-scrubber',
      'animation-loop',
      'animation-track',
    ]) {
      expect(index, contains('id="$id"'), reason: id);
    }
    expect(player, isNot(contains('MutationObserver')));
    expect(player, isNot(contains("createElement('button')")));
  });

  test('editor app no longer owns an animation timer', () {
    expect(app, isNot(contains('function toggleAnimation')));
    expect(app, isNot(contains('function startAnimation')));
    expect(
      app,
      isNot(contains("elements['animate-button'].addEventListener")),
    );
    expect(player, contains('player.frames'));
    expect(player, contains('ensureClip'));
  });

  test('resolution has one visible control and separate preview zoom', () {
    expect(RegExp('data-resolution="').allMatches(index), hasLength(4));
    expect(index, contains('id="quick-resolution" hidden'));
    expect(index, contains('id="preview-zoom"'));
    expect(index, contains('data-preview-zoom="fit"'));
  });
}
