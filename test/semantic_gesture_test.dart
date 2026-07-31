import 'package:avatar_genome/avatar_genome.dart';
import 'package:test/test.dart';

void main() {
  final generator = AvatarGenerator();

  test('laugh creates articulated forearms and a semantic hand shape', () {
    final result = generator.generate(const AvatarRequest(
      seed: 'gesture-laugh',
      overrides: <String, Object>{
        'v4.faceAnimation': 'laugh',
        'v4.mouthProp': 'none',
        'body.armVisibility': 4,
      },
    ));

    final nodes = result.layers.map((layer) => layer.nodeId).toSet();
    expect(nodes, contains('leftForearm'));
    expect(nodes, contains('rightForearm'));
    expect(nodes, contains('leftHand'));
    expect(nodes, contains('rightHand'));
    expect(
      result.layers.where((layer) => layer.nodeId.endsWith('Hand')).any(
            (layer) => layer.meta['handShape'] != null,
          ),
      isTrue,
    );
  });

  test('angry animation records boxer or fist gesture events', () {
    final animation = generator.generateAnimation(
      const AvatarRequest(
        seed: 'gesture-angry',
        overrides: <String, Object>{
          'v4.faceAnimation': 'angry',
          'body.armVisibility': 4,
        },
      ),
      frameCount: 8,
    );

    final events = <String>{};
    for (final frame in animation.frames) {
      final motion = frame.layout.graph.nodes['rig.motion']?.value;
      if (motion is Map) {
        final values = motion['events'];
        if (values is List) events.addAll(values.cast<String>());
      }
    }
    expect(
      events.intersection(<String>{
        'gestureBoxerGuard',
        'gestureFistsDown',
        'gesturePoint',
      }),
      isNotEmpty,
    );
  });
}
