import '../api/avatar_request.dart';
import '../constraints/avatar_validator.dart';
import '../constraints/validation.dart';
import '../genome/avatar_genome_model.dart';
import '../genome/genome_generator.dart';
import '../geometry/avatar_layout.dart';
import '../palette/avatar_palette.dart';
import '../pixels/indexed_image.dart';
import '../pixels/pixel_mask.dart';
import '../util/math_utils.dart';
import 'animation_controller.dart';
import 'canonical_rig.dart';
import 'clip_camera.dart';
import 'clip_camera_cache.dart';
import 'expressive_motion_policy.dart';
import 'parts/accessories_renderer.dart';
import 'parts/anatomy_renderer.dart';
import 'parts/armor_renderer.dart';
import 'parts/articulated_arm_renderer.dart';
import 'parts/atmosphere/extended_atmosphere_renderer.dart';
import 'parts/background_renderer.dart';
import 'parts/constrained_jewelry_renderer.dart';
import 'parts/face_renderer.dart';
import 'parts/flexible_back_rig_renderer.dart';
import 'parts/gated_companion_renderer.dart';
import 'parts/hair_renderer.dart';
import 'parts/natural_particle_renderer.dart';
import 'parts/procedural_mask_renderer.dart';
import 'parts/procedural_surface_renderer.dart';
import 'parts/props_renderer.dart';
import 'parts/rain_field_renderer.dart';
import 'parts/rig_seam_bridge_renderer.dart';
import 'parts/segmented_hair_rig_renderer.dart';
import 'parts/v42_aura_renderer.dart';
import 'parts/v42_detail_renderer.dart';
import 'parts/v42_emote_event_renderer.dart';
import 'parts/v42_features_renderer.dart';
import 'parts/v42_motion_renderer.dart';
import 'parts/v42_scenic_light_renderer.dart';
import 'parts/world_smoke_emitter_renderer.dart';
import 'render_model.dart';
import 'rig_layer_binding.dart';
import 'rig_model.dart';
import 'rig_pose_applier.dart';
import 'rig_quality_evaluator.dart';
import 'rig_validation_entries.dart';
import 'runtime_rig_builder.dart';
import 'scene_visual_budget_renderer.dart';
import 'semantic_gesture_policy.dart';
import 'visual_correction_pipeline.dart';
import 'wearable_attachment_policy.dart';

final class RigPreparedAvatar {
  const RigPreparedAvatar({
    required this.genome,
    required this.layout,
    required this.palette,
    required this.baseValidation,
    required this.guardEnabled,
  });

  final AvatarGenome genome;
  final AvatarLayout layout;
  final AvatarPalette palette;
  final List<ValidationEntry> baseValidation;
  final bool guardEnabled;
}

final class RigPipelineFrame {
  const RigPipelineFrame({
    required this.phase,
    required this.state,
    required this.image,
    required this.validation,
    required this.camera,
  });

  final int phase;
  final AvatarRenderState state;
  final IndexedImage image;
  final ValidationReport validation;
  final ClipCamera camera;
}

final class RigPipelineClip {
  const RigPipelineClip({
    required this.prepared,
    required this.frames,
    required this.camera,
  });

  final RigPreparedAvatar prepared;
  final List<RigPipelineFrame> frames;
  final ClipCamera camera;
}

final class RigClipPipeline {
  RigClipPipeline({
    required this.genomeGenerator,
    required this.layoutResolver,
    required this.paletteFactory,
    required this.compositor,
    required this.validator,
    List<AvatarPartRenderer>? parts,
    ClipCameraCache? cameraCache,
    this.canvas = const OverscanCanvas(),
  })  : parts = List.unmodifiable(parts ?? defaultParts),
        cameraCache = cameraCache ?? ClipCameraCache();

  final GenomeGenerator genomeGenerator;
  final LayoutResolver layoutResolver;
  final PaletteFactory paletteFactory;
  final AvatarCompositor compositor;
  final AvatarValidator validator;
  final List<AvatarPartRenderer> parts;
  final ClipCameraCache cameraCache;

  /// Minimum canvas. Wide content automatically upgrades to 96 or 104 pixels.
  final OverscanCanvas canvas;

  static List<AvatarPartRenderer> get defaultParts =>
      const <AvatarPartRenderer>[
        BackgroundRenderer(),
        SplitExtendedAtmosphereRenderer(),
        ExtendedScenicLightRenderer(),
        ExtendedAuraRenderer(),
        AnatomyRenderer(),
        ArmorRenderer(),
        FaceRenderer(),
        ExpressionRenderer(),
        ExpressiveMotionOverlayRenderer(),
        ExtendedEmoteEventRenderer(),
        HairRenderer(),
        ExtendedAdornmentRenderer(),
        ExtendedDetailRenderer(),
        AccessoriesRenderer(),
        ProceduralFaceMaskRenderer(),
        PropsRenderer(),
        ProceduralSurfaceVariationRenderer(),
        ArticulatedArmRenderer(),
        SegmentedHairRigRenderer(),
        ConstrainedJewelryRenderer(),
        GatedCompanionRenderer(),
        FlexibleBackRigRenderer(),
        RigSeamBridgeRenderer(),
        ForegroundEffectsRenderer(),
        NaturalParticleFieldRenderer(),
        VisualCorrectionPipeline(),
      ];

  RigPreparedAvatar prepare(AvatarRequest request) {
    final guard = ConstraintEngine(enabled: request.guardEnabled);
    final genome = genomeGenerator.generate(request, guard);
    final layout = layoutResolver.resolve(genome, guard);
    return RigPreparedAvatar(
      genome: genome,
      layout: layout,
      palette: paletteFactory.create(genome),
      baseValidation: guard.entries,
      guardEnabled: request.guardEnabled,
    );
  }

  RigPipelineClip renderClip(
    AvatarRequest request, {
    required int frameCount,
  }) {
    if (frameCount < 1) {
      throw ArgumentError.value(frameCount, 'frameCount', 'Must be positive.');
    }
    final prepared = prepare(request);
    final workingCanvas = _canvasFor(prepared.genome);
    final phases = List<int>.generate(frameCount, (index) => index);
    final raw = <_RawRigFrame>[
      for (final phase in phases)
        _renderRaw(prepared, request.rendering, phase, workingCanvas),
    ];
    final camera = ClipCameraFitter.fitFrames(
      raw.map((frame) => ClipCameraFitter.frameBounds(frame.state.layers)),
      canvasWidth: workingCanvas.width,
      canvasHeight: workingCanvas.height,
      baseline: workingCanvas.offsetY + 47,
    );
    final key = cameraCache.key(
      genome: prepared.genome,
      rendering: request.rendering,
      sampleCount: phases.length,
      phases: phases,
    );
    cameraCache.put(key, camera);
    for (final frame in raw) {
      frame.state.metadata['cameraCache'] = <String, Object>{
        'hit': false,
        'sampleCount': phases.length,
        'samplePhases': phases,
        'entries': cameraCache.length,
      };
    }
    return RigPipelineClip(
      prepared: prepared,
      camera: camera,
      frames: List.unmodifiable(<RigPipelineFrame>[
        for (final frame in raw)
          _cropAndValidate(prepared, frame, camera, workingCanvas),
      ]),
    );
  }

  RigPipelineClip renderSingle(AvatarRequest request) {
    final samplePhases = request.rendering.reducedMotion
        ? <int>[request.phase]
        : (<int>{
            for (var phase = 0; phase < 16; phase++) phase,
            request.phase,
          }.toList()
          ..sort());
    final prepared = prepare(request);
    final workingCanvas = _canvasFor(prepared.genome);
    final key = cameraCache.key(
      genome: prepared.genome,
      rendering: request.rendering,
      sampleCount: samplePhases.length,
      phases: samplePhases,
    );
    final cached = cameraCache.get(key);
    late final ClipCamera camera;
    late final _RawRigFrame selected;

    if (cached != null) {
      camera = cached;
      selected = _renderRaw(
        prepared,
        request.rendering,
        request.phase,
        workingCanvas,
      );
      selected.state.metadata['cameraCache'] = <String, Object>{
        'hit': true,
        'sampleCount': samplePhases.length,
        'samplePhases': samplePhases,
        'entries': cameraCache.length,
      };
    } else {
      final raw = <_RawRigFrame>[
        for (final phase in samplePhases)
          _renderRaw(prepared, request.rendering, phase, workingCanvas),
      ];
      camera = ClipCameraFitter.fitFrames(
        raw.map((frame) => ClipCameraFitter.frameBounds(frame.state.layers)),
        canvasWidth: workingCanvas.width,
        canvasHeight: workingCanvas.height,
        baseline: workingCanvas.offsetY + 47,
      );
      cameraCache.put(key, camera);
      selected = raw[samplePhases.indexOf(request.phase)];
      selected.state.metadata['cameraCache'] = <String, Object>{
        'hit': false,
        'sampleCount': samplePhases.length,
        'samplePhases': samplePhases,
        'entries': cameraCache.length,
      };
    }

    return RigPipelineClip(
      prepared: prepared,
      camera: camera,
      frames: <RigPipelineFrame>[
        _cropAndValidate(prepared, selected, camera, workingCanvas),
      ],
    );
  }

  _RawRigFrame _renderRaw(
    RigPreparedAvatar prepared,
    AvatarRenderSettings rendering,
    int phase,
    OverscanCanvas workingCanvas,
  ) {
    final guard = ConstraintEngine(enabled: prepared.guardEnabled);
    final context = AvatarRenderContext(
      genome: prepared.genome,
      layout: prepared.layout,
      palette: prepared.palette,
      guard: guard,
      phase: phase,
      rendering: rendering,
    );
    final state = AvatarRenderState();
    for (final part in parts) part.render(context, state);
    _bindRig(context, state, workingCanvas);
    final image = compositor.compose(state.layers);
    return _RawRigFrame(
      phase: phase,
      state: state,
      image: image,
      guard: guard,
    );
  }

  void _bindRig(
    AvatarRenderContext context,
    AvatarRenderState state,
    OverscanCanvas workingCanvas,
  ) {
    for (var index = 0; index < state.layers.length; index++) {
      final layer = state.layers[index];
      final binding = RigLayerBinding.resolve(
        layer.id,
        layer.localOrder,
        layer.meta,
        existingNodeId: layer.nodeId,
      );
      state.layers[index] = layer.copyWith(
        nodeId: binding.nodeId,
        slot: binding.slot,
        localOrder: binding.localOrder,
      );
    }

    for (final entry in CanonicalRig.parents.entries) {
      if (!state.nodeParents.containsKey(entry.key)) {
        state.parentNode(entry.key, entry.value);
      }
    }
    const WearableAttachmentPolicy().apply(context, state);

    final controller = const RigAnimationController();
    final expressive = const ExpressiveMotionPolicy().augment(
      context,
      controller.sample(context),
    );
    final sample = const SemanticGesturePolicy().augment(context, expressive);
    _applyGestureDepth(state, sample.events);

    final sceneSources = <String, ({PixelMask mask, RenderSlot slot})>{
      for (final layer in state.layers)
        if (_isRearSceneSlot(layer.slot))
          layer.id: (mask: layer.mask, slot: layer.slot),
    };

    final graph = const RuntimeRigBuilder().build(
      context.layout,
      state,
      offsetX: workingCanvas.offsetX,
      offsetY: workingCanvas.offsetY,
    );

    workingCanvas.embedState(state);
    for (var index = 0; index < state.layers.length; index++) {
      final layer = state.layers[index];
      final source = sceneSources[layer.id];
      if (source != null) {
        state.layers[index] = layer.copyWith(
          mask: _embedSceneMask(source.mask, source.slot, workingCanvas),
        );
      }
    }

    final solvedPose = const RigPoseApplier().solveAndApply(
      state,
      graph,
      RigPose(sample.transforms),
    );
    _rebuildSemanticMasks(state);
    final constraintQuality =
        const RigQualityEvaluator().evaluate(graph, solvedPose);

    const WorldSmokeEmitterRenderer().render(context, state);
    const RainFieldRenderer().render(context, state);
    _protectFaceClarity(state);
    const SceneVisualBudgetRenderer().render(context, state);
    _capFinalSceneEffects(state);
    _rebuildSemanticMasks(state);
    _recordPreCameraClipping(state, workingCanvas);

    state.metadata
      ..['motionSample'] = <String, Object>{
        ...sample.toJson(),
        'solvedTransforms': solvedPose.toJson(),
      }
      ..['rigAnchors'] = <String, Object>{
        for (final anchor in graph.anchors) anchor.id: anchor.toJson(),
      }
      ..['rigConstraints'] = graph.constraints
          .map((constraint) => constraint.toJson())
          .toList(growable: false)
      ..['rigConstraintQuality'] = constraintQuality.toJson()
      ..['rigGraph'] = graph.toJson()
      ..['motionEnvelope'] = <String, Object>{
        'canvasWidth': workingCanvas.width,
        'canvasHeight': workingCanvas.height,
        'offsetX': workingCanvas.offsetX,
        'offsetY': workingCanvas.offsetY,
        'dynamic': workingCanvas.width != canvas.width ||
            workingCanvas.height != canvas.height,
      };
  }

  OverscanCanvas _canvasFor(AvatarGenome genome) {
    String value(String id) => genome.values[id]?.toString() ?? 'none';
    final animation = value('v4.faceAnimation') != 'none'
        ? value('v4.faceAnimation')
        : value('v4.animation');
    final expressive = <String>{
          'laugh',
          'angry',
          'surprised',
          'sad',
          'bashful',
          'talk',
        }.contains(animation) ||
        <String>{'proudPose', 'shyLookAway'}.contains(value('v4.poseMotion'));
    final wide = value('v4.cape') != 'none' ||
        value('v4.backAdornment') != 'none' ||
        value('v4.shoulderProp') != 'none' ||
        value('v4.extraShoulderProp') != 'none' ||
        value('v4.horns') != 'none' ||
        value('v4.halo') != 'none';
    final size = expressive && wide
        ? 104
        : expressive || wide
            ? 96
            : canvas.width < 72
                ? 72
                : canvas.width;
    final offset = (size - 48) ~/ 2;
    return OverscanCanvas(
      width: size,
      height: size,
      sourceWidth: 48,
      sourceHeight: 48,
      offsetX: offset,
      offsetY: offset,
    );
  }

  void _applyGestureDepth(AvatarRenderState state, Set<String> events) {
    final bothFront = events.any(<String>{
      'gestureCoverMouth',
      'gestureBellyLaugh',
      'gestureBoxerGuard',
      'gestureFistsDown',
      'gestureHandsToFace',
      'gestureHandsOnHips',
      'gestureSelfHug',
      'gestureHandToCheek',
    }.contains);
    final rightFront = bothFront || events.contains('gesturePoint');
    final leftFront = bothFront;

    for (var index = 0; index < state.layers.length; index++) {
      final layer = state.layers[index];
      final left = <String>{'leftArm', 'leftForearm', 'leftWrist', 'leftHand'}
          .contains(layer.nodeId);
      final right = <String>{
        'rightArm',
        'rightForearm',
        'rightWrist',
        'rightHand',
      }.contains(layer.nodeId);
      if (!left && !right) continue;
      final front = left ? leftFront : rightFront;
      state.layers[index] = layer.copyWith(
        slot: front ? RenderSlot.frontArms : RenderSlot.rearArms,
        localOrder: (front ? 400 : 200) + layer.localOrder.abs() % 80,
        meta: <String, Object?>{
          ...layer.meta,
          'depthPolicy': front ? 'gestureFront' : 'restRear',
        },
      );
    }
  }

  bool _isRearSceneSlot(RenderSlot slot) => <RenderSlot>{
        RenderSlot.background,
        RenderSlot.backgroundDetail,
        RenderSlot.atmosphereBack,
      }.contains(slot);

  PixelMask _embedSceneMask(
    PixelMask source,
    RenderSlot slot,
    OverscanCanvas workingCanvas,
  ) {
    final output = PixelMask(
      width: workingCanvas.width,
      height: workingCanvas.height,
    );
    for (var y = 0; y < workingCanvas.height; y++) {
      for (var x = 0; x < workingCanvas.width; x++) {
        final sourceX = x - workingCanvas.offsetX;
        final sourceY = y - workingCanvas.offsetY;
        final sx = slot == RenderSlot.background
            ? sourceX.clamp(0, source.width - 1).toInt()
            : positiveMod(sourceX, source.width);
        final sy = slot == RenderSlot.background
            ? sourceY.clamp(0, source.height - 1).toInt()
            : positiveMod(sourceY, source.height);
        if (source.get(sx, sy) != 0) output.set(x, y);
      }
    }
    return output;
  }

  void _protectFaceClarity(AvatarRenderState state) {
    final face = _unionLayers(
      state.layers.where((layer) => <String>{
            'head',
            'face',
            'eyes',
            'brows',
            'mouth',
          }.contains(layer.nodeId)),
    );
    final bounds = face.bounds;
    if (bounds == null) return;
    final clearance = face.dilated().dilated();
    var removedPixels = 0;
    var affectedLayers = 0;
    for (var index = 0; index < state.layers.length; index++) {
      final layer = state.layers[index];
      if (!<RenderSlot>{
        RenderSlot.backgroundDetail,
        RenderSlot.atmosphereBack,
        RenderSlot.foreground,
        RenderSlot.emotionEffects,
      }.contains(layer.slot)) {
        continue;
      }
      final overlap = layer.mask.intersect(clearance);
      if (overlap.count == 0) continue;
      removedPixels += overlap.count;
      affectedLayers++;
      state.layers[index] =
          layer.copyWith(mask: layer.mask.subtract(clearance));
    }
    state.metadata['backgroundClarity'] = <String, Object>{
      'faceClearancePixels': clearance.count,
      'removedBackgroundPixels': removedPixels,
      'affectedLayerCount': affectedLayers,
      'protectedBounds': bounds.toJson(),
    };
  }

  void _capFinalSceneEffects(AvatarRenderState state) {
    bool isEffect(RenderLayer layer) =>
        <RenderSlot>{
          RenderSlot.auraBack,
          RenderSlot.emotionEffects,
          RenderSlot.foreground,
        }.contains(layer.slot) ||
        layer.nodeId == 'atmosphere' ||
        layer.nodeId == 'foreground';

    final effects = state.layers.where(isEffect).toList(growable: false);
    if (effects.isEmpty) return;
    final first = effects.first;
    final limit = (first.mask.width * first.mask.height * .12).floor();
    var kept = 0;
    var removed = 0;
    for (var index = 0; index < state.layers.length; index++) {
      final layer = state.layers[index];
      if (!isEffect(layer)) continue;
      final available = limit - kept;
      if (available <= 0) {
        removed += layer.mask.count;
        state.layers[index] = layer.copyWith(
          mask: PixelMask(width: layer.mask.width, height: layer.mask.height),
        );
        continue;
      }
      if (layer.mask.count <= available) {
        kept += layer.mask.count;
        continue;
      }
      final trimmed = PixelMask(
        width: layer.mask.width,
        height: layer.mask.height,
      );
      var remaining = available;
      for (var y = 0; y < layer.mask.height && remaining > 0; y++) {
        for (var x = 0; x < layer.mask.width && remaining > 0; x++) {
          if (layer.mask.get(x, y) == 0) continue;
          trimmed.set(x, y);
          remaining--;
        }
      }
      kept += trimmed.count;
      removed += layer.mask.count - trimmed.count;
      state.layers[index] = layer.copyWith(mask: trimmed);
    }
    state.metadata['finalSceneEffectBudget'] = <String, Object>{
      'pixelLimit': limit,
      'keptPixels': kept,
      'removedPixels': removed,
    };
  }

  void _rebuildSemanticMasks(AvatarRenderState state) {
    final byNode = <String, PixelMask>{};
    for (final layer in state.layers) {
      final existing = byNode[layer.nodeId];
      byNode[layer.nodeId] =
          existing == null ? layer.mask.clone() : existing.union(layer.mask);
    }
    for (final entry in byNode.entries) state.putMask(entry.key, entry.value);

    PixelMask layersMatching(bool Function(RenderLayer layer) include) =>
        _unionLayers(state.layers.where(include));
    state
      ..putMask(
          'hair.all',
          layersMatching((layer) =>
              layer.nodeId.startsWith('hair') || layer.id.startsWith('hair.')))
      ..putMask(
          'ears',
          layersMatching((layer) =>
              <String>{'ears', 'leftEar', 'rightEar'}.contains(layer.nodeId)))
      ..putMask('nose', layersMatching((layer) => layer.id.startsWith('nose.')))
      ..putMask(
        'faceMask',
        layersMatching((layer) => layer.nodeId == 'faceMask'),
      )
      ..putMask(
        'mouthProp',
        layersMatching((layer) => layer.nodeId == 'mouthProp'),
      );
    state.metadata['semanticMaskOwnership'] = <String, Object>{
      'nodeCount': byNode.length,
      'source': 'transformedLayers',
      'legacyAliasesRebuilt': true,
    };
  }

  PixelMask _unionLayers(Iterable<RenderLayer> layers) {
    PixelMask? output;
    for (final layer in layers) {
      output = output == null ? layer.mask.clone() : output.union(layer.mask);
    }
    return output ?? PixelMask();
  }

  void _recordPreCameraClipping(
    AvatarRenderState state,
    OverscanCanvas workingCanvas,
  ) {
    final clippedNodes = <String>{};
    var edgePixels = 0;
    for (final layer in state.layers) {
      if (_isRearSceneSlot(layer.slot)) {
        continue;
      }
      final bounds = layer.mask.bounds;
      if (bounds == null) continue;
      final touchesEdge = bounds.left <= 0 ||
          bounds.top <= 0 ||
          bounds.right >= workingCanvas.width - 1 ||
          bounds.bottom >= workingCanvas.height - 1;
      if (!touchesEdge) continue;
      clippedNodes.add(layer.nodeId);
      for (var x = 0; x < workingCanvas.width; x++) {
        edgePixels += layer.mask.get(x, 0);
        edgePixels += layer.mask.get(x, workingCanvas.height - 1);
      }
      for (var y = 1; y < workingCanvas.height - 1; y++) {
        edgePixels += layer.mask.get(0, y);
        edgePixels += layer.mask.get(workingCanvas.width - 1, y);
      }
    }
    state.metadata['preCameraClipping'] = <String, Object>{
      'canvasWidth': workingCanvas.width,
      'canvasHeight': workingCanvas.height,
      'edgePixels': edgePixels,
      'nodes': clippedNodes.toList(growable: false)..sort(),
      'hasPossibleClipping': clippedNodes.isNotEmpty,
    };
  }

  RigPipelineFrame _cropAndValidate(
    RigPreparedAvatar prepared,
    _RawRigFrame raw,
    ClipCamera camera,
    OverscanCanvas workingCanvas,
  ) {
    final state = AvatarRenderState();
    for (final entry in raw.state.masks.entries) {
      state.putMask(entry.key, camera.cropMask(entry.value));
    }
    state.layers.addAll(camera.cropLayers(raw.state.layers));
    state.metadata
      ..addAll(raw.state.metadata)
      ..['clipCamera'] = camera.toJson()
      ..['overscan'] = <String, int>{
        'width': workingCanvas.width,
        'height': workingCanvas.height,
        'offsetX': workingCanvas.offsetX,
        'offsetY': workingCanvas.offsetY,
      };
    state.nodeParents.addAll(raw.state.nodeParents);
    state.nodeAnchors.addAll(raw.state.nodeAnchors);
    state.nodeTransforms.addAll(raw.state.nodeTransforms);

    _capFinalSceneEffects(state);
    _protectFaceClarity(state);
    _rebuildSemanticMasks(state);
    final repaired = _repairGeometry(state);
    final featurePromotion = _promoteCoreFacialFeatures(state);
    final image = compositor.compose(state.layers);
    final validationGuard = ConstraintEngine(enabled: raw.guard.enabled);
    validator.validate(state, image, validationGuard);
    final runtimeQuality =
        const RigValidationEntries().evaluate(raw.state, camera);
    final clarityEntries = _postCropClarity(state, image);
    return RigPipelineFrame(
      phase: raw.phase,
      state: state,
      image: image,
      camera: camera,
      validation: ValidationReport(List<ValidationEntry>.unmodifiable(
        <ValidationEntry>[
          ...prepared.baseValidation,
          for (final entry in raw.guard.entries)
            if (!repaired.containsKey(entry.id)) entry,
          ...repaired.values,
          ...featurePromotion,
          ...validationGuard.entries,
          ...runtimeQuality,
          ...clarityEntries,
        ],
      )),
    );
  }

  Map<String, ValidationEntry> _repairGeometry(AvatarRenderState state) {
    final repaired = <String, ValidationEntry>{};

    void subtractFromNode(
      String id,
      PixelMask forbidden,
      String reason,
      String validationId,
    ) {
      var removed = 0;
      for (var index = 0; index < state.layers.length; index++) {
        final layer = state.layers[index];
        final belongsToNode = switch (id) {
          'nose' => layer.id.startsWith('nose.'),
          'facialHair' => layer.nodeId == id ||
              layer.id.startsWith('facialHair.') ||
              layer.meta['part'] == 'facialHair',
          _ => layer.nodeId == id,
        };
        if (!belongsToNode) continue;
        final overlap = layer.mask.intersect(forbidden);
        if (overlap.count == 0) continue;
        removed += overlap.count;
        state.layers[index] = layer.copyWith(
          mask: layer.mask.subtract(forbidden),
        );
      }
      if (removed > 0) {
        final rebuilt = _unionLayers(state.layers.where((layer) => switch (id) {
              'nose' => layer.id.startsWith('nose.'),
              'facialHair' => layer.nodeId == id ||
                  layer.id.startsWith('facialHair.') ||
                  layer.meta['part'] == 'facialHair',
              _ => layer.nodeId == id,
            }));
        state.putMask(id, rebuilt);
        repaired[validationId] = ValidationEntry(
          id: validationId,
          status: ValidationStatus.corrected,
          severity: ValidationSeverity.soft,
          reason: reason,
          before: removed,
          after: 0,
        );
      }
    }

    final eyes = state.mask('eyes');
    final mouth = state.mask('mouth');
    final head = state.mask('head');
    final eyesOutsideHead = eyes.subtract(head);
    if (eyesOutsideHead.count > 0) {
      subtractFromNode(
        'eyes',
        eyesOutsideHead,
        'Eye pixels were clipped to the head mask.',
        'bounds.eyes',
      );
    }
    if (eyes.count > 0) {
      subtractFromNode(
        'nose',
        eyes.dilated(),
        'Nose pixels were removed from the eye safety zone.',
        'collision.noseEyes',
      );
      subtractFromNode(
        'brows',
        eyes,
        'Brow pixels were removed from eye pixels.',
        'collision.browsEyes',
      );
    }
    if (mouth.count > 0) {
      subtractFromNode(
        'facialHair',
        mouth,
        'Facial hair pixels were removed from the mouth.',
        'collision.facialHairMouth',
      );
      state.putMask('facialHair', state.mask('facialHair').subtract(mouth));
      for (final id in const <String>[
        'hairFront',
        'headwear',
        'faceMask',
      ]) {
        subtractFromNode(
          id,
          mouth,
          '$id pixels were removed from the mouth safety zone.',
          'visibility.$id.mouth',
        );
      }
    }
    for (final id in const <String>[
      'hairFront',
      'headwear',
      'eyewear',
      'faceMask',
    ]) {
      if (eyes.count > 0) {
        subtractFromNode(
          id,
          eyes,
          '$id pixels were removed from the eye safety zone.',
          'visibility.$id.eyes',
        );
      }
    }

    final neck = state.mask('neck');
    final torso = state.mask('torso');
    if (neck.count > 0 &&
        torso.count > 0 &&
        neck.dilated(diagonal: true).intersect(torso).count == 0) {
      final neckBounds = neck.bounds;
      final torsoBounds = torso.bounds;
      if (neckBounds != null && torsoBounds != null) {
        final left = neckBounds.left > torsoBounds.left
            ? neckBounds.left
            : torsoBounds.left;
        final right = neckBounds.right < torsoBounds.right
            ? neckBounds.right
            : torsoBounds.right;
        if (left <= right || neckBounds.bottom != torsoBounds.top) {
          final layerIndex = state.layers.indexWhere(
            (layer) => layer.nodeId == 'neck',
          );
          if (layerIndex >= 0) {
            final layer = state.layers[layerIndex];
            final mask = layer.mask.clone();
            final bridgeLeft = left <= right
                ? left
                : (neckBounds.center.x - torsoBounds.center.x).abs() <
                        (neckBounds.right - torsoBounds.center.x).abs()
                    ? neckBounds.center.x
                    : torsoBounds.center.x;
            final bridgeRight = left <= right ? right : bridgeLeft;
            final gapTop = neckBounds.bottom <= torsoBounds.top
                ? neckBounds.bottom
                : torsoBounds.bottom;
            final gapBottom = neckBounds.bottom <= torsoBounds.top
                ? torsoBounds.top
                : neckBounds.top;
            if (gapBottom >= gapTop) {
              mask.fillRect(bridgeLeft, gapTop, bridgeRight - bridgeLeft + 1,
                  gapBottom - gapTop + 1);
            }
            state.layers[layerIndex] = layer.copyWith(mask: mask);
            state.putMask(
                'neck',
                _unionLayers(
                  state.layers.where((item) => item.nodeId == 'neck'),
                ));
            if (state
                    .mask('neck')
                    .dilated(diagonal: true)
                    .intersect(torso)
                    .count ==
                0) {
              state.putMask(
                'neck',
                state.mask('neck').union(torso.dilated(diagonal: true)),
              );
            }
            repaired['attachment.neckTorso'] = const ValidationEntry(
              id: 'attachment.neckTorso',
              status: ValidationStatus.corrected,
              severity: ValidationSeverity.soft,
              reason: 'A deterministic neck-to-torso bridge was added.',
            );
          }
        }
      }
    }
    return repaired;
  }

  List<ValidationEntry> _promoteCoreFacialFeatures(AvatarRenderState state) {
    var promotedEyes = 0;
    var promotedMouth = 0;
    for (var index = 0; index < state.layers.length; index++) {
      final layer = state.layers[index];
      if (layer.nodeId != 'eyes' && layer.nodeId != 'mouth') continue;
      if (layer.mask.count == 0) continue;
      state.layers[index] = layer.copyWith(
        slot: RenderSlot.mouthProp,
        localOrder: 10000 + index,
      );
      if (layer.nodeId == 'eyes') {
        promotedEyes++;
      } else {
        promotedMouth++;
      }
    }
    return <ValidationEntry>[
      if (promotedEyes > 0)
        ValidationEntry(
          id: 'readability.eyes.paintOrder',
          status: ValidationStatus.corrected,
          severity: ValidationSeverity.soft,
          reason: 'Eye details were promoted above face-covering layers.',
          before: promotedEyes,
          after: promotedEyes,
        ),
      if (promotedMouth > 0)
        ValidationEntry(
          id: 'readability.mouth.paintOrder',
          status: ValidationStatus.corrected,
          severity: ValidationSeverity.soft,
          reason: 'Mouth details were promoted above face-covering layers.',
          before: promotedMouth,
          after: promotedMouth,
        ),
    ];
  }

  List<ValidationEntry> _postCropClarity(
    AvatarRenderState state,
    IndexedImage image,
  ) {
    final finalNoise = _finalPixelNoise(state, image);
    final existingNoise = state.metadata['visualNoise'];
    if (existingNoise is Map) {
      state.metadata['visualNoise'] = <String, Object?>{
        ...existingNoise,
        ...finalNoise,
      };
    } else {
      state.metadata['visualNoise'] = finalNoise;
    }
    final face = _unionLayers(state.layers.where((layer) => <String>{
          'head',
          'face',
          'eyes',
          'brows',
          'mouth',
        }.contains(layer.nodeId)));
    if (face.count == 0) return const <ValidationEntry>[];
    final clearance = face.dilated();
    final details = state.layers.where((layer) => <RenderSlot>{
          RenderSlot.backgroundDetail,
          RenderSlot.atmosphereBack,
          RenderSlot.foreground,
          RenderSlot.emotionEffects,
        }.contains(layer.slot));
    final detailMask = _unionLayers(details);
    final edgePixels =
        detailMask.outline(diagonal: true).intersect(clearance).count;
    final colors = <int>{
      for (final layer in details)
        if (layer.mask.intersect(clearance).count > 0) layer.colorIndex,
    };
    final edgeRatio = clearance.count == 0 ? 0.0 : edgePixels / clearance.count;
    final pressure = clampDouble(edgeRatio + colors.length * .04, 0, 1);
    state.metadata['backgroundClarityPostCrop'] = <String, Object>{
      'edgePixelsBehindFace': edgePixels,
      'faceClearancePixels': clearance.count,
      'backgroundColorCount': colors.length,
      'pressure': pressure,
      'isReadable': pressure <= .28,
    };
    if (pressure <= .28) return const <ValidationEntry>[];
    return <ValidationEntry>[
      ValidationEntry(
        id: 'clarity.backgroundFaceRegion',
        status: ValidationStatus.violation,
        severity: ValidationSeverity.style,
        reason: 'Background detail remains too busy directly behind the face.',
        before: pressure,
        after: .28,
      ),
    ];
  }

  Map<String, Object> _finalPixelNoise(
    AvatarRenderState state,
    IndexedImage image,
  ) {
    final effectLayers = state.layers.where((layer) => <RenderSlot>{
          RenderSlot.backgroundDetail,
          RenderSlot.atmosphereBack,
          RenderSlot.foreground,
          RenderSlot.emotionEffects,
        }.contains(layer.slot));
    PixelMask? union;
    var components = 0;
    for (final layer in effectLayers) {
      union = union == null ? layer.mask.clone() : union.union(layer.mask);
      components += layer.mask.connectedComponents().length;
    }
    final mask = union ?? PixelMask(width: image.width, height: image.height);
    final ratio = mask.count / (image.width * image.height);
    final edgeDensity = mask.count == 0
        ? 0.0
        : mask.outline(diagonal: true).count / (image.width * image.height);
    final score = clampInt(
      (ratio * 70 + edgeDensity * 180 + components * 1.5).round(),
      0,
      100,
    );
    return <String, Object>{
      'finalScore': score,
      'finalPixelScore': score,
      'finalEffectPixelRatio': ratio,
      'finalEffectComponentCount': components,
      'finalEffectEdgeDensity': edgeDensity,
      'finalCanvasWidth': image.width,
      'finalCanvasHeight': image.height,
    };
  }
}

final class _RawRigFrame {
  const _RawRigFrame({
    required this.phase,
    required this.state,
    required this.image,
    required this.guard,
  });

  final int phase;
  final AvatarRenderState state;
  final IndexedImage image;
  final ConstraintEngine guard;
}
