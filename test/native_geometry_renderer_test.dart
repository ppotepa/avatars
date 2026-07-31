import 'dart:typed_data';

import 'package:avatar_genome/avatar_genome.dart';
import 'package:test/test.dart';

void main() {
  test(
    'large renders rasterize semantic contours beyond nearest neighbour',
    () {
      final mask = PixelMask(width: 4, height: 4)
        ..set(1, 1)
        ..set(2, 2);
      final layer = RenderLayer(
        id: 'head.base',
        z: 1,
        mask: mask,
        colorIndex: 4,
        nodeId: 'head',
        slot: RenderSlot.head,
        localOrder: 1,
        meta: const <String, Object?>{'part': 'head'},
      );
      final source = IndexedImage(width: 4, height: 4)
        ..setPixel(1, 1, 4)
        ..setPixel(2, 2, 4);
      final palette = AvatarPalette(
        id: 'test',
        colors: Uint32List.fromList(
          List<int>.generate(32, (index) => (index << 24) | 0xff),
        ),
        roles: const <String, int>{
          'outline': 0,
          'skinShadow': 3,
          'skinBase': 4,
          'skinLight': 5,
          'hairShadow': 8,
          'hairBase': 9,
          'hairLight': 10,
          'irisDark': 13,
          'irisBase': 14,
          'irisLight': 15,
          'mouthDark': 17,
          'mouthBase': 18,
          'mouthLight': 19,
          'clothDark': 20,
          'clothBase': 21,
          'clothLight': 22,
          'bgDark': 24,
          'bg': 25,
          'bgLight': 26,
          'fantasyDark': 27,
          'fantasyBase': 28,
          'fantasyLight': 29,
          'white': 31,
        },
      );
      const settings = AvatarRenderSettings(
        size: 64,
        detailLevel: AvatarDetailLevel.basic,
        shadingStrength: 0,
      );
      const renderer = ResolutionAwareRenderer();

      final first = renderer.render(
        source: source,
        layers: <RenderLayer>[layer],
        palette: palette,
        settings: settings,
        phase: 0,
      );
      final second = renderer.render(
        source: source,
        layers: <RenderLayer>[layer],
        palette: palette,
        settings: settings,
        phase: 0,
      );

      final occupied = first.indices
          .where((value) => value != first.transparentIndex)
          .length;
      const nearestNeighbourArea = 2 * 16 * 16;
      expect(occupied, greaterThan(nearestNeighbourArea));
      expect(second.hash, first.hash);
    },
  );
}
