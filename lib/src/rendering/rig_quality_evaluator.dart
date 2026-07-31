import 'dart:math' as math;

import 'rig_model.dart';
import 'rig_transform_solver.dart';

final class RigQualityReport {
  const RigQualityReport({
    required this.maxAttachError,
    required this.maxDistanceViolation,
    required this.constraints,
  });

  final double maxAttachError;
  final double maxDistanceViolation;
  final List<Map<String, Object>> constraints;

  Map<String, Object> toJson() => <String, Object>{
        'maxAttachError': maxAttachError,
        'maxDistanceViolation': maxDistanceViolation,
        'constraints': constraints,
      };
}

final class RigQualityEvaluator {
  const RigQualityEvaluator();

  RigQualityReport evaluate(RigGraph graph, RigPose pose) {
    final resolver = const RigWorldResolver();
    final matrices = resolver.resolveMatrices(graph, pose);
    var maxAttach = 0.0;
    var maxDistance = 0.0;
    final values = <Map<String, Object>>[];

    for (final constraint in graph.constraints) {
      if (constraint.anchorIds.length < 2) continue;
      final first = resolver.worldAnchor(
        graph,
        pose,
        constraint.anchorIds[0],
        matrices: matrices,
      );
      final second = resolver.worldAnchor(
        graph,
        pose,
        constraint.anchorIds[1],
        matrices: matrices,
      );
      final dx = second.x - first.x;
      final dy = second.y - first.y;
      final distance = math.sqrt((dx * dx + dy * dy).toDouble());
      var error = 0.0;
      if (constraint.kind == RigConstraintKind.attach) {
        error = distance;
        if (error > maxAttach) maxAttach = error;
      } else if (constraint.kind == RigConstraintKind.fixedDistance) {
        if (constraint.minimum != null && distance < constraint.minimum!) {
          error = constraint.minimum! - distance;
        }
        if (constraint.maximum != null && distance > constraint.maximum!) {
          error = distance - constraint.maximum!;
        }
        if (error > maxDistance) maxDistance = error;
      }
      values.add(<String, Object>{
        'id': constraint.id,
        'kind': constraint.kind.name,
        'distance': distance,
        'error': error,
        'first': first.toJson(),
        'second': second.toJson(),
      });
    }

    return RigQualityReport(
      maxAttachError: maxAttach,
      maxDistanceViolation: maxDistance,
      constraints: List.unmodifiable(values),
    );
  }
}
