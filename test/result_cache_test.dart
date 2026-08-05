import 'package:avatar_genome/avatar_genome.dart';
import 'package:test/test.dart';

void main() {
  test('repeated requests reuse the immutable result snapshot', () {
    final generator = AvatarGenerator(cacheCapacity: 2);
    final request = AvatarRequest(seed: 'cache-hit');

    final first = generator.generate(request);
    final second = generator.generate(request);

    expect(identical(first, second), isTrue);
    expect(generator.cachedResultCount, 1);
  });

  test('cache is bounded and can be disabled', () {
    final bounded = AvatarGenerator(cacheCapacity: 2);
    bounded.generate(AvatarRequest(seed: 'cache-a'));
    bounded.generate(AvatarRequest(seed: 'cache-b'));
    bounded.generate(AvatarRequest(seed: 'cache-c'));
    expect(bounded.cachedResultCount, 2);

    final disabled = AvatarGenerator(cacheCapacity: 0);
    disabled.generate(AvatarRequest(seed: 'cache-disabled'));
    expect(disabled.cachedResultCount, 0);
  });
}
