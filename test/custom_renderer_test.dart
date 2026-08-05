import 'package:avatar_genome/avatar_genome.dart';
import 'package:test/test.dart';

final class _BadgeRenderer implements AvatarPartRenderer {
  const _BadgeRenderer();

  @override
  void render(AvatarRenderContext context, AvatarRenderState state) {
    state.addLayer(
      'test.badge',
      999,
      PixelMask()..set(0, 0),
      context.color('white'),
      meta: const <String, Object?>{'part': 'testBadge'},
    );
  }
}

void main() {
  test('custom parts are used by the public generator', () {
    final generator = AvatarGenerator(
      parts: <AvatarPartRenderer>[
        ...RigClipPipeline.defaultParts,
        const _BadgeRenderer(),
      ],
    );
    final result = generator.generate(
      AvatarRequest(seed: 'custom-renderer'),
    );

    expect(result.layers.any((layer) => layer.id == 'test.badge'), isTrue);
  });

  test('custom parts cannot be combined with a complete pipeline', () {
    final base = AvatarGenerator();
    expect(
      () => AvatarGenerator(
        pipeline: base.pipeline,
        parts: const <AvatarPartRenderer>[_BadgeRenderer()],
      ),
      throwsArgumentError,
    );
  });
}
