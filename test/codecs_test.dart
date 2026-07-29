import 'dart:convert';

import 'package:avatar_genome/avatar_genome_io.dart';
import 'package:test/test.dart';

void main() {
  final result = AvatarGenerator().generate(
    const AvatarRequest(seed: 'codec-test'),
  );

  test('JSON codec includes the genome and indexed pixels', () {
    final json = jsonDecode(const AvatarJsonCodec().encode(result)) as Map;
    expect(json['seed'], result.genome.seed);
    expect(json['genome'], isA<Map>());
    expect(json['image'], isA<Map>());
  });

  test('SVG codec emits crisp pixel rectangles', () {
    final svg = const AvatarSvgCodec(scale: 8).encode(result);
    expect(svg, contains('<svg'));
    expect(svg, contains('shape-rendering="crispEdges"'));
    expect(svg, contains('<rect'));
  });

  test('RGBA codec returns four bytes per scaled pixel', () {
    final rgba = const AvatarRgbaCodec(scale: 2).encode(result);
    expect(rgba.length, 48 * 2 * 48 * 2 * 4);
  });

  test('PNG codec emits a valid PNG signature', () {
    final png = const AvatarPngCodec(scale: 2).encode(result);
    expect(png.sublist(0, 8), <int>[137, 80, 78, 71, 13, 10, 26, 10]);
  });
}
