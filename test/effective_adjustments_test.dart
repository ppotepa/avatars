import 'package:avatar_genome/avatar_genome.dart';
import 'package:test/test.dart';

void main() {
  test('scene and companion conflicts are returned as adjustments', () {
    final result = AvatarGenerator().generate(const AvatarRequest(
      seed: 'effective-adjustments',
      overrides: <String, Object>{
        'v4.shoulderProp': 'parrot',
        'v4.extraShoulderProp': 'miniSkeleton',
        'v4.weather': 'heavyRain',
        'v4.backgroundEvent': 'lightningBranch',
      },
    ));

    final byField = <String, EffectiveAdjustment>{
      for (final adjustment in result.effectiveAdjustments)
        adjustment.field: adjustment,
    };
    expect(byField['v4.extraShoulderProp']?.effective, 'none');
    expect(
      byField['v4.extraShoulderProp']?.reason,
      contains('companionSlotConflict'),
    );
    expect(byField['v4.backgroundEvent']?.effective, 'none');
    expect(
      byField['v4.backgroundEvent']?.reason,
      contains('sceneChannelConflict'),
    );
  });
}
