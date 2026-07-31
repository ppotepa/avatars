import '../../pixels/pixel_mask.dart';
import '../../random/random_stream.dart';
import '../../util/math_utils.dart';
import '../render_model.dart';

/// Adds restrained seed-level surface construction to larger accessories.
/// The overlay uses the existing semantic masks, so it increases variation
/// without changing attachment geometry or introducing clipping conflicts.
final class ProceduralSurfaceVariationRenderer implements AvatarPartRenderer {
  const ProceduralSurfaceVariationRenderer();

  @override
  void render(AvatarRenderContext context, AvatarRenderState state) {
    _decorate(
      context,
      state,
      maskId: 'cape',
      layerPrefix: 'cape.procedural',
      z: 14,
      namespace: context.string('v4.cape'),
      damage: 0,
    );
    _decorate(
      context,
      state,
      maskId: 'armor',
      layerPrefix: 'armor.procedural',
      z: 160,
      namespace: context.string('v4.armor'),
      damage: context.integer('v4.armorDamage'),
    );
    _decorate(
      context,
      state,
      maskId: 'cybernetics',
      layerPrefix: 'cyber.procedural',
      z: 149,
      namespace: context.string('v4.cybernetics'),
      damage: context.integer('v4.cyberCoverage') ~/ 2,
      mechanical: true,
    );
    _decorate(
      context,
      state,
      maskId: 'headwear',
      layerPrefix: 'headwear.procedural',
      z: 169,
      namespace: context.string('v4.headwear'),
      damage: context.integer('v4.headwearDamage'),
    );
    _decorate(
      context,
      state,
      maskId: 'shoulderProp',
      layerPrefix: 'shoulderProp.procedural',
      z: 198,
      namespace: context.string('v4.shoulderProp'),
      damage: 0,
    );
    _decorate(
      context,
      state,
      maskId: 'companion',
      layerPrefix: 'companion.procedural',
      z: 201,
      namespace: context.string('v4.extraShoulderProp'),
      damage: 0,
    );
    _decorate(
      context,
      state,
      maskId: 'relic',
      layerPrefix: 'relic.procedural',
      z: 192,
      namespace: context.string('v4.relic'),
      damage: 0,
    );
  }

  PixelMask _resolvedMask(AvatarRenderState state, String maskId) {
    var mask = state.mask(maskId);
    if (mask.count > 0) return mask;
    for (final layer in state.layers) {
      final part = layer.meta['part'];
      if (part == maskId || layer.id.startsWith('$maskId.')) {
        mask = mask.union(layer.mask);
      }
    }
    return mask;
  }

  void _decorate(
    AvatarRenderContext context,
    AvatarRenderState state, {
    required String maskId,
    required String layerPrefix,
    required int z,
    required String namespace,
    required int damage,
    bool mechanical = false,
  }) {
    final mask = _resolvedMask(state, maskId);
    final bounds = mask.bounds;
    if (mask.count < 6 || bounds == null || namespace == 'none') return;

    final random = context.random('surface.procedural.$maskId.$namespace');
    final dark = PixelMask();
    final accent = PixelMask();
    final light = PixelMask();
    final variant = random.nextInt(0, 7);
    final centerX = bounds.center.x;
    final centerY = bounds.center.y;
    final left = bounds.left;
    final right = bounds.right;
    final top = bounds.top;
    final bottom = bounds.bottom;

    if (variant == 0) {
      accent.vLine(centerX + random.nextInt(-2, 2), top, bottom);
    } else if (variant == 1) {
      accent.hLine(left, right, centerY + random.nextInt(-2, 2));
    } else if (variant == 2) {
      accent.line(left, bottom, right, top);
    } else if (variant == 3) {
      accent.line(left, top, right, bottom);
    } else if (variant == 4) {
      final panelWidth = clampInt(bounds.width ~/ 2, 2, 10);
      final panelHeight = clampInt(bounds.height ~/ 3, 2, 8);
      dark.fillRect(
        centerX - panelWidth ~/ 2,
        centerY - panelHeight ~/ 2,
        panelWidth,
        panelHeight,
      );
      accent.data.setAll(0, dark.outline(diagonal: true).data);
    } else if (variant == 5) {
      final step = clampInt(bounds.width ~/ 4, 2, 6);
      for (var x = left + 1; x < right; x += step) {
        accent.vLine(x, top + 1, bottom - 1);
      }
    } else if (variant == 6) {
      final step = clampInt(bounds.height ~/ 4, 2, 6);
      for (var y = top + 1; y < bottom; y += step) {
        accent.hLine(left + 1, right - 1, y);
      }
    } else {
      for (var index = 0; index < 5; index++) {
        accent.set(
          random.nextInt(left, right),
          random.nextInt(top, bottom),
        );
      }
    }

    final rivets = mechanical ? 4 + variant % 4 : 1 + variant % 3;
    for (var index = 0; index < rivets; index++) {
      final x = random.nextInt(left, right);
      final y = random.nextInt(top, bottom);
      dark.set(x, y);
      if (index.isEven) light.set(x - 1, y - 1);
    }

    final wear = clampInt(damage + random.nextInt(0, 2), 0, 7);
    for (var index = 0; index < wear; index++) {
      final x = random.nextInt(left, right);
      final y = random.nextInt(top, bottom);
      final direction = random.nextBool() ? 1 : -1;
      dark.line(x, y, x + direction * random.nextInt(2, 5), y + 1);
    }

    if (_organic(namespace)) {
      _organicTexture(
        random,
        accent,
        light,
        bounds.left,
        bounds.right,
        bounds.top,
        bounds.bottom,
      );
    }

    state
      ..addLayer('$layerPrefix.dark', z, dark.intersect(mask),
          context.color('clothDark'), meta: {'part': maskId})
      ..addLayer('$layerPrefix.accent', z + 1, accent.intersect(mask),
          context.color('clothAccent'), meta: {'part': maskId})
      ..addLayer('$layerPrefix.light', z + 2, light.intersect(mask),
          context.color('fantasyLight'), meta: {'part': maskId});
  }

  bool _organic(String value) => const <String>{
        'furCollar',
        'angelWings',
        'demonWings',
        'dragonWings',
        'owl',
        'crow',
        'raven',
        'bat',
        'snake',
        'cat',
        'parrot',
        'smallDragon',
      }.contains(value);

  void _organicTexture(
    RandomStream random,
    PixelMask accent,
    PixelMask light,
    int left,
    int right,
    int top,
    int bottom,
  ) {
    final marks = clampInt((right - left + bottom - top) ~/ 4, 2, 9);
    for (var index = 0; index < marks; index++) {
      final x = random.nextInt(left, right);
      final y = random.nextInt(top, bottom);
      accent.line(x, y, x + (index.isEven ? 1 : -1), y + 2);
      if (index % 3 == 0) light.set(x, y - 1);
    }
  }
}
