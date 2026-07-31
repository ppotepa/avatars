import 'dart:io';

import 'package:avatar_genome/avatar_genome.dart';
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

  test('player validates track values before requesting a clip', () {
    expect(player, contains('function validateTrackValue'));
    expect(player, contains("'v4.faceAnimation': 'laugh'"));
    expect(player, isNot(contains("'v4.faceAnimation': 'laughing'")));

    final catalog = ParameterCatalog.v41;
    const trackValues = <String, Object>{
      'v4.animation': 'idle',
      'v4.faceAnimation': 'laugh',
      'v4.mouthMotionStyle': 'laughLoop',
      'v4.expression': 'laugh',
      'v4.eyeExpression': 'laughing',
      'v4.mouthExpression': 'laughOpen',
      'v4.weather': 'heavyRain',
      'v4.weatherDensity': 6,
      'v4.weatherDepth': 2,
      'v4.ambientOverlay': 'stormClouds',
      'v4.backgroundEvent': 'lightningBranch',
      'v4.eventFrequency': 2,
      'v4.eventIntensity': 5,
      'v4.backFlames': 'hellfire',
      'v4.flameHeight': 7,
      'v4.flameIntensity': 6,
      'v4.flameFlicker': 5,
    };
    for (final entry in trackValues.entries) {
      expect(
        catalog.fieldById[entry.key]!.accepts(entry.value),
        isTrue,
        reason: '${entry.key}=${entry.value}',
      );
    }
  });
}
