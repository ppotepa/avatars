import 'dart:typed_data';

import 'package:avatar_genome/avatar_genome.dart';
import 'package:test/test.dart';

void main() {
  final generator = AvatarGenerator();

  test('image hash uses a deterministic 48-bit hexadecimal contract', () {
    const request = AvatarRequest(seed: 'hash-48-contract');
    final first = generator.generate(request);
    final second = generator.generate(request);

    expect(first.imageHash, matches(RegExp(r'^[0-9a-f]{12}$')));
    expect(second.imageHash, first.imageHash);
  });

  test('image dimensions participate in the 48-bit hash', () {
    const seed = 'hash-48-resolution';
    final hashes = <String>{
      for (final size in AvatarRenderSettings.supportedSizes)
        generator
            .generate(AvatarRequest(
              seed: seed,
              rendering: AvatarRenderSettings(size: size),
            ))
            .imageHash,
    };

    expect(hashes, hasLength(AvatarRenderSettings.supportedSizes.length));
  });

  test('palette colors participate in the complete image hash', () {
    final image = IndexedImage.fromIndices(
      width: 2,
      height: 1,
      indices: Uint8List.fromList(<int>[0, 1]),
    );
    final firstPalette = Uint32List.fromList(<int>[
      0xff0000ff,
      0x00ff00ff,
    ]);
    final secondPalette = Uint32List.fromList(<int>[
      0x0000ffff,
      0x00ff00ff,
    ]);

    final first = image.hashWithPalette(firstPalette);
    final second = image.hashWithPalette(secondPalette);

    expect(first, matches(RegExp(r'^[0-9a-f]{12}$')));
    expect(second, matches(RegExp(r'^[0-9a-f]{12}$')));
    expect(second, isNot(first));
  });
}
