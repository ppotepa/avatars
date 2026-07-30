import 'package:avatar_genome/avatar_genome.dart';
import 'package:test/test.dart';

void main() {
  final generator = AvatarGenerator();
  const styles = <String>[
    'radiant',
    'divine',
    'corrupted',
    'shadowFlame',
    'storm',
    'plasma',
    'poison',
    'nature',
    'bloodMist',
    'arcaneCircle',
    'void',
    'dream',
    'starlight',
    'goldenDust',
    'sacredRunes',
    'toxicSteam',
  ];

  test('every extended aura creates a visible dedicated layer', () {
    final hashes = <String>{};
    for (final style in styles) {
      final result = generator.generate(
        AvatarRequest(
          seed: 'v42-aura-$style',
          settings: const GenomeSettings(fantasy: FantasyLevel.strong),
          overrides: <String, Object>{
            'v4.aura': style,
            'v4.motionSpeed': 4,
            'v4.animationAmplitude': 3,
          },
        ),
      );
      expect(
        result.layers.any(
          (layer) => layer.id.startsWith('aura.v42.extended'),
        ),
        isTrue,
        reason: style,
      );
      hashes.add(result.imageHash);
    }
    expect(hashes.length, greaterThan(styles.length ~/ 2));
  });

  test('animated extended aura remains deterministic per phase', () {
    const request = AvatarRequest(
      seed: 'v42-aura-animation',
      settings: GenomeSettings(fantasy: FantasyLevel.strong),
      overrides: <String, Object>{
        'v4.aura': 'storm',
        'v4.motionSpeed': 5,
        'v4.animationAmplitude': 3,
      },
    );
    final first = generator.generate(request.copyWith(phase: 0));
    final repeated = generator.generate(request.copyWith(phase: 0));
    final hashes = <String>{
      for (var phase = 0; phase < 24; phase++)
        generator.generate(request.copyWith(phase: phase)).imageHash,
    };

    expect(repeated.imageHash, first.imageHash);
    expect(hashes.length, greaterThan(1));
  });
}
