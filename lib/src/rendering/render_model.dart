import 'dart:math' as math;

import '../constraints/validation.dart';
import '../genome/avatar_genome_model.dart';
import '../geometry/avatar_layout.dart';
import '../geometry/pixel_rect.dart';
import '../palette/avatar_palette.dart';
import '../pixels/indexed_image.dart';
import '../pixels/pixel_mask.dart';
import '../random/random_stream.dart';
import '../util/math_utils.dart';
import 'avatar_animation.dart';
import 'render_graph.dart';

final class RenderLayer {
  const RenderLayer({
    required this.id,
    required this.z,
    required this.mask,
    required this.colorIndex,
    required this.nodeId,
    required this.slot,
    this.localOrder = 0,
    this.sourcePixelCount,
    this.visiblePixelCount,
    this.meta = const <String, Object?>{},
  });

  final String id;
  final int z;
  final PixelMask mask;
  final int colorIndex;
  final String nodeId;
  final String slot;
  final int localOrder;
  final int? sourcePixelCount;
  final int? visiblePixelCount;
  final Map<String, Object?> meta;

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'z': z,
        'nodeId': nodeId,
        'slot': slot,
        'colorIndex': colorIndex,
        'pixelCount': mask.count,
        if (sourcePixelCount != null) 'sourcePixelCount': sourcePixelCount,
        if (visiblePixelCount != null) 'visiblePixelCount': visiblePixelCount,
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
  });

  final AvatarGenome genome;
  final AvatarLayout layout;
  final AvatarPalette palette;
  final ConstraintEngine guard;
  final int phase;

  AvatarAnimationState get animation => AvatarAnimationState(
        id: string('v4.animation'),
        phase: phase,
        speed: clampInt(integer('v4.animationSpeed', 3), 1, 6),
        amplitude: clampInt(integer('v4.animationAmplitude', 2), 1, 4),
        randomKey: genome.seed,
      );

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
  final Map<String, NodeTransform> nodeTransforms = <String, NodeTransform>{};
  final Map<String, String> nodeAnchors = <String, String>{};
  final Map<String, String?> nodeParents = <String, String?>{};

  PixelMask mask(String id) => masks[id] ?? PixelMask();

  void putMask(String id, PixelMask mask) {
    masks[id] = mask;
  }

  void anchorNode(String nodeId, String anchor) {
    nodeAnchors[nodeId] = anchor;
  }

  void parentNode(String nodeId, String? parentId) {
    nodeParents[nodeId] = parentId;
  }

  /// Moves every currently rendered mask onto a larger canvas.
  ///
  /// This is deliberately done before motion is applied: translating a
  /// 48x48 mask first would irreversibly discard pixels at the feed edge.
  /// Calling this again is safe and also promotes masks added by later
  /// renderers (effects and foreground).
  void embedCanvas({
    required int width,
    required int height,
    int offsetX = 0,
    int offsetY = 0,
  }) {
    for (final entry in masks.entries.toList(growable: false)) {
      if (entry.value.width == width && entry.value.height == height) continue;
      masks[entry.key] = _embedMask(
        entry.value,
        width: width,
        height: height,
        offsetX: offsetX,
        offsetY: offsetY,
      );
    }
    for (var index = 0; index < layers.length; index++) {
      final layer = layers[index];
      if (layer.mask.width == width && layer.mask.height == height) continue;
      layers[index] = layer.copyWith(
        mask: _embedMask(
          layer.mask,
          width: width,
          height: height,
          offsetX: offsetX,
          offsetY: offsetY,
        ),
      );
    }
  }

  void addLayer(
    String id,
    int z,
    PixelMask mask,
    int colorIndex, {
    Map<String, Object?> meta = const <String, Object?>{},
  }) {
    final semantics = _semanticsFor(id, meta);
    final localOrder = z;
    final derivedZ = RenderSlots.compatibilityZ(semantics.slot, localOrder);
    final pixelCount = mask.count;
    if (pixelCount == 0) {
      final skipped =
          (metadata['skippedEmptyLayers'] as List<Object?>?) ?? <Object?>[];
      skipped.add(<String, Object?>{
        'id': id,
        'z': derivedZ,
        'nodeId': semantics.nodeId,
        'slot': semantics.slot,
        'meta': meta,
      });
      metadata['skippedEmptyLayers'] = skipped;
      return;
    }
    layers.add(RenderLayer(
      id: id,
      z: derivedZ,
      mask: mask,
      colorIndex: colorIndex,
      nodeId: semantics.nodeId,
      slot: semantics.slot,
      localOrder: localOrder,
      sourcePixelCount: pixelCount,
      meta: meta,
    ));
  }

  void translateNode(String nodeId, {required int dx, required int dy}) {
    if (dx == 0 && dy == 0) return;
    final current = nodeTransforms[nodeId] ?? NodeTransform.identity;
    nodeTransforms[nodeId] = NodeTransform(
      dx: current.dx + dx,
      dy: current.dy + dy,
      rotationDegrees: current.rotationDegrees,
      pivotX: current.pivotX,
      pivotY: current.pivotY,
    );
    final graph = buildRenderGraph();
    final descendants = <String>{nodeId};
    var changed = true;
    while (changed) {
      changed = false;
      for (final node in graph.nodes) {
        if (node.parentId != null &&
            descendants.contains(node.parentId) &&
            descendants.add(node.id)) {
          changed = true;
        }
      }
    }
    for (var index = 0; index < layers.length; index++) {
      final layer = layers[index];
      if (!descendants.contains(layer.nodeId)) continue;
      layers[index] = layer.copyWith(mask: layer.mask.translated(dx, dy));
    }
  }

  /// Rotates a node and all descendants around a stable anatomical joint.
  ///
  /// The angle is reduced when necessary so the transformed subtree remains
  /// inside the overscan canvas instead of losing pixels at an edge.
  void rotateNode(
    String nodeId, {
    required int degrees,
    required int pivotX,
    required int pivotY,
  }) {
    if (degrees == 0) return;
    final descendants = _nodeAndDescendants(nodeId);
    final affected = layers
        .where((layer) => descendants.contains(layer.nodeId))
        .toList(growable: false);
    if (affected.isEmpty) return;
    var safeDegrees = degrees;
    while (safeDegrees != 0 &&
        !_rotationFits(
          affected,
          degrees: safeDegrees,
          pivotX: pivotX,
          pivotY: pivotY,
        )) {
      safeDegrees += safeDegrees.isNegative ? 1 : -1;
    }
    if (safeDegrees == 0) return;
    final current = nodeTransforms[nodeId] ?? NodeTransform.identity;
    nodeTransforms[nodeId] = NodeTransform(
      dx: current.dx,
      dy: current.dy,
      rotationDegrees: current.rotationDegrees + safeDegrees,
      pivotX: pivotX,
      pivotY: pivotY,
    );
    for (var index = 0; index < layers.length; index++) {
      final layer = layers[index];
      if (!descendants.contains(layer.nodeId)) continue;
      layers[index] = layer.copyWith(
        mask: layer.mask.rotated(
          safeDegrees,
          pivotX: pivotX,
          pivotY: pivotY,
        ),
      );
    }
  }

  Set<String> _nodeAndDescendants(String nodeId) {
    final graph = buildRenderGraph();
    final descendants = <String>{nodeId};
    var changed = true;
    while (changed) {
      changed = false;
      for (final node in graph.nodes) {
        if (node.parentId != null &&
            descendants.contains(node.parentId) &&
            descendants.add(node.id)) {
          changed = true;
        }
      }
    }
    return descendants;
  }

  bool _rotationFits(
    List<RenderLayer> affected, {
    required int degrees,
    required int pivotX,
    required int pivotY,
  }) {
    final radians = degrees * 3.141592653589793 / 180;
    final cosine = math.cos(radians);
    final sine = math.sin(radians);
    for (final layer in affected) {
      final bounds = layer.mask.bounds;
      if (bounds == null) continue;
      for (final point in <(int, int)>[
        (bounds.left, bounds.top),
        (bounds.right, bounds.top),
        (bounds.left, bounds.bottom),
        (bounds.right, bounds.bottom),
      ]) {
        final dx = point.$1 - pivotX;
        final dy = point.$2 - pivotY;
        final x = (pivotX + cosine * dx - sine * dy).round();
        final y = (pivotY + sine * dx + cosine * dy).round();
        if (x < 0 || x >= layer.mask.width || y < 0 || y >= layer.mask.height) {
          return false;
        }
      }
    }
    return true;
  }

  RenderGraph buildRenderGraph({
    int viewportY = 3,
    double fitScale = 1,
    int baseline = 47,
  }) {
    final nodeIds = layers.map((layer) => layer.nodeId).toSet()
      ..addAll(const <String>{'actor', 'torso', 'neck', 'head'});
    var addedAncestor = true;
    while (addedAncestor) {
      addedAncestor = false;
      for (final id in nodeIds.toList(growable: false)) {
        final parentId = nodeParents.containsKey(id)
            ? nodeParents[id]
            : _nodeSpec(id).parentId;
        if (parentId != null && nodeIds.add(parentId)) {
          addedAncestor = true;
        }
      }
    }
    final nodes = <RenderNode>[];
    for (final id in nodeIds) {
      final spec = _nodeSpec(id);
      final nodeLayers = layers.where((layer) => layer.nodeId == id);
      PixelRect? bounds;
      for (final layer in nodeLayers) {
        final current = layer.mask.bounds;
        if (current == null) continue;
        bounds = bounds == null ? current : _unionBounds(bounds, current);
      }
      nodes.add(RenderNode(
        id: id,
        parentId: nodeParents.containsKey(id) ? nodeParents[id] : spec.parentId,
        slot: spec.slot,
        anchor: nodeAnchors[id] ?? spec.anchor,
        localTransform: nodeTransforms[id] ?? NodeTransform.identity,
        bounds: bounds,
        tags: spec.tags,
      ));
    }
    nodes.sort((a, b) {
      final slot =
          RenderSlots.indexOf(a.slot).compareTo(RenderSlots.indexOf(b.slot));
      return slot != 0 ? slot : a.id.compareTo(b.id);
    });
    return RenderGraph(
      nodes: nodes,
      viewportY: viewportY,
      fitScale: fitScale,
      baseline: baseline,
    );
  }

  /// Applies a deterministic spatial transform to selected masks and layers.
  ///
  /// This is intentionally implemented at render-state level so animation
  /// channels can move a composed avatar without mutating its genome or layout.
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
      layers[index] = RenderLayer(
        id: layer.id,
        z: layer.z,
        mask: layer.mask.translated(dx, dy),
        colorIndex: layer.colorIndex,
        nodeId: layer.nodeId,
        slot: layer.slot,
        localOrder: layer.localOrder,
        sourcePixelCount: layer.sourcePixelCount,
        visiblePixelCount: layer.visiblePixelCount,
        meta: layer.meta,
      );
    }
  }
}

PixelRect _unionBounds(PixelRect a, PixelRect b) {
  final left = a.left < b.left ? a.left : b.left;
  final top = a.top < b.top ? a.top : b.top;
  final right = a.right > b.right ? a.right : b.right;
  final bottom = a.bottom > b.bottom ? a.bottom : b.bottom;
  return PixelRect(left, top, right - left + 1, bottom - top + 1);
}

PixelMask _embedMask(
  PixelMask source, {
  required int width,
  required int height,
  required int offsetX,
  required int offsetY,
}) {
  final output = PixelMask(width: width, height: height);
  for (var y = 0; y < source.height; y++) {
    for (var x = 0; x < source.width; x++) {
      if (source.get(x, y) != 0) {
        output.set(x + offsetX, y + offsetY);
      }
    }
  }
  return output;
}

({String nodeId, String slot}) _semanticsFor(
    String id, Map<String, Object?> meta) {
  final part = meta['part']?.toString() ?? '';
  if (id.startsWith('background')) {
    return (nodeId: 'background', slot: 'background');
  }
  if (id.startsWith('aura.')) return (nodeId: 'aura', slot: 'aura-back');
  if (id.contains('cape') || id.startsWith('hair.back')) {
    return (
      nodeId: id.contains('cape') ? 'cape' : 'hairBack',
      slot: 'cape/hair-back'
    );
  }
  if (id.startsWith('armor.')) return (nodeId: 'armor', slot: 'armor');
  if (id.startsWith('leftArm.')) {
    return (nodeId: 'leftArm', slot: 'front-arms/hands');
  }
  if (id.startsWith('rightArm.')) {
    return (nodeId: 'rightArm', slot: 'front-arms/hands');
  }
  if (id.startsWith('leftHand.')) {
    return (nodeId: 'leftHand', slot: 'front-arms/hands');
  }
  if (id.startsWith('rightHand.')) {
    return (nodeId: 'rightHand', slot: 'front-arms/hands');
  }
  if (id.startsWith('clothing.')) {
    return (nodeId: 'clothing', slot: 'torso/clothing');
  }
  if (id.startsWith('neck.')) return (nodeId: 'neck', slot: 'neck');
  if (id.startsWith('head.') || id.startsWith('ears.')) {
    return (nodeId: 'head', slot: 'head');
  }
  if (id.startsWith('hair.')) return (nodeId: 'hairFront', slot: 'hair-front');
  if (id.startsWith('headwear.')) return (nodeId: 'headwear', slot: 'headwear');
  if (id.startsWith('eyewear.')) return (nodeId: 'eyewear', slot: 'eyewear');
  if (id.startsWith('faceMask.'))
    return (nodeId: 'faceMask', slot: 'face-mask');
  if (id.startsWith('morphology.')) {
    if (id == 'morphology.ribs') {
      return (nodeId: 'torso', slot: 'torso/clothing');
    }
    return (nodeId: 'head', slot: 'face');
  }
  if (id.startsWith('jewelry.head.')) {
    return (nodeId: 'head', slot: 'face');
  }
  if (id.startsWith('jewelry.neck.')) {
    return (nodeId: 'neck', slot: 'neck');
  }
  final shoulderPropKind = meta['shoulderPropKind']?.toString();
  const companionKinds = <String>{
    'cat',
    'parrot',
    'smallDragon',
    'ghost',
    'insect',
    'shoulderRobot',
  };
  if (id.startsWith('shoulderProp.') &&
      !companionKinds.contains(shoulderPropKind)) {
    return (nodeId: 'shoulderObject', slot: 'shoulder-companion');
  }
  if (id == 'shoulderProp.outline') {
    return (nodeId: 'companionBody', slot: 'shoulder-companion');
  }
  if (id == 'shoulderProp.headOutline') {
    return (nodeId: 'companionHead', slot: 'shoulder-companion');
  }
  if (id == 'shoulderProp.wingsOutline') {
    return (nodeId: 'companionWings', slot: 'shoulder-companion');
  }
  if (id == 'shoulderProp.tailOutline') {
    return (nodeId: 'companionTail', slot: 'shoulder-companion');
  }
  if (id == 'shoulderProp.ears' || id == 'shoulderProp.earsOutline') {
    return (nodeId: 'companionEars', slot: 'shoulder-companion');
  }
  if (id == 'shoulderProp.beak' || id == 'shoulderProp.beakOutline') {
    return (nodeId: 'companionBeak', slot: 'shoulder-companion');
  }
  if (id == 'shoulderProp.eyes') {
    return (nodeId: 'companionEyes', slot: 'shoulder-companion');
  }
  if (id == 'shoulderProp.base') {
    return (nodeId: 'companionBody', slot: 'shoulder-companion');
  }
  if (id == 'shoulderProp.head') {
    return (nodeId: 'companionHead', slot: 'shoulder-companion');
  }
  if (id == 'shoulderProp.wings') {
    return (nodeId: 'companionWings', slot: 'shoulder-companion');
  }
  if (id == 'shoulderProp.tail') {
    return (nodeId: 'companionTail', slot: 'shoulder-companion');
  }
  if (id == 'shoulderProp.light') {
    return (nodeId: 'companionHeadDetails', slot: 'shoulder-companion');
  }
  if (id == 'shoulderProp.shadow') {
    return (nodeId: 'companionDetails', slot: 'shoulder-companion');
  }
  if (id.startsWith('shoulderProp.')) {
    return (nodeId: 'shoulderCompanion', slot: 'shoulder-companion');
  }
  if (id.startsWith('mouthProp.'))
    return (nodeId: 'mouthProp', slot: 'mouth-prop');
  if (id.startsWith('effect.'))
    return (nodeId: 'emotionEffects', slot: 'emotion-effects');
  if (id.startsWith('foreground'))
    return (nodeId: 'foreground', slot: 'foreground');
  if (id.startsWith('brows')) return (nodeId: 'brows', slot: 'face');
  if (id.startsWith('eyes.') ||
      id.startsWith('iris.') ||
      id.startsWith('pupil.')) {
    return (nodeId: 'eyes', slot: 'face');
  }
  if (id.startsWith('mouth.')) return (nodeId: 'mouth', slot: 'face');
  if (id.startsWith('face.') ||
      id.startsWith('nose.') ||
      id.startsWith('cheeks.') ||
      id.startsWith('skin.details') ||
      id.startsWith('cyber.')) {
    return (nodeId: 'face', slot: 'face');
  }
  if (part.toLowerCase().contains('beard') || id.contains('facialHair')) {
    return (nodeId: 'facialHair', slot: 'facial-hair');
  }
  return (nodeId: 'torso', slot: 'torso/clothing');
}

({String? parentId, String slot, String anchor, Set<String> tags}) _nodeSpec(
    String id) {
  return switch (id) {
    'background' => (
        parentId: null,
        slot: 'background',
        anchor: 'canvas',
        tags: <String>{}
      ),
    'aura' => (
        parentId: null,
        slot: 'aura-back',
        anchor: 'canvas',
        tags: <String>{}
      ),
    'actor' => (
        parentId: null,
        slot: 'torso/clothing',
        anchor: 'baseline',
        tags: <String>{}
      ),
    'torso' => (
        parentId: 'actor',
        slot: 'torso/clothing',
        anchor: 'baseline',
        tags: <String>{}
      ),
    'clothing' => (
        parentId: 'torso',
        slot: 'torso/clothing',
        anchor: 'torso-surface',
        tags: <String>{}
      ),
    'neck' => (
        parentId: 'torso',
        slot: 'neck',
        anchor: 'neck-base',
        tags: <String>{}
      ),
    'head' => (
        parentId: 'neck',
        slot: 'head',
        anchor: 'neck-top',
        tags: <String>{}
      ),
    'cape' => (
        parentId: 'torso',
        slot: 'cape/hair-back',
        anchor: 'shoulders',
        tags: <String>{'may-paint-behind-parent'}
      ),
    'hairBack' => (
        parentId: 'head',
        slot: 'cape/hair-back',
        anchor: 'head',
        tags: <String>{'may-paint-behind-parent'}
      ),
    'armor' => (
        parentId: 'torso',
        slot: 'armor',
        anchor: 'torso',
        tags: <String>{}
      ),
    'leftArm' => (
        parentId: 'torso',
        slot: 'front-arms/hands',
        anchor: 'left-shoulder',
        tags: <String>{}
      ),
    'rightArm' => (
        parentId: 'torso',
        slot: 'front-arms/hands',
        anchor: 'right-shoulder',
        tags: <String>{}
      ),
    'leftHand' => (
        parentId: 'leftArm',
        slot: 'front-arms/hands',
        anchor: 'left-wrist',
        tags: <String>{}
      ),
    'rightHand' => (
        parentId: 'rightArm',
        slot: 'front-arms/hands',
        anchor: 'right-wrist',
        tags: <String>{}
      ),
    'eyes' || 'brows' || 'mouth' || 'face' => (
        parentId: 'head',
        slot: 'face',
        anchor: 'head',
        tags: <String>{}
      ),
    'facialHair' => (
        parentId: 'head',
        slot: 'facial-hair',
        anchor: 'face',
        tags: <String>{}
      ),
    'hairFront' => (
        parentId: 'head',
        slot: 'hair-front',
        anchor: 'head',
        tags: <String>{}
      ),
    'headwear' => (
        parentId: 'head',
        slot: 'headwear',
        anchor: 'head-top',
        tags: <String>{}
      ),
    'eyewear' => (
        parentId: 'head',
        slot: 'eyewear',
        anchor: 'eyes',
        tags: <String>{}
      ),
    'faceMask' => (
        parentId: 'head',
        slot: 'face-mask',
        anchor: 'face',
        tags: <String>{}
      ),
    'shoulderCompanion' => (
        parentId: 'torso',
        slot: 'shoulder-companion',
        anchor: 'shoulder',
        tags: <String>{}
      ),
    'shoulderObject' => (
        parentId: 'rightArm',
        slot: 'shoulder-companion',
        anchor: 'right-hand',
        tags: <String>{}
      ),
    'companionBody' => (
        parentId: 'shoulderCompanion',
        slot: 'shoulder-companion',
        anchor: 'shoulder',
        tags: <String>{}
      ),
    'companionHead' => (
        parentId: 'companionBody',
        slot: 'shoulder-companion',
        anchor: 'companion-neck',
        tags: <String>{}
      ),
    'companionWings' => (
        parentId: 'companionBody',
        slot: 'shoulder-companion',
        anchor: 'companion-back',
        tags: <String>{}
      ),
    'companionTail' => (
        parentId: 'companionBody',
        slot: 'shoulder-companion',
        anchor: 'companion-back',
        tags: <String>{}
      ),
    'companionDetails' => (
        parentId: 'companionBody',
        slot: 'shoulder-companion',
        anchor: 'companion-surface',
        tags: <String>{}
      ),
    'companionHeadDetails' => (
        parentId: 'companionHead',
        slot: 'shoulder-companion',
        anchor: 'companion-face',
        tags: <String>{}
      ),
    'companionEars' => (
        parentId: 'companionHead',
        slot: 'shoulder-companion',
        anchor: 'companion-head-top',
        tags: <String>{}
      ),
    'companionBeak' => (
        parentId: 'companionHead',
        slot: 'shoulder-companion',
        anchor: 'companion-mouth',
        tags: <String>{}
      ),
    'companionEyes' => (
        parentId: 'companionHead',
        slot: 'shoulder-companion',
        anchor: 'companion-face',
        tags: <String>{}
      ),
    'mouthProp' => (
        parentId: 'head',
        slot: 'mouth-prop',
        anchor: 'mouth',
        tags: <String>{}
      ),
    'emotionEffects' => (
        parentId: null,
        slot: 'emotion-effects',
        anchor: 'canvas',
        tags: <String>{}
      ),
    'foreground' => (
        parentId: null,
        slot: 'foreground',
        anchor: 'canvas',
        tags: <String>{}
      ),
    _ => (
        parentId: 'actor',
        slot: 'torso/clothing',
        anchor: 'actor',
        tags: <String>{}
      ),
  };
}

extension on RenderLayer {
  RenderLayer copyWith({PixelMask? mask, int? visiblePixelCount}) =>
      RenderLayer(
        id: id,
        z: z,
        mask: mask ?? this.mask,
        colorIndex: colorIndex,
        nodeId: nodeId,
        slot: slot,
        localOrder: localOrder,
        sourcePixelCount: sourcePixelCount,
        visiblePixelCount: visiblePixelCount ?? this.visiblePixelCount,
        meta: meta,
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
    final sorted = List<RenderLayer>.from(layers)
      ..sort((a, b) {
        final bySlot =
            RenderSlots.indexOf(a.slot).compareTo(RenderSlots.indexOf(b.slot));
        if (bySlot != 0) return bySlot;
        final local = a.localOrder.compareTo(b.localOrder);
        return local != 0 ? local : a.id.compareTo(b.id);
      });
    final image = sorted.isEmpty
        ? IndexedImage()
        : IndexedImage(
            width: sorted.first.mask.width,
            height: sorted.first.mask.height,
          );
    for (final layer in sorted) {
      image.applyMask(layer.mask, layer.colorIndex);
    }
    final covered = PixelMask(width: image.width, height: image.height);
    final visibleCounts = <RenderLayer, int>{};
    for (var index = sorted.length - 1; index >= 0; index--) {
      final layer = sorted[index];
      var visible = 0;
      for (var i = 0; i < image.indices.length; i++) {
        if (layer.mask.data[i] != 0 && covered.data[i] == 0) {
          visible++;
          covered.data[i] = 1;
        }
      }
      visibleCounts[layer] = visible;
    }
    for (var i = 0; i < layers.length; i++) {
      final layer = layers[i];
      layers[i] = RenderLayer(
        id: layer.id,
        z: layer.z,
        mask: layer.mask,
        colorIndex: layer.colorIndex,
        nodeId: layer.nodeId,
        slot: layer.slot,
        localOrder: layer.localOrder,
        sourcePixelCount: layer.sourcePixelCount ?? layer.mask.count,
        visiblePixelCount: visibleCounts[layer] ?? 0,
        meta: layer.meta,
      );
    }
    return image;
  }
}
