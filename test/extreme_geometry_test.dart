import 'package:avatar_genome/avatar_genome.dart';
import 'package:test/test.dart';

void main() {
  test('extreme face and accessory combinations keep visible core features',
      () {
    final generator = AvatarGenerator();
    final requests = <AvatarRequest>[
      const AvatarRequest(
        seed: 'extreme-eyes-headwear',
        overrides: <String, Object>{
          'head.width': 18,
          'eyes.spacing': 12,
          'eyes.width': 7,
          'eyes.height': 1,
          'v4.headwear': 'topHat',
          'v4.headwearWidth': 36,
          'v4.headwearHeight': 14,
          'v4.eyewear': 'oversizeGlasses',
        },
      ),
      const AvatarRequest(
        seed: 'extreme-ears',
        overrides: <String, Object>{
          'ears.shape': 'elfLong',
          'ears.height': 12,
          'ears.tipLength': 9,
          'ears.angle': 4,
        },
      ),
      const AvatarRequest(
        seed: 'extreme-fantasy',
        overrides: <String, Object>{
          'fantasy.hornStyle': 'curved',
          'fantasy.hornLength': 10,
          'fantasy.hornWidth': 3,
          'fantasy.hornCurvature': 5,
          'fantasy.antennaStyle': 'ballTip',
          'fantasy.antennaLength': 10,
        },
      ),
    ];

    for (final request in requests) {
      final result = generator.generate(request);
      expect(result.image.usedColorCount, lessThanOrEqualTo(32));
      expect(result.metrics.occupiedPixelCount, greaterThan(150));
      expect(
        result.validation.entries
            .where((entry) => entry.id.startsWith('empty.'))
            .isEmpty,
        isTrue,
      );
      expect(
        result.validation.entries
            .where((entry) => entry.id.startsWith('bounds.eyes'))
            .isEmpty,
        isTrue,
      );
    }
  });
}
