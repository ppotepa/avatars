import 'render_model.dart';
import 'rig_model.dart';

/// Applies explicit ownership and occlusion semantics to wearables.
final class WearableAttachmentPolicy {
  const WearableAttachmentPolicy();

  void apply(AvatarRenderContext context, AvatarRenderState state) {
    final cyber = context.string('v4.cybernetics');
    final symbols = context.string('v4.symbolOverlay');
    final back = context.string('v4.backAdornment');
    final fallbackLayers = <String>[];

    for (var index = 0; index < state.layers.length; index++) {
      final layer = state.layers[index];
      var nodeId = layer.nodeId;
      var slot = layer.slot;
      var occlusion = layer.meta['occlusionGroup']?.toString();
      var explicit = layer.meta['attachmentTarget'] != null;

      if (layer.id.startsWith('cyber.')) {
        final resolved = _cyberSemantics(layer.id, cyber);
        nodeId = resolved.nodeId;
        slot = resolved.slot;
        occlusion ??= resolved.occlusion;
      } else if (layer.id.startsWith('symbols.v42')) {
        nodeId = _symbolNode(symbols);
        slot = nodeId == 'sceneSymbols'
            ? RenderSlot.foreground
            : nodeId == 'headAdornment'
                ? RenderSlot.hairFront
                : RenderSlot.emotionEffects;
        occlusion ??= nodeId == 'sceneSymbols' ? 'effectFront' : 'faceFront';
      } else if (layer.id.startsWith('backAdornment.v42')) {
        final resolved = _backSemantics(layer.id, back);
        nodeId = resolved.nodeId;
        slot = resolved.slot;
        occlusion ??= resolved.occlusion;
      } else if (layer.nodeId == 'leftEarJewelry' ||
          layer.nodeId == 'rightEarJewelry') {
        final behindHair = layer.id.contains('back') || layer.id.contains('shadow');
        slot = behindHair ? RenderSlot.earJewelryBack : RenderSlot.earJewelryFront;
        occlusion ??= behindHair ? 'earBack' : 'earFront';
      } else if (layer.nodeId == 'necklace' ||
          layer.nodeId == 'necklaceLeft' ||
          layer.nodeId == 'necklaceRight' ||
          layer.nodeId == 'pendant') {
        slot = RenderSlot.neckJewelry;
        occlusion ??= 'bodyFront';
      } else {
        explicit = true;
      }

      if (!explicit && nodeId == layer.nodeId) fallbackLayers.add(layer.id);
      if (nodeId != layer.nodeId || slot != layer.slot || occlusion != null) {
        state.layers[index] = layer.copyWith(
          nodeId: nodeId,
          slot: slot,
          meta: <String, Object?>{
            ...layer.meta,
            'attachmentTarget': nodeId,
            'wearableOwner': nodeId,
            if (occlusion != null) 'occlusionGroup': occlusion,
          },
        );
      }
    }

    state
      ..parentNode('chestWearable', 'torso')
      ..parentNode('neckWearable', 'neck')
      ..parentNode('leftEarWearable', 'leftEar')
      ..parentNode('rightEarWearable', 'rightEar')
      ..parentNode('headAdornment', 'head')
      ..parentNode('sceneSymbols', 'scene')
      ..parentNode('actorSymbols', 'actor')
      ..parentNode('rigidBackWearable', 'torso')
      ..parentNode('backEmitter', 'torso')
      ..parentNode('backWearableFront', 'torso');

    state.metadata['wearableAttachments'] = <String, Object>{
      'fallbackLayerCount': fallbackLayers.length,
      'fallbackLayers': fallbackLayers,
    };
  }

  ({String nodeId, RenderSlot slot, String occlusion}) _cyberSemantics(
    String layerId,
    String style,
  ) {
    if (layerId.contains('chest') || layerId.contains('reactor')) {
      return (
        nodeId: 'chestWearable',
        slot: RenderSlot.torsoClothing,
        occlusion: 'bodyFront',
      );
    }
    if (layerId.contains('neck') || layerId.contains('port')) {
      return (
        nodeId: 'neckWearable',
        slot: RenderSlot.neck,
        occlusion: 'bodyFront',
      );
    }
    if (layerId.contains('ear.left')) {
      return (
        nodeId: 'leftEarWearable',
        slot: RenderSlot.earJewelryFront,
        occlusion: 'earFront',
      );
    }
    if (layerId.contains('ear') || style == 'artificialEar') {
      return (
        nodeId: 'rightEarWearable',
        slot: RenderSlot.earJewelryFront,
        occlusion: 'earFront',
      );
    }
    return (
      nodeId: 'headAdornment',
      slot: RenderSlot.hairFront,
      occlusion: 'faceFront',
    );
  }

  String _symbolNode(String style) => switch (style) {
        'crosshair' || 'targetLock' || 'warningTriangles' => 'sceneSymbols',
        'runes' ||
        'glyphs' ||
        'prayerText' ||
        'musicNotes' ||
        'hearts' =>
          'headAdornment',
        _ => 'actorSymbols',
      };

  ({String nodeId, RenderSlot slot, String occlusion}) _backSemantics(
    String layerId,
    String style,
  ) {
    final frontPiece = layerId.contains('strap') ||
        layerId.contains('buckle') ||
        layerId.contains('front') ||
        layerId.contains('chest');
    if (frontPiece) {
      return (
        nodeId: 'backWearableFront',
        slot: RenderSlot.torsoClothing,
        occlusion: 'bodyFront',
      );
    }
    final emitter = style == 'energyBackpack' ||
        style == 'jetpackSmall' ||
        style == 'jetpackLarge' ||
        style == 'crystalClusterBack';
    if (emitter) {
      return (
        nodeId: 'backEmitter',
        slot: layerId.contains('light') || layerId.contains('flame')
            ? RenderSlot.auraBack
            : RenderSlot.capeHairBack,
        occlusion: 'bodyBack',
      );
    }
    final rigid = style == 'bannerBack' ||
        style == 'prayerScrollBack' ||
        style == 'totemPoleBack' ||
        style == 'boneSpineBack';
    return (
      nodeId: rigid ? 'rigidBackWearable' : 'backAdornment',
      slot: RenderSlot.capeHairBack,
      occlusion: 'bodyBack',
    );
  }
}
