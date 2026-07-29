import 'package:avatar_genome/avatar_genome.dart';
import 'package:test/test.dart';

void main() {
  test('request and result expose independent schema versions', () {
    const request = AvatarRequest(seed: 'version-contract');
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
}
