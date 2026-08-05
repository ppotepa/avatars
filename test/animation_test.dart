import 'package:avatar_genome/avatar_genome.dart';
import 'package:avatar_genome/src/rendering/render_helpers.dart';
import 'package:test/test.dart';

void main() {
  test('animation speed shortens the shared motion period', () {
    expect(animationPeriod(1, slow: 20, fast: 10), 20);
    expect(animationPeriod(6, slow: 20, fast: 10), 10);
  });

  test('idle composes local and rig motion channels', () {
    for (final channel in <String>[
      'blink',
      'hairWind',
      'jewelrySwing',
      'smoke',
      'auraPulse',
      'particles',
    ]) {
      expect(animationChannelEnabled('idle', channel), isTrue, reason: channel);
    }
    final animation = AvatarGenerator().generateAnimation(
      AvatarRequest(
        seed: 'rig-idle-motion',
        overrides: <String, Object>{
          'v4.animation': 'idle',
          'v4.animationAmplitude': 4,
          'hair.lengthStyle': 'belowShoulder',
          'hair.length': 15,
          'v4.neckJewelry': 'medallion',
          'v4.shoulderProp': 'parrot',
        },
      ),
      frameCount: 16,
    );
    expect(animation.frames.map((frame) => frame.imageHash).toSet().length,
        greaterThan(2));
    expect(
      animation.frames
          .map((frame) =>
              frame.layout.graph.nodes['rig.camera']?.value.toString())
          .toSet(),
      hasLength(1),
    );
  });

  for (final track in <String>[
    'blink',
    'lookAround',
    'idle',
    'smoke',
    'hairWind',
    'jewelrySwing',
    'glowPulse',
    'auraPulse',
    'particles',
  ]) {
    test('$track changes pixels without changing genome identity', () {
      final overrides = <String, Object>{'v4.animation': track};
      if (track == 'smoke') {
        overrides
          ..['v4.mouthProp'] = 'cigarette'
          ..['v4.smokeAmount'] = 4;
      }
      if (track == 'hairWind') {
        overrides
          ..['hair.lengthStyle'] = 'belowShoulder'
          ..['hair.length'] = 15;
      }
      if (track == 'jewelrySwing') {
        overrides['v4.neckJewelry'] = 'medallion';
      }
      if (track == 'glowPulse' || track == 'auraPulse') {
        overrides['v4.aura'] = 'magic';
      }
      if (track == 'particles') overrides['v4.effect'] = 'snow';
      final request =
          AvatarRequest(seed: 'animation-$track', overrides: overrides);
      final animation =
          AvatarGenerator().generateAnimation(request, frameCount: 16);
      expect(animation.frames.map((frame) => frame.genome.seed).toSet(),
          <String>{request.seed});
      expect(animation.frames.map((frame) => frame.imageHash).toSet().length,
          greaterThan(1));
    });
  }
}
