import 'dart:typed_data';

import '../api/avatar_version.dart';
import '../genome/avatar_genome_model.dart';
import '../util/math_utils.dart';

final class AvatarPalette {
  AvatarPalette({
    required this.id,
    required Iterable<int> colors,
    required Map<String, int> roles,
  })  : colors = List<int>.unmodifiable(colors),
        roles = Map<String, int>.unmodifiable(roles);

  final String id;

  /// RGBA colors encoded as 0xRRGGBBAA.
  final List<int> colors;
  final Map<String, int> roles;

  int role(String name) => roles[name] ?? 0;

  String hexAt(int index) {
    final rgba = colors[index];
    final rgb = rgba >> 8;
    return '#${rgb.toRadixString(16).padLeft(6, '0')}';
  }

  Map<String, Object> toJson() => <String, Object>{
        'id': id,
        'colors': List<String>.generate(colors.length, hexAt),
        'roles': roles,
      };
}

abstract interface class PaletteFactory {
  AvatarPalette create(AvatarGenome genome);
}

final class V41PaletteFactory implements PaletteFactory {
  const V41PaletteFactory();

  static const Map<String, String> _skin = <String, String>{
    'veryFair': '#f5d6c6',
    'fair': '#e9bfa8',
    'fairWarm': '#e7b08c',
    'fairCool': '#d7b1aa',
    'medium': '#c88762',
    'olive': '#aa7d54',
    'golden': '#bd7f42',
    'brown': '#8b563a',
    'darkBrown': '#623a2c',
    'veryDark': '#38231f',
    'fantasyBlue': '#568dc7',
    'fantasyGreen': '#5c9a65',
    'fantasyRed': '#b85b58',
    'fantasyPurple': '#8a63a9',
    'fantasyGray': '#858b93',
  };
  static const Map<String, String> _hair = <String, String>{
    'black': '#20232b',
    'darkBrown': '#3a271f',
    'brown': '#62412d',
    'lightBrown': '#94643f',
    'blond': '#d7b66d',
    'platinum': '#e4dfcf',
    'red': '#a7432c',
    'auburn': '#793628',
    'gray': '#777b83',
    'white': '#d8d8d2',
    'blue': '#345fa8',
    'green': '#3a855b',
    'pink': '#b85a91',
    'purple': '#704a9d',
    'multicolor': '#6c58aa',
  };
  static const Map<String, String> _iris = <String, String>{
    'brown': '#6b432b',
    'darkBrown': '#3b2a22',
    'hazel': '#8a7437',
    'green': '#4b8a5b',
    'blue': '#4f80bc',
    'gray': '#7b8b9b',
    'amber': '#c18a32',
    'violet': '#7654a8',
    'red': '#b44145',
    'black': '#20232b',
    'glowCyan': '#5ee8e2',
    'glowGold': '#f0cf57',
  };
  static const Map<String, String> _mouth = <String, String>{
    'skin': '#a65c55',
    'softPink': '#c7737f',
    'red': '#b8444d',
    'brown': '#80504a',
    'purple': '#86558f',
    'black': '#30252c',
    'coral': '#d2695d',
  };
  static const Map<String, String> _cloth = <String, String>{
    'blue': '#426db4',
    'navy': '#273f70',
    'teal': '#328888',
    'green': '#43815a',
    'olive': '#6f773c',
    'red': '#a84449',
    'rust': '#9a522d',
    'orange': '#c27635',
    'yellow': '#c2a83e',
    'purple': '#684c9c',
    'magenta': '#a54683',
    'gray': '#626d7c',
    'black': '#252a33',
    'white': '#c9d0d8',
  };
  static const Map<String, String> _background = <String, String>{
    'navy': '#111b2d',
    'slate': '#263343',
    'charcoal': '#171b22',
    'cream': '#d8c9ad',
    'sand': '#9d8060',
    'forest': '#1e3b31',
    'teal': '#174349',
    'rust': '#512c26',
    'deepPurple': '#2b1b3d',
    'black': '#080a0e',
  };

  @override
  AvatarPalette create(AvatarGenome genome) {
    var skin = _skin[genome.string('skin.tone')] ?? _skin['medium']!;
    var hair = _hair[genome.string('colors.hairColor')] ?? _hair['brown']!;
    var iris = _iris[genome.string('colors.irisColor')] ?? _iris['brown']!;
    final mouth = _mouth[genome.string('colors.mouthColor')] ?? _mouth['skin']!;
    var cloth = _cloth[genome.string('colors.clothColor')] ?? _cloth['blue']!;
    var background = _background[genome.string('colors.backgroundColor')] ??
        _background['navy']!;
    final brow = _hair[genome.string('colors.browIndependent')] ?? hair;
    final facial = _hair[genome.string('colors.facialHairIndependent')] ?? hair;

    skin = _adjust(skin, genome.integer('skin.brightness') * 0.045);
    skin = _mix(
      skin,
      genome.integer('skin.warmth') > 0 ? '#ff9d62' : '#789fe0',
      genome.integer('skin.warmth').abs() * 0.035,
    );
    hair = _mix(hair, '#a9a8a0', genome.integer('hair.grayingAmount') * 0.11);

    final style = genome.string('colors.paletteStyle');
    final soft = style == 'soft';
    final high = style == 'highContrast';
    final vivid = style == 'vivid';
    final darkAmount = high ? 0.55 : (soft ? 0.24 : 0.38);
    final lightAmount = high ? 0.5 : (soft ? 0.28 : 0.38);
    final outlineMode = genome.string('colors.outlineMode');
    var outline = outlineMode == 'highContrast'
        ? '#050608'
        : outlineMode == 'colored'
            ? _mix(hair, background, 0.35)
            : outlineMode == 'softDark'
                ? _adjust(background, -0.45)
                : '#10131a';
    outline = _ensureReadableOutline(
      outline,
      <String>[skin, hair, cloth, background],
    );
    if (style == 'warm') background = _mix(background, '#8f4c2d', 0.15);
    if (style == 'cool') background = _mix(background, '#315f86', 0.18);
    if (vivid) {
      cloth = _mix(cloth, '#ff49b6', 0.18);
      iris = _mix(iris, '#4ff5dc', 0.15);
    }
    background =
        _ensureReadableBackground(background, <String>[skin, hair, cloth]);
    outline = _ensureReadableOutline(
        outline, <String>[skin, hair, cloth, background]);

    final hex = <String>[
      outline,
      _adjust(outline, 0.18),
      _adjust(skin, -0.56),
      _adjust(skin, -darkAmount),
      skin,
      _adjust(skin, lightAmount),
      _mix(skin, mouth, 0.32),
      _adjust(hair, -0.55),
      _adjust(hair, -darkAmount),
      hair,
      _adjust(hair, lightAmount),
      _mix(hair, '#d4d2c9', 0.62),
      '#e7e2d6',
      _adjust(iris, -0.48),
      iris,
      _adjust(iris, 0.42),
      _adjust(outline, -0.2),
      _adjust(mouth, -0.38),
      mouth,
      _adjust(mouth, 0.35),
      _adjust(cloth, -0.5),
      cloth,
      _adjust(cloth, 0.4),
      facial,
      _adjust(background, -0.35),
      background,
      _adjust(background, 0.24),
      _adjust(iris, -0.5),
      iris,
      _adjust(iris, 0.55),
      brow,
      '#f4f5f7',
    ];
    final colorBudget = _supportedBudget(
      int.tryParse(genome.string('colors.colorBudget', '16')) ?? 16,
    );
    final budgetedHex = _applyColorBudget(hex, colorBudget);
    return AvatarPalette(
      id: '${AvatarGenomeVersion.palette}.$style.$colorBudget',
      colors: Uint32List.fromList(budgetedHex.map(_rgbaFromHex).toList()),
      roles: const <String, int>{
        'outline': 0,
        'outlineSoft': 1,
        'skinDeep': 2,
        'skinShadow': 3,
        'skinBase': 4,
        'skinLight': 5,
        'skinAccent': 6,
        'hairDeep': 7,
        'hairShadow': 8,
        'hairBase': 9,
        'hairLight': 10,
        'hairGray': 11,
        'sclera': 12,
        'irisDark': 13,
        'irisBase': 14,
        'irisLight': 15,
        'pupil': 16,
        'mouthDark': 17,
        'mouthBase': 18,
        'mouthLight': 19,
        'clothDark': 20,
        'clothBase': 21,
        'clothLight': 22,
        'clothAccent': 23,
        'facialIndependent': 23,
        'bgDark': 24,
        'bg': 25,
        'bgLight': 26,
        'fantasyDark': 27,
        'fantasyBase': 28,
        'fantasyLight': 29,
        'browIndependent': 30,
        'detail': 30,
        'white': 31,
        'weatherRainDark': 26,
        'weatherRainBase': 28,
        'weatherRainLight': 29,
        'weatherLightning': 31,
        'weatherFogDark': 24,
        'weatherFogLight': 26,
        'weatherSnow': 31,
        'weatherEmber': 29,
      },
    );
  }

  static List<int> _rgb(String hex) {
    final value = int.parse(hex.substring(1), radix: 16);
    return <int>[(value >> 16) & 255, (value >> 8) & 255, value & 255];
  }

  static String _hex(List<num> rgb) =>
      '#${rgb.map((value) => clampInt(value.round(), 0, 255).toRadixString(16).padLeft(2, '0')).join()}';

  static String _mix(String a, String b, double amount) {
    final left = _rgb(a);
    final right = _rgb(b);
    return _hex(List<num>.generate(
      3,
      (index) => left[index] + (right[index] - left[index]) * amount,
    ));
  }

  static String _adjust(String hex, double amount) => amount >= 0
      ? _mix(hex, '#ffffff', amount)
      : _mix(hex, '#000000', -amount);

  static String _ensureReadableOutline(String outline, List<String> surfaces) {
    final current = _minimumLumaDistance(outline, surfaces);
    if (current >= 52) return outline;
    const dark = '#080a0e';
    const light = '#f4f5f7';
    return _minimumLumaDistance(dark, surfaces) >=
            _minimumLumaDistance(light, surfaces)
        ? dark
        : light;
  }

  static int _supportedBudget(int value) => switch (value) {
        4 || 8 || 16 || 32 => value,
        _ => 16,
      };

  static List<String> _applyColorBudget(List<String> source, int budget) {
    if (budget >= source.length) return List<String>.from(source);
    const priority = <int>[
      0,
      4,
      12,
      25,
      9,
      21,
      14,
      18,
      30,
      5,
      10,
      22,
      26,
      13,
      17,
      20,
    ];
    final selected = <String>[];
    for (final index in priority) {
      final color = source[index];
      if (!selected.contains(color)) selected.add(color);
      if (selected.length == budget) break;
    }
    for (final color in source) {
      if (selected.length == budget) break;
      if (!selected.contains(color)) selected.add(color);
    }
    return <String>[
      for (final color in source) _nearestColor(color, selected),
    ];
  }

  static String _nearestColor(String color, List<String> candidates) {
    final rgb = _rgb(color);
    String? best;
    var bestDistance = double.infinity;
    for (final candidate in candidates) {
      final target = _rgb(candidate);
      final distance = (rgb[0] - target[0]) * (rgb[0] - target[0]) * .2126 +
          (rgb[1] - target[1]) * (rgb[1] - target[1]) * .7152 +
          (rgb[2] - target[2]) * (rgb[2] - target[2]) * .0722;
      if (distance < bestDistance) {
        best = candidate;
        bestDistance = distance;
      }
    }
    return best!;
  }

  static String _ensureReadableBackground(
    String background,
    List<String> foreground,
  ) {
    if (_minimumLumaDistance(background, foreground) >= 48) return background;
    final candidates = <String>[
      background,
      _adjust(background, -0.52),
      _adjust(background, 0.52),
      '#111827',
      '#e7e2d6',
    ];
    return candidates.reduce((best, candidate) =>
        _minimumLumaDistance(candidate, foreground) >
                _minimumLumaDistance(best, foreground)
            ? candidate
            : best);
  }

  static double _minimumLumaDistance(String color, List<String> surfaces) {
    final base = _luma(color);
    var minimum = 255.0;
    for (final surface in surfaces) {
      final distance = (base - _luma(surface)).abs();
      if (distance < minimum) minimum = distance;
    }
    return minimum;
  }

  static double _luma(String color) {
    final rgb = _rgb(color);
    return rgb[0] * .2126 + rgb[1] * .7152 + rgb[2] * .0722;
  }

  static int _rgbaFromHex(String hex) =>
      (int.parse(hex.substring(1), radix: 16) << 8) | 0xff;
}
