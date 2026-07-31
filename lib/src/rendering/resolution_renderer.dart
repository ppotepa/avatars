import '../api/avatar_request.dart';
import '../palette/avatar_palette.dart';
import '../pixels/indexed_image.dart';
import 'native_detail_renderer.dart';
import 'native_geometry_renderer.dart';
import 'render_model.dart';
import 'resolution_profile.dart';
import 'resolution_render_cache.dart';

/// Renders the canonical composition on the requested pixel grid.
///
/// Sizes above 48 rasterize every semantic layer independently before lighting
/// and detail enrichment. This avoids enlarging an already flattened image.
final class ResolutionAwareRenderer {
  const ResolutionAwareRenderer({
    this.nativeGeometry = const NativeGeometryRenderer(),
    this.nativeDetails = const NativeDetailRenderer(),
  });

  final NativeGeometryRenderer nativeGeometry;
  final NativeDetailRenderer nativeDetails;
  static final ResolutionRenderCache _cache = ResolutionRenderCache();
  static final Map<String, Map<String, Object>> _diagnostics =
      <String, Map<String, Object>>{};
  static final List<String> _diagnosticOrder = <String>[];

  static Map<String, Object> diagnosticsFor(
    IndexedImage image,
    AvatarPalette palette,
  ) {
    final hash = image.hashWithPalette(palette.colors);
    return Map<String, Object>.unmodifiable(
      _diagnostics[hash] ??
          <String, Object>{
            'nativeGeometryPixelCount': 0,
            'nativeGeometryPixelRatio': 0.0,
            'geometryProfile': image.width == 48
                ? 'canonical48'
                : 'native${image.width}',
          },
    );
  }

  IndexedImage render({
    required IndexedImage source,
    required List<RenderLayer> layers,
    required AvatarPalette palette,
    required AvatarRenderSettings settings,
    required int phase,
  }) {
    if (settings.size == source.width && settings.size == source.height) {
      _recordDiagnostics(
        source: source,
        output: source,
        palette: palette,
        profile: ResolutionProfile.forSettings(settings),
      );
      return source;
    }

    final key = _cacheKey(source, layers, palette, settings, phase);
    final cached = _cache.get(key);
    if (cached != null) return cached;

    final profile = ResolutionProfile.forSettings(settings);
    final geometry = nativeGeometry.rasterize(
      layers: layers,
      profile: profile,
    );
    final lit = _applyLighting(
      geometry,
      layers: layers,
      palette: palette,
      settings: settings,
    );
    final enhanced = nativeDetails.enhance(
      image: lit,
      source: source,
      layers: layers,
      palette: palette,
      settings: settings,
      phase: phase,
    );
    _recordDiagnostics(
      source: source,
      output: enhanced,
      palette: palette,
      profile: profile,
    );
    _cache.put(key, enhanced);
    return enhanced;
  }

  void _recordDiagnostics({
    required IndexedImage source,
    required IndexedImage output,
    required AvatarPalette palette,
    required ResolutionProfile profile,
  }) {
    var changed = 0;
    for (var y = 0; y < output.height; y++) {
      final sy = y * source.height ~/ output.height;
      for (var x = 0; x < output.width; x++) {
        final sx = x * source.width ~/ output.width;
        if (output.get(x, y) != source.get(sx, sy)) changed++;
      }
    }
    final total = output.width * output.height;
    final hash = output.hashWithPalette(palette.colors);
    _diagnostics[hash] = <String, Object>{
      'nativeGeometryPixelCount': changed,
      'nativeGeometryPixelRatio': total == 0 ? 0.0 : changed / total,
      'geometryProfile': profile.nativeGeometry
          ? 'native${profile.size}.budget${profile.detailBudget}'
          : 'canonical48',
    };
    _diagnosticOrder
      ..remove(hash)
      ..add(hash);
    while (_diagnosticOrder.length > 64) {
      _diagnostics.remove(_diagnosticOrder.removeAt(0));
    }
  }

  IndexedImage _applyLighting(
    IndexedImage image, {
    required List<RenderLayer> layers,
    required AvatarPalette palette,
    required AvatarRenderSettings settings,
  }) {
    if (settings.detailLevel == AvatarDetailLevel.basic ||
        settings.shadingStrength == 0) {
      return image;
    }

    final owners = _nativeOwners(layers, image.width, image.height);
    final output = image.clone();
    final fromRight =
        settings.lightingDirection == AvatarLightingDirection.upperRight;
    final frontal =
        settings.lightingDirection == AvatarLightingDirection.frontal;

    for (var y = 0; y < image.height; y++) {
      for (var x = 0; x < image.width; x++) {
        final original = image.get(x, y);
        if (original == image.transparentIndex) continue;
        final owner = owners[y * image.width + x] ?? '';
        final lightX = frontal ? x : x + (fromRight ? 1 : -1);
        final shadowX = frontal ? x : x + (fromRight ? -1 : 1);
        final exposedLight = image.get(lightX, y) != original ||
            image.get(x, y - 1) != original;
        final exposedShadow = image.get(shadowX, y) != original ||
            image.get(x, y + 1) != original;
        if (exposedLight) {
          output.setPixel(
            x,
            y,
            _ramp(original, palette, lighter: true, owner: owner),
          );
        } else if (settings.shadingStrength >= 2 && exposedShadow) {
          output.setPixel(
            x,
            y,
            _ramp(original, palette, lighter: false, owner: owner),
          );
        }
      }
    }
    return output;
  }

  String _cacheKey(
    IndexedImage source,
    List<RenderLayer> layers,
    AvatarPalette palette,
    AvatarRenderSettings settings,
    int phase,
  ) {
    final layerSignature = layers
        .map(
          (layer) => <Object>[
            layer.id,
            layer.nodeId,
            layer.slot.index,
            layer.localOrder,
            layer.mask.count,
            layer.mask.bounds,
          ].join(':'),
        )
        .join('|');
    return '${source.hashWithPalette(palette.colors)}:'
        '${settings.size}:${settings.detailLevel.name}:'
        '${settings.lightingDirection.name}:${settings.shadingStrength}:'
        '$phase:$layerSignature';
  }

  int _ramp(
    int color,
    AvatarPalette palette, {
    required bool lighter,
    required String owner,
  }) {
    final roles = palette.roles;
    final ramps = <(int, int, int)>[
      (roles['skinShadow']!, roles['skinBase']!, roles['skinLight']!),
      (roles['hairShadow']!, roles['hairBase']!, roles['hairLight']!),
      (roles['irisDark']!, roles['irisBase']!, roles['irisLight']!),
      (roles['mouthDark']!, roles['mouthBase']!, roles['mouthLight']!),
      (roles['clothDark']!, roles['clothBase']!, roles['clothLight']!),
      (roles['bgDark']!, roles['bg']!, roles['bgLight']!),
      (roles['fantasyDark']!, roles['fantasyBase']!, roles['fantasyLight']!),
    ];
    for (final ramp in ramps) {
      if (color == ramp.$1) return lighter ? ramp.$2 : ramp.$1;
      if (color == ramp.$2) return lighter ? ramp.$3 : ramp.$1;
      if (color == ramp.$3) return lighter ? ramp.$3 : ramp.$2;
    }
    if (lighter &&
        <String>{'jewelry', 'armor', 'eyewear', 'cyber'}
            .contains(owner)) {
      return roles['white']!;
    }
    return color;
  }

  List<String?> _nativeOwners(
    List<RenderLayer> layers,
    int width,
    int height,
  ) {
    final owners = List<String?>.filled(width * height, null);
    final sorted = List<RenderLayer>.from(layers)
      ..sort((a, b) {
        final bySlot = a.slot.index.compareTo(b.slot.index);
        if (bySlot != 0) return bySlot;
        final byLocal = a.localOrder.compareTo(b.localOrder);
        return byLocal != 0 ? byLocal : a.id.compareTo(b.id);
      });
    for (final layer in sorted) {
      final owner = layer.meta['part'] is String
          ? layer.meta['part']! as String
          : layer.nodeId;
      for (var sy = 0; sy < layer.mask.height; sy++) {
        final top = sy * height ~/ layer.mask.height;
        final bottom = ((sy + 1) * height ~/ layer.mask.height)
            .clamp(top + 1, height)
            .toInt();
        for (var sx = 0; sx < layer.mask.width; sx++) {
          if (layer.mask.get(sx, sy) == 0) continue;
          final left = sx * width ~/ layer.mask.width;
          final right = ((sx + 1) * width ~/ layer.mask.width)
              .clamp(left + 1, width)
              .toInt();
          for (var y = top; y < bottom; y++) {
            for (var x = left; x < right; x++) {
              owners[y * width + x] = owner;
            }
          }
        }
      }
    }
    return owners;
  }
}
