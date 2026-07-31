import '../pixels/pixel_mask.dart';
import 'render_model.dart';
import 'rig_model.dart';
import 'rig_transform_solver.dart';

/// Applies a solved pose to every render layer exactly once.
///
/// Semantic masks are rebuilt from transformed layers by [RigClipPipeline].
/// Keeping ownership on [RenderLayer.nodeId] removes the former second mapping
/// based on mask-name prefixes.
final class RigPoseApplier {
  const RigPoseApplier();

  RigPose solveAndApply(
    AvatarRenderState state,
    RigGraph graph,
    RigPose requestedPose,
  ) {
    final ownedPose = _removeDuplicateSecondaryMotion(state, requestedPose);
    final solved = const RigConstraintSolver().solve(graph, ownedPose);
    final matrices = const RigWorldResolver().resolveMatrices(graph, solved);

    for (var index = 0; index < state.layers.length; index++) {
      final layer = state.layers[index];
      final matrix = matrices[layer.nodeId] ?? RigMatrix.identity;
      state.layers[index] = layer.copyWith(
        mask: _transformMask(layer.mask, matrix),
      );
    }

    state.nodeTransforms
      ..clear()
      ..addAll(solved.transforms);
    state.metadata['rigWorldTransforms'] = <String, Object>{
      for (final entry in matrices.entries)
        entry.key: <String, double>{
          'a': entry.value.a,
          'b': entry.value.b,
          'c': entry.value.c,
          'd': entry.value.d,
          'tx': entry.value.tx,
          'ty': entry.value.ty,
        },
    };
    return solved;
  }

  RigPose _removeDuplicateSecondaryMotion(
    AvatarRenderState state,
    RigPose requested,
  ) {
    final pose = requested.clone();

    void remove(Iterable<String> ids) {
      for (final id in ids) pose.transforms.remove(id);
    }

    final hairRig = state.metadata['hairRig'];
    final localHairMotion = hairRig is Map && hairRig['localMotion'] == true;
    if (localHairMotion) {
      remove(const <String>[
        'hairBackMiddle',
        'hairBackTips',
        'hairSideLeftRoot',
        'hairSideLeftTip',
        'hairSideRightRoot',
        'hairSideRightTip',
      ]);
    }
    if (state.metadata.containsKey('jewelryRig')) {
      remove(const <String>[
        'necklace',
        'necklaceLeft',
        'necklaceRight',
        'pendant',
        'leftEarJewelry',
        'rightEarJewelry',
      ]);
    }
    if (state.metadata.containsKey('companionRig')) {
      remove(const <String>[
        'shoulderCompanion',
        'companionBody',
        'companionHead',
        'companionEyes',
        'companionMouth',
        'companionBeak',
        'companionWings',
        'companionLeftWing',
        'companionRightWing',
        'companionLeftArm',
        'companionRightArm',
        'companionLeftLeg',
        'companionRightLeg',
        'companionTail',
        'companionEars',
        'companionLeftEar',
        'companionRightEar',
        'companionLeftAntenna',
        'companionRightAntenna',
        'companionLeftTentacle',
        'companionRightTentacle',
        'companionHeldItem',
        'companionTrail',
        'companionShadow',
        'companionLight',
      ]);
    }
    if (state.metadata.containsKey('backRig')) {
      remove(const <String>[
        'capeMidLeft',
        'capeMidRight',
        'capeTipLeft',
        'capeTipRight',
        'leftWingMid',
        'leftWingTip',
        'rightWingMid',
        'rightWingTip',
      ]);
    }
    return pose;
  }

  PixelMask _transformMask(PixelMask source, RigMatrix matrix) {
    if (_isIdentity(matrix)) return source.clone();
    final output = PixelMask(width: source.width, height: source.height);
    final determinant = matrix.a * matrix.d - matrix.b * matrix.c;
    if (determinant.abs() < .000001) return source.clone();
    final inverseA = matrix.d / determinant;
    final inverseB = -matrix.b / determinant;
    final inverseC = -matrix.c / determinant;
    final inverseD = matrix.a / determinant;

    // Inverse sampling keeps filled surfaces continuous.
    for (var y = 0; y < output.height; y++) {
      for (var x = 0; x < output.width; x++) {
        final shiftedX = x - matrix.tx;
        final shiftedY = y - matrix.ty;
        final sourceX = inverseA * shiftedX + inverseC * shiftedY;
        final sourceY = inverseB * shiftedX + inverseD * shiftedY;
        if (source.get(sourceX.round(), sourceY.round()) != 0) {
          output.set(x, y);
        }
      }
    }

    // Forward sampling preserves one-pixel tips, pivots and thin chains that can
    // otherwise disappear between inverse-sampled destination centers.
    for (var y = 0; y < source.height; y++) {
      for (var x = 0; x < source.width; x++) {
        if (source.get(x, y) == 0) continue;
        final destinationX = matrix.a * x + matrix.c * y + matrix.tx;
        final destinationY = matrix.b * x + matrix.d * y + matrix.ty;
        output.set(destinationX.round(), destinationY.round());
      }
    }
    return output;
  }

  bool _isIdentity(RigMatrix matrix) =>
      (matrix.a - 1).abs() < .000001 &&
      matrix.b.abs() < .000001 &&
      matrix.c.abs() < .000001 &&
      (matrix.d - 1).abs() < .000001 &&
      matrix.tx.abs() < .000001 &&
      matrix.ty.abs() < .000001;
}
