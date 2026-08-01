import 'package:avatar_genome/avatar_genome.dart';
import 'package:test/test.dart';

void main() {
  test('final quality architecture remains connected', () {
    final result = AvatarGenerator().generate(
      const AvatarRequest(seed: 'final-quality-architecture'),
    );
    final graph = result.layout.graph.nodes;
    expect(result.layers, isNotEmpty);
    expect(graph, contains('rig.camera'));
    expect(graph, contains('rig.leftArm'));
    expect(graph, contains('rig.leftHand'));
    expect(graph, contains('rig.rightArm'));
    expect(graph, contains('rig.rightHand'));
    expect(result.validation.isValid, isTrue);
  });

  test('large render profiles provide increasing semantic detail', () {
    expect(ResolutionProfile.forSize(48).detailBudget, 0);
    expect(ResolutionProfile.forSize(64).detailBudget, greaterThan(0));
    expect(
      ResolutionProfile.forSize(80).detailBudget,
      greaterThan(ResolutionProfile.forSize(64).detailBudget),
    );
    expect(
      ResolutionProfile.forSize(96).detailBudget,
      greaterThan(ResolutionProfile.forSize(80).detailBudget),
    );
  });
}
