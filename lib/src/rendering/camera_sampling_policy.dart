import '../api/avatar_request.dart';

final class CameraSamplePlan {
  const CameraSamplePlan({
    required this.phases,
    required this.policyVersion,
    required this.reason,
  });

  final List<int> phases;
  final String policyVersion;
  final String reason;

  bool get isSingleFrame => phases.length == 1;
}

final class CameraSamplingPolicy {
  const CameraSamplingPolicy();

  static const String version = 'camera-sampling.1';

  CameraSamplePlan plan(AvatarRequest request) {
    if (request.phase == 0 && request.rendering.reducedMotion) {
      return const CameraSamplePlan(
        phases: <int>[0],
        policyVersion: version,
        reason: 'reducedMotionStaticFrame',
      );
    }
    if (request.phase >= 16) {
      return CameraSamplePlan(
        phases: <int>[for (var phase = 0; phase <= request.phase; phase++) phase],
        policyVersion: version,
        reason: 'exactRequestedPhase',
      );
    }
    return const CameraSamplePlan(
      phases: <int>[
        0, 1, 2, 3, 4, 5, 6, 7,
        8, 9, 10, 11, 12, 13, 14, 15,
      ],
      policyVersion: version,
      reason: 'animationSafeEnvelope',
    );
  }
}
