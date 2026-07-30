import '../../pixels/pixel_mask.dart';
import '../../util/math_utils.dart';
import '../render_helpers.dart';
import '../render_model.dart';

/// Renders clothing overlays, armor, capes and rear equipment.
final class ArmorRenderer implements AvatarPartRenderer {
  const ArmorRenderer();

  @override
  void render(AvatarRenderContext context, AvatarRenderState state) {
    final cape = _cape(context);
    final armor = _armor(context, state.mask('torso'));
    state
      ..putMask('cape', cape.base)
      ..putMask('armor', armor.base)
      ..addLayer('cape.outline', 10, cape.base.outline(diagonal: true),
          context.color('outline'),
          meta: const {'part': 'cape'})
      ..addLayer('cape.base', 11, cape.base, context.color('clothDark'),
          meta: const {'part': 'cape'})
      ..addLayer('cape.light', 12, cape.light, context.color('clothBase'),
          meta: const {'part': 'cape'})
      ..addLayer('cape.detail', 13, cape.detail, context.color('clothAccent'),
          meta: const {'part': 'cape'})
      ..addLayer('armor.outline', 154, armor.base.outline(diagonal: true),
          context.color('outline'),
          meta: const {'part': 'armor'})
      ..addLayer('armor.base', 155, armor.base, context.color('clothBase'),
          meta: const {'part': 'armor'})
      ..addLayer('armor.shadow', 156, armor.shadow, context.color('clothDark'),
          meta: const {'part': 'armor'})
      ..addLayer('armor.light', 157, armor.light, context.color('clothLight'),
          meta: const {'part': 'armor'})
      ..addLayer(
          'armor.accent', 158, armor.accent, context.color('clothAccent'),
          meta: const {'part': 'armor'})
      ..addLayer('armor.glow', 159, armor.glow, context.color('fantasyLight'),
          meta: const {'part': 'armor'});
  }

  _Cape _cape(AvatarRenderContext c) {
    final style = c.string('v4.cape');
    if (style == 'none') return _Cape.empty();
    final base = PixelMask();
    final light = PixelMask();
    final detail = PixelMask();
    if (style == 'shortCape' || style == 'longCape') {
      final bottom = style == 'longCape' ? 47 : 42;
      base.fillTriangle((x: 10, y: 31), (x: 38, y: 31), (x: 24, y: bottom));
      light.line(13, 34, 20, bottom - 1);
    } else if (style == 'loweredHood') {
      base.fillEllipse(24, 31, 12, 7);
      detail.fillEllipse(24, 31, 8, 4);
    } else if (style == 'scarfBack') {
      base.fillRect(17, 32, 14, 4);
      base.fillTriangle((x: 17, y: 35), (x: 24, y: 35), (x: 15, y: 47));
      base.fillTriangle((x: 24, y: 35), (x: 31, y: 35), (x: 34, y: 47));
    } else if (style == 'furCollar') {
      for (var x = 10; x <= 38; x += 4) base.fillEllipse(x, 34, 3, 3);
      light.hLine(12, 36, 32);
    } else if (<String>[
      'angelWings',
      'demonWings',
      'dragonWings',
      'mechanicalWings'
    ].contains(style)) {
      final feathered = style == 'angelWings';
      final mechanical = style == 'mechanicalWings';
      base.fillTriangle((x: 13, y: 34), (x: 1, y: 16), (x: 8, y: 42));
      base.fillTriangle((x: 35, y: 34), (x: 47, y: 16), (x: 40, y: 42));
      if (feathered) {
        for (var y = 22; y <= 39; y += 4) {
          light.line(10, 34, 3, y);
          light.line(38, 34, 45, y);
        }
      } else if (mechanical) {
        detail.line(12, 34, 2, 18).line(36, 34, 46, 18);
        for (var i = 0; i < 3; i++) {
          detail.set(5 + i * 3, 23 + i * 4);
          detail.set(42 - i * 3, 23 + i * 4);
        }
      } else {
        detail.line(12, 34, 3, 18).line(36, 34, 45, 18);
      }
    } else if (style == 'backpack') {
      base.fillRect(12, 31, 24, 17);
      detail.hLine(14, 34, 35).vLine(16, 33, 47).vLine(32, 33, 47);
    } else if (style == 'quiver') {
      base.fillTriangle((x: 35, y: 25), (x: 41, y: 27), (x: 37, y: 47));
      for (var i = 0; i < 4; i++) detail.line(37 + i, 27, 39 + i, 17 - i);
    } else if (style == 'swordBack' || style == 'energyRifleBack') {
      final left = style == 'swordBack';
      base.line(left ? 11 : 37, 46, left ? 37 : 11, 13,
          thickness: style == 'energyRifleBack' ? 3 : 2);
      detail.line(left ? 9 : 39, 42, left ? 15 : 33, 46, thickness: 2);
    } else if (style == 'mechanicalTubes') {
      base
          .line(14, 47, 10, 32, thickness: 2)
          .line(34, 47, 38, 32, thickness: 2);
      detail.set(10, 32).set(38, 32).set(14, 46).set(34, 46);
    }
    return _Cape(base, light.intersect(base), detail);
  }

  _Armor _armor(AvatarRenderContext c, PixelMask torso) {
    final style = c.string('v4.armor');
    if (style == 'none') return _Armor.empty();
    final bulk = c.integer('v4.armorBulk');
    final pauldron = c.integer('v4.pauldronSize');
    final damage = c.integer('v4.armorDamage');
    final glowAmount = c.integer('v4.armorGlow');
    var base = torso.clone();
    final shadow = PixelMask();
    final light = PixelMask();
    final accent = PixelMask();
    final glow = PixelMask();

    // Soft clothes stay close to the base torso; hard armor expands shoulders.
    final hard = <String>[
      'leatherArmor',
      'chainmail',
      'plateArmor',
      'samuraiArmor',
      'gladiatorArmor',
      'ceremonialArmor',
      'magicArmor',
      'iceArmor',
      'demonArmor',
      'mechanicalArmor',
      'spaceArmor',
      'scrapArmor'
    ];
    if (hard.contains(style)) {
      base = base.union(base.dilated(iterations: clampInt(bulk ~/ 2, 0, 2)));
      if (pauldron > 0) {
        base.fillEllipse(8, 36, 3 + pauldron, 2 + pauldron ~/ 2);
        base.fillEllipse(39, 36, 3 + pauldron, 2 + pauldron ~/ 2);
      }
      shadow.data
          .setAll(0, shadingMask(base, kind: 'clothing', strength: 2).data);
      light.data
          .setAll(0, highlightMask(base, kind: 'clothing', strength: 2).data);
    } else {
      shadow.data
          .setAll(0, shadingMask(base, kind: 'clothing', strength: 1).data);
      light.data
          .setAll(0, highlightMask(base, kind: 'clothing', strength: 1).data);
    }

    if (style == 'chainmail') {
      for (var y = 36; y < 48; y += 2) {
        for (var x = 10 + positiveMod(y, 4); x < 39; x += 4) accent.set(x, y);
      }
    } else if (style == 'plateArmor' || style == 'spaceArmor') {
      accent.hLine(13, 35, 38).vLine(24, 35, 47);
      accent.fillRect(20, 38, 8, 5);
    } else if (style == 'samuraiArmor') {
      for (var y = 36; y < 48; y += 3) accent.hLine(10, 38, y);
    } else if (style == 'gladiatorArmor') {
      accent.line(12, 35, 24, 47).line(36, 35, 24, 47);
    } else if (style == 'ceremonialArmor') {
      accent.vLine(24, 34, 47).hLine(15, 33, 36);
    } else if (style == 'magicArmor' ||
        style == 'iceArmor' ||
        style == 'demonArmor') {
      accent.fillTriangle((x: 19, y: 38), (x: 29, y: 38), (x: 24, y: 46));
      for (var i = 0; i < glowAmount; i++) glow.set(22 + i * 2, 41);
    } else if (style == 'mechanicalArmor') {
      accent.fillRect(14, 36, 6, 5).fillRect(28, 36, 6, 5).line(20, 38, 28, 38);
      glow.set(17, 38).set(31, 38);
    } else if (style == 'scrapArmor') {
      accent.line(11, 38, 20, 35).line(28, 36, 38, 42);
    } else if (style == 'hoodie') {
      accent.line(20, 35, 22, 47).line(28, 35, 26, 47);
    } else if (style == 'shirt' || style == 'blazer' || style == 'uniform') {
      accent.vLine(24, 35, 47);
      accent.line(17, 35, 24, 40).line(31, 35, 24, 40);
    } else if (style == 'jacket' ||
        style == 'coat' ||
        style == 'travelerCoat' ||
        style == 'pirateCoat') {
      accent.line(16, 34, 22, 47).line(32, 34, 26, 47);
      accent.vLine(24, 39, 47);
    } else if (style == 'apron' || style == 'labCoat') {
      accent.fillRect(17, 37, 14, 11);
      accent.vLine(24, 37, 47);
    } else if (style == 'wizardRobe' || style == 'priestRobe') {
      accent.vLine(24, 34, 47);
      if (style == 'priestRobe') accent.hLine(20, 28, 38);
      if (style == 'wizardRobe')
        accent.fillTriangle((x: 20, y: 39), (x: 28, y: 39), (x: 24, y: 45));
    } else if (style == 'cowboyVest' || style == 'vest') {
      accent.line(14, 35, 20, 47).line(34, 35, 28, 47);
    } else if (style == 'tshirt' ||
        style == 'sweater' ||
        style == 'turtleneck') {
      accent.hLine(18, 30, 36);
    }

    if (c.integer('v4.emblemSize') > 0) {
      final size = c.integer('v4.emblemSize');
      accent.fillEllipse(24, 40, size, size);
      shadow.fillEllipse(
          24, 40, clampInt(size - 1, 0, 5), clampInt(size - 1, 0, 5));
    }
    if (damage > 0) {
      final rng = c.random('armor.damage.$style');
      final holes = PixelMask();
      for (var i = 0; i < damage; i++) {
        holes.line(rng.nextInt(12, 35), rng.nextInt(35, 46),
            rng.nextInt(12, 35), rng.nextInt(35, 46));
      }
      base = base.subtract(holes);
    }
    if (glowAmount > 0 &&
        <String>{
          'idle',
          'talking',
          'laughing',
          'glowPulse',
          'celebration',
          'scared',
          'surprised',
          'angry',
          'sad',
          'happy',
          'thinking',
          'confused',
          'hurt',
        }.contains(c.animation.id)) {
      final pulse = c.animation.pulse(basePeriod: 8, peak: 2);
      if (pulse > 0) {
        glow
          ..fillEllipse(24, 40, 1 + pulse, 1 + pulse)
          ..hLine(21 - pulse, 27 + pulse, 40);
      }
    }
    return _Armor(
        base.removeSmallComponents(2, maxComponents: 4),
        shadow.intersect(base),
        light.intersect(base),
        accent.intersect(base),
        glow.intersect(base));
  }
}

final class _Cape {
  const _Cape(this.base, this.light, this.detail);
  factory _Cape.empty() => _Cape(PixelMask(), PixelMask(), PixelMask());
  final PixelMask base;
  final PixelMask light;
  final PixelMask detail;
}

final class _Armor {
  const _Armor(this.base, this.shadow, this.light, this.accent, this.glow);
  factory _Armor.empty() =>
      _Armor(PixelMask(), PixelMask(), PixelMask(), PixelMask(), PixelMask());
  final PixelMask base;
  final PixelMask shadow;
  final PixelMask light;
  final PixelMask accent;
  final PixelMask glow;
}
