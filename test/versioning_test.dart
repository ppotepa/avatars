import 'package:avatar_genome/avatar_genome.dart';
import 'package:test/test.dart';

void main() {
  test('request and result expose independent schema versions', () {
    final request = AvatarRequest(seed: 'version-contract');
    final result = AvatarGenerator().generate(request);

    expect(request.toJson()['schemaVersion'], AvatarGenomeVersion.requestSchema);
    expect(result.toJson()['schemaVersion'], AvatarGenomeVersion.resultSchema);
    expect(result.genome.generatorVersion, AvatarGenomeVersion.generator);
    expect(result.palette.id, contains(AvatarGenomeVersion.palette));
  });

  test('unsupported request schema fails explicitly', () {
    expect(
      () => AvatarRequest.fromJson(<String, Object?>{
        'schemaVersion': AvatarGenomeVersion.requestSchema + 1,
        'seed': 'future-schema',
      }),
      throwsFormatException,
    );
  });

  test('render settings round-trip without changing the request schema', () {
    final request = AvatarRequest(
      seed: 'render-settings',
      rendering: const AvatarRenderSettings(
        size: 80,
        detailLevel: AvatarDetailLevel.rich,
        lightingDirection: AvatarLightingDirection.upperRight,
        shadingStrength: 3,
        animateBackground: false,
        reducedMotion: true,
      ),
    );
    final decoded = AvatarRequest.fromJson(request.toJson());
    expect(decoded.rendering.size, 80);
    expect(decoded.rendering.detailLevel, AvatarDetailLevel.rich);
    expect(
      decoded.rendering.lightingDirection,
      AvatarLightingDirection.upperRight,
    );
    expect(decoded.rendering.animateBackground, isFalse);
    expect(decoded.rendering.reducedMotion, isTrue);
  });
}
