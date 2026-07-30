import 'package:avatar_genome/avatar_genome.dart';
import 'package:test/test.dart';

void main() {
  final generator = AvatarGenerator();

  for (final emote in const <String>[
    'curious',
    'proud',
    'sad',
    'evil',
    'happy',
    'bashful',
    'confused',
  ]) {
    test('$emote face animation changes deterministic frames', () {
      final request = AvatarRequest(
        seed: 'v42-emote-$emote',
        overrides: <String, Object>{
          'v4.expression': 'neutral',
          'v4.faceAnimation': emote,
          'v4.expressionIntensity': 5,
          'v4.expressionSpeed': 4,
          'v4.motionIntensity': 4,
        },
      );
      final first = generator.generate(request.copyWith(phase: 0));
      final repeated = generator.generate(request.copyWith(phase: 0));
      final hashes = <String>{
        for (var phase = 0; phase < 24; phase++)
          generator.generate(request.copyWith(phase: phase)).imageHash,
      };

      expect(repeated.imageHash, first.imageHash);
      expect(hashes.length, greaterThan(1), reason: emote);
      expect(
        first.layers.any((layer) => layer.id.startsWith('emote.v42')),
        isTrue,
        reason: emote,
      );
    });
  }

  for (final motion in const <String>['flameSurge', 'lightning']) {
    test('$motion event motion creates animated event layers', () {
      final request = AvatarRequest(
        seed: 'v42-event-$motion',
        overrides: <String, Object>{
          'v4.eventMotion': motion,
          'v4.motionIntensity': 5,
          'v4.motionSpeed': 5,
          'v4.motionPhaseOffset': 0,
          'v4.backFlames': 'wideFlames',
          'v4.flameHeight': 6,
          'v4.flameIntensity': 5,
        },
      );
      final hashes = <String>{
        for (var phase = 0; phase < 24; phase++)
          generator.generate(request.copyWith(phase: phase)).imageHash,
      };
      final first = generator.generate(request.copyWith(phase: 0));

      expect(hashes.length, greaterThan(1), reason: motion);
      expect(
        first.layers.any((layer) => layer.id.startsWith('eventMotion.v42')),
        isTrue,
        reason: motion,
      );
    });
  }
}
