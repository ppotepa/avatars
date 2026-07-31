import '../../geometry/pixel_rect.dart';
import '../../pixels/pixel_mask.dart';
import '../../util/math_utils.dart';
import '../render_helpers.dart';
import '../render_model.dart';
import '../rig_model.dart';
import 'rain_field_renderer.dart';

/// Rebuilds world-space weather emitters after the actor pose has been applied.
///
/// Rain collision uses the transformed actor masks. The mouth emitter follows
/// the transformed prop, but emitted smoke belongs to scene space and therefore
/// does not continue rotating or translating with the head.
final class WorldSmokeEmitterRenderer implements AvatarPartRenderer {
  const WorldSmokeEmitterRenderer();

  @override
  void render(AvatarRenderContext context, AvatarRenderState state) {
    // Replace the pre-pose rain field with one evaluated against the visible
    // actor geometry, so shoulder and head splashes stay aligned.
    state.layers.removeWhere((layer) => layer.id.startsWith('rain.field.'));
    const RainFieldRenderer().render(context, state);

    final style = context.string('v4.mouthProp');
    final amount = context.integer('v4.smokeAmount');
    if (!<String>{'cigarette', 'cigar', 'pipe', 'matchstick'}.contains(style) ||
        amount <= 0) {
      state.layers.removeWhere((layer) => layer.id.startsWith('mouthProp.smoke'));
      return;
    }

    final propLayers = state.layers
        .where((layer) =>
            layer.nodeId == 'mouthProp' &&
            !layer.id.startsWith('mouthProp.smoke'))
        .toList(growable: false);
    if (propLayers.isEmpty) return;

    state.layers.removeWhere((layer) => layer.id.startsWith('mouthProp.smoke'));
    final bounds = _bounds(propLayers);
    if (bounds == null) return;
    final side = context.integer('v4.propSide') == 0
        ? (context.random('worldSmoke.side').nextBool() ? -1 : 1)
        : context.integer('v4.propSide').sign;
    final emitterX = side < 0 ? bounds.left : bounds.right;
    final emitterY = bounds.top;
    final template = propLayers.first.mask;
    final dark = PixelMask(width: template.width, height: template.height);
    final light = PixelMask(width: template.width, height: template.height);
    final wind = clampInt(context.integer('v4.weatherDrift'), -3, 3);

    for (var index = 0; index < amount; index++) {
      final random = context.random('worldSmoke.$style.$index');
      final lifetime = 20 + index * 3 + random.nextInt(0, 7);
      final spawn = random.nextInt(0, lifetime - 1);
      final age = positiveMod(context.phase - spawn, lifetime);
      final sway = cyclicOffset(age + index * 2, lifetime, 1 + index ~/ 3);
      final x = emitterX + side * (index ~/ 3) + wind * age ~/ 7 + sway;
      final y = emitterY - 1 - age;
      if (x < -6 || x >= template.width + 6 || y < -6 || y >= template.height) {
        continue;
      }
      final radius = 1 + index ~/ 3 + age * 2 ~/ lifetime;
      final target = age < lifetime * .2 || age > lifetime * .85
          ? dark
          : light;
      target.fillEllipse(x, y, radius, clampInt(radius ~/ 2, 1, 3));
    }

    state
      ..addLayer(
        'smoke.world.dark',
        204,
        dark,
        context.color('weatherFogDark'),
        nodeId: 'atmosphere',
        slot: RenderSlot.foreground,
        meta: const <String, Object?>{
          'part': 'smoke',
          'space': 'world',
          'rigSegment': 'atmosphere',
        },
      )
      ..addLayer(
        'smoke.world.light',
        205,
        light,
        context.color('weatherFogLight'),
        nodeId: 'foreground',
        slot: RenderSlot.foreground,
        meta: const <String, Object?>{
          'part': 'smoke',
          'space': 'world',
          'rigSegment': 'foreground',
        },
      );
    state.metadata['worldSmokeEmitter'] = <String, Object>{
      'x': emitterX,
      'y': emitterY,
      'side': side,
      'amount': amount,
      'wind': wind,
    };
  }

  PixelRect? _bounds(List<RenderLayer> layers) {
    PixelRect? result;
    for (final layer in layers) {
      final current = layer.mask.bounds;
      if (current == null) continue;
      if (result == null) {
        result = current;
      } else {
        final left = result.left < current.left ? result.left : current.left;
        final top = result.top < current.top ? result.top : current.top;
        final right = result.right > current.right ? result.right : current.right;
        final bottom = result.bottom > current.bottom
            ? result.bottom
            : current.bottom;
        result = PixelRect(
          left,
          top,
          right - left + 1,
          bottom - top + 1,
        );
      }
    }
    return result;
  }
}
