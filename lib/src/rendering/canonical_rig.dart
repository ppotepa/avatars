import '../geometry/avatar_layout.dart';
import '../geometry/point.dart';
import 'rig_model.dart';

/// Canonical actor hierarchy shared by renderers, animation and diagnostics.
abstract final class CanonicalRig {
  static const Map<String, String?> parents = <String, String?>{
    'scene': null,
    'background': 'scene',
    'atmosphere': 'scene',
    'actor': 'scene',
    'torso': 'actor',
    'chest': 'torso',
    'clothing': 'torso',
    'armor': 'torso',
    'cape': 'torso',
    'backAdornment': 'torso',
    'necklace': 'torso',
    'leftShoulder': 'torso',
    'rightShoulder': 'torso',
    'leftArm': 'leftShoulder',
    'rightArm': 'rightShoulder',
    'leftHand': 'leftArm',
    'rightHand': 'rightArm',
    'leftShoulderAttachment': 'leftShoulder',
    'rightShoulderAttachment': 'rightShoulder',
    'shoulderCompanion': 'leftShoulderAttachment',
    'neck': 'torso',
    'head': 'neck',
    'face': 'head',
    'eyes': 'face',
    'brows': 'face',
    'mouth': 'face',
    'expressionMarks': 'face',
    'mouthProp': 'mouth',
    'smokeEmitter': 'mouthProp',
    'leftEar': 'head',
    'rightEar': 'head',
    'ears': 'head',
    'leftEarJewelry': 'leftEar',
    'rightEarJewelry': 'rightEar',
    'facialHair': 'head',
    'hairBack': 'head',
    'hairFront': 'head',
    'hairBackRoot': 'hairBack',
    'hairBackMiddle': 'hairBackRoot',
    'hairBackTips': 'hairBackMiddle',
    'hairSideLeftRoot': 'hairFront',
    'hairSideLeftTip': 'hairSideLeftRoot',
    'hairSideRightRoot': 'hairFront',
    'hairSideRightTip': 'hairSideRightRoot',
    'eyewear': 'head',
    'faceMask': 'head',
    'headwear': 'head',
    'horns': 'head',
    'halo': 'head',
    'headAdornment': 'head',
    'creatureTraits': 'head',
    'capeLeftRoot': 'leftShoulder',
    'capeRightRoot': 'rightShoulder',
    'capeCenter': 'torso',
    'capeMidLeft': 'capeLeftRoot',
    'capeMidRight': 'capeRightRoot',
    'capeTipLeft': 'capeMidLeft',
    'capeTipRight': 'capeMidRight',
    'leftWingRoot': 'torso',
    'leftWingMid': 'leftWingRoot',
    'leftWingTip': 'leftWingMid',
    'rightWingRoot': 'torso',
    'rightWingMid': 'rightWingRoot',
    'rightWingTip': 'rightWingMid',
    'actorEffects': 'actor',
    'aura': 'actor',
    'foreground': 'scene',
  };

  static RenderSlot slotFor(String id) => switch (id) {
        'scene' || 'background' || 'atmosphere' => RenderSlot.background,
        'aura' => RenderSlot.auraBack,
        'cape' ||
        'capeLeftRoot' ||
        'capeRightRoot' ||
        'capeCenter' ||
        'capeMidLeft' ||
        'capeMidRight' ||
        'capeTipLeft' ||
        'capeTipRight' ||
        'hairBack' ||
        'hairBackRoot' ||
        'hairBackMiddle' ||
        'hairBackTips' ||
        'leftWingRoot' ||
        'leftWingMid' ||
        'leftWingTip' ||
        'rightWingRoot' ||
        'rightWingMid' ||
        'rightWingTip' ||
        'backAdornment' =>
          RenderSlot.capeHairBack,
        'leftArm' || 'rightArm' => RenderSlot.rearArms,
        'actor' || 'torso' || 'chest' || 'clothing' || 'necklace' =>
          RenderSlot.torsoClothing,
        'armor' => RenderSlot.armor,
        'neck' => RenderSlot.neck,
        'head' || 'leftEar' || 'rightEar' || 'ears' => RenderSlot.head,
        'face' ||
        'eyes' ||
        'brows' ||
        'mouth' ||
        'expressionMarks' ||
        'creatureTraits' =>
          RenderSlot.face,
        'facialHair' => RenderSlot.facialHair,
        'hairFront' ||
        'hairSideLeftRoot' ||
        'hairSideLeftTip' ||
        'hairSideRightRoot' ||
        'hairSideRightTip' ||
        'horns' ||
        'headAdornment' =>
          RenderSlot.hairFront,
        'headwear' || 'halo' => RenderSlot.headwear,
        'eyewear' => RenderSlot.eyewear,
        'faceMask' => RenderSlot.faceMask,
        'leftShoulder' ||
        'rightShoulder' ||
        'leftHand' ||
        'rightHand' ||
        'leftShoulderAttachment' ||
        'rightShoulderAttachment' =>
          RenderSlot.frontArms,
        'shoulderCompanion' => RenderSlot.shoulderCompanion,
        'mouthProp' || 'smokeEmitter' => RenderSlot.mouthProp,
        'actorEffects' => RenderSlot.emotionEffects,
        _ => RenderSlot.foreground,
      };

  static RigGraph build(AvatarLayout layout) {
    final anchors = <RigAnchor>[
      for (final entry in layout.landmarks.entries)
        RigAnchor(
          id: entry.key,
          nodeId: _nodeForAnchor(entry.key),
          localPosition: entry.value,
        ),
      for (final entry in layout.slots.entries)
        RigAnchor(
          id: 'slot.${entry.key}',
          nodeId: _slotNode(entry.key),
          localPosition: entry.value.anchor,
        ),
    ];

    final nodes = <RigNode>[
      for (final entry in parents.entries)
        RigNode(
          id: entry.key,
          parentId: entry.value,
          slot: slotFor(entry.key),
          anchorId: _defaultAnchor(entry.key, anchors),
        ),
    ];

    final constraints = <RigConstraint>[
      const RigConstraint(
        id: 'neck-to-head',
        kind: RigConstraintKind.attach,
        nodeIds: <String>['neck', 'head'],
        anchorIds: <String>['body.neckTop', 'head.neckAttach'],
      ),
      const RigConstraint(
        id: 'clothing-to-torso',
        kind: RigConstraintKind.attach,
        nodeIds: <String>['torso', 'clothing'],
      ),
      const RigConstraint(
        id: 'armor-to-torso',
        kind: RigConstraintKind.attach,
        nodeIds: <String>['torso', 'armor'],
      ),
      const RigConstraint(
        id: 'mouth-prop-to-mouth',
        kind: RigConstraintKind.attach,
        nodeIds: <String>['mouth', 'mouthProp'],
        anchorIds: <String>['face.mouth'],
      ),
      const RigConstraint(
        id: 'companion-to-shoulder',
        kind: RigConstraintKind.attach,
        nodeIds: <String>['leftShoulderAttachment', 'shoulderCompanion'],
      ),
    ];
    return RigGraph(nodes: nodes, anchors: anchors, constraints: constraints);
  }

  static String _nodeForAnchor(String id) {
    if (id.startsWith('face.')) return 'face';
    if (id.startsWith('hair.')) return 'hairFront';
    if (id.startsWith('head.')) return 'head';
    if (id.startsWith('body.neck')) return 'neck';
    if (id.contains('Shoulder') || id.contains('shoulder')) return 'torso';
    if (id.startsWith('v4.back')) return 'torso';
    return 'actor';
  }

  static String _slotNode(String id) => switch (id) {
        'headwear' => 'headwear',
        'eyewear' => 'eyewear',
        'mouthProp' => 'mouthProp',
        'shoulderLeft' => 'leftShoulderAttachment',
        'shoulderRight' => 'rightShoulderAttachment',
        'back' => 'backAdornment',
        _ => 'actor',
      };

  static String? _defaultAnchor(String id, List<RigAnchor> anchors) {
    final preferred = switch (id) {
      'torso' => 'body.shoulderCenter',
      'neck' => 'body.neckBase',
      'head' => 'head.neckAttach',
      'face' => 'face.noseTip',
      'mouth' || 'mouthProp' || 'smokeEmitter' => 'face.mouth',
      'eyes' => 'face.leftEye',
      'hairBack' || 'hairFront' || 'headwear' => 'hair.top',
      'leftShoulder' || 'leftShoulderAttachment' => 'v4.shoulderLeft',
      'rightShoulder' || 'rightShoulderAttachment' => 'v4.shoulderRight',
      'backAdornment' || 'cape' => 'v4.back',
      'headAdornment' || 'halo' || 'horns' => 'v4.forehead',
      _ => null,
    };
    if (preferred == null) return null;
    return anchors.any((anchor) => anchor.id == preferred) ? preferred : null;
  }
}

PixelPoint translatedAnchor(PixelPoint anchor, RigTransform transform) =>
    PixelPoint(anchor.x + transform.dx, anchor.y + transform.dy);
