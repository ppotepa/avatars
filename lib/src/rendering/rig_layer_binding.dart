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
    final explicitSlot = meta['slot']?.toString();
    if (explicitNode != null) {
      return RigLayerBinding(
        nodeId: explicitNode,
        slot: _parseSlot(explicitSlot) ?? _slotForNode(explicitNode),
        localOrder: legacyOrder,
      );
    }

    if (id.startsWith('background') ||
        id.startsWith('cosmic.') ||
        id.startsWith('ambient.') ||
        id.startsWith('weather.v42.back') ||
        id.startsWith('flames.')) {
      return RigLayerBinding(
        nodeId: id.startsWith('background') ? 'background' : 'atmosphere',
        slot: RenderSlot.background,
        localOrder: legacyOrder,
      );
    }
    if (id.startsWith('aura.') || id.startsWith('halo.v42.back')) {
      return RigLayerBinding(
        nodeId: id.startsWith('halo.') ? 'halo' : 'aura',
        slot: RenderSlot.auraBack,
        localOrder: legacyOrder,
      );
    }
    if (id.startsWith('cape') || id.startsWith('backAdornment')) {
      return RigLayerBinding(
        nodeId: id.startsWith('cape') ? 'cape' : 'backAdornment',
        slot: RenderSlot.capeHairBack,
        localOrder: legacyOrder,
      );
    }
    if (id.startsWith('hair.back')) {
      return RigLayerBinding(
        nodeId: 'hairBack',
        slot: RenderSlot.capeHairBack,
        localOrder: legacyOrder,
      );
    }
    if (id.startsWith('torso.') || id.startsWith('chest.')) {
      return RigLayerBinding(
        nodeId: id.startsWith('chest.') ? 'chest' : 'torso',
        slot: RenderSlot.torsoClothing,
        localOrder: legacyOrder,
      );
    }
    if (id.startsWith('clothing.')) {
      return RigLayerBinding(
        nodeId: 'clothing',
        slot: RenderSlot.torsoClothing,
        localOrder: legacyOrder,
      );
    }
    if (id.startsWith('armor.')) {
      return RigLayerBinding(
        nodeId: 'armor',
        slot: RenderSlot.armor,
        localOrder: legacyOrder,
      );
    }
    if (id.startsWith('neck.')) {
      return RigLayerBinding(
        nodeId: 'neck',
        slot: RenderSlot.neck,
        localOrder: legacyOrder,
      );
    }
    if (id.startsWith('head.')) {
      return RigLayerBinding(
        nodeId: 'head',
        slot: RenderSlot.head,
        localOrder: legacyOrder,
      );
    }
    if (id.startsWith('ears.')) {
      return RigLayerBinding(
        nodeId: 'ears',
        slot: RenderSlot.head,
        localOrder: legacyOrder,
      );
    }
    if (id.startsWith('eyes.') ||
        id.startsWith('expression.eyes') ||
        id.startsWith('motion.v42.eye')) {
      return RigLayerBinding(
        nodeId: 'eyes',
        slot: RenderSlot.face,
        localOrder: legacyOrder,
      );
    }
    if (id == 'brows' ||
        id.startsWith('expression.brows') ||
        id.startsWith('motion.v42.brows')) {
      return RigLayerBinding(
        nodeId: 'brows',
        slot: RenderSlot.face,
        localOrder: legacyOrder,
      );
    }
    if (id.startsWith('mouth.') || id.startsWith('expression.mouth')) {
      return RigLayerBinding(
        nodeId: 'mouth',
        slot: RenderSlot.face,
        localOrder: legacyOrder,
      );
    }
    if (id.startsWith('nose.') ||
        id.startsWith('cheeks.') ||
        id.startsWith('skin.details')) {
      return RigLayerBinding(
        nodeId: 'face',
        slot: RenderSlot.face,
        localOrder: legacyOrder,
      );
    }
    if (id.startsWith('expression.mark') || id.startsWith('emote.v42')) {
      return RigLayerBinding(
        nodeId: 'expressionMarks',
        slot: RenderSlot.emotionEffects,
        localOrder: legacyOrder,
      );
    }
    if (id.startsWith('facialHair.')) {
      return RigLayerBinding(
        nodeId: 'facialHair',
        slot: RenderSlot.facialHair,
        localOrder: legacyOrder,
      );
    }
    if (id.startsWith('hair.front') ||
        id.startsWith('hair.gray') ||
        id.startsWith('hair.part')) {
      return RigLayerBinding(
        nodeId: 'hairFront',
        slot: RenderSlot.hairFront,
        localOrder: legacyOrder,
      );
    }
    if (id.startsWith('headwear.')) {
      return RigLayerBinding(
        nodeId: 'headwear',
        slot: RenderSlot.headwear,
        localOrder: legacyOrder,
      );
    }
    if (id.startsWith('eyewear.')) {
      return RigLayerBinding(
        nodeId: 'eyewear',
        slot: RenderSlot.eyewear,
        localOrder: legacyOrder,
      );
    }
    if (id.startsWith('faceMask.')) {
      return RigLayerBinding(
        nodeId: 'faceMask',
        slot: RenderSlot.faceMask,
        localOrder: legacyOrder,
      );
    }
    if (id.startsWith('cyber.')) {
      final part = meta['part']?.toString();
      final node = part == 'cybernetics' ? 'headAdornment' : 'actorEffects';
      return RigLayerBinding(
        nodeId: node,
        slot: node == 'headAdornment'
            ? RenderSlot.hairFront
            : RenderSlot.emotionEffects,
        localOrder: legacyOrder,
      );
    }
    if (id.startsWith('fantasy.') || id.startsWith('hornAccent')) {
      return RigLayerBinding(
        nodeId: 'horns',
        slot: RenderSlot.hairFront,
        localOrder: legacyOrder,
      );
    }
    if (id.startsWith('halo.')) {
      return RigLayerBinding(
        nodeId: 'halo',
        slot: id.contains('.back')
            ? RenderSlot.auraBack
            : RenderSlot.headwear,
        localOrder: legacyOrder,
      );
    }
    if (id.startsWith('headAdornment.')) {
      return RigLayerBinding(
        nodeId: 'headAdornment',
        slot: RenderSlot.hairFront,
        localOrder: legacyOrder,
      );
    }
    if (id.startsWith('creature.')) {
      return RigLayerBinding(
        nodeId: 'creatureTraits',
        slot: RenderSlot.face,
        localOrder: legacyOrder,
      );
    }
    if (id.startsWith('jewelry.')) {
      final earRelated = id.contains('ear') || meta['attachment'] == 'ear';
      return RigLayerBinding(
        nodeId: earRelated ? 'leftEarJewelry' : 'necklace',
        slot: earRelated ? RenderSlot.headwear : RenderSlot.frontArms,
        localOrder: legacyOrder,
      );
    }
    if (id.startsWith('relic.')) {
      return RigLayerBinding(
        nodeId: 'necklace',
        slot: RenderSlot.frontArms,
        localOrder: legacyOrder,
      );
    }
    if (id.startsWith('shoulderProp.') || id.startsWith('companion.')) {
      return RigLayerBinding(
        nodeId: _companionPartNode(id),
        slot: RenderSlot.shoulderCompanion,
        localOrder: legacyOrder,
      );
    }
    if (id.startsWith('mouthProp.smoke')) {
      return RigLayerBinding(
        nodeId: 'smokeEmitter',
        slot: RenderSlot.mouthProp,
        localOrder: legacyOrder,
      );
    }
    if (id.startsWith('mouthProp.')) {
      return RigLayerBinding(
        nodeId: 'mouthProp',
        slot: RenderSlot.mouthProp,
        localOrder: legacyOrder,
      );
    }
    if (id.startsWith('particle.') || id.startsWith('effect.front')) {
      return RigLayerBinding(
        nodeId: 'foreground',
        slot: RenderSlot.foreground,
        localOrder: legacyOrder,
      );
    }
    return RigLayerBinding(
      nodeId: 'actorEffects',
      slot: RenderSlot.emotionEffects,
      localOrder: legacyOrder,
    );
  }

  static String _companionPartNode(String id) {
    if (id.contains('head')) return 'companionHead';
    if (id.contains('wing')) return 'companionWings';
    if (id.contains('tail')) return 'companionTail';
    if (id.contains('ear')) return 'companionEars';
    if (id.contains('beak')) return 'companionBeak';
    if (id.contains('eyes')) return 'companionEyes';
    return 'shoulderCompanion';
  }

  static RenderSlot _slotForNode(String nodeId) => switch (nodeId) {
        'background' || 'atmosphere' => RenderSlot.background,
        'aura' => RenderSlot.auraBack,
        'cape' || 'hairBack' || 'backAdornment' => RenderSlot.capeHairBack,
        'torso' || 'chest' || 'clothing' || 'necklace' =>
          RenderSlot.torsoClothing,
        'armor' => RenderSlot.armor,
        'neck' => RenderSlot.neck,
        'head' || 'ears' => RenderSlot.head,
        'face' || 'eyes' || 'brows' || 'mouth' || 'creatureTraits' =>
          RenderSlot.face,
        'facialHair' => RenderSlot.facialHair,
        'hairFront' || 'horns' || 'headAdornment' => RenderSlot.hairFront,
        'headwear' || 'halo' => RenderSlot.headwear,
        'eyewear' => RenderSlot.eyewear,
        'faceMask' => RenderSlot.faceMask,
        'shoulderCompanion' ||
        'companionHead' ||
        'companionWings' ||
        'companionTail' ||
        'companionEars' ||
        'companionBeak' ||
        'companionEyes' =>
          RenderSlot.shoulderCompanion,
        'mouthProp' || 'smokeEmitter' => RenderSlot.mouthProp,
        _ => RenderSlot.emotionEffects,
      };

  static RenderSlot? _parseSlot(String? value) {
    if (value == null) return null;
    for (final slot in RenderSlot.values) {
      if (slot.name == value) return slot;
    }
    return null;
  }
}
