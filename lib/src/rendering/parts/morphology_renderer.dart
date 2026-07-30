import '../../pixels/pixel_mask.dart';
import '../render_model.dart';

/// Adds a readable, deterministic silhouette treatment for non-human profiles.
/// It deliberately sits after facial features so a skull/construct cannot leak
/// a normal face through its plate geometry.
final class MorphologyRenderer implements AvatarPartRenderer {
  const MorphologyRenderer();

  @override
  void render(AvatarRenderContext context, AvatarRenderState state) {
    final profile = context.string('v4.morphology', 'human');
    if (profile == 'human') return;
    final head = state.mask('head');
    if (head.count == 0) return;
    var dark = PixelMask();
    final light = PixelMask();
    final detail = PixelMask();
    final bounds = head.bounds;
    if (bounds == null) return;
    if (profile == 'skull' || profile == 'undead') {
      dark.fillEllipse(bounds.center.x, bounds.center.y + 1, bounds.width * .34,
          bounds.height * .38);
      dark = dark.intersect(head);
      detail.fillEllipse(bounds.center.x - bounds.width * .16,
          bounds.center.y - bounds.height * .04, 2.5, 3.0);
      detail.fillEllipse(bounds.center.x + bounds.width * .16,
          bounds.center.y - bounds.height * .04, 2.5, 3.0);
      detail.hLine(bounds.center.x.floor() - 3, bounds.center.x.floor() + 3,
          bounds.bottom - 5);
      light.hLine(bounds.left + 3, bounds.right - 3, bounds.center.y.floor());
    } else if (profile == 'skeleton') {
      dark = head.intersect(PixelMask()
          .fillRect(bounds.left, bounds.top, bounds.width, bounds.height));
      for (var i = 0; i < 3; i++) {
        detail.hLine(
            bounds.left + 3, bounds.right - 3, bounds.bottom - 10 + i * 3);
      }
      detail.vLine(bounds.center.x.floor(), bounds.top + 4, bounds.bottom - 3);
    } else if (profile == 'construct') {
      dark.fillRect(
          bounds.left + 2, bounds.top + 2, bounds.width - 4, bounds.height - 4);
      dark = dark.intersect(head);
      detail.hLine(bounds.left + 3, bounds.right - 3, bounds.center.y.floor());
      detail.vLine(bounds.center.x.floor(), bounds.top + 3, bounds.bottom - 3);
      light.fillRect(bounds.left + 3, bounds.top + 3, 2, 2);
      light.fillRect(bounds.right - 4, bounds.top + 3, 2, 2);
    }
    state
      ..addLayer('morphology.plate', 126, dark, context.color('skinShadow'),
          meta: const {'part': 'morphology'})
      ..addLayer('morphology.highlight', 127, light, context.color('skinLight'),
          meta: const {'part': 'morphology'})
      ..addLayer('morphology.detail', 128, detail, context.color('outline'),
          meta: const {'part': 'morphology'});

    if (profile == 'skeleton' || profile == 'construct') {
      final torso = state.mask('torso');
      final torsoBounds = torso.bounds;
      if (torsoBounds != null) {
        final ribs = PixelMask();
        for (var i = 0; i < 3; i++) {
          ribs.hLine(torsoBounds.left + 4, torsoBounds.right - 4,
              torsoBounds.top + 7 + i * 4);
        }
        state.addLayer('morphology.ribs', 56, ribs, context.color('skinLight'),
            meta: const {'part': 'morphology'});
      }
    }
  }
}
