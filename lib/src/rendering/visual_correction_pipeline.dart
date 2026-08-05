import '../pixels/pixel_mask.dart';
import 'render_model.dart';

/// Applies deterministic readability corrections after semantic parts render
/// and before rig binding. Existing pipeline guards may repeat these operations;
/// every operation is intentionally idempotent.
final class VisualCorrectionPipeline implements AvatarPartRenderer {
  const VisualCorrectionPipeline();

  @override
  void render(AvatarRenderContext context, AvatarRenderState state) {
    _ensureBackgroundContrast(context, state);
    _simplifyHighFrequencyBackground(context, state);
    _simplifyFaceMaskPattern(context, state);
    _reduceInternalOutlines(state);
    _reduceMicroFaceDetails(state);
  }

  void _reduceInternalOutlines(AvatarRenderState state) {
    const structuralParts = <String>{
      'torso',
      'neck',
      'head',
      'hair',
      'cape',
      'armor',
      'headwear',
      'fantasy',
      'companion',
    };
    var removed = 0;
    state.layers.removeWhere((layer) {
      if (!layer.id.endsWith('.outline')) return false;
      final part = layer.meta['part']?.toString() ?? layer.id.split('.').first;
      final remove = !structuralParts.contains(part);
      if (remove) removed++;
      return remove;
    });
    state.metadata['outlineBudget'] = <String, Object>{
      'removedInternalOutlines': removed,
      'structuralParts': structuralParts.toList(growable: false),
    };
  }

  void _simplifyHighFrequencyBackground(
    AvatarRenderContext context,
    AvatarRenderState state,
  ) {
    const noisyBackgrounds = <String>{
      'checker',
      'diagonalStripes',
      'pixelNoise',
      'warpTunnel',
      'voidStatic',
      'factionSymbol',
      'dataGrid',
      'cathedralWindow',
      'citySkyline',
      'starshipBridge',
      'spaceStation',
      'castleWall',
      'throneRoom',
      'libraryShelves',
      'neonCity',
      'laboratory',
      'terminal',
    };
    final background = context.string('v4.background');
    if (!noisyBackgrounds.contains(background)) return;
    var removed = 0;
    state.layers.removeWhere((layer) {
      if (!layer.id.startsWith('background.') ||
          layer.id == 'background.base') {
        return false;
      }
      removed++;
      return true;
    });
    state.metadata['backgroundClarityBudget'] = <String, Object>{
      'background': background,
      'removedHighFrequencyLayers': removed,
      'reason': 'highFrequencyPattern',
    };
  }

  void _simplifyFaceMaskPattern(
    AvatarRenderContext context,
    AvatarRenderState state,
  ) {
    if (context.string('v4.faceMask') != 'robotMask') return;
    var removed = 0;
    state.layers.removeWhere((layer) {
      if (!layer.id.startsWith('faceMask.procedural.')) return false;
      removed++;
      return true;
    });
    state.metadata['faceMaskClarityBudget'] = <String, Object>{
      'style': 'robotMask',
      'removedProceduralPatternLayers': removed,
      'reason': 'fullSurfaceGridAtSmallResolution',
    };
  }

  void _ensureBackgroundContrast(
    AvatarRenderContext context,
    AvatarRenderState state,
  ) {
    final candidates = <int>[
      context.color('bg'),
      context.color('bgDark'),
      context.color('bgLight'),
    ];
    final actorColors = <int>[
      context.color('skinBase'),
      context.color('clothBase'),
      context.color('hairBase'),
    ];
    double luma(int rgba) {
      final red = (rgba >> 24) & 0xff;
      final green = (rgba >> 16) & 0xff;
      final blue = (rgba >> 8) & 0xff;
      return red * .2126 + green * .7152 + blue * .0722;
    }

    final actorLuma = actorColors.map(luma).toList(growable: false);
    int score(int background) => actorLuma
        .map((actor) => (luma(background) - actor).abs().round())
        .reduce((a, b) => a < b ? a : b);
    final selected = candidates.reduce(
      (a, b) => score(a) >= score(b) ? a : b,
    );
    final original = context.color('bg');
    if (selected == original) return;
    var adjusted = 0;
    for (var index = 0; index < state.layers.length; index++) {
      final layer = state.layers[index];
      if (layer.id != 'background.base') continue;
      state.layers[index] = layer.copyWith(colorIndex: selected);
      adjusted++;
    }
    state.metadata['backgroundContrast'] = <String, Object>{
      'originalColorIndex': original,
      'selectedColorIndex': selected,
      'minimumActorLumaDistance': score(selected),
      'adjustedLayerCount': adjusted,
    };
  }

  void _reduceMicroFaceDetails(AvatarRenderState state) {
    final head = state.mask('head');
    if (head.count == 0 || head.count >= 360) return;
    const optionalParts = <String>{'skinDetails', 'cheeks'};
    var removed = 0;
    state.layers.removeWhere((layer) {
      final part = layer.meta['part']?.toString();
      if (!optionalParts.contains(part)) return false;
      removed++;
      return true;
    });
    state.metadata['faceDetailBudget'] = <String, Object>{
      'headPixels': head.count,
      'removedMicroDetailLayers': removed,
      'reason': 'smallFaceRegion',
    };
  }

  PixelMask unionLayers(Iterable<RenderLayer> layers) {
    PixelMask? output;
    for (final layer in layers) {
      output = output == null ? layer.mask.clone() : output.union(layer.mask);
    }
    return output ?? PixelMask();
  }
}
