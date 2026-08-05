import 'package:avatar_genome/avatar_genome_advanced.dart';
import 'package:avatar_genome/src/rendering/parts/v42_features_renderer.dart'
    show ExtendedAtmosphereRenderer;
import 'package:test/test.dart';

void main() {
  test('split atmosphere preserves the legacy rendered appearance', () {
    final legacyParts = <AvatarPartRenderer>[
      for (final part in RigClipPipeline.defaultParts)
        if (part is SplitExtendedAtmosphereRenderer)
          const ExtendedAtmosphereRenderer()
        else
          part,
    ];
    final legacy = AvatarGenerator(parts: legacyParts);
    final split = AvatarGenerator();
    final requests = <AvatarRequest>[
      AvatarRequest(
        seed: 'atmosphere-scenic',
        overrides: <String, Object>{'v4.background': 'runeCircle'},
      ),
      AvatarRequest(
        seed: 'atmosphere-weather',
        overrides: <String, Object>{
          'v4.weather': 'heavyRain',
          'v4.weatherDensity': 5,
          'v4.weatherDepth': 3,
        },
      ),
      AvatarRequest(
        seed: 'atmosphere-cosmic',
        overrides: <String, Object>{
          'v4.cosmicLayer': 'blackHole',
          'v4.cosmicDensity': 4,
        },
      ),
      AvatarRequest(
        seed: 'atmosphere-event',
        phase: 1,
        overrides: <String, Object>{
          'v4.backgroundEvent': 'portalPulse',
          'v4.eventIntensity': 3,
        },
      ),
    ];

    for (final request in requests) {
      expect(
        split.generate(request).imageHash,
        legacy.generate(request).imageHash,
        reason: request.seed,
      );
    }
  });
}
