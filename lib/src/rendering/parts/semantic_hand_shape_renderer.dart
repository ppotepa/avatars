import '../../pixels/pixel_mask.dart';
import '../render_model.dart';

/// Rebuilds the tiny terminal hand masks into deterministic semantic shapes.
/// The selected shape follows the same emotion/seed grammar as gesture motion.
final class SemanticHandShapeRenderer implements AvatarPartRenderer {
  const SemanticHandShapeRenderer();

  @override
  void render(AvatarRenderContext context, AvatarRenderState state) {
    final profile = _profile(context);
    final variant = context.random('rig.gesture.$profile').nextInt(0, 4);
    final shape = _shape(profile, variant, context.string('v4.mouthProp'));
    if (shape == 'relaxed') return;

    for (final side in const <String>['left', 'right']) {
      final nodeId = '${side}Hand';
      final original = state.mask(nodeId);
      final bounds = original.bounds;
      if (bounds == null) continue;
      final left = side == 'left';
      final shaped = PixelMask(width: original.width, height: original.height);
      final cx = bounds.center.x;
      final cy = bounds.center.y;
      switch (shape) {
        case 'fist':
          shaped.fillRect(cx - 1, cy - 1, 3, 3);
          break;
        case 'open':
          shaped
            ..fillRect(cx - 1, cy - 1, 3, 2)
            ..line(cx - 2, cy - 1, cx - 2, cy + 1)
            ..line(cx + 2, cy - 1, cx + 2, cy + 1);
          break;
        case 'point':
          shaped
            ..fillRect(cx - 1, cy - 1, 2, 2)
            ..line(cx, cy, cx + (left ? -3 : 3), cy - 1);
          break;
        case 'grip':
          shaped
            ..fillRect(cx - 1, cy - 1, 3, 2)
            ..set(cx + (left ? -2 : 2), cy);
          break;
        case 'covering':
          shaped
            ..fillRect(cx - 1, cy - 2, 3, 4)
            ..set(cx + (left ? -2 : 2), cy - 1);
          break;
      }

      final output = <RenderLayer>[];
      for (final layer in state.layers) {
        if (layer.nodeId != nodeId) {
          output.add(layer);
          continue;
        }
        final visible = shaped.intersect(layer.mask.dilated(diagonal: true, iterations: 2));
        output.add(layer.copyWith(
          mask: visible.count == 0 ? shaped : visible,
          meta: <String, Object?>{
            ...layer.meta,
            'handShape': shape,
          },
        ));
      }
      state.layers
        ..clear()
        ..addAll(output);
      state.putMask(nodeId, shaped);
    }
    state.metadata['handShape'] = shape;
  }

  String _shape(String profile, int variant, String mouthProp) {
    return switch (profile) {
      'angry' => variant == 3 ? 'point' : 'fist',
      'surprised' => 'open',
      'proud' => 'grip',
      'sad' => variant.isEven ? 'grip' : 'relaxed',
      'bashful' => 'covering',
      'laugh' => variant == 0 && mouthProp == 'none'
          ? 'covering'
          : variant == 1
              ? 'grip'
              : 'open',
      'talk' => variant == 0 ? 'open' : 'relaxed',
      _ => 'relaxed',
    };
  }

  String _profile(AvatarRenderContext context) {
    final face = context.string('v4.faceAnimation');
    if (face != 'none') return face;
    final expression = context.string('v4.expression');
    if (<String>{'laugh', 'openLaugh', 'manic'}.contains(expression)) return 'laugh';
    if (<String>{'angry', 'furious', 'determined'}.contains(expression)) return 'angry';
    if (<String>{'sad', 'crying', 'worried'}.contains(expression)) return 'sad';
    if (<String>{'surprised', 'shocked'}.contains(expression)) return 'surprised';
    final pose = context.string('v4.poseMotion');
    if (pose == 'proudPose') return 'proud';
    if (pose == 'shyLookAway') return 'bashful';
    return context.string('v4.animation');
  }
}
