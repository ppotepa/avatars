import 'rig_model.dart';

final class RigLayerBinding {
  const RigLayerBinding({
    required this.nodeId,
    required this.slot,
    required this.localOrder,
  });

  final String nodeId;
  final RenderSlot slot;
  final int localOrder;

  static RigLayerBinding resolve(
    String id,
    int legacyOrder,
    Map<String, Object?> meta,
  ) {
    final explicitNode = meta['nodeId']?.toString();
    if (explicitNode != null) {
      return _binding(explicitNode, legacyOrder);
    }

    final node = _nodeFor(id, meta);
    return _binding(node, legacyOrder);
  }

  static RigLayerBinding _binding(String node, int order) => RigLayerBinding(
        nodeId: node,
        slot: _slotFor(node),
        localOrder: order,
      );

  static String _nodeFor(String id, Map<String, Object?> meta) {
    final segment = meta['rigSegment']?.toString();
    if (segment != null) return segment;

    if (id.startsWith('background')) return 'background';
    if (id.startsWith('cosmic.') ||
        id.startsWith('ambient.') ||
        id.startsWith('weather.v42.back') ||
        id.startsWith('flames.')) return 'atmosphere';
    if (id.startsWith('particle.') || id.startsWith('effect.front')) {
      return 'foreground';
    }
    if (id.startsWith('aura.')) return 'aura';
    if (id.startsWith('halo.')) return 'halo';
    if (id.startsWith('cape')) return 'cape';
    if (id.startsWith('backAdornment')) return 'backAdornment';
    if (id.startsWith('hair.back')) return 'hairBack';
    if (id.startsWith('hair.front') ||
        id.startsWith('hair.gray') ||
        id.startsWith('hair.part')) return 'hairFront';
    if (id.startsWith('torso.')) return 'torso';
    if (id.startsWith('chest.')) return 'chest';
    if (id.startsWith('clothing.')) return 'clothing';
    if (id.startsWith('armor.')) return 'armor';
    if (id.startsWith('neck.')) return 'neck';
    if (id.startsWith('head.')) return 'head';
    if (id.startsWith('ears.')) return 'ears';
    if (id.startsWith('eyes.') ||
        id.startsWith('expression.eyes') ||
        id.startsWith('motion.v42.eye')) return 'eyes';
    if (id == 'brows' ||
        id.startsWith('expression.brows') ||
        id.startsWith('motion.v42.brows')) return 'brows';
    if (id.startsWith('mouth.') || id.startsWith('expression.mouth')) {
      return 'mouth';
    }
    if (id.startsWith('nose.') ||
        id.startsWith('cheeks.') ||
        id.startsWith('skin.details')) return 'face';
    if (id.startsWith('expression.mark') || id.startsWith('emote.v42')) {
      return 'expressionMarks';
    }
    if (id.startsWith('facialHair.')) return 'facialHair';
    if (id.startsWith('headwear.')) return 'headwear';
    if (id.startsWith('eyewear.')) return 'eyewear';
    if (id.startsWith('faceMask.')) return 'faceMask';
    if (id.startsWith('fantasy.') || id.startsWith('hornAccent')) {
      return 'horns';
    }
    if (id.startsWith('headAdornment.')) return 'headAdornment';
    if (id.startsWith('creature.')) return 'creatureTraits';
    if (id.startsWith('cyber.')) return 'headAdornment';

    if (id.startsWith('jewelry.rig.leftChain')) return 'necklaceLeft';
    if (id.startsWith('jewelry.rig.rightChain')) return 'necklaceRight';
    if (id.startsWith('jewelry.rig.pendant')) return 'pendant';
    if (id.startsWith('jewelry.rig.leftEar')) return 'leftEarJewelry';
    if (id.startsWith('jewelry.rig.rightEar')) return 'rightEarJewelry';
    if (id.startsWith('jewelry.') || id.startsWith('relic.')) {
      return 'necklace';
    }

    if (id.startsWith('companion.rig.body')) return 'companionBody';
    if (id.startsWith('companion.rig.head')) return 'companionHead';
    if (id.startsWith('companion.rig.wings')) return 'companionWings';
    if (id.startsWith('companion.rig.tail')) return 'companionTail';
    if (id.startsWith('companion.rig.ears')) return 'companionEars';
    if (id.startsWith('companion.rig.eyes')) return 'companionEyes';
    if (id.startsWith('companion.rig.beak')) return 'companionBeak';
    if (id.startsWith('companion.rig')) return 'shoulderCompanion';
    if (id.startsWith('shoulderProp.') || id.startsWith('companion.v42')) {
      return 'shoulderCompanion';
    }

    if (id.startsWith('mouthProp.smoke')) return 'smokeEmitter';
    if (id.startsWith('mouthProp.')) return 'mouthProp';
    if (id.startsWith('eventMotion') || id.startsWith('emotion')) {
      return 'actorEffects';
    }
    return 'actorEffects';
  }

  static RenderSlot _slotFor(String node) => switch (node) {
        'background' || 'atmosphere' => RenderSlot.background,
        'aura' => RenderSlot.auraBack,
        'cape' ||
        'backAdornment' ||
        'hairBack' ||
        'hairBackRoot' ||
        'hairBackMiddle' ||
        'hairBackTips' ||
        'capeLeftRoot' ||
        'capeRightRoot' ||
        'capeCenter' ||
        'capeMidLeft' ||
        'capeMidRight' ||
        'capeTipLeft' ||
        'capeTipRight' ||
        'leftWingRoot' ||
        'leftWingMid' ||
        'leftWingTip' ||
        'rightWingRoot' ||
        'rightWingMid' ||
        'rightWingTip' => RenderSlot.capeHairBack,
        'torso' || 'chest' || 'clothing' => RenderSlot.torsoClothing,
        'armor' => RenderSlot.armor,
        'neck' => RenderSlot.neck,
        'head' || 'ears' => RenderSlot.head,
        'face' ||
        'eyes' ||
        'brows' ||
        'mouth' ||
        'creatureTraits' => RenderSlot.face,
        'facialHair' => RenderSlot.facialHair,
        'hairFront' ||
        'hairSideLeftRoot' ||
        'hairSideLeftTip' ||
        'hairSideRightRoot' ||
        'hairSideRightTip' ||
        'horns' ||
        'headAdornment' => RenderSlot.hairFront,
        'headwear' || 'halo' => RenderSlot.headwear,
        'eyewear' => RenderSlot.eyewear,
        'faceMask' => RenderSlot.faceMask,
        'necklace' ||
        'necklaceLeft' ||
        'necklaceRight' ||
        'pendant' ||
        'leftEarJewelry' ||
        'rightEarJewelry' => RenderSlot.frontArms,
        'shoulderCompanion' ||
        'companionBody' ||
        'companionHead' ||
        'companionWings' ||
        'companionTail' ||
        'companionEars' ||
        'companionEyes' ||
        'companionBeak' => RenderSlot.shoulderCompanion,
        'mouthProp' || 'smokeEmitter' => RenderSlot.mouthProp,
        'foreground' => RenderSlot.foreground,
        _ => RenderSlot.emotionEffects,
      };
}
