import '../../geometry/point.dart';
import '../../pixels/pixel_mask.dart';
import '../rig_transform_solver.dart';

abstract final class CompanionNode {
  static const root = 'shoulderCompanion';
  static const body = 'companionBody';
  static const head = 'companionHead';
  static const eyes = 'companionEyes';
  static const mouth = 'companionMouth';
  static const beak = 'companionBeak';
  static const leftWing = 'companionLeftWing';
  static const rightWing = 'companionRightWing';
  static const leftArm = 'companionLeftArm';
  static const rightArm = 'companionRightArm';
  static const leftLeg = 'companionLeftLeg';
  static const rightLeg = 'companionRightLeg';
  static const tail = 'companionTail';
  static const leftEar = 'companionLeftEar';
  static const rightEar = 'companionRightEar';
  static const leftAntenna = 'companionLeftAntenna';
  static const rightAntenna = 'companionRightAntenna';
  static const leftTentacle = 'companionLeftTentacle';
  static const rightTentacle = 'companionRightTentacle';
  static const heldItem = 'companionHeldItem';
  static const trail = 'companionTrail';
  static const shadow = 'companionShadow';
  static const light = 'companionLight';

  static const all = <String>[
    body,
    head,
    eyes,
    mouth,
    beak,
    leftWing,
    rightWing,
    leftArm,
    rightArm,
    leftLeg,
    rightLeg,
    tail,
    leftEar,
    rightEar,
    leftAntenna,
    rightAntenna,
    leftTentacle,
    rightTentacle,
    heldItem,
    trail,
    shadow,
    light,
  ];
}

enum CompanionMotionProfile {
  bird,
  quadruped,
  humanoid,
  floating,
  mechanical,
  tentacled,
  slime,
  arcade,
}

typedef CompanionPainter = void Function(
  CompanionRigParts parts,
  int x,
  int y,
  int side,
);

final class CompanionStyleSpec {
  const CompanionStyleSpec({
    required this.id,
    required this.profile,
    required this.paint,
    this.speaks = false,
    this.floats = false,
  });

  final String id;
  final CompanionMotionProfile profile;
  final CompanionPainter paint;
  final bool speaks;
  final bool floats;
}

final class CompanionRigParts {
  CompanionRigParts({int width = 48, int height = 48})
      : width = width,
        height = height,
        masks = <String, PixelMask>{
          for (final node in CompanionNode.all)
            node: PixelMask(width: width, height: height),
        },
        parents = <String, String>{
          CompanionNode.body: CompanionNode.root,
          CompanionNode.head: CompanionNode.body,
          CompanionNode.eyes: CompanionNode.head,
          CompanionNode.mouth: CompanionNode.head,
          CompanionNode.beak: CompanionNode.head,
          CompanionNode.leftWing: CompanionNode.body,
          CompanionNode.rightWing: CompanionNode.body,
          CompanionNode.leftArm: CompanionNode.body,
          CompanionNode.rightArm: CompanionNode.body,
          CompanionNode.leftLeg: CompanionNode.body,
          CompanionNode.rightLeg: CompanionNode.body,
          CompanionNode.tail: CompanionNode.body,
          CompanionNode.leftEar: CompanionNode.head,
          CompanionNode.rightEar: CompanionNode.head,
          CompanionNode.leftAntenna: CompanionNode.head,
          CompanionNode.rightAntenna: CompanionNode.head,
          CompanionNode.leftTentacle: CompanionNode.body,
          CompanionNode.rightTentacle: CompanionNode.body,
          CompanionNode.heldItem: CompanionNode.rightArm,
          CompanionNode.trail: CompanionNode.body,
          CompanionNode.shadow: CompanionNode.body,
          CompanionNode.light: CompanionNode.body,
        },
        colorRoles = <String, String>{
          CompanionNode.body: 'clothAccent',
          CompanionNode.head: 'clothAccent',
          CompanionNode.eyes: 'fantasyLight',
          CompanionNode.mouth: 'mouthDark',
          CompanionNode.beak: 'clothLight',
          CompanionNode.leftWing: 'clothLight',
          CompanionNode.rightWing: 'clothLight',
          CompanionNode.leftArm: 'clothAccent',
          CompanionNode.rightArm: 'clothAccent',
          CompanionNode.leftLeg: 'clothDark',
          CompanionNode.rightLeg: 'clothDark',
          CompanionNode.tail: 'clothAccent',
          CompanionNode.leftEar: 'clothAccent',
          CompanionNode.rightEar: 'clothAccent',
          CompanionNode.leftAntenna: 'fantasyLight',
          CompanionNode.rightAntenna: 'fantasyLight',
          CompanionNode.leftTentacle: 'fantasyBase',
          CompanionNode.rightTentacle: 'fantasyBase',
          CompanionNode.heldItem: 'clothLight',
          CompanionNode.trail: 'fantasyLight',
          CompanionNode.shadow: 'clothDark',
          CompanionNode.light: 'fantasyLight',
        };

  final int width;
  final int height;
  final Map<String, PixelMask> masks;
  final Map<String, String> parents;
  final Map<String, PixelPoint> joints = <String, PixelPoint>{};
  final Map<String, String> colorRoles;
  final Map<String, Object> metadata = <String, Object>{};

  PixelMask operator [](String nodeId) => masks[nodeId]!;

  void anchor(
    String childNode,
    PixelPoint point, {
    String? parentNode,
  }) {
    joints[childNode] = point;
    if (parentNode != null) parents[childNode] = parentNode;
  }

  void color(String nodeId, String role) {
    colorRoles[nodeId] = role;
  }

  void deriveMissingAnchors(PixelPoint root) {
    anchor(CompanionNode.body, root, parentNode: CompanionNode.root);
    for (final node in CompanionNode.all) {
      if (node == CompanionNode.body || joints.containsKey(node)) continue;
      final bounds = masks[node]!.bounds;
      if (bounds == null) continue;
      final parent = parents[node] ?? CompanionNode.body;
      final point = switch (node) {
        CompanionNode.head ||
        CompanionNode.leftEar ||
        CompanionNode.rightEar ||
        CompanionNode.leftAntenna ||
        CompanionNode.rightAntenna =>
          PixelPoint(bounds.center.x, bounds.bottom),
        CompanionNode.leftLeg || CompanionNode.rightLeg =>
          PixelPoint(bounds.center.x, bounds.top),
        CompanionNode.tail ||
        CompanionNode.leftWing ||
        CompanionNode.rightWing ||
        CompanionNode.leftArm ||
        CompanionNode.rightArm ||
        CompanionNode.leftTentacle ||
        CompanionNode.rightTentacle =>
          PixelPoint(
            node.contains('Left') ? bounds.right : bounds.left,
            bounds.top,
          ),
        _ => bounds.center,
      };
      anchor(node, point, parentNode: parent);
    }
  }

  Map<String, RigMatrix> worldMatrices(Map<String, RigMatrix> local) {
    final output = <String, RigMatrix>{CompanionNode.root: RigMatrix.identity};

    RigMatrix resolve(String nodeId) {
      final cached = output[nodeId];
      if (cached != null) return cached;
      final parentId = parents[nodeId] ?? CompanionNode.root;
      final parent = resolve(parentId);
      final matrix = local[nodeId] ?? RigMatrix.identity;
      return output[nodeId] = matrix.followedBy(parent);
    }

    for (final node in CompanionNode.all) resolve(node);
    return output;
  }

  Map<String, PixelPoint> animatedJoints(Map<String, RigMatrix> matrices) =>
      <String, PixelPoint>{
        for (final entry in joints.entries)
          entry.key:
              (matrices[parents[entry.key]] ?? RigMatrix.identity)
                  .transformPoint(entry.value),
      };
}
