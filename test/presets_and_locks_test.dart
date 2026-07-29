import 'package:avatar_genome/avatar_genome.dart';
import 'package:test/test.dart';

void main() {
  final generator = AvatarGenerator();
  final presets = AvatarPresetService();
  final locks = AvatarLockService();

  test('whole avatar preset applies settings and values', () {
    final request = presets.applyWholePreset(
      const AvatarRequest(seed: 'preset'),
      'cyberpunk',
    );
    final result = generator.generate(request);
    expect(request.overrides, isNotEmpty);
    expect(result.genome.values.keys, containsAll(request.overrides.keys));
    for (final entry in request.overrides.entries) {
      expect(result.genome.values[entry.key], entry.value, reason: entry.key);
    }
  });

  test('parameter lock survives a new seed', () {
    const originalRequest = AvatarRequest(seed: 'lock-a');
    final original = generator.generate(originalRequest);
    final locked = locks.lockParameter(
      originalRequest,
      original.genome,
      'eyes.shape',
    );
    final changedSeed = generator.generate(locked.copyWith(seed: 'lock-b'));
    expect(changedSeed.genome['eyes.shape'], original.genome['eyes.shape']);
  });

  test('category lock survives a new seed', () {
    const originalRequest = AvatarRequest(seed: 'category-lock-a');
    final original = generator.generate(originalRequest);
    final locked = locks.lockCategory(
      originalRequest,
      original.genome,
      'hair',
    );
    final changedSeed = generator.generate(locked.copyWith(seed: 'category-lock-b'));
    for (final field in ParameterCatalog.v41.categoryById['hair']!.fields) {
      expect(
        changedSeed.genome.values[field.id],
        original.genome.values[field.id],
        reason: field.id,
      );
    }
  });

  test('request JSON round-trip preserves generation', () {
    var request = presets.applyCategoryPreset(
      const AvatarRequest(seed: 'request-json'),
      'eyes',
      'robotic',
    );
    request = request.copyWith(categoryNonces: const <String, int>{'hair': 2});
    final restored = AvatarRequest.fromJson(request.toJson());
    expect(
      generator.generate(restored).imageHash,
      generator.generate(request).imageHash,
    );
  });
}
