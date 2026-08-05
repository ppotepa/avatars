import '../api/avatar_request.dart';

final class CameraSamplePlan {
  CameraSamplePlan({
    required Iterable<int> phases,
    required this.policyVersion,
    required this.reason,
  }) : phases = List<int>.unmodifiable(phases);

  final List<int> phases;
  final String policyVersion;
  final String reason;

  bool get isSingleFrame => phases.length == 1;
}

final class CameraSamplingPolicy {
  const CameraSamplingPolicy();

  static const String version = 'camera-sampling.2';
  static const List<int> _animationEnvelope = <int>[
    0, 1, 2, 3, 4, 5, 6, 7,
    8, 9, 10, 11, 12, 13, 14, 15,
  ];

  CameraSamplePlan plan(AvatarRequest request) {
    if (request.phase == 0 && request.rendering.reducedMotion) {
      return CameraSamplePlan(
        phases: const <int>[0],
        policyVersion: version,
        reason: 'reducedMotionStaticFrame',
      );
    }
    if (request.phase >= _animationEnvelope.length) {
      return CameraSamplePlan(
        phases: <int>[..._animationEnvelope, request.phase],
        policyVersion: version,
        reason: 'boundedExactRequestedPhase',
      );
    }
    return CameraSamplePlan(
      phases: _animationEnvelope,
      policyVersion: version,
      reason: 'animationSafeEnvelope',
    );
  }
}
