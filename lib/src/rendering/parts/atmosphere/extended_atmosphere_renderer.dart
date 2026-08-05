import '../../render_model.dart';
import 'ambient_overlay_renderer.dart';
import 'back_flames_renderer.dart';
import 'background_event_renderer.dart';
import 'cosmic_layer_renderer.dart';
import 'scenic_background_renderer.dart';
import 'weather_layer_renderer.dart';

final class SplitExtendedAtmosphereRenderer implements AvatarPartRenderer {
  const SplitExtendedAtmosphereRenderer({
    this.scenic = const ScenicBackgroundRenderer(),
    this.cosmic = const CosmicLayerRenderer(),
    this.ambient = const AmbientOverlayRenderer(),
    this.flames = const BackFlamesRenderer(),
    this.event = const BackgroundEventRenderer(),
    this.weather = const WeatherLayerRenderer(),
  });

  final ScenicBackgroundRenderer scenic;
  final CosmicLayerRenderer cosmic;
  final AmbientOverlayRenderer ambient;
  final BackFlamesRenderer flames;
  final BackgroundEventRenderer event;
  final WeatherLayerRenderer weather;

  @override
  void render(AvatarRenderContext context, AvatarRenderState state) {
    final scenicMasks = scenic.build(context);
    final cosmicMasks = cosmic.build(context);
    final ambientMasks = ambient.build(context);
    final flameMasks = flames.build(context);
    final eventMasks = event.build(context);
    final weatherBack = weather.build(context, back: true);
    final weatherFront = weather.build(context, back: false);

    state
      ..addLayer(
        'background.v42.dark',
        2,
        scenicMasks.dark,
        context.color('bgDark'),
        meta: const <String, Object?>{'part': 'background'},
      )
      ..addLayer(
        'background.v42.light',
        3,
        scenicMasks.base,
        context.color('bgLight'),
        meta: const <String, Object?>{'part': 'background'},
      )
      ..addLayer(
        'background.v42.accent',
        4,
        scenicMasks.light,
        context.color('clothAccent'),
        meta: const <String, Object?>{'part': 'background'},
      )
      ..addLayer(
        'cosmic.v42.dark',
        3,
        cosmicMasks.dark,
        context.color('fantasyDark'),
        meta: const <String, Object?>{'part': 'cosmic'},
      )
      ..addLayer(
        'cosmic.v42.base',
        4,
        cosmicMasks.base,
        context.color('fantasyBase'),
        meta: const <String, Object?>{'part': 'cosmic'},
      )
      ..addLayer(
        'cosmic.v42.light',
        5,
        cosmicMasks.light,
        context.color('fantasyLight'),
        meta: const <String, Object?>{'part': 'cosmic'},
      )
      ..addLayer(
        'ambient.v42.dark',
        5,
        ambientMasks.dark,
        context.color('bgDark'),
        meta: const <String, Object?>{'part': 'ambient'},
      )
      ..addLayer(
        'ambient.v42.light',
        6,
        ambientMasks.light,
        context.color('bgLight'),
        meta: const <String, Object?>{'part': 'ambient'},
      )
      ..addLayer(
        'weather.v42.back.dark',
        7,
        weatherBack.dark,
        context.color('bgDark'),
        meta: const <String, Object?>{'part': 'weather'},
      )
      ..addLayer(
        'weather.v42.back',
        8,
        weatherBack.base,
        context.color('fantasyBase'),
        meta: const <String, Object?>{'part': 'weather'},
      )
      ..addLayer(
        'weather.v42.back.light',
        9,
        weatherBack.light,
        context.color('fantasyLight'),
        meta: const <String, Object?>{'part': 'weather'},
      )
      ..addLayer(
        'flames.v42.dark',
        8,
        flameMasks.dark,
        context.color('fantasyDark'),
        meta: const <String, Object?>{'part': 'flames'},
      )
      ..addLayer(
        'flames.v42.base',
        9,
        flameMasks.base,
        context.color('fantasyBase'),
        meta: const <String, Object?>{'part': 'flames'},
      )
      ..addLayer(
        'flames.v42.light',
        9,
        flameMasks.light,
        context.color('fantasyLight'),
        meta: const <String, Object?>{'part': 'flames'},
      )
      ..addLayer(
        'backgroundEvent.v42.dark',
        6,
        eventMasks.dark,
        context.color('bgDark'),
        meta: const <String, Object?>{'part': 'backgroundEvent'},
      )
      ..addLayer(
        'backgroundEvent.v42.base',
        7,
        eventMasks.base,
        context.color('clothAccent'),
        meta: const <String, Object?>{'part': 'backgroundEvent'},
      )
      ..addLayer(
        'backgroundEvent.v42.light',
        8,
        eventMasks.light,
        context.color('white'),
        meta: const <String, Object?>{'part': 'backgroundEvent'},
      )
      ..addLayer(
        'weather.v42.front.dark',
        233,
        weatherFront.dark,
        context.color('bgDark'),
        meta: const <String, Object?>{'part': 'weather'},
      )
      ..addLayer(
        'weather.v42.front',
        234,
        weatherFront.base,
        context.color('fantasyBase'),
        meta: const <String, Object?>{'part': 'weather'},
      )
      ..addLayer(
        'weather.v42.front.light',
        235,
        weatherFront.light,
        context.color('fantasyLight'),
        meta: const <String, Object?>{'part': 'weather'},
      );
  }
}
