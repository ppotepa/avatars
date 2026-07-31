import '../render_model.dart';
import '../rig_model.dart';
import 'articulated_companion_renderer.dart';

/// Routes living shoulder companions to the articulated rig while preserving
/// ordinary shoulder wearables as rigid objects attached to the chosen side.
final class GatedCompanionRenderer implements AvatarPartRenderer {
  const GatedCompanionRenderer();

  static const Set<String> companionStyles = <String>{
    'parrot',
    'cat',
    'smallDragon',
    'shoulderRobot',
    'ghost',
    'insect',
    'owl',
    'crow',
    'raven',
    'bat',
    'snake',
    'frog',
    'mushroomBuddy',
    'floatingSkull',
    'miniDrone',
    'lanternSpirit',
    'starOrb',
    'cloudSpirit',
    'bookFamiliar',
  };

  @override
  void render(AvatarRenderContext context, AvatarRenderState state) {
    final primary = context.string('v4.shoulderProp');
    final extra = context.string('v4.extraShoulderProp');
    final style = primary != 'none' ? primary : extra;
    if (style == 'none') return;

    if (companionStyles.contains(style)) {
      const ArticulatedCompanionRenderer().render(context, state);
      return;
    }

    final side = context.integer('v4.propSide') == 0
        ? (context.random('shoulderObject.side').nextBool() ? -1 : 1)
        : context.integer('v4.propSide').sign;
    final attachment = side < 0
        ? 'leftShoulderAttachment'
        : 'rightShoulderAttachment';
    state
      ..parentNode('shoulderObject', attachment)
      ..anchorNode(
        'shoulderObject',
        side < 0 ? 'leftShoulder.joint' : 'rightShoulder.joint',
      );

    for (var index = 0; index < state.layers.length; index++) {
      final layer = state.layers[index];
      if (!layer.id.startsWith('shoulderProp.') &&
          !layer.id.startsWith('companion.v42')) {
        continue;
      }
      state.layers[index] = layer.copyWith(
        nodeId: 'shoulderObject',
        slot: RenderSlot.shoulderCompanion,
        meta: <String, Object?>{
          ...layer.meta,
          'attachmentKind': 'rigidShoulderObject',
          'attachmentSide': side,
        },
      );
    }
    state.metadata['shoulderObjectRig'] = <String, Object>{
      'style': style,
      'side': side,
      'attachment': attachment,
    };
  }
}
