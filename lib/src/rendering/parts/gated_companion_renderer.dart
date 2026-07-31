import '../companion/articulated_companion_v2_renderer.dart';
import '../companion/companion_style_registry.dart';
import '../render_model.dart';
import '../rig_model.dart';

/// Routes living shoulder companions to the articulated V2 rig while ordinary
/// shoulder wearables remain rigid objects attached to the selected side.
final class GatedCompanionRenderer implements AvatarPartRenderer {
  const GatedCompanionRenderer();

  static const Set<String> companionStyles = kArticulatedCompanionStyles;

  @override
  void render(AvatarRenderContext context, AvatarRenderState state) {
    final primary = context.string('v4.shoulderProp');
    final extra = context.string('v4.extraShoulderProp');
    final style = primary != 'none' ? primary : extra;
    if (style == 'none') return;

    if (companionStyles.contains(style)) {
      const ArticulatedCompanionV2Renderer().render(context, state);
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
