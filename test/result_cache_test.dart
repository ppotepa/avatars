import 'package:avatar_genome/avatar_genome.dart';
import 'package:avatar_genome/src/genome/cached_genome_generator.dart';
import 'package:avatar_genome/src/geometry/cached_layout_resolver.dart';
import 'package:test/test.dart';

void main() {
  test('repeated requests reuse the immutable result snapshot', () {
    final generator = AvatarGenerator(cacheCapacity: 2);
    final request = AvatarRequest(seed: 'cache-hit');

    final first = generator.generate(request);
    final second = generator.generate(request);

    expect(identical(first, second), isTrue);
    expect(generator.cachedResultCount, 1);
    expect(generator.cacheMisses, 1);
    expect(generator.cacheHits, 1);
  });

  test('equivalent map insertion orders share one cache entry', () {
    final generator = AvatarGenerator(cacheCapacity: 2);
    final first = AvatarRequest.frozen(
      seed: 'cache-canonical',
      overrides: <String, Object>{
        'eyes.width': 5,
        'eyes.height': 3,
      },
    );
    final second = AvatarRequest.frozen(
      seed: 'cache-canonical',
      overrides: <String, Object>{
        'eyes.height': 3,
        'eyes.width': 5,
      },
    );

    final firstResult = generator.generate(first);
    final secondResult = generator.generate(second);

    expect(identical(firstResult, secondResult), isTrue);
    expect(generator.cachedResultCount, 1);
    expect(generator.cacheHits, 1);
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

  test('clearCache resets result, prepared and camera caches', () {
    final generator = AvatarGenerator(cacheCapacity: 2);
    generator.generate(AvatarRequest(seed: 'cache-clear'));

    expect(generator.cachedResultCount, greaterThan(0));
    expect((generator.genomeService as CachedGenomeGenerator).length, greaterThan(0));
    expect((generator.layoutResolver as CachedLayoutResolver).length, greaterThan(0));
    expect(generator.pipeline.cameraCache.length, greaterThan(0));

    generator.clearCache();

    expect(generator.cachedResultCount, 0);
    expect(generator.cacheHits, 0);
    expect(generator.cacheMisses, 0);
    expect((generator.genomeService as CachedGenomeGenerator).length, 0);
    expect((generator.layoutResolver as CachedLayoutResolver).length, 0);
    expect(generator.pipeline.cameraCache.length, 0);
  });

  test('negative capacities fail in release mode', () {
    expect(() => AvatarGenerator(cacheCapacity: -1), throwsArgumentError);
    expect(
      () => CachedGenomeGenerator(
        delegate: AvatarGenerator(cacheCapacity: 0).genomeService,
        capacity: -1,
      ),
      throwsArgumentError,
    );
  });
}
