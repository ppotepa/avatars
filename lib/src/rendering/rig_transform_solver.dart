import 'dart:math' as math;

import '../geometry/point.dart';
import '../util/math_utils.dart';
import 'rig_model.dart';

/// Deterministic affine transform used by the runtime rig.
///
/// Pixel geometry is rounded only when converted back to [PixelPoint]. Keeping
/// intermediate values as doubles prevents child translations from being added
/// in world space without respecting the parent's rotation and pivot.
final class RigMatrix {
  const RigMatrix(
    this.a,
    this.b,
    this.c,
    this.d,
    this.tx,
    this.ty,
  );

  static const identity = RigMatrix(1, 0, 0, 1, 0, 0);

  final double a;
  final double b;
  final double c;
  final double d;
  final double tx;
  final double ty;

  factory RigMatrix.translation(num dx, num dy) =>
      RigMatrix(1, 0, 0, 1, dx.toDouble(), dy.toDouble());

  factory RigMatrix.rotationAround(
    num degrees, {
    required num pivotX,
    required num pivotY,
  }) {
    if (degrees == 0) return RigMatrix.identity;
    final radians = degrees * math.pi / 180;
    final cosine = math.cos(radians);
    final sine = math.sin(radians);
    final px = pivotX.toDouble();
    final py = pivotY.toDouble();
    return RigMatrix(
      cosine,
      sine,
      -sine,
      cosine,
      px - cosine * px + sine * py,
      py - sine * px - cosine * py,
    );
  }

  RigMatrix followedBy(RigMatrix next) => RigMatrix(
        next.a * a + next.c * b,
        next.b * a + next.d * b,
        next.a * c + next.c * d,
        next.b * c + next.d * d,
        next.a * tx + next.c * ty + next.tx,
        next.b * tx + next.d * ty + next.ty,
      );

  ({double x, double y}) transform(num x, num y) => (
        x: a * x + c * y + tx,
        y: b * x + d * y + ty,
      );

  /// Converts a world-space vector into this matrix's local coordinate space.
  ({double x, double y}) inverseVector(num x, num y) {
    final determinant = a * d - b * c;
    if (determinant.abs() < .000001) {
      return (x: x.toDouble(), y: y.toDouble());
    }
    return (
      x: (d * x - c * y) / determinant,
      y: (-b * x + a * y) / determinant,
    );
  }

  PixelPoint transformPoint(PixelPoint point) {
    final result = transform(point.x, point.y);
    return PixelPoint(result.x.round(), result.y.round());
  }
}

extension RigTransformMatrix on RigTransform {
  RigMatrix toMatrix({PixelPoint? fallbackPivot}) {
    final pivot = PixelPoint(
      pivotX ?? fallbackPivot?.x ?? 0,
      pivotY ?? fallbackPivot?.y ?? 0,
    );
    return RigMatrix.rotationAround(
      rotationDegrees,
      pivotX: pivot.x,
      pivotY: pivot.y,
    ).followedBy(RigMatrix.translation(dx, dy));
  }
}

/// Resolves local poses and anchors into one coherent world-space hierarchy.
final class RigWorldResolver {
  const RigWorldResolver();

  Map<String, RigMatrix> resolveMatrices(RigGraph graph, RigPose pose) {
    final output = <String, RigMatrix>{};

    RigMatrix resolve(String nodeId) {
      final cached = output[nodeId];
      if (cached != null) return cached;
      final node = graph.byId[nodeId];
      if (node == null) throw StateError('Unknown rig node "$nodeId".');
      final parent = node.parentId == null
          ? RigMatrix.identity
          : resolve(node.parentId!);
      final pivot = node.anchorId == null
          ? null
          : graph.anchorById[node.anchorId!]?.localPosition;
      final local = node.restTransform
          .toMatrix(fallbackPivot: pivot)
          .followedBy(pose.transformFor(nodeId).toMatrix(fallbackPivot: pivot));
      return output[nodeId] = local.followedBy(parent);
    }

    for (final node in graph.nodes) {
      resolve(node.id);
    }
    return output;
  }

  PixelPoint worldAnchor(
    RigGraph graph,
    RigPose pose,
    String anchorId, {
    Map<String, RigMatrix>? matrices,
  }) {
    final anchor = graph.anchorById[anchorId];
    if (anchor == null) throw StateError('Unknown rig anchor "$anchorId".');
    final resolved = matrices ?? resolveMatrices(graph, pose);
    return resolved[anchor.nodeId]!.transformPoint(anchor.localPosition);
  }
}

/// Small deterministic positional solver for attachments and chains.
///
/// It adjusts child translations in the coordinate system of the child's
/// parent. This keeps constraints correct when a shoulder, neck or torso has
/// already rotated.
final class RigConstraintSolver {
  const RigConstraintSolver({this.iterations = 5});

  final int iterations;

  RigPose solve(RigGraph graph, RigPose input) {
    final pose = input.clone();
    final resolver = const RigWorldResolver();
    for (var iteration = 0; iteration < iterations; iteration++) {
      for (final constraint in graph.constraints) {
        switch (constraint.kind) {
          case RigConstraintKind.attach:
            _solveAttach(graph, pose, resolver, constraint);
            break;
          case RigConstraintKind.fixedDistance:
            _solveDistance(graph, pose, resolver, constraint);
            break;
          case RigConstraintKind.limitRotation:
            _limitRotation(pose, constraint);
            break;
          case RigConstraintKind.keepInsideCanvas:
            break;
        }
      }
    }
    return pose;
  }

  void _solveAttach(
    RigGraph graph,
    RigPose pose,
    RigWorldResolver resolver,
    RigConstraint constraint,
  ) {
    if (constraint.nodeIds.length < 2 || constraint.anchorIds.length < 2) {
      return;
    }
    final matrices = resolver.resolveMatrices(graph, pose);
    final parentPoint = resolver.worldAnchor(
      graph,
      pose,
      constraint.anchorIds[0],
      matrices: matrices,
    );
    final childPoint = resolver.worldAnchor(
      graph,
      pose,
      constraint.anchorIds[1],
      matrices: matrices,
    );
    final childId = constraint.nodeIds[1];
    final worldDx = (parentPoint.x - childPoint.x) * constraint.stiffness;
    final worldDy = (parentPoint.y - childPoint.y) * constraint.stiffness;
    final local = _parentLocalVector(graph, matrices, childId, worldDx, worldDy);
    final current = pose.transformFor(childId);
    pose.set(
      childId,
      current.copyWith(
        dx: current.dx + local.x.round(),
        dy: current.dy + local.y.round(),
      ),
    );
  }

  void _solveDistance(
    RigGraph graph,
    RigPose pose,
    RigWorldResolver resolver,
    RigConstraint constraint,
  ) {
    if (constraint.nodeIds.length < 2 || constraint.anchorIds.length < 2) {
      return;
    }
    final matrices = resolver.resolveMatrices(graph, pose);
    final origin = resolver.worldAnchor(
      graph,
      pose,
      constraint.anchorIds[0],
      matrices: matrices,
    );
    final target = resolver.worldAnchor(
      graph,
      pose,
      constraint.anchorIds[1],
      matrices: matrices,
    );
    final dx = target.x - origin.x;
    final dy = target.y - origin.y;
    final distance = math.sqrt((dx * dx + dy * dy).toDouble());
    if (distance == 0) return;
    final wanted = clampDouble(
      constraint.minimum ?? distance,
      0,
      constraint.maximum ?? double.infinity,
    );
    final correction = (wanted - distance) * constraint.stiffness;
    final childId = constraint.nodeIds[1];
    final worldDx = dx / distance * correction;
    final worldDy = dy / distance * correction;
    final local = _parentLocalVector(graph, matrices, childId, worldDx, worldDy);
    final current = pose.transformFor(childId);
    pose.set(
      childId,
      current.copyWith(
        dx: current.dx + local.x.round(),
        dy: current.dy + local.y.round(),
      ),
    );
  }

  ({double x, double y}) _parentLocalVector(
    RigGraph graph,
    Map<String, RigMatrix> matrices,
    String childId,
    double worldX,
    double worldY,
  ) {
    final parentId = graph.byId[childId]?.parentId;
    final parent = parentId == null
        ? RigMatrix.identity
        : matrices[parentId] ?? RigMatrix.identity;
    return parent.inverseVector(worldX, worldY);
  }

  void _limitRotation(RigPose pose, RigConstraint constraint) {
    if (constraint.nodeIds.isEmpty) return;
    final id = constraint.nodeIds.last;
    final current = pose.transformFor(id);
    pose.set(
      id,
      current.copyWith(
        rotationDegrees: clampInt(
          current.rotationDegrees,
          (constraint.minimum ?? -180).round(),
          (constraint.maximum ?? 180).round(),
        ),
      ),
    );
  }
}
