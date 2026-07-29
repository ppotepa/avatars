import 'package:avatar_genome/avatar_genome.dart';

void main() {
  final generator = AvatarGenerator();
  const iterations = 1000;
  final stopwatch = Stopwatch()..start();
  var checksum = 0;
  for (var index = 0; index < iterations; index++) {
    final result = generator.generate(AvatarRequest(seed: 'bench-$index'));
    checksum ^= int.parse(result.imageHash, radix: 16);
  }
  stopwatch.stop();
  final perAvatar = stopwatch.elapsedMicroseconds / iterations;
  print('Generated $iterations avatars in ${stopwatch.elapsedMilliseconds} ms.');
  print('${perAvatar.toStringAsFixed(2)} µs/avatar; checksum=$checksum');
}
