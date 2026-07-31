import '../pixels/pixel_mask.dart';
import 'render_model.dart';
import 'rig_model.dart';
import 'rig_transform_solver.dart';

/// Applies a solved pose to every layer exactly once.
///
/// This replaces sequential subtree translations, which caused a head to move
/// once for the torso, once for the neck and once for the head itself. World
/// matrices already contain inherited motion, so every pixel is transformed by
/// only the matrix of its owning node.
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

    for (final entry in state.masks.entries.toList(growable: false)) {
      final nodeId = _maskNode(entry.key);
      final matrix = matrices[nodeId] ?? RigMatrix.identity;
      state.masks[entry.key] = _transformMask(entry.value, matrix);
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

    if (state.metadata.containsKey('hairRig')) {
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
        'companionWings',
        'companionTail',
        'companionEars',
        'companionEyes',
        'companionBeak',
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
    return output;
  }

  bool _isIdentity(RigMatrix matrix) =>
      (matrix.a - 1).abs() < .000001 &&
      matrix.b.abs() < .000001 &&
      matrix.c.abs() < .000001 &&
      (matrix.d - 1).abs() < .000001 &&
      matrix.tx.abs() < .000001 &&
      matrix.ty.abs() < .000001;

  String _maskNode(String id) {
    if (id.startsWith('hair.back.root')) return 'hairBackRoot';
    if (id.startsWith('hair.back.middle')) return 'hairBackMiddle';
    if (id.startsWith('hair.back.tips')) return 'hairBackTips';
    if (id.startsWith('hair.side.left.root')) return 'hairSideLeftRoot';
    if (id.startsWith('hair.side.left.tip')) return 'hairSideLeftTip';
    if (id.startsWith('hair.side.right.root')) return 'hairSideRightRoot';
    if (id.startsWith('hair.side.right.tip')) return 'hairSideRightTip';
    if (id.startsWith('hair.back')) return 'hairBack';
    if (id.startsWith('hair.front') || id == 'hair.all') return 'hairFront';
    if (id.startsWith('head')) return 'head';
    if (id.startsWith('neck')) return 'neck';
    if (id.startsWith('torso') || id == 'skinChest') return 'torso';
    if (id.startsWith('clothing')) return 'clothing';
    if (id.startsWith('armor')) return 'armor';
    if (id.startsWith('eye')) return 'eyes';
    if (id.startsWith('mouth')) return 'mouth';
    if (id.startsWith('ear')) return 'ears';
    if (id.startsWith('headwear')) return 'headwear';
    if (id.startsWith('eyewear')) return 'eyewear';
    if (id.startsWith('faceMask')) return 'faceMask';
    if (id.startsWith('necklace.left')) return 'necklaceLeft';
    if (id.startsWith('necklace.right')) return 'necklaceRight';
    if (id.startsWith('necklace.pendant')) return 'pendant';
    if (id.startsWith('jewelry')) return 'necklace';
    if (id.startsWith('companion.body')) return 'companionBody';
    if (id.startsWith('companion.head')) return 'companionHead';
    if (id.startsWith('companion.wings')) return 'companionWings';
    if (id.startsWith('companion.tail')) return 'companionTail';
    if (id.startsWith('companion.ears')) return 'companionEars';
    if (id.startsWith('companion.beak')) return 'companionBeak';
    if (id.startsWith('companion.eyes')) return 'companionEyes';
    if (id.startsWith('shoulderProp')) return 'shoulderCompanion';
    return 'actor';
  }
}
