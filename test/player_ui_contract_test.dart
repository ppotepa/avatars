import 'dart:io';

import 'package:avatar_genome/avatar_genome.dart';
import 'package:test/test.dart';

void main() {
  final index = File('web/index.html').readAsStringSync();
  final app = File('web/app.js').readAsStringSync();
  final player = File('web/player.js').readAsStringSync();
  final playerCss = File('web/player.css').readAsStringSync();

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

  test('track selector restores the complete grouped animation menu', () {
    final start = index.indexOf('id="animation-track"');
    final end = index.indexOf('</select>', start);
    final trackMarkup = index.substring(start, end);
    final optionValues = RegExp(r'<option value="([^"]+)"')
        .allMatches(trackMarkup)
        .map((match) => match.group(1))
        .toSet();

    expect(optionValues, hasLength(31));
    expect(optionValues, containsAll(const <String>{
      'current',
      'none',
      'idle',
      'blink',
      'lookAround',
      'smoke',
      'hairWind',
      'jewelrySwing',
      'glowPulse',
      'auraPulse',
      'particles',
      'talk',
      'laugh',
      'smirk',
      'angry',
      'sleepy',
      'curious',
      'proud',
      'sad',
      'surprised',
      'evil',
      'happy',
      'bashful',
      'confused',
      'storm',
      'fire',
      'cosmic',
      'rain',
      'snow',
      'embers',
      'fog',
    }));
    expect(trackMarkup, contains('<option value="idle" selected>'));
    expect(trackMarkup, contains('<optgroup label="Klasyczne kanały">'));
    expect(trackMarkup, contains('<optgroup label="Ekspresje twarzy">'));
    expect(trackMarkup, contains('<optgroup label="Atmosfera">'));
  });

  test('idle starts automatically after the initial render', () {
    expect(player, contains('autoStarted: false'));
    expect(player, contains("trackSelect.value = 'idle'"));
    expect(player, contains('state.request && state.schema && state.response'));
    expect(player, contains('void play();'));
  });

  test('track selector enforces a readable dark native menu', () {
    expect(playerCss, contains('.deck-track select option'));
    expect(playerCss, contains('.deck-track select optgroup'));
    expect(playerCss, contains('background-color: #091019'));
    expect(playerCss, contains('color: #d1f6df'));
    expect(playerCss, contains('color-scheme: dark'));
  });

  test('player validates every track value before requesting a clip', () {
    expect(player, contains('function validateTrackValue'));
    expect(player, contains("'v4.faceAnimation': 'laugh'"));
    expect(player, isNot(contains("'v4.faceAnimation': 'laughing'")));

    final catalog = ParameterCatalog.v41;
    const tracks = <String, Map<String, Object>>{
      'none': <String, Object>{
        'v4.animation': 'none',
        'v4.faceAnimation': 'none',
        'v4.mouthMotionStyle': 'none',
      },
      'idle': <String, Object>{
        'v4.animation': 'idle',
        'v4.faceAnimation': 'none',
        'v4.mouthMotionStyle': 'none',
      },
      'blink': <String, Object>{
        'v4.animation': 'blink',
        'v4.faceAnimation': 'none',
      },
      'lookAround': <String, Object>{
        'v4.animation': 'lookAround',
        'v4.faceAnimation': 'none',
      },
      'smoke': <String, Object>{
        'v4.animation': 'smoke',
        'v4.effect': 'smoke',
        'v4.mouthProp': 'cigarette',
        'v4.smokeAmount': 4,
      },
      'hairWind': <String, Object>{
        'v4.animation': 'hairWind',
        'hair.lengthStyle': 'shoulder',
        'hair.length': 12,
        'hair.volumeBack': 3,
        'hair.volumeSides': 2,
      },
      'jewelrySwing': <String, Object>{
        'v4.animation': 'jewelrySwing',
        'v4.earJewelry': 'dangling',
        'v4.neckJewelry': 'medallion',
        'v4.jewelrySize': 2,
      },
      'glowPulse': <String, Object>{
        'v4.animation': 'glowPulse',
        'v4.aura': 'electric',
        'v4.animationAmplitude': 3,
      },
      'auraPulse': <String, Object>{
        'v4.animation': 'auraPulse',
        'v4.aura': 'magic',
        'v4.animationAmplitude': 3,
      },
      'particles': <String, Object>{
        'v4.animation': 'particles',
        'v4.effect': 'snow',
        'v4.particleDensity': 4,
      },
      'talk': <String, Object>{
        'v4.faceAnimation': 'talk',
        'v4.mouthMotionStyle': 'talkNormal',
      },
      'laugh': <String, Object>{
        'v4.expression': 'laugh',
        'v4.eyeExpression': 'laughing',
        'v4.mouthExpression': 'laughOpen',
        'v4.faceAnimation': 'laugh',
        'v4.mouthMotionStyle': 'laughLoop',
      },
      'smirk': <String, Object>{
        'v4.expression': 'confident',
        'v4.eyeExpression': 'suspicious',
        'v4.browExpression': 'skepticalSingle',
        'v4.mouthExpression': 'smirkLeft',
        'v4.faceAnimation': 'smirk',
      },
      'angry': <String, Object>{
        'v4.expression': 'angry',
        'v4.eyeExpression': 'angry',
        'v4.browExpression': 'angryDown',
        'v4.mouthExpression': 'snarl',
        'v4.faceAnimation': 'angry',
      },
      'sleepy': <String, Object>{
        'v4.expression': 'sleepy',
        'v4.eyeExpression': 'halfLidded',
        'v4.browExpression': 'sleepyFlat',
        'v4.mouthExpression': 'breathingOpen',
        'v4.faceAnimation': 'sleepy',
        'v4.blinkStyle': 'sleepyBlink',
      },
      'curious': <String, Object>{
        'v4.expression': 'surprised',
        'v4.eyeExpression': 'wide',
        'v4.browExpression': 'liftedOuter',
        'v4.mouthExpression': 'oShape',
        'v4.faceAnimation': 'curious',
      },
      'proud': <String, Object>{
        'v4.expression': 'proud',
        'v4.eyeExpression': 'focused',
        'v4.browExpression': 'confidentTilt',
        'v4.mouthExpression': 'smallSmile',
        'v4.faceAnimation': 'proud',
        'v4.poseMotion': 'proudPose',
      },
      'sad': <String, Object>{
        'v4.expression': 'sad',
        'v4.eyeExpression': 'sad',
        'v4.browExpression': 'sadUp',
        'v4.mouthExpression': 'sadFrown',
        'v4.faceAnimation': 'sad',
      },
      'surprised': <String, Object>{
        'v4.expression': 'surprised',
        'v4.eyeExpression': 'wide',
        'v4.browExpression': 'surprisedHigh',
        'v4.mouthExpression': 'oShape',
        'v4.faceAnimation': 'surprised',
      },
      'evil': <String, Object>{
        'v4.expression': 'evilSmile',
        'v4.eyeExpression': 'narrowed',
        'v4.browExpression': 'angryDown',
        'v4.mouthExpression': 'fangSmile',
        'v4.faceAnimation': 'evil',
      },
      'happy': <String, Object>{
        'v4.expression': 'bigSmile',
        'v4.eyeExpression': 'happy',
        'v4.browExpression': 'relaxed',
        'v4.mouthExpression': 'wideSmile',
        'v4.faceAnimation': 'happy',
        'v4.emotionMark': 'blush',
      },
      'bashful': <String, Object>{
        'v4.expression': 'shy',
        'v4.eyeExpression': 'soft',
        'v4.browExpression': 'liftedInner',
        'v4.mouthExpression': 'tinySmile',
        'v4.faceAnimation': 'bashful',
        'v4.emotionMark': 'blush',
      },
      'confused': <String, Object>{
        'v4.expression': 'worried',
        'v4.eyeExpression': 'suspicious',
        'v4.browExpression': 'skepticalSingle',
        'v4.mouthExpression': 'flatAnnoyed',
        'v4.faceAnimation': 'confused',
      },
      'storm': <String, Object>{
        'v4.weather': 'heavyRain',
        'v4.weatherDensity': 6,
        'v4.weatherDepth': 2,
        'v4.ambientOverlay': 'stormClouds',
        'v4.backgroundEvent': 'lightningBranch',
        'v4.eventFrequency': 2,
        'v4.eventIntensity': 5,
      },
      'fire': <String, Object>{
        'v4.backFlames': 'hellfire',
        'v4.flameHeight': 7,
        'v4.flameIntensity': 6,
        'v4.flameFlicker': 5,
        'v4.backgroundEvent': 'fireBurst',
        'v4.eventFrequency': 2,
        'v4.eventIntensity': 5,
      },
      'cosmic': <String, Object>{
        'v4.background': 'space',
        'v4.cosmicLayer': 'starsDense',
        'v4.cosmicDensity': 5,
        'v4.backgroundEvent': 'cometPass',
        'v4.eventFrequency': 3,
        'v4.eventIntensity': 4,
      },
      'rain': <String, Object>{
        'v4.weather': 'rain',
        'v4.weatherDensity': 5,
        'v4.weatherDepth': 2,
        'v4.weatherDrift': 1,
      },
      'snow': <String, Object>{
        'v4.weather': 'snow',
        'v4.weatherDensity': 5,
        'v4.weatherDepth': 2,
        'v4.weatherDrift': 2,
      },
      'embers': <String, Object>{
        'v4.weather': 'embers',
        'v4.weatherDensity': 5,
        'v4.weatherDepth': 3,
        'v4.backFlames': 'smallFlames',
        'v4.flameHeight': 4,
        'v4.flameIntensity': 4,
      },
      'fog': <String, Object>{
        'v4.weather': 'fog',
        'v4.weatherDensity': 4,
        'v4.weatherDepth': 3,
        'v4.ambientOverlay': 'softFog',
        'v4.ambientDensity': 4,
      },
    };

    for (final track in tracks.entries) {
      for (final value in track.value.entries) {
        expect(
          catalog.fieldById[value.key]!.accepts(value.value),
          isTrue,
          reason: '${track.key}: ${value.key}=${value.value}',
        );
      }
    }
  });
}
