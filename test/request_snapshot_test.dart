import 'package:avatar_genome/avatar_genome.dart';
import 'package:test/test.dart';

void main() {
  test('public generator snapshots mutable request maps', () {
    final source = <String, Object>{'eyes.width': 5};
    final inspecting = _InspectingGenomeGenerator(source);
    final generator = AvatarGenerator(genomeService: inspecting);

    generator.generate(AvatarRequest(seed: 'snapshot', overrides: source));

    expect(inspecting.receivedIndependentMap, isTrue);
  });
}

final class _InspectingGenomeGenerator implements GenomeGenerator {
  _InspectingGenomeGenerator(this.source)
      : delegate = V41GenomeGenerator(catalog: ParameterCatalog.current);

  final Map<String, Object> source;
  final V41GenomeGenerator delegate;
  bool receivedIndependentMap = false;

  @override
  AvatarGenome generate(AvatarRequest request, ConstraintEngine guard) {
    receivedIndependentMap = !identical(request.overrides, source);
    return delegate.generate(request, guard);
  }
}
