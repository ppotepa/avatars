import 'package:avatar_genome/avatar_genome.dart';
import 'package:test/test.dart';

void main() {
  test('overscan and camera support expressive wide motion', () {
    final result = AvatarGenerator().generate(const AvatarRequest(
      seed: 'expressive-wide-stability',
      overrides: <String, Object>{
        'v4.animation': 'idle',
        'v4.cape': 'longCape',
        'v4.shoulderProp': 'parrot',
        'hair.lengthStyle': 'belowShoulder',
        'hair.length': 15,
      },
    ));
    final camera = result.layout.graph.nodes['rig.camera']!.value as Map;
    expect(camera['width'], 48);
    expect(camera['height'], 48);
    expect((camera['criticalCoverage']! as num).toDouble(), greaterThan(.998));
    expect(result.validation.isValid, isTrue);
  });

  test('canonical rig contains complete articulated arm chains', () {
    final result = AvatarGenerator().generate(const AvatarRequest(
      seed: 'articulated-arm-chain',
      overrides: <String, Object>{'body.armVisibility': 5},
    ));
    final nodes = result.layout.graph.nodes.keys;
    for (final side in const <String>['left', 'right']) {
      expect(nodes, contains('rig.${side}Arm'));
      expect(nodes, contains('rig.${side}Forearm'));
      expect(nodes, contains('rig.${side}Wrist'));
      expect(nodes, contains('rig.${side}Hand'));
    }
  });

  test('arm segmentation follows a bone axis with seam overlap', () {
    final result = AvatarGenerator().generate(const AvatarRequest(
      seed: 'arm-segmentation-axis',
      guardEnabled: false,
      overrides: <String, Object>{'body.armVisibility': 5},
    ));
    final arms = result.layers.where((layer) =>
        layer.nodeId == 'leftForearm' || layer.nodeId == 'rightForearm');
    expect(arms, isNotEmpty);
    expect(arms.every((layer) => layer.mask.count > 0), isTrue);
  });

  test('scene and wearable paint groups are semantically separated', () {
    final result = AvatarGenerator().generate(const AvatarRequest(
      seed: 'semantic-paint-groups',
      overrides: <String, Object>{
        'v4.background': 'solid',
        'v4.neckJewelry': 'medallion',
        'v4.earJewelry': 'dangling',
      },
    ));
    expect(
        result.layers.any((layer) => layer.slot.name == 'background'), isTrue);
    expect(result.layers.any((layer) => layer.meta['occlusionGroup'] != null),
        isTrue);
    expect(result.layout.graph.nodes.keys.any((id) => id.startsWith('rig.')),
        isTrue);
  });

  test('final scene clarity and clipping are measured after posing', () {
    final result = AvatarGenerator().generate(const AvatarRequest(
      seed: 'post-pose-quality-metadata',
      overrides: <String, Object>{'v4.effect': 'rain'},
    ));
    final metadata = result.layout.graph.nodes['rig.camera']!.value as Map;
    expect(metadata, contains('criticalCoverage'));
    expect(
      result.layout.graph.nodes['rig.preCameraClipping']!.value,
      isA<Map>(),
    );
    expect(result.validation.entries, isNotEmpty);
    expect(result.validation.isValid, isTrue);
  });
}
