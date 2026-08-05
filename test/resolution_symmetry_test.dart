import 'package:avatar_genome/avatar_genome.dart';
import 'package:test/test.dart';

void main() {
  final palette = AvatarGenerator()
      .generate(AvatarRequest(seed: 'resolution-test-palette'))
      .palette;
  const renderer = ResolutionAwareRenderer();

  int renderedColumnPixels(int sourceX, int size) {
    final source = IndexedImage();
    for (var y = 0; y < source.height; y++) {
      source.setPixel(sourceX, y, 1);
    }
    final output = renderer.render(
      source: source,
      layers: const <RenderLayer>[],
      palette: palette,
      settings: AvatarRenderSettings(
        size: size,
        detailLevel: AvatarDetailLevel.basic,
        shadingStrength: 0,
      ),
      phase: 0,
    );
    return output.indices.where((value) => value == 1).length;
  }

  for (final size in const <int>[64, 80, 96]) {
    test('$size px gives mirrored source columns equal area', () {
      for (var sourceX = 0; sourceX < 24; sourceX++) {
        expect(
          renderedColumnPixels(sourceX, size),
          renderedColumnPixels(47 - sourceX, size),
          reason: 'source columns $sourceX and ${47 - sourceX}',
        );
      }
    });
  }
}
