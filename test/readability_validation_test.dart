import 'package:avatar_genome/avatar_genome.dart';
import 'package:test/test.dart';

void main() {
  test('generated avatar exposes readability validation without hard failure',
      () {
    final result = AvatarGenerator().generate(AvatarRequest(
      seed: 'readability-validation',
      overrides: <String, Object>{
        'v4.background': 'solid',
        'v4.weather': 'none',
        'v4.effect': 'none',
        'v4.faceAnimation': 'laugh',
        'body.armVisibility': 4,
      },
    ));

    final readability = result.validation.entries
        .where((entry) => entry.id.startsWith('readability.'))
        .toList(growable: false);
    expect(result.validation.isValid, isTrue);
    expect(
      readability.every((entry) => entry.severity == ValidationSeverity.soft),
      isTrue,
    );
  });

  test('face cues stay visible above an intentionally crowded composition', () {
    final result = AvatarGenerator().generate(AvatarRequest(
      seed: 'readability-crowded-face',
      overrides: <String, Object>{
        'v4.headwear': 'robotHelmet',
        'v4.eyewear': 'cyberVisor',
        'v4.faceMask': 'robotMask',
        'v4.mouthProp': 'pipe',
        'hair.fringe': 'asymmetric',
        'hair.fringeLength': 8,
        'facialHair.style': 'longBeard',
        'v4.effect': 'rain',
        'v4.particleDensity': 6,
      },
    ));

    expect(result.metrics.visibility.visiblePixels['eyes'],
        greaterThanOrEqualTo(2));
    expect(result.metrics.visibility.visiblePixels['mouth'],
        greaterThanOrEqualTo(1));
    expect(result.metrics.visibility.visibleRatio('eyes'),
        greaterThanOrEqualTo(.90));
    expect(result.metrics.visibility.visibleRatio('mouth'),
        greaterThanOrEqualTo(.90));
    expect(result.metrics.sceneEffectPixelRatio, lessThanOrEqualTo(.12));
    expect(
      result.validation.entries.where((entry) =>
          entry.status == ValidationStatus.violation &&
          (entry.id == 'visibility.eyes' || entry.id == 'visibility.mouth')),
      isEmpty,
    );
  });

  test('automatic icon batch maintains a minimum face-readability floor', () {
    final generator = AvatarGenerator();
    for (var index = 0; index < 24; index++) {
      final result = generator.generate(
        AvatarRequest(seed: 'readability-batch-$index'),
      );
      expect(result.metrics.faceReadabilityScore, greaterThanOrEqualTo(40),
          reason: result.genome.seed);
      expect(result.metrics.sceneEffectPixelRatio, lessThanOrEqualTo(.12),
          reason: result.genome.seed);
      final faceVisibilityViolations = result.validation.entries
          .where((entry) =>
              entry.status == ValidationStatus.violation &&
              (entry.id == 'visibility.eyes' || entry.id == 'visibility.mouth'))
          .map((entry) => entry.id)
          .toList(growable: false);
      expect(
        faceVisibilityViolations,
        isEmpty,
        reason: '${result.genome.seed}: $faceVisibilityViolations',
      );
    }
  });
}
