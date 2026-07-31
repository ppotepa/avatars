import 'render_model.dart';
import 'rig_model.dart';

/// Applies semantic ownership to wearables whose layer prefix alone does not
/// identify the body part that carries them.
final class WearableAttachmentPolicy {
  const WearableAttachmentPolicy();

  void apply(AvatarRenderContext context, AvatarRenderState state) {
    final cyber = context.string('v4.cybernetics');
    final symbols = context.string('v4.symbolOverlay');
    final back = context.string('v4.backAdornment');

    for (var index = 0; index < state.layers.length; index++) {
      final layer = state.layers[index];
      var nodeId = layer.nodeId;
      var slot = layer.slot;

      if (layer.id.startsWith('cyber.')) {
        nodeId = _cyberNode(cyber);
        slot = _slotFor(nodeId);
      } else if (layer.id.startsWith('symbols.v42')) {
        nodeId = _symbolNode(symbols);
        slot = nodeId == 'sceneSymbols'
            ? RenderSlot.foreground
            : nodeId == 'headAdornment'
                ? RenderSlot.hairFront
                : RenderSlot.emotionEffects;
      } else if (layer.id.startsWith('backAdornment.v42')) {
        nodeId = _backNode(back);
        slot = RenderSlot.capeHairBack;
      }

      if (nodeId != layer.nodeId || slot != layer.slot) {
        state.layers[index] = layer.copyWith(
          nodeId: nodeId,
          slot: slot,
          meta: <String, Object?>{
            ...layer.meta,
            'wearableOwner': nodeId,
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
      ..parentNode('backEmitter', 'torso');
  }

  String _cyberNode(String style) => switch (style) {
        'chestReactor' => 'chestWearable',
        'neckPorts' => 'neckWearable',
        'artificialEar' => 'rightEarWearable',
        'metalJaw' ||
        'cyberEyeLeft' ||
        'cyberEyeRight' ||
        'templeImplant' ||
        'faceWires' ||
        'cheekPlate' ||
        'scanner' ||
        'halfFace' =>
          'headAdornment',
        _ => 'headAdornment',
      };

  String _symbolNode(String style) => switch (style) {
        'crosshair' ||
        'targetLock' ||
        'warningTriangles' =>
          'sceneSymbols',
        'runes' ||
        'glyphs' ||
        'prayerText' ||
        'musicNotes' ||
        'hearts' =>
          'headAdornment',
        _ => 'actorSymbols',
      };

  String _backNode(String style) => switch (style) {
        'energyBackpack' ||
        'jetpackSmall' ||
        'jetpackLarge' ||
        'crystalClusterBack' =>
          'backEmitter',
        'bannerBack' ||
        'prayerScrollBack' ||
        'totemPoleBack' ||
        'boneSpineBack' =>
          'rigidBackWearable',
        _ => 'backAdornment',
      };

  RenderSlot _slotFor(String nodeId) => switch (nodeId) {
        'chestWearable' => RenderSlot.torsoClothing,
        'neckWearable' => RenderSlot.neck,
        'leftEarWearable' || 'rightEarWearable' => RenderSlot.head,
        _ => RenderSlot.hairFront,
      };
}
