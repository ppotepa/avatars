import '../../pixels/pixel_mask.dart';
import '../render_model.dart';

/// Splits rendered hair into anchored root/middle/tip rig segments without
/// changing the static union of pixels.
final class SegmentedHairRigRenderer implements AvatarPartRenderer {
  const SegmentedHairRigRenderer();

  @override
  void render(AvatarRenderContext context, AvatarRenderState state) {
    if (state.mask('hair.all').count == 0) return;

    state
      ..parentNode('hairBack', 'head')
      ..parentNode('hairBackRoot', 'hairBack')
      ..parentNode('hairBackMiddle', 'hairBackRoot')
      ..parentNode('hairBackTips', 'hairBackMiddle')
      ..parentNode('hairFront', 'head')
      ..parentNode('hairSideLeftRoot', 'hairFront')
      ..parentNode('hairSideLeftTip', 'hairSideLeftRoot')
      ..parentNode('hairSideRightRoot', 'hairFront')
      ..parentNode('hairSideRightTip', 'hairSideRightRoot');

    final headBottom = context.integer('head.bottomY');
    final eyeY = context.integer('face.eyeY');
    final headLeft = context.integer('head.leftX');
    final headRight = context.integer('head.rightX');
    final backRootZone = _zone((x, y) => y <= headBottom + 1);
    final backMiddleZone = _zone(
      (x, y) => y > headBottom + 1 && y <= headBottom + 7,
    );
    final backTipZone = _zone((x, y) => y > headBottom + 7);
    final leftSideZone = _zone(
      (x, y) => y >= eyeY && x <= headLeft + 5,
    );
    final rightSideZone = _zone(
      (x, y) => y >= eyeY && x >= headRight - 5,
    );
    final leftTipZone = _zone((x, y) => y >= headBottom + 2 && x < 24);
    final rightTipZone = _zone((x, y) => y >= headBottom + 2 && x >= 24);

    final replacement = <RenderLayer>[];
    for (final layer in state.layers) {
      if (layer.id.startsWith('hair.back')) {
        _split(
          layer,
          replacement,
          <(String, PixelMask)>[
            ('hairBackRoot', layer.mask.intersect(backRootZone)),
            ('hairBackMiddle', layer.mask.intersect(backMiddleZone)),
            ('hairBackTips', layer.mask.intersect(backTipZone)),
          ],
        );
      } else if (layer.id.startsWith('hair.front') ||
          layer.id == 'hair.gray' ||
          layer.id == 'hair.part') {
        final left = layer.mask.intersect(leftSideZone);
        final right = layer.mask.intersect(rightSideZone);
        final leftTip = left.intersect(leftTipZone);
        final rightTip = right.intersect(rightTipZone);
        final leftRoot = left.subtract(leftTip);
        final rightRoot = right.subtract(rightTip);
        final center = layer.mask.subtract(left.union(right));
        _split(
          layer,
          replacement,
          <(String, PixelMask)>[
            ('hairFront', center),
            ('hairSideLeftRoot', leftRoot),
            ('hairSideLeftTip', leftTip),
            ('hairSideRightRoot', rightRoot),
            ('hairSideRightTip', rightTip),
          ],
        );
      } else {
        replacement.add(layer);
      }
    }
    state.layers
      ..clear()
      ..addAll(replacement);

    final back = state.mask('hair.back');
    state
      ..putMask('hair.back.root', back.intersect(backRootZone))
      ..putMask('hair.back.middle', back.intersect(backMiddleZone))
      ..putMask('hair.back.tips', back.intersect(backTipZone));
    final front = state.mask('hair.front');
    final left = front.intersect(leftSideZone);
    final right = front.intersect(rightSideZone);
    state
      ..putMask('hair.side.left.root', left.subtract(left.intersect(leftTipZone)))
      ..putMask('hair.side.left.tip', left.intersect(leftTipZone))
      ..putMask('hair.side.right.root', right.subtract(right.intersect(rightTipZone)))
      ..putMask('hair.side.right.tip', right.intersect(rightTipZone));

    state.metadata['hairRig'] = <String, Object>{
      'headBottom': headBottom,
      'segments': <String, int>{
        'backRoot': state.mask('hair.back.root').count,
        'backMiddle': state.mask('hair.back.middle').count,
        'backTips': state.mask('hair.back.tips').count,
        'leftTip': state.mask('hair.side.left.tip').count,
        'rightTip': state.mask('hair.side.right.tip').count,
      },
    };
  }

  void _split(
    RenderLayer source,
    List<RenderLayer> output,
    List<(String, PixelMask)> pieces,
  ) {
    var index = 0;
    for (final piece in pieces) {
      if (piece.$2.count == 0) continue;
      output.add(RenderLayer(
        id: '${source.id}.rig$index',
        z: source.z,
        mask: piece.$2,
        colorIndex: source.colorIndex,
        nodeId: piece.$1,
        slot: source.slot,
        localOrder: source.localOrder + index,
        meta: <String, Object?>{
          ...source.meta,
          'sourceLayerId': source.id,
          'rigSegment': piece.$1,
        },
      ));
      index++;
    }
  }

  PixelMask _zone(bool Function(int x, int y) predicate) {
    final mask = PixelMask();
    for (var y = 0; y < mask.height; y++) {
      for (var x = 0; x < mask.width; x++) {
        if (predicate(x, y)) mask.set(x, y);
      }
    }
    return mask;
  }
}
