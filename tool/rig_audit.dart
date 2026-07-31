import 'dart:convert';
import 'dart:io';

import 'package:avatar_genome/avatar_genome.dart';

final class RigAuditScenario {
  const RigAuditScenario(this.id, this.overrides);

  final String id;
  final Map<String, Object> overrides;
}

void main(List<String> arguments) {
  final frameCount = _readInt(arguments, '--frames', fallback: 16, min: 2, max: 64);
  final generator = AvatarGenerator();
  const scenarios = <RigAuditScenario>[
    RigAuditScenario('idle', <String, Object>{
      'v4.animation': 'idle',
      'hair.lengthStyle': 'shoulder',
      'v4.earJewelry': 'dangling',
      'v4.neckJewelry': 'medallion',
      'v4.shoulderProp': 'parrot',
    }),
    RigAuditScenario('laugh', <String, Object>{
      'v4.animation': 'idle',
      'v4.expression': 'laugh',
      'v4.faceAnimation': 'laugh',
      'v4.mouthMotionStyle': 'laughLoop',
      'hair.lengthStyle': 'belowShoulder',
      'v4.neckJewelry': 'royalMedallion',
      'v4.shoulderProp': 'smallDragon',
    }),
    RigAuditScenario('angry', <String, Object>{
      'v4.animation': 'idle',
      'v4.expression': 'furious',
      'v4.faceAnimation': 'angry',
      'v4.poseMotion': 'tinyShake',
      'v4.shoulderProp': 'shoulderRobot',
    }),
    RigAuditScenario('hairWind', <String, Object>{
      'v4.animation': 'hairWind',
      'hair.lengthStyle': 'belowShoulder',
      'hair.length': 16,
      'hair.volumeBack': 4,
      'hair.volumeSides': 3,
    }),
    RigAuditScenario('jewelrySwing', <String, Object>{
      'v4.animation': 'jewelrySwing',
      'v4.earJewelry': 'dangling',
      'v4.neckJewelry': 'royalMedallion',
      'v4.jewelrySize': 3,
    }),
    RigAuditScenario('companion', <String, Object>{
      'v4.animation': 'idle',
      'v4.shoulderProp': 'parrot',
    }),
  ];

  final report = <String, Object>{
    'generatorVersion': AvatarGenomeVersion.generator,
    'frameCount': frameCount,
    'scenarios': <Object>[],
  };
  final output = report['scenarios']! as List<Object>;

  for (final scenario in scenarios) {
    final request = AvatarRequest(
      seed: 'rig-audit-${scenario.id}',
      overrides: scenario.overrides,
    );
    final animation = generator.generateAnimation(request, frameCount: frameCount);
    final layerIds = animation.frames
        .expand((frame) => frame.layers.map((layer) => layer.id))
        .toSet()
        .toList()
      ..sort();
    final layerMotion = <String, int>{};
    for (final id in layerIds) {
      final signatures = <String>{};
      for (final frame in animation.frames) {
        final matching = frame.layers.where((layer) => layer.id == id);
        if (matching.isEmpty) continue;
        signatures.add(matching.first.mask.data.join());
      }
      layerMotion[id] = signatures.length;
    }
    output.add(<String, Object>{
      'id': scenario.id,
      'uniqueFrames': animation.frames.map((frame) => frame.imageHash).toSet().length,
      'actorBounds': <Object?>[
        for (final frame in animation.frames) _actorBounds(frame.layers),
      ],
      'movingLayers': <String>[
        for (final entry in layerMotion.entries)
          if (entry.value > 1) entry.key,
      ],
      'staticLayers': <String>[
        for (final entry in layerMotion.entries)
          if (entry.value <= 1) entry.key,
      ],
      'layerVariation': layerMotion,
    });
  }

  stdout.writeln(const JsonEncoder.withIndent('  ').convert(report));
}

Map<String, int>? _actorBounds(List<RenderLayer> layers) {
  final actorLayers = layers.where((layer) {
    final part = layer.meta['part']?.toString() ?? '';
    return !<String>{
      'background',
      'weather',
      'ambient',
      'cosmic',
      'backgroundEvent',
      'effect',
      'flames',
    }.contains(part);
  });
  var left = 1 << 30;
  var top = 1 << 30;
  var right = -1;
  var bottom = -1;
  for (final layer in actorLayers) {
    final bounds = layer.mask.bounds;
    if (bounds == null) continue;
    if (bounds.left < left) left = bounds.left;
    if (bounds.top < top) top = bounds.top;
    if (bounds.right > right) right = bounds.right;
    if (bounds.bottom > bottom) bottom = bounds.bottom;
  }
  if (right < left || bottom < top) return null;
  return <String, int>{
    'left': left,
    'top': top,
    'right': right,
    'bottom': bottom,
    'width': right - left + 1,
    'height': bottom - top + 1,
  };
}

int _readInt(
  List<String> arguments,
  String name, {
  required int fallback,
  required int min,
  required int max,
}) {
  final index = arguments.indexOf(name);
  if (index < 0 || index + 1 >= arguments.length) return fallback;
  return (int.tryParse(arguments[index + 1]) ?? fallback).clamp(min, max).toInt();
}
