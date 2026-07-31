import 'dart:io';

import 'package:avatar_genome/avatar_genome.dart';

final class VariationProbe {
  const VariationProbe({
    required this.id,
    required this.overrides,
    required this.layerPrefixes,
    required this.minimumUnique,
  });

  final String id;
  final Map<String, Object> overrides;
  final List<String> layerPrefixes;
  final int minimumUnique;
}

void main(List<String> arguments) {
  final samples = _samples(arguments);
  final generator = AvatarGenerator();
  const probes = <VariationProbe>[
    VariationProbe(
      id: 'hockey-mask',
      overrides: <String, Object>{
        'v4.faceMask': 'hockeyMask',
        'v4.maskCoverage': 3,
        'v4.maskDamage': 2,
      },
      layerPrefixes: <String>['faceMask.procedural.'],
      minimumUnique: 30,
    ),
    VariationProbe(
      id: 'tactical-helmet',
      overrides: <String, Object>{
        'v4.headwear': 'tacticalHelmet',
        'v4.headwearDamage': 2,
      },
      layerPrefixes: <String>['headwear.procedural.'],
      minimumUnique: 16,
    ),
    VariationProbe(
      id: 'plate-armor',
      overrides: <String, Object>{
        'v4.armor': 'plateArmor',
        'v4.armorDamage': 2,
        'v4.armorBulk': 3,
      },
      layerPrefixes: <String>['armor.procedural.'],
      minimumUnique: 16,
    ),
    VariationProbe(
      id: 'owl-companion',
      overrides: <String, Object>{
        'v4.extraShoulderProp': 'owl',
      },
      layerPrefixes: <String>['companion.procedural.'],
      minimumUnique: 10,
    ),
    VariationProbe(
      id: 'crystal-relic',
      overrides: <String, Object>{
        'v4.relic': 'crystalPendant',
      },
      layerPrefixes: <String>['relic.procedural.'],
      minimumUnique: 10,
    ),
    VariationProbe(
      id: 'heavy-rain',
      overrides: <String, Object>{
        'v4.weather': 'heavyRain',
        'v4.weatherDensity': 6,
        'v4.weatherDepth': 2,
        'v4.weatherDrift': 2,
        'v4.effect': 'none',
      },
      layerPrefixes: <String>['particle.v2.'],
      minimumUnique: 40,
    ),
  ];

  var failed = false;
  stdout.writeln('VARIATION AUDIT ($samples seeds per probe)');
  for (final probe in probes) {
    final signatures = <String>{};
    for (var index = 0; index < samples; index++) {
      final result = generator.generate(AvatarRequest(
        seed: 'variation-${probe.id}-$index',
        settings: const GenomeSettings(
          fantasy: FantasyLevel.strong,
          symmetry: false,
        ),
        overrides: probe.overrides,
        phase: index % 24,
      ));
      signatures.add(_signature(result, probe.layerPrefixes));
    }
    final required = probe.minimumUnique.clamp(1, samples);
    final passed = signatures.length >= required;
    stdout.writeln(
      '- ${probe.id}: ${signatures.length}/$samples unique '
      '(minimum $required) ${passed ? 'PASS' : 'FAIL'}',
    );
    failed = failed || !passed;
  }
  if (failed) exitCode = 1;
}

String _signature(AvatarResult result, List<String> prefixes) {
  final layers = result.layers
      .where((layer) => prefixes.any(layer.id.startsWith))
      .toList(growable: false)
    ..sort((a, b) => a.id.compareTo(b.id));
  return layers
      .map((layer) => '${layer.id}:${layer.mask.data.join()}')
      .join('|');
}

int _samples(List<String> arguments) {
  final index = arguments.indexOf('--samples');
  if (index < 0 || index + 1 >= arguments.length) return 100;
  final parsed = int.tryParse(arguments[index + 1]) ?? 100;
  return parsed.clamp(10, 1000);
}
