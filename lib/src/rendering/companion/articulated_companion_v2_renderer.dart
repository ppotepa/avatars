import '../../geometry/point.dart';
import '../../pixels/pixel_mask.dart';
import '../../util/math_utils.dart';
import '../render_helpers.dart';
import '../render_model.dart';
import '../rig_anchor_resolver.dart';
import '../rig_model.dart';
import '../rig_transform_solver.dart';
import 'companion_rig_v2_model.dart';
import 'companion_style_registry.dart';

/// Renders all shoulder creatures through one articulated mini-rig.
///
/// Every moving appendage has an explicit pivot. Geometry is animated around
/// those pivots before the avatar-level rig inherits the selected shoulder
/// transform, so wings, arms, legs, ears, antennas and tentacles never drift
/// away from the body that carries them.
final class ArticulatedCompanionV2Renderer implements AvatarPartRenderer {
  const ArticulatedCompanionV2Renderer({
    this.anchorResolver = const RigAnchorResolver(),
  });

  final RigAnchorResolver anchorResolver;

  @override
  void render(AvatarRenderContext context, AvatarRenderState state) {
    final primary = context.string('v4.shoulderProp');
    final extra = context.string('v4.extraShoulderProp');
    final style = primary != 'none' ? primary : extra;
    final spec = companionStyle(style);
    if (spec == null) return;

    final side = context.integer('v4.propSide') == 0
        ? (context.random('companion.v2.side').nextBool() ? -1 : 1)
        : context.integer('v4.propSide').sign;
    final anchors = <String, PixelPoint>{
      for (final anchor in anchorResolver.resolve(context.layout, state))
        anchor.id: anchor.localPosition,
    };
    final shoulderId =
        side < 0 ? 'leftShoulder.joint' : 'rightShoulder.joint';
    final shoulder = anchors[shoulderId];
    if (shoulder == null) return;

    state.layers.removeWhere(
      (layer) =>
          layer.id.startsWith('shoulderProp.') ||
          layer.id.startsWith('companion.v42') ||
          layer.id.startsWith('companion.rig.') ||
          layer.id.startsWith('companion.v2.'),
    );

    final attachment = side < 0
        ? 'leftShoulderAttachment'
        : 'rightShoulderAttachment';
    final root = PixelPoint(
      shoulder.x + side,
      shoulder.y - (spec.floats ? 3 : 1),
    );
    final parts = CompanionRigParts();
    spec.paint(parts, root.x, root.y, side);
    parts.deriveMissingAnchors(root);

    state
      ..parentNode(CompanionNode.root, attachment)
      ..anchorNode(CompanionNode.root, shoulderId);
    for (final entry in parts.parents.entries) {
      state.parentNode(entry.key, entry.value);
    }

    final local = _sampleLocalPose(context, spec, parts, side);
    final matrices = parts.worldMatrices(local);
    final animatedJoints = parts.animatedJoints(matrices);
    final blink = _isBlinkFrame(context);

    var order = 192;
    final partCounts = <String, int>{};
    for (final node in CompanionNode.all) {
      var source = parts[node];
      if (blink && node == CompanionNode.eyes) {
        source = PixelMask(width: source.width, height: source.height);
      }
      if (!_partVisible(context, style, node)) {
        source = PixelMask(width: source.width, height: source.height);
      }
      if (source.count == 0) continue;
      final matrix = matrices[node] ?? RigMatrix.identity;
      final mask = _transformMask(source, matrix);
      if (mask.count == 0) continue;
      final anchor = animatedJoints[node];
      state.addLayer(
        'companion.v2.$style.${_suffix(node)}',
        order++,
        mask,
        context.color(parts.colorRoles[node] ?? 'clothAccent'),
        nodeId: node,
        slot: RenderSlot.shoulderCompanion,
        meta: <String, Object?>{
          'part': 'shoulderCompanion',
          'companionStyle': style,
          'rigSegment': node,
          'attachmentSide': side,
          if (anchor != null) 'anchor': anchor.toJson(),
        },
      );
      partCounts[node] = mask.count;
    }

    final anchorJson = <String, Object>{
      'shoulder': shoulder.toJson(),
      for (final entry in animatedJoints.entries)
        entry.key: entry.value.toJson(),
    };
    state.metadata['companionRig'] = <String, Object>{
      'version': 2,
      'style': style,
      'profile': spec.profile.name,
      'side': side,
      'attachment': attachment,
      'speaks': spec.speaks,
      'floats': spec.floats,
      'anchors': anchorJson,
      'parts': partCounts,
      'localTransforms': <String, Object>{
        for (final entry in local.entries)
          entry.key: _matrixJson(entry.value),
      },
      ...parts.metadata,
    };

    final runtimeAnchors = <Object>[];
    final existingRuntimeAnchors = state.metadata['runtimeAnchors'];
    if (existingRuntimeAnchors is List) {
      runtimeAnchors.addAll(existingRuntimeAnchors.cast<Object>());
    }
    runtimeAnchors.addAll(<Object>[
      for (final entry in animatedJoints.entries)
        <String, Object>{
          'id': 'companion.${_suffix(entry.key)}.anchor',
          'nodeId': entry.key,
          'x': entry.value.x,
          'y': entry.value.y,
        },
    ]);
    state.metadata['runtimeAnchors'] = runtimeAnchors;
  }

  Map<String, RigMatrix> _sampleLocalPose(
    AvatarRenderContext context,
    CompanionStyleSpec spec,
    CompanionRigParts parts,
    int side,
  ) {
    final active = context.string('v4.animation') != 'none' ||
        context.string('v4.faceAnimation') != 'none';
    if (!active) return const <String, RigMatrix>{};

    final speed = clampInt(context.integer('v4.animationSpeed', 3), 1, 6);
    final period = animationPeriod(speed, slow: 22, fast: 8);
    final phase = context.phase;
    final slow = cyclicOffset(phase - 3, period, 1);
    final medium = cyclicOffset(phase, clampInt(period ~/ 2, 4, period), 1);
    final fast = cyclicOffset(phase, clampInt(period ~/ 3, 3, period), 1);
    final delayed = cyclicOffset(phase - 5, period, 2);
    final speaking = spec.speaks &&
        <String>{'talk', 'laugh', 'happy', 'angry'}
            .contains(context.string('v4.faceAnimation'));
    final output = <String, RigMatrix>{};

    void rotate(String node, int degrees) {
      final pivot = parts.joints[node];
      if (pivot == null || degrees == 0) return;
      final next = RigMatrix.rotationAround(
        degrees,
        pivotX: pivot.x,
        pivotY: pivot.y,
      );
      output[node] = (output[node] ?? RigMatrix.identity).followedBy(next);
    }

    void translate(String node, int dx, int dy) {
      if (dx == 0 && dy == 0) return;
      final current = output[node] ?? RigMatrix.identity;
      output[node] = current.followedBy(RigMatrix.translation(dx, dy));
    }

    switch (spec.profile) {
      case CompanionMotionProfile.bird:
        rotate(CompanionNode.head, slow * 4);
        rotate(CompanionNode.leftWing, -18 - fast * 12);
        rotate(CompanionNode.rightWing, 18 + fast * 12);
        rotate(CompanionNode.tail, delayed * 5);
        rotate(CompanionNode.leftEar, -medium * 3);
        rotate(CompanionNode.rightEar, medium * 3);
        if (speaking) {
          translate(CompanionNode.beak, 0, positiveMod(phase, 2));
        }
        break;
      case CompanionMotionProfile.quadruped:
        rotate(CompanionNode.head, slow * 4);
        rotate(CompanionNode.leftEar, -medium * 4);
        rotate(CompanionNode.rightEar, medium * 4);
        rotate(CompanionNode.tail, delayed * 7);
        rotate(CompanionNode.leftLeg, medium * 4);
        rotate(CompanionNode.rightLeg, -medium * 4);
        if (speaking) {
          translate(CompanionNode.mouth, 0, positiveMod(phase, 2));
        }
        break;
      case CompanionMotionProfile.humanoid:
        rotate(CompanionNode.head, slow * 3);
        rotate(CompanionNode.leftArm, -medium * 8);
        rotate(CompanionNode.rightArm, medium * 8);
        rotate(CompanionNode.leftLeg, medium * 4);
        rotate(CompanionNode.rightLeg, -medium * 4);
        rotate(CompanionNode.heldItem, delayed * 3);
        rotate(CompanionNode.leftAntenna, -delayed * 3);
        rotate(CompanionNode.rightAntenna, delayed * 3);
        if (speaking) {
          translate(CompanionNode.mouth, 0, positiveMod(phase, 2));
        }
        break;
      case CompanionMotionProfile.floating:
        translate(CompanionNode.body, 0, medium > 0 ? -1 : 0);
        rotate(CompanionNode.head, slow * 3);
        rotate(CompanionNode.leftArm, -medium * 6);
        rotate(CompanionNode.rightArm, medium * 6);
        rotate(CompanionNode.leftTentacle, -delayed * 5);
        rotate(CompanionNode.rightTentacle, delayed * 5);
        rotate(CompanionNode.trail, slow * 3);
        if (speaking) {
          translate(CompanionNode.mouth, 0, positiveMod(phase, 2));
        }
        break;
      case CompanionMotionProfile.mechanical:
        rotate(CompanionNode.head, slow * 2);
        rotate(CompanionNode.leftWing, -fast * 18);
        rotate(CompanionNode.rightWing, fast * 18);
        rotate(CompanionNode.leftArm, -medium * 7);
        rotate(CompanionNode.rightArm, medium * 7);
        rotate(CompanionNode.leftAntenna, -delayed * 5);
        rotate(CompanionNode.rightAntenna, delayed * 5);
        rotate(CompanionNode.heldItem, medium * 5);
        if (speaking) {
          translate(CompanionNode.mouth, 0, positiveMod(phase, 2));
        }
        break;
      case CompanionMotionProfile.tentacled:
        rotate(CompanionNode.head, slow * 3);
        rotate(CompanionNode.leftTentacle, -10 - delayed * 6);
        rotate(CompanionNode.rightTentacle, 10 + delayed * 6);
        rotate(CompanionNode.leftArm, -medium * 5);
        rotate(CompanionNode.rightArm, medium * 5);
        rotate(CompanionNode.tail, delayed * 5);
        if (speaking) {
          translate(CompanionNode.mouth, side, positiveMod(phase, 2));
        }
        break;
      case CompanionMotionProfile.slime:
        translate(CompanionNode.body, medium, medium.abs());
        rotate(CompanionNode.leftTentacle, -delayed * 6);
        rotate(CompanionNode.rightTentacle, delayed * 6);
        translate(CompanionNode.eyes, slow, 0);
        if (speaking) {
          translate(CompanionNode.mouth, 0, positiveMod(phase, 2));
        }
        break;
      case CompanionMotionProfile.arcade:
        rotate(CompanionNode.body, medium * 3);
        rotate(CompanionNode.leftArm, -fast * 8);
        rotate(CompanionNode.rightArm, fast * 8);
        rotate(CompanionNode.leftLeg, medium * 5);
        rotate(CompanionNode.rightLeg, -medium * 5);
        translate(CompanionNode.trail, -side * positiveMod(phase, 2), 0);
        if (speaking) {
          translate(
            CompanionNode.mouth,
            side * positiveMod(phase, 2),
            0,
          );
        }
        break;
    }

    switch (spec.id) {
      case 'parrot':
      case 'crow':
      case 'raven':
        translate(CompanionNode.beak, 0, positiveMod(phase, 4) == 0 ? 1 : 0);
        break;
      case 'miniSkeleton':
      case 'skullHands':
        translate(CompanionNode.mouth, 0, positiveMod(phase, 2));
        rotate(CompanionNode.leftArm, -slow * 10);
        rotate(CompanionNode.rightArm, slow * 10);
        break;
      case 'miniReaper':
        rotate(CompanionNode.heldItem, 6 + delayed * 6);
        break;
      case 'miniUfo':
      case 'scoutDrone':
      case 'miniDrone':
        translate(CompanionNode.body, slow, medium > 0 ? -1 : 0);
        rotate(CompanionNode.leftWing, -fast * 24);
        rotate(CompanionNode.rightWing, fast * 24);
        break;
      case 'robotSpider':
        rotate(CompanionNode.leftArm, -12 - fast * 8);
        rotate(CompanionNode.rightArm, 12 + fast * 8);
        rotate(CompanionNode.leftLeg, 10 + medium * 7);
        rotate(CompanionNode.rightLeg, -10 - medium * 7);
        break;
      case 'bookFamiliar':
        rotate(CompanionNode.leftWing, -12 - fast * 10);
        rotate(CompanionNode.rightWing, 12 + fast * 10);
        break;
      case 'arcadeChomper':
        translate(CompanionNode.trail, -side * positiveMod(phase, 3), 0);
        break;
      case 'stormCloud':
        rotate(CompanionNode.leftTentacle, -medium * 4);
        rotate(CompanionNode.rightTentacle, medium * 4);
        break;
      case 'blackHole':
        rotate(CompanionNode.trail, 8 + phase * 9);
        rotate(CompanionNode.leftTentacle, -delayed * 8);
        rotate(CompanionNode.rightTentacle, delayed * 8);
        break;
      case 'coffeeBuddy':
        translate(CompanionNode.trail, slow, -positiveMod(phase, 3));
        break;
      case 'donutBuddy':
      case 'diceBuddy':
        rotate(CompanionNode.body, phase * 5);
        break;
      case 'alienBlob':
      case 'slime':
        translate(CompanionNode.body, medium, medium.abs());
        break;
    }
    return output;
  }

  bool _partVisible(
    AvatarRenderContext context,
    String style,
    String node,
  ) {
    final phase = context.phase;
    if (style == 'arcadeChomper' && node == CompanionNode.mouth) {
      return positiveMod(phase, 4) < 2;
    }
    if (style == 'stormCloud' && node == CompanionNode.trail) {
      return positiveMod(phase, 7) <= 1;
    }
    if (style == 'hologramAssistant' && node != CompanionNode.body) {
      return positiveMod(phase + node.length, 9) != 0;
    }
    return true;
  }

  bool _isBlinkFrame(AvatarRenderContext context) {
    final speed = clampInt(context.integer('v4.animationSpeed', 3), 1, 6);
    final period = animationPeriod(speed, slow: 31, fast: 16);
    final phase = positiveMod(context.phase + 7, period);
    return phase == 0;
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

  String _suffix(String nodeId) => nodeId
      .replaceFirst('companion', '')
      .replaceFirst('shoulder', '')
      .replaceFirstMapped(
        RegExp(r'^.'),
        (match) => match.group(0)!.toLowerCase(),
      );

  Map<String, double> _matrixJson(RigMatrix matrix) => <String, double>{
        'a': matrix.a,
        'b': matrix.b,
        'c': matrix.c,
        'd': matrix.d,
        'tx': matrix.tx,
        'ty': matrix.ty,
      };
}
