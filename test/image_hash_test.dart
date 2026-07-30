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
}
