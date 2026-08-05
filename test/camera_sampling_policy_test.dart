import 'package:avatar_genome/avatar_genome.dart';
import 'package:test/test.dart';

void main() {
  const policy = CameraSamplingPolicy();

  test('reduced-motion requests use exactly the requested phase', () {
    for (final phase in <int>[0, 7, 1000000]) {
      final plan = policy.plan(
        AvatarRequest(
          seed: 'camera-reduced-motion-$phase',
          phase: phase,
          rendering: const AvatarRenderSettings(reducedMotion: true),
        ),
      );

      expect(plan.phases, <int>[phase]);
      expect(plan.isSingleFrame, isTrue);
    }
  });

  test('large exact phases keep a bounded camera envelope', () {
    final plan = policy.plan(
      AvatarRequest(seed: 'camera-large-phase', phase: 1000000),
    );

    expect(plan.phases, hasLength(17));
    expect(plan.phases.take(16), orderedEquals(List<int>.generate(16, (i) => i)));
    expect(plan.phases.last, 1000000);
    expect(plan.phases.toSet(), hasLength(plan.phases.length));
  });

  test('sample plans expose immutable phases', () {
    final plan = policy.plan(AvatarRequest(seed: 'camera-immutable'));

    expect(() => plan.phases.clear(), throwsUnsupportedError);
  });
}
