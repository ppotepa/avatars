import '../../pixels/pixel_mask.dart';
import '../render_model.dart';

/// Adds deterministic overlap pixels between flexible rig segments.
///
/// All color layers use the same source-layer segmentation metadata, so the
/// bridge follows outlines, bases, highlights and shadows consistently.
final class RigSeamBridgeRenderer implements AvatarPartRenderer {
  const RigSeamBridgeRenderer();

  static const List<(String, String)> _pairs = <(String, String)>[
    ('hairBackRoot', 'hairBackMiddle'),
    ('hairBackMiddle', 'hairBackTips'),
    ('hairSideLeftRoot', 'hairSideLeftTip'),
    ('hairSideRightRoot', 'hairSideRightTip'),
    ('capeLeftRoot', 'capeMidLeft'),
    ('capeMidLeft', 'capeTipLeft'),
    ('capeRightRoot', 'capeMidRight'),
    ('capeMidRight', 'capeTipRight'),
    ('leftWingRoot', 'leftWingMid'),
    ('leftWingMid', 'leftWingTip'),
    ('rightWingRoot', 'rightWingMid'),
    ('rightWingMid', 'rightWingTip'),
  ];

  @override
  void render(AvatarRenderContext context, AvatarRenderState state) {
    final groups = <String, List<RenderLayer>>{};
    for (final layer in state.layers) {
      final source = layer.meta['sourceLayerId']?.toString();
      final segment = layer.meta['rigSegment']?.toString();
      if (source == null || segment == null) continue;
      final key = '$source:${layer.colorIndex}';
      groups.putIfAbsent(key, () => <RenderLayer>[]).add(layer);
    }

    final bridges = <RenderLayer>[];
    for (final entry in groups.entries) {
      final bySegment = <String, RenderLayer>{
        for (final layer in entry.value)
          layer.meta['rigSegment']!.toString(): layer,
      };
      for (final pair in _pairs) {
        final first = bySegment[pair.$1];
        final second = bySegment[pair.$2];
        if (first == null || second == null) continue;
        final bridge = _bridge(first.mask, second.mask);
        if (bridge.count == 0) continue;
        bridges.add(RenderLayer(
          id: '${entry.key}.seam.${pair.$1}.${pair.$2}',
          z: second.z,
          mask: bridge,
          colorIndex: second.colorIndex,
          nodeId: pair.$2,
          slot: second.slot,
          localOrder: second.localOrder - 1,
          meta: <String, Object?>{
            ...second.meta,
            'part': 'rigSeam',
            'rigSegment': pair.$2,
            'seamFrom': pair.$1,
            'seamTo': pair.$2,
          },
        ));
      }
    }
    state.layers.addAll(bridges);
    state.metadata['rigSeams'] = <String, Object>{
      'bridgeCount': bridges.length,
      'bridgePixels': bridges.fold<int>(
        0,
        (total, layer) => total + layer.mask.count,
      ),
    };
  }

  PixelMask _bridge(PixelMask first, PixelMask second) {
    if (first.dilated(diagonal: true).intersect(second).count > 0) {
      return first.dilated(diagonal: true).intersect(second);
    }
    final firstReach = first.dilated(diagonal: true, iterations: 2);
    final secondReach = second.dilated(diagonal: true, iterations: 2);
    return firstReach
        .intersect(secondReach)
        .subtract(first.union(second))
        .removeSmallComponents(1, maxComponents: 4);
  }
}
