import '../util/math_utils.dart';
import 'render_helpers.dart';

final class AvatarAnimationState {
  AvatarAnimationState({
    required this.id,
    required this.phase,
    required this.speed,
    required this.amplitude,
    required this.randomKey,
  });

  final String id;
  final int phase;
  final int speed;
  final int amplitude;
  final String randomKey;

  bool get isNone => id == 'none';

  bool get isIdleLike =>
      id == 'idle' ||
      id == 'happy' ||
      id == 'sad' ||
      id == 'thinking' ||
      id == 'confused';

  bool get isTalkingLike => id == 'talking' || id == 'laughing';

  bool get isSleepLike => id == 'sleeping';

  bool get isAlertLike =>
      id == 'scared' ||
      id == 'surprised' ||
      id == 'hurt' ||
      id == 'celebration';

  int oscillate({
    required int basePeriod,
    int amplitudeScale = 1,
    int phaseOffset = 0,
  }) {
    return cyclicOffset(
      phase + phaseOffset,
      _period(basePeriod),
      clampInt(amplitude * amplitudeScale, 1, 4),
    );
  }

  int pulse({
    required int basePeriod,
    int peak = 2,
    int phaseOffset = 0,
  }) {
    final safePeak = clampInt(peak + amplitude - 1, 1, 4);
    final step = positiveMod(phase + phaseOffset, _period(basePeriod));
    final mid = _period(basePeriod) ~/ 2;
    final distance = (step - mid).abs();
    final value = safePeak - (distance * safePeak ~/ (mid == 0 ? 1 : mid));
    return clampInt(value, 0, safePeak);
  }

  bool blinkFrame() {
    if (id == 'sleeping') return true;
    final shouldBlink = id == 'idle' ||
        id == 'talking' ||
        id == 'happy' ||
        id == 'thinking' ||
        id == 'confused' ||
        id == 'sad';
    if (!shouldBlink) return false;
    final cycle = _period(12);
    final step = positiveMod(phase, cycle);
    final start = id == 'idle'
        ? clampInt(cycle - 2 + _cycleJitter('blink.start', period: cycle), 0,
            cycle - 1)
        : cycle - 2;
    final span = id == 'idle'
        ? 1 + positiveMod(_cycleHash('blink.span', period: cycle), 2)
        : 2;
    return step >= start && step < clampInt(start + span, start, cycle);
  }

  int mouthOpenAmount() {
    return switch (id) {
      'talking' => 1 + pulse(basePeriod: 6, peak: 2),
      'laughing' => 2 + pulse(basePeriod: 5, peak: 1),
      'surprised' => 2 + pulse(basePeriod: 10, peak: 1),
      'scared' => 1 + pulse(basePeriod: 8, peak: 1),
      'hurt' => 1,
      'sleeping' => 0,
      _ => 0,
    };
  }

  int eyeOffsetX() {
    return switch (id) {
      'idle' => _cycleJitter('idle.eye', period: _period(14)),
      'lookAround' => oscillate(basePeriod: 10, amplitudeScale: 1),
      'thinking' =>
        oscillate(basePeriod: 14, amplitudeScale: 1, phaseOffset: 2),
      'confused' => oscillate(basePeriod: 9, amplitudeScale: 1, phaseOffset: 1),
      'scared' => oscillate(basePeriod: 6, amplitudeScale: 1),
      _ => 0,
    };
  }

  int headBobY() {
    return switch (id) {
      'idle' => (oscillate(
                basePeriod: 10,
                amplitudeScale: 1,
                phaseOffset: _cycleJitter('idle.phase', period: _period(10)),
              ) +
              _cycleJitter('idle.bob', period: _period(10))) ~/
          2,
      'talking' => oscillate(basePeriod: 8, amplitudeScale: 1) ~/ 2,
      'laughing' => oscillate(basePeriod: 5, amplitudeScale: 1),
      'celebration' => oscillate(basePeriod: 4, amplitudeScale: 2),
      'happy' => oscillate(basePeriod: 8, amplitudeScale: 1) ~/ 2,
      'sad' => -clampInt(pulse(basePeriod: 12, peak: 1), 0, 1),
      'angry' => oscillate(basePeriod: 7, amplitudeScale: 1) ~/ 2,
      'thinking' => -pulse(basePeriod: 14, peak: 1),
      'confused' => oscillate(basePeriod: 9, amplitudeScale: 1) ~/ 2,
      'surprised' => -pulse(basePeriod: 10, peak: 2),
      'sleeping' => oscillate(basePeriod: 16, amplitudeScale: 1) ~/ 2,
      'hurt' => oscillate(basePeriod: 7, amplitudeScale: 1),
      'scared' => oscillate(basePeriod: 4, amplitudeScale: 1),
      _ => 0,
    };
  }

  int traitSwingX() {
    return switch (id) {
      'celebration' => oscillate(basePeriod: 5, amplitudeScale: 2),
      'laughing' => oscillate(basePeriod: 6, amplitudeScale: 1),
      'thinking' => oscillate(basePeriod: 12, amplitudeScale: 1),
      'confused' => oscillate(basePeriod: 8, amplitudeScale: 1),
      'angry' => oscillate(basePeriod: 7, amplitudeScale: 1),
      'happy' => oscillate(basePeriod: 9, amplitudeScale: 1),
      'hurt' => -pulse(basePeriod: 8, peak: 1),
      'surprised' => oscillate(basePeriod: 10, amplitudeScale: 1),
      'scared' => oscillate(basePeriod: 4, amplitudeScale: 1),
      'sleeping' => oscillate(basePeriod: 16, amplitudeScale: 1) ~/ 2,
      _ => 0,
    };
  }

  int accessorySwingX() {
    return switch (id) {
      'jewelrySwing' => oscillate(basePeriod: 8, amplitudeScale: 1),
      'talking' => oscillate(basePeriod: 10, amplitudeScale: 1) ~/ 2,
      'laughing' => oscillate(basePeriod: 6, amplitudeScale: 1),
      'celebration' => oscillate(basePeriod: 5, amplitudeScale: 2),
      'happy' => oscillate(basePeriod: 9, amplitudeScale: 1) ~/ 2,
      'sad' => oscillate(basePeriod: 14, amplitudeScale: 1) ~/ 2,
      'angry' => oscillate(basePeriod: 7, amplitudeScale: 1),
      'thinking' => oscillate(basePeriod: 12, amplitudeScale: 1) ~/ 2,
      'confused' => oscillate(basePeriod: 8, amplitudeScale: 1),
      'hurt' => -pulse(basePeriod: 8, peak: 1),
      'scared' => oscillate(basePeriod: 4, amplitudeScale: 1),
      'surprised' => oscillate(basePeriod: 10, amplitudeScale: 1),
      'sleeping' => oscillate(basePeriod: 16, amplitudeScale: 1) ~/ 2,
      _ => 0,
    };
  }

  int propSwingX() {
    return switch (id) {
      'talking' => oscillate(basePeriod: 6, amplitudeScale: 1),
      'laughing' => oscillate(basePeriod: 5, amplitudeScale: 1),
      'celebration' => oscillate(basePeriod: 4, amplitudeScale: 2),
      'scared' => oscillate(basePeriod: 4, amplitudeScale: 1),
      'surprised' => oscillate(basePeriod: 10, amplitudeScale: 1),
      'happy' => oscillate(basePeriod: 9, amplitudeScale: 1),
      'sad' => oscillate(basePeriod: 14, amplitudeScale: 1) ~/ 2,
      'angry' => oscillate(basePeriod: 7, amplitudeScale: 1),
      'thinking' => oscillate(basePeriod: 12, amplitudeScale: 1) ~/ 2,
      'confused' => oscillate(basePeriod: 8, amplitudeScale: 1),
      'hurt' => -pulse(basePeriod: 8, peak: 1),
      'sleeping' => oscillate(basePeriod: 14, amplitudeScale: 1) ~/ 2,
      _ => 0,
    };
  }

  int _cycleHash(String channel, {required int period}) {
    final cycleIndex = phase ~/ (period <= 0 ? 1 : period);
    return fnv1a32('$randomKey:$id:$channel:$cycleIndex:$speed:$amplitude');
  }

  int _cycleJitter(String channel, {required int period, int magnitude = 1}) {
    final span = magnitude * 2 + 1;
    return positiveMod(_cycleHash(channel, period: period), span) - magnitude;
  }

  int _period(int basePeriod) => clampInt(basePeriod + (7 - speed), 3, 24);
}
