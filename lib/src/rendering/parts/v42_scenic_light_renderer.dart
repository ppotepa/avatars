import '../../pixels/pixel_mask.dart';
import '../../util/math_utils.dart';
import '../render_model.dart';

/// Restores a dedicated light pass for expanded scenic backgrounds.
///
/// V4.2 scenes use separate structural and accent masks. Keeping this pass
/// independent prevents suns, skies, windows and horizon light from collapsing
/// into the smaller accent mask.
final class ExtendedScenicLightRenderer implements AvatarPartRenderer {
  const ExtendedScenicLightRenderer();

  @override
  void render(AvatarRenderContext context, AvatarRenderState state) {
    final light = _light(context);
    state.addLayer(
      'background.v42.scenicLight',
      3,
      light,
      context.color('bgLight'),
      meta: const {'part': 'background'},
    );
  }

  PixelMask _light(AvatarRenderContext c) {
    final style = c.string('v4.background');
    final light = PixelMask();
    if (style == 'sunrise' || style == 'sunsetMountains') {
      light.fillRect(0, 0, 48, 25);
    } else if (style == 'moonlitForest') {
      light.fillEllipse(38, 9, 5, 5);
      for (var x = 1; x < 48; x += 7) {
        light.line(x + 1, 20, x - 3, 10 + positiveMod(x, 6));
      }
    } else if (style == 'foggyForest') {
      for (var y = 21; y < 46; y += 6) light.hLine(0, 47, y);
    } else if (style == 'desertDunes' || style == 'alienPlanet') {
      light.fillRect(0, 0, 48, 27);
    } else if (style == 'oceanHorizon') {
      light.fillRect(0, 0, 48, 24);
      for (var y = 28; y < 48; y += 4) {
        light.hLine(positiveMod(y, 5), 47 - positiveMod(y, 7), y);
      }
    } else if (style == 'snowMountains') {
      light.fillRect(0, 0, 48, 48);
    } else if (style == 'volcanicSky' || style == 'demonicGate') {
      for (var x = 0; x < 48; x += 6) {
        light.line(x, 47, x + 2, 35 - positiveMod(x, 8));
      }
    } else if (style == 'caveGlow' || style == 'crystalCave') {
      for (var x = 2; x < 48; x += 7) {
        light.set(x + 2, 31 - positiveMod(x, 10));
      }
    } else if (style == 'citySkyline' || style == 'factorySmoke') {
      for (var x = 0; x < 48; x += 6) {
        final height = 10 + positiveMod(x * 3, 24);
        for (var y = 48 - height + 3; y < 47; y += 5) {
          light.set(x + 2, y);
        }
      }
    } else if (style == 'castleWall' || style == 'throneRoom' ||
        style == 'cathedralWindow') {
      for (var y = 3; y < 48; y += 6) {
        for (var x = (y ~/ 6).isEven ? 0 : -4; x < 48; x += 9) {
          light.hLine(x, x + 7, y);
        }
      }
    } else if (style == 'libraryShelves') {
      for (var y = 5; y < 48; y += 10) light.hLine(1, 46, y);
    } else if (style == 'runeCircle' || style == 'portalRift' ||
        style == 'astralPlane') {
      for (var i = 0; i < 12; i++) {
        light.set(5 + positiveMod(i * 13, 38),
            5 + positiveMod(i * 7, 38));
      }
    } else if (style == 'floatingIslands' || style == 'celestialHall') {
      light.fillRect(0, 0, 48, 48);
    } else if (style == 'spaceStation' || style == 'starshipBridge') {
      light.fillRect(4, 4, 40, 30);
    } else if (style == 'dataGrid' || style == 'warpTunnel' ||
        style == 'voidStatic') {
      for (var y = 0; y < 48; y += 5) light.hLine(0, 47, y);
    } else if (style == 'graveyard' || style == 'bloodMoon' ||
        style == 'mistSwamp') {
      for (var x = 4; x < 46; x += 8) {
        light.fillRect(x, 32 + positiveMod(x, 5), 4, 12);
      }
    }
    return light;
  }
}
