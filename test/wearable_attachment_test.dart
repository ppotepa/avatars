import 'package:avatar_genome/avatar_genome.dart';
import 'package:test/test.dart';

void main() {
  final generator = AvatarGenerator();

  final cyberCases = <String, String>{
    'chestReactor': 'chestWearable',
    'neckPorts': 'neckWearable',
    'artificialEar': 'rightEarWearable',
    'metalJaw': 'headAdornment',
    'faceWires': 'headAdornment',
  };
  for (final entry in cyberCases.entries) {
    test('${entry.key} is owned by ${entry.value}', () {
      final frame = generator.generate(AvatarRequest(
        seed: 'cyber-${entry.key}',
        overrides: <String, Object>{
          'v4.cybernetics': entry.key,
          'v4.cyberCoverage': 4,
          'v4.cyberGlow': 2,
        },
      ));
      final cyberNodes = frame.layers
          .where((layer) => layer.id.startsWith('cyber.'))
          .map((layer) => layer.nodeId)
          .toSet();
      expect(cyberNodes, <String>{entry.value});
    });
  }

  test('backpack remains a rigid back wearable', () {
    final frame = generator.generate(AvatarRequest(
      seed: 'rigid-backpack',
      overrides: <String, Object>{
        'v4.animation': 'idle',
        'v4.cape': 'backpack',
      },
    ));
    final capeLayers = frame.layers
        .where((layer) => layer.id.startsWith('cape.'))
        .toList(growable: false);
    expect(capeLayers, isNotEmpty);
    expect(
      capeLayers.map((layer) => layer.nodeId).toSet(),
      <String>{'rigidBackWearable'},
    );
    expect(
      capeLayers.any((layer) => layer.nodeId.contains('Tip')),
      isFalse,
    );
  });

  test('cape wing styles use articulated wing nodes', () {
    final frame = generator.generate(AvatarRequest(
      seed: 'articulated-cape-wings',
      overrides: <String, Object>{
        'v4.animation': 'idle',
        'v4.cape': 'angelWings',
      },
    ));
    final nodes = frame.layers
        .where((layer) => layer.id.startsWith('cape.'))
        .map((layer) => layer.nodeId)
        .toSet();
    expect(nodes, contains('leftWingRoot'));
    expect(nodes, contains('leftWingTip'));
    expect(nodes, contains('rightWingRoot'));
    expect(nodes, contains('rightWingTip'));
    expect(nodes.any((node) => node.startsWith('capeTip')), isFalse);
  });
}
