import '../../../pixels/pixel_mask.dart';
import '../../../util/math_utils.dart';
import '../../render_model.dart';
import 'atmosphere_masks.dart';

final class ScenicBackgroundRenderer {
  const ScenicBackgroundRenderer();

  AtmosphereMasks build(AvatarRenderContext c) {
    final style = c.string('v4.background');
    final dark = PixelMask();
    final light = PixelMask();
    final accent = PixelMask();
    if (style == 'sunrise' || style == 'sunsetMountains') {
      light.fillRect(0, 0, 48, 25);
      accent.fillEllipse(style == 'sunrise' ? 12 : 36, 14, 5, 5);
      for (var x = -5; x < 53; x += 10) {
        dark.fillTriangle((x: x, y: 39), (x: x + 13, y: 39),
            (x: x + 6, y: 22 + positiveMod(x, 7)));
      }
    } else if (style == 'moonlitForest' ||
        style == 'foggyForest' ||
        style == 'deadForest') {
      dark.fillRect(0, 0, 48, 48);
      accent.fillEllipse(38, 9, 4, 4);
      for (var x = 1; x < 48; x += 7) {
        dark.fillRect(x, 17 + positiveMod(x, 7), 2, 31);
        light.line(x + 1, 20, x - 3, 10 + positiveMod(x, 6));
      }
      if (style == 'foggyForest') {
        for (var y = 22; y < 45; y += 6) light.hLine(0, 47, y);
      }
    } else if (style == 'desertDunes' || style == 'alienPlanet') {
      light.fillRect(0, 0, 48, 27);
      dark.fillEllipse(10, 45, 30, 12);
      accent.fillEllipse(41, 8, style == 'alienPlanet' ? 6 : 4, 4);
      if (style == 'alienPlanet') accent.fillEllipse(7, 13, 2, 2);
    } else if (style == 'oceanHorizon') {
      light.fillRect(0, 0, 48, 24);
      dark.fillRect(0, 25, 48, 23);
      for (var y = 28; y < 48; y += 4) {
        accent.hLine(positiveMod(y, 5), 47 - positiveMod(y, 7), y);
      }
    } else if (style == 'snowMountains') {
      light.fillRect(0, 0, 48, 48);
      for (var x = -8; x < 55; x += 14) {
        dark.fillTriangle((x: x, y: 42), (x: x + 18, y: 42),
            (x: x + 9, y: 15 + positiveMod(x, 8)));
        accent.fillTriangle((x: x + 4, y: 29), (x: x + 14, y: 29),
            (x: x + 9, y: 16 + positiveMod(x, 8)));
      }
    } else if (style == 'volcanicSky' || style == 'demonicGate') {
      dark.fillRect(0, 0, 48, 48);
      accent.fillEllipse(24, 31, 17, 22);
      dark.fillEllipse(24, 31, 11, 17);
      for (var x = 0; x < 48; x += 6) {
        light.line(x, 47, x + 2, 35 - positiveMod(x, 8));
      }
    } else if (style == 'caveGlow' || style == 'crystalCave') {
      dark.fillRect(0, 0, 48, 48);
      for (var x = 2; x < 48; x += 7) {
        accent.fillTriangle((x: x, y: 47), (x: x + 5, y: 47),
            (x: x + 2, y: 28 - positiveMod(x, 10)));
        light.set(x + 2, 31 - positiveMod(x, 10));
      }
    } else if (style == 'citySkyline' || style == 'factorySmoke') {
      dark.fillRect(0, 0, 48, 48);
      for (var x = 0; x < 48; x += 6) {
        final height = 10 + positiveMod(x * 3, 24);
        light.fillRect(x, 48 - height, 5, height);
        for (var y = 48 - height + 3; y < 47; y += 5) {
          accent.set(x + 2, y);
        }
      }
      if (style == 'factorySmoke') {
        for (var i = 0; i < 5; i++) {
          accent.fillEllipse(8 + i * 8, 12 - i, 3 + i % 2, 2);
        }
      }
    } else if (style == 'castleWall' ||
        style == 'throneRoom' ||
        style == 'cathedralWindow') {
      dark.fillRect(0, 0, 48, 48);
      for (var y = 3; y < 48; y += 6) {
        for (var x = (y ~/ 6).isEven ? 0 : -4; x < 48; x += 9) {
          light.hLine(x, x + 7, y);
        }
      }
      if (style == 'throneRoom') {
        accent.fillRect(18, 10, 12, 28);
        accent.fillTriangle((x: 18, y: 10), (x: 30, y: 10), (x: 24, y: 3));
      } else if (style == 'cathedralWindow') {
        accent.fillEllipse(24, 15, 10, 13);
        dark.vLine(24, 3, 28).hLine(14, 34, 15);
      }
    } else if (style == 'libraryShelves') {
      dark.fillRect(0, 0, 48, 48);
      for (var y = 5; y < 48; y += 10) {
        light.hLine(1, 46, y);
        for (var x = 3; x < 45; x += 4) {
          accent.fillRect(x, y + 1, 2, 7);
        }
      }
    } else if (style == 'runeCircle' ||
        style == 'portalRift' ||
        style == 'astralPlane') {
      dark.fillRect(0, 0, 48, 48);
      final outer = PixelMask()..fillEllipse(24, 24, 21, 21);
      final inner = PixelMask()..fillEllipse(24, 24, 17, 17);
      accent.replaceData(outer.subtract(inner).data);
      for (var i = 0; i < 12; i++) {
        light.set(5 + positiveMod(i * 13, 38), 5 + positiveMod(i * 7, 38));
      }
      if (style == 'portalRift') light.vLine(24, 5, 43);
    } else if (style == 'floatingIslands') {
      light.fillRect(0, 0, 48, 48);
      for (var i = 0; i < 4; i++) {
        final x = 5 + i * 12;
        final y = 12 + positiveMod(i * 7, 20);
        dark.fillEllipse(x, y, 7, 3);
        accent.fillTriangle(
          (x: x - 5, y: y + 1),
          (x: x + 5, y: y + 1),
          (x: x, y: y + 8),
        );
      }
    } else if (style == 'celestialHall') {
      light.fillRect(0, 0, 48, 48);
      for (var x = 4; x < 48; x += 10) dark.fillRect(x, 6, 4, 42);
      accent.fillEllipse(24, 8, 7, 3);
    } else if (style == 'spaceStation' || style == 'starshipBridge') {
      dark.fillRect(0, 0, 48, 48);
      light.fillRect(4, 4, 40, 30);
      dark.fillRect(7, 7, 34, 24);
      accent.hLine(8, 40, 34).vLine(24, 7, 31);
    } else if (style == 'dataGrid' ||
        style == 'warpTunnel' ||
        style == 'voidStatic') {
      dark.fillRect(0, 0, 48, 48);
      for (var x = 0; x < 48; x += 5) accent.vLine(x, 0, 47);
      for (var y = 0; y < 48; y += 5) light.hLine(0, 47, y);
      if (style == 'warpTunnel') {
        for (var i = 0; i < 8; i++) {
          light.line(24, 24, i * 7, i.isEven ? 0 : 47);
        }
      }
    } else if (style == 'graveyard' ||
        style == 'bloodMoon' ||
        style == 'mistSwamp') {
      dark.fillRect(0, 0, 48, 48);
      accent.fillEllipse(37, 9, style == 'bloodMoon' ? 7 : 4, 7);
      for (var x = 4; x < 46; x += 8) {
        light.fillRect(x, 32 + positiveMod(x, 5), 4, 12);
        light.hLine(x - 2, x + 5, 35 + positiveMod(x, 5));
      }
    }
    return AtmosphereMasks(dark, light, accent);
  }
}
