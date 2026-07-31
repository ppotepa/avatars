import 'package:avatar_genome/avatar_genome.dart';
import 'package:avatar_genome/src/api/rig_avatar_generator.dart' as rig;
import 'package:test/test.dart';

void main() {
  final generator = rig.AvatarGenerator();

  test('rig animation keeps one camera and owned layers', () {
    final animation = generator.generateAnimation(
      const AvatarRequest(
        seed: 'rig-invariants',
        overrides: <String, Object>{
          'v4.animation': 'idle',
          'hair.lengthStyle': 'belowShoulder',
          'hair.length': 18,
          'v4.neckJewelry': 'medallion',
          'v4.shoulderProp': 'parrot',
        },
      ),
      frameCount: 12,
    );
    final cameras = <String>{};
    for (final frame in animation.frames) {
      expect(frame.image.width, 48);
      expect(frame.image.height, 48);
      cameras.add(frame.layout.graph.nodes['rig.camera']?.value.toString() ?? '');
      for (final layer in frame.layers) {
        expect(layer.nodeId, isNotEmpty, reason: layer.id);
      }
    }
    expect(cameras, hasLength(1));
    expect(animation.frames.map((frame) => frame.imageHash).toSet().length,
        greaterThan(1));
  });

  test('secondary rigs expose articulated nodes', () {
    final frame = generator.generate(const AvatarRequest(
      seed: 'rig-secondary',
      overrides: <String, Object>{
        'v4.animation': 'hairWind',
        'hair.lengthStyle': 'belowShoulder',
        'hair.length': 18,
        'v4.neckJewelry': 'royalMedallion',
        'v4.earJewelry': 'dangling',
        'v4.shoulderProp': 'parrot',
        'v4.cape': 'longCape',
      },
    ));
    final ids = frame.layers.map((layer) => layer.nodeId).toSet();
    expect(ids, contains('hairBackRoot'));
    expect(ids, contains('hairBackTips'));
    expect(ids, contains('necklaceLeft'));
    expect(ids, contains('necklaceRight'));
    expect(ids, contains('pendant'));
    expect(ids, contains('companionHead'));
    expect(ids, contains('companionWings'));
    expect(ids, contains('capeTipLeft'));
    expect(ids, contains('capeTipRight'));
  });
}
