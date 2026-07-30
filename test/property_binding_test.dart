import 'package:avatar_genome/avatar_genome.dart';
import 'package:test/test.dart';

void main() {
  test('registry exposes request and all catalog fields', () {
    final registry = AvatarPropertyRegistry();
    expect(registry.requestBindings, hasLength(14));
    expect(registry.catalogBindings, hasLength(ParameterCatalog.v41.fieldCount));
    expect(registry.bindings, hasLength(ParameterCatalog.v41.fieldCount + 14));
    expect(registry.bindingById['hair.length'], isNotNull);
    expect(registry.bindingById['settings.age'], isNotNull);
    expect(registry.bindingById['rendering.size'], isNotNull);
  });

  test('binder writes request properties and override values', () {
    final binder = AvatarRequestBinder();
    var request = const AvatarRequest(seed: 'binding-test');
    request = binder.setValue(request, 'settings.age', 64);
    request = binder.setValue(request, 'hair.length', 7);
    request = binder.setValue(request, 'rendering.size', 96);
    request = binder.setValue(request, 'rendering.detailLevel', 'rich');
    expect(request.settings.age, 64);
    expect(request.overrides['hair.length'], 7);
    expect(request.rendering.size, 96);
    expect(request.rendering.detailLevel, AvatarDetailLevel.rich);

    request = binder.resetValue(request, 'hair.length');
    expect(request.overrides.containsKey('hair.length'), isFalse);
  });

  test('property state reports automatic and manual sources', () {
    final registry = AvatarPropertyRegistry();
    final generator = AvatarGenerator();
    const request = AvatarRequest(
      seed: 'state-test',
      overrides: <String, Object>{'eyes.shape': 'almond'},
    );
    final result = generator.generate(request);
    final state = registry.stateToJson(request, result.genome);
    expect((state['eyes.shape']! as Map)['isOverridden'], isTrue);
    expect((state['hair.length']! as Map)['resolvedValue'], isNotNull);
  });
}
