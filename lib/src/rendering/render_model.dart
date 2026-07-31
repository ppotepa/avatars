import '../api/avatar_request.dart';
import '../constraints/validation.dart';
import '../genome/avatar_genome_model.dart';
import '../geometry/avatar_layout.dart';
import '../geometry/pixel_rect.dart';
import '../palette/avatar_palette.dart';
import '../pixels/indexed_image.dart';
import '../pixels/pixel_mask.dart';
import '../random/random_stream.dart';
import '../util/math_utils.dart';
import 'rig_model.dart';

final class RenderLayer {
  const RenderLayer({
    required this.id,
    required this.z,
    required this.mask,
    required this.colorIndex,
    required this.nodeId,
    required this.slot,
    this.localOrder = 0,
    this.meta = const <String, Object?>{},
  });

  final String id;

  /// Compatibility depth. New code should use [slot] and [localOrder].
  final int z;
  final PixelMask mask;
  final int colorIndex;
  final String nodeId;
  final RenderSlot slot;
  final int localOrder;
  final Map<String, Object?> meta;

  RenderLayer copyWith({
    PixelMask? mask,
    String? nodeId,
    RenderSlot? slot,
    int? localOrder,
    int? z,
    Map<String, Object?>? meta,
  }) =>
      RenderLayer(
        id: id,
        z: z ?? this.z,
        mask: mask ?? this.mask,
        colorIndex: colorIndex,
        nodeId: nodeId ?? this.nodeId,
        slot: slot ?? this.slot,
        localOrder: localOrder ?? this.localOrder,
        meta: meta ?? this.meta,
      );

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'z': z,
        'nodeId': nodeId,
        'slot': slot.name,
        'localOrder': localOrder,
        'colorIndex': colorIndex,
        'pixelCount': mask.count,
        'bounds': mask.bounds?.toJson(),
        'meta': meta,
      };
}

final class AvatarRenderContext {
  AvatarRenderContext({
    required this.genome,
    required this.layout,
    required this.palette,
    required this.guard,
    required this.phase,
    this.rendering = const AvatarRenderSettings(),
  });

  final AvatarGenome genome;
  final AvatarLayout layout;
  final AvatarPalette palette;
  final ConstraintEngine guard;
  final int phase;
  final AvatarRenderSettings rendering;

  int integer(String id, [int fallback = 0]) => layout.integer(id, fallback);
  String string(String id, [String fallback = 'none']) =>
      layout.string(id, fallback);
  int color(String role) => palette.role(role);
  RandomStream random(String namespace) =>
      RandomStream(layout.values['seedHash'] is int
              ? layout.values['seedHash']! as int
              : fnv1a32('${genome.generatorVersion}:${genome.seed}'))
          .fork(namespace);
}

final class AvatarRenderState {
  final Map<String, PixelMask> masks = <String, PixelMask>{};
  final List<RenderLayer> layers = <RenderLayer>[];
  final Map<String, Object?> metadata = <String, Object?>{};

  /// Explicit overrides used while renderers migrate to the canonical rig.
  final Map<String, String?> nodeParents = <String, String?>{};
  final Map<String, String> nodeAnchors = <String, String>{};
  final Map<String, RigTransform> nodeTransforms = <String, RigTransform>{};

  PixelMask mask(String id) => masks[id] ?? PixelMask();

  void putMask(String id, PixelMask mask) {
    masks[id] = mask;
  }

  void parentNode(String nodeId, String? parentId) {
    nodeParents[nodeId] = parentId;
  }

  void anchorNode(String nodeId, String anchorId) {
    nodeAnchors[nodeId] = anchorId;
  }

  void setNodeTransform(String nodeId, RigTransform transform) {
    nodeTransforms[nodeId] = transform;
  }

  void addLayer(
    String id,
    int z,
    PixelMask mask,
    int colorIndex, {
    Map<String, Object?> meta = const <String, Object?>{},
    String? nodeId,
    RenderSlot? slot,
    int? localOrder,
  }) {
    if (mask.count == 0) return;
    final semantics = _semanticsFor(id, meta);
    layers.add(RenderLayer(
      id: id,
      z: z,
      mask: mask,
      colorIndex: colorIndex,
      nodeId: nodeId ?? semantics.nodeId,
      slot: slot ?? semantics.slot,
      localOrder: localOrder ?? z,
      meta: meta,
    ));
  }

  Set<String> nodeAndDescendants(String nodeId) {
    final graph = buildRigGraph();
    return graph
        .descendantsOf(nodeId)
        .map((node) => node.id)
        .toSet();
  }

  void translateNode(String nodeId, {required int dx, required int dy}) {
    if (dx == 0 && dy == 0) return;
    final descendants = nodeAndDescendants(nodeId);
    final current = nodeTransforms[nodeId] ?? RigTransform.identity;
    nodeTransforms[nodeId] = current.copyWith(
      dx: current.dx + dx,
      dy: current.dy + dy,
    );
    for (var index = 0; index < layers.length; index++) {
      final layer = layers[index];
      if (!descendants.contains(layer.nodeId)) continue;
      layers[index] = layer.copyWith(mask: layer.mask.translated(dx, dy));
    }
    final maskEntries = masks.entries.toList(growable: false);
    for (final entry in maskEntries) {
      final maskNode = _maskNode(entry.key);
      if (descendants.contains(maskNode)) {
        masks[entry.key] = entry.value.translated(dx, dy);
      }
    }
  }

  RigGraph buildRigGraph() {
    final layerNodeIds = layers.map((layer) => layer.nodeId).toSet();
    final nodeIds = <String>{'scene', 'actor', ...layerNodeIds};
    var added = true;
    while (added) {
      added = false;
      for (final id in nodeIds.toList(growable: false)) {
        final parent = nodeParents.containsKey(id)
            ? nodeParents[id]
            : _defaultParent(id);
        if (parent != null && nodeIds.add(parent)) added = true;
      }
    }

    PixelRect? boundsFor(String id) {
      PixelRect? result;
      for (final layer in layers.where((layer) => layer.nodeId == id)) {
        final current = layer.mask.bounds;
        if (current == null) continue;
        result = result == null ? current : _unionBounds(result, current);
      }
      return result;
    }

    final nodes = <RigNode>[
      for (final id in nodeIds)
        RigNode(
          id: id,
          parentId: nodeParents.containsKey(id)
              ? nodeParents[id]
              : _defaultParent(id),
          slot: _nodeSlot(id, layers),
          anchorId: nodeAnchors[id],
          restTransform: nodeTransforms[id] ?? RigTransform.identity,
          bounds: boundsFor(id),
        ),
    ];
    return RigGraph(nodes: nodes);
  }

  /// Legacy selector retained until commit 18/20. New animation code must use
  /// [translateNode] and the rig hierarchy.
  void translateWhere({
    required int dx,
    required int dy,
    required bool Function(String id) includeMask,
    required bool Function(RenderLayer layer) includeLayer,
  }) {
    if (dx == 0 && dy == 0) return;
    final maskEntries = masks.entries.toList(growable: false);
    for (final entry in maskEntries) {
      if (includeMask(entry.key)) {
        masks[entry.key] = entry.value.translated(dx, dy);
      }
    }
    for (var index = 0; index < layers.length; index++) {
      final layer = layers[index];
      if (!includeLayer(layer)) continue;
      layers[index] = layer.copyWith(mask: layer.mask.translated(dx, dy));
    }
  }
}

PixelRect _unionBounds(PixelRect first, PixelRect second) {
  final left = first.left < second.left ? first.left : second.left;
  final top = first.top < second.top ? first.top : second.top;
  final right = first.right > second.right ? first.right : second.right;
  final bottom = first.bottom > second.bottom ? first.bottom : second.bottom;
  return PixelRect(left, top, right - left + 1, bottom - top + 1);
}

String _maskNode(String id) {
  if (id.startsWith('hair.back')) return 'hairBack';
  if (id.startsWith('hair.front') || id == 'hair.all') return 'hairFront';
  if (id.startsWith('head')) return 'head';
  if (id.startsWith('neck')) return 'neck';
  if (id.startsWith('torso') || id == 'skinChest') return 'torso';
  if (id.startsWith('clothing')) return 'clothing';
  if (id.startsWith('armor')) return 'armor';
  if (id.startsWith('eyes')) return 'eyes';
  if (id.startsWith('mouth')) return 'mouth';
  if (id.startsWith('ear')) return 'ears';
  if (id.startsWith('headwear')) return 'headwear';
  if (id.startsWith('eyewear')) return 'eyewear';
  if (id.startsWith('faceMask')) return 'faceMask';
  if (id.startsWith('jewelry')) return 'necklace';
  if (id.startsWith('shoulderProp')) return 'shoulderCompanion';
  return 'actor';
}

({String nodeId, RenderSlot slot}) _semanticsFor(
  String id,
  Map<String, Object?> meta,
) {
  final part = meta['part']?.toString() ?? '';
  if (id.startsWith('background') ||
      <String>{'background', 'weather', 'ambient', 'cosmic', 'flames'}
          .contains(part)) {
    return (nodeId: 'background', slot: RenderSlot.background);
  }
  if (id.startsWith('particle.') || id.startsWith('effect.front')) {
    return (nodeId: 'foreground', slot: RenderSlot.foreground);
  }
  if (id.startsWith('aura.') || id.startsWith('halo.v42.back')) {
    return (nodeId: 'aura', slot: RenderSlot.auraBack);
  }
  if (id.startsWith('cape') || id.startsWith('backAdornment')) {
    return (nodeId: 'cape', slot: RenderSlot.capeHairBack);
  }
  if (id.startsWith('hair.back')) {
    return (nodeId: 'hairBack', slot: RenderSlot.capeHairBack);
  }
  if (id.startsWith('torso.') || id.startsWith('chest.')) {
    return (nodeId: 'torso', slot: RenderSlot.torsoClothing);
  }
  if (id.startsWith('clothing.')) {
    return (nodeId: 'clothing', slot: RenderSlot.torsoClothing);
  }
  if (id.startsWith('armor.')) {
    return (nodeId: 'armor', slot: RenderSlot.armor);
  }
  if (id.startsWith('neck.')) {
    return (nodeId: 'neck', slot: RenderSlot.neck);
  }
  if (id.startsWith('head.') || id.startsWith('ears.')) {
    return (nodeId: id.startsWith('ears.') ? 'ears' : 'head', slot: RenderSlot.head);
  }
  if (id.startsWith('face.') ||
      id.startsWith('expression.') ||
      id.startsWith('motion.v42') ||
      id.startsWith('emote.v42')) {
    return (nodeId: 'face', slot: RenderSlot.face);
  }
  if (id.startsWith('facialHair.')) {
    return (nodeId: 'facialHair', slot: RenderSlot.facialHair);
  }
  if (id.startsWith('hair.front') || id.startsWith('hair.gray') ||
      id.startsWith('hair.part')) {
    return (nodeId: 'hairFront', slot: RenderSlot.hairFront);
  }
  if (id.startsWith('headwear.')) {
    return (nodeId: 'headwear', slot: RenderSlot.headwear);
  }
  if (id.startsWith('eyewear.')) {
    return (nodeId: 'eyewear', slot: RenderSlot.eyewear);
  }
  if (id.startsWith('faceMask.')) {
    return (nodeId: 'faceMask', slot: RenderSlot.faceMask);
  }
  if (id.startsWith('jewelry.') || id.startsWith('relic.')) {
    return (nodeId: 'necklace', slot: RenderSlot.frontArms);
  }
  if (id.startsWith('shoulderProp.') || id.startsWith('companion.')) {
    return (
      nodeId: 'shoulderCompanion',
      slot: RenderSlot.shoulderCompanion,
    );
  }
  if (id.startsWith('mouthProp.')) {
    return (nodeId: 'mouthProp', slot: RenderSlot.mouthProp);
  }
  if (id.startsWith('emotion') || id.startsWith('eventMotion')) {
    return (nodeId: 'actorEffects', slot: RenderSlot.emotionEffects);
  }
  if (id.startsWith('horn') || id.startsWith('fantasy.')) {
    return (nodeId: 'horns', slot: RenderSlot.hairFront);
  }
  if (id.startsWith('halo.')) {
    return (nodeId: 'halo', slot: RenderSlot.headwear);
  }
  if (id.startsWith('headAdornment') || id.startsWith('creature.')) {
    return (nodeId: 'headAdornment', slot: RenderSlot.hairFront);
  }
  return (nodeId: 'actorEffects', slot: RenderSlot.foreground);
}

String? _defaultParent(String id) => switch (id) {
      'scene' => null,
      'background' || 'foreground' => 'scene',
      'actor' => 'scene',
      'torso' => 'actor',
      'clothing' || 'armor' || 'cape' || 'necklace' => 'torso',
      'neck' => 'torso',
      'head' => 'neck',
      'ears' ||
      'face' ||
      'facialHair' ||
      'hairBack' ||
      'hairFront' ||
      'headwear' ||
      'eyewear' ||
      'faceMask' ||
      'horns' ||
      'halo' ||
      'headAdornment' =>
        'head',
      'eyes' || 'brows' || 'mouth' => 'face',
      'mouthProp' => 'mouth',
      'shoulderCompanion' => 'torso',
      'aura' || 'actorEffects' => 'actor',
      _ => 'actor',
    };

RenderSlot _nodeSlot(String id, List<RenderLayer> layers) {
  final own = layers.where((layer) => layer.nodeId == id).toList(growable: false);
  if (own.isNotEmpty) {
    own.sort((a, b) => a.slot.index.compareTo(b.slot.index));
    return own.first.slot;
  }
  return switch (id) {
    'scene' || 'background' => RenderSlot.background,
    'actor' => RenderSlot.torsoClothing,
    'torso' || 'clothing' => RenderSlot.torsoClothing,
    'armor' => RenderSlot.armor,
    'neck' => RenderSlot.neck,
    'head' || 'ears' => RenderSlot.head,
    'face' || 'eyes' || 'brows' || 'mouth' => RenderSlot.face,
    'facialHair' => RenderSlot.facialHair,
    'hairBack' || 'cape' => RenderSlot.capeHairBack,
    'hairFront' || 'horns' || 'headAdornment' => RenderSlot.hairFront,
    'headwear' || 'halo' => RenderSlot.headwear,
    'eyewear' => RenderSlot.eyewear,
    'faceMask' => RenderSlot.faceMask,
    'shoulderCompanion' => RenderSlot.shoulderCompanion,
    'mouthProp' => RenderSlot.mouthProp,
    'actorEffects' => RenderSlot.emotionEffects,
    _ => RenderSlot.foreground,
  };
}

final class RenderVisibility {
  const RenderVisibility({
    required this.visiblePixels,
    required this.sourcePixels,
  });

  final Map<String, int> visiblePixels;
  final Map<String, int> sourcePixels;

  double visibleRatio(String part) {
    final source = sourcePixels[part] ?? 0;
    if (source == 0) return 1;
    return (visiblePixels[part] ?? 0) / source;
  }

  Map<String, Object> toJson() => <String, Object>{
        'visiblePixels': visiblePixels,
        'sourcePixels': sourcePixels,
        'visibleRatios': <String, double>{
          for (final part in sourcePixels.keys) part: visibleRatio(part),
        },
      };
}

RenderVisibility analyzeRenderVisibility(List<RenderLayer> layers) {
  final sorted = List<RenderLayer>.from(layers)
    ..sort(_compareLayers);
  final width = sorted.isEmpty ? 48 : sorted.first.mask.width;
  final height = sorted.isEmpty ? 48 : sorted.first.mask.height;
  final sourceMasks = <String, PixelMask>{};
  final owners = List<String?>.filled(width * height, null);
  for (final layer in sorted) {
    final part = layer.meta['part'] is String
        ? layer.meta['part']! as String
        : layer.id.split('.').first;
    sourceMasks[part] =
        (sourceMasks[part] ?? PixelMask(width: width, height: height))
            .union(layer.mask);
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        if (layer.mask.get(x, y) != 0) owners[y * width + x] = part;
      }
    }
  }
  final visible = <String, int>{};
  for (final owner in owners) {
    if (owner != null) visible[owner] = (visible[owner] ?? 0) + 1;
  }
  return RenderVisibility(
    visiblePixels: Map.unmodifiable(visible),
    sourcePixels: Map.unmodifiable(<String, int>{
      for (final entry in sourceMasks.entries) entry.key: entry.value.count,
    }),
  );
}

abstract interface class AvatarPartRenderer {
  void render(AvatarRenderContext context, AvatarRenderState state);
}

abstract interface class AvatarCompositor {
  IndexedImage compose(List<RenderLayer> layers);
}

final class IndexedAvatarCompositor implements AvatarCompositor {
  const IndexedAvatarCompositor();

  @override
  IndexedImage compose(List<RenderLayer> layers) {
    if (layers.isEmpty) return IndexedImage();
    final sorted = List<RenderLayer>.from(layers)..sort(_compareLayers);
    final first = sorted.first.mask;
    final image = IndexedImage(width: first.width, height: first.height);
    for (final layer in sorted) {
      image.applyMask(layer.mask, layer.colorIndex);
    }
    return image;
  }
}

int _compareLayers(RenderLayer first, RenderLayer second) {
  final bySlot = first.slot.index.compareTo(second.slot.index);
  if (bySlot != 0) return bySlot;
  final byLocal = first.localOrder.compareTo(second.localOrder);
  if (byLocal != 0) return byLocal;
  return first.id.compareTo(second.id);
}
