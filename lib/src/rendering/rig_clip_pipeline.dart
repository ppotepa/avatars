import '../api/avatar_request.dart';
import '../constraints/avatar_validator.dart';
import '../constraints/validation.dart';
import '../genome/avatar_genome_model.dart';
import '../genome/genome_generator.dart';
import '../geometry/avatar_layout.dart';
import '../palette/avatar_palette.dart';
import '../pixels/indexed_image.dart';
import '../pixels/pixel_mask.dart';
import 'animation_controller.dart';
import 'canonical_rig.dart';
import 'clip_camera.dart';
import 'clip_camera_cache.dart';
import 'expressive_motion_policy.dart';
import 'parts/accessories_renderer.dart';
import 'parts/anatomy_renderer.dart';
import 'parts/armor_renderer.dart';
import 'parts/articulated_arm_renderer.dart';
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
  final OverscanCanvas canvas;

  static List<AvatarPartRenderer> get defaultParts =>
      const <AvatarPartRenderer>[
        BackgroundRenderer(),
        ExtendedAtmosphereRenderer(),
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
    final raw = <_RawRigFrame>[
      for (var phase = 0; phase < frameCount; phase++)
        _renderRaw(prepared, request.rendering, phase),
    ];
    final camera = ClipCameraFitter.fitFrames(
      raw.map((frame) => ClipCameraFitter.frameBounds(frame.state.layers)),
      canvasWidth: canvas.width,
      canvasHeight: canvas.height,
    );
    final key = cameraCache.key(
      genome: prepared.genome,
      rendering: request.rendering,
      sampleCount: frameCount,
    );
    cameraCache.put(key, camera);
    for (final frame in raw) {
      frame.state.metadata['cameraCache'] = <String, Object>{
        'hit': false,
        'sampleCount': frameCount,
        'entries': cameraCache.length,
      };
    }
    return RigPipelineClip(
      prepared: prepared,
      camera: camera,
      frames: List.unmodifiable(<RigPipelineFrame>[
        for (final frame in raw) _cropAndValidate(prepared, frame, camera),
      ]),
    );
  }

  RigPipelineClip renderSingle(AvatarRequest request) {
    const cameraSampleCount = 16;
    final prepared = prepare(request);
    final key = cameraCache.key(
      genome: prepared.genome,
      rendering: request.rendering,
      sampleCount: cameraSampleCount,
    );
    final cached = cameraCache.get(key);
    late final ClipCamera camera;
    late final _RawRigFrame selected;

    if (cached != null) {
      camera = cached;
      selected = _renderRaw(
        prepared,
        request.rendering,
        request.phase % cameraSampleCount,
      );
      selected.state.metadata['cameraCache'] = <String, Object>{
        'hit': true,
        'sampleCount': cameraSampleCount,
        'entries': cameraCache.length,
      };
    } else {
      final raw = <_RawRigFrame>[
        for (var phase = 0; phase < cameraSampleCount; phase++)
          _renderRaw(prepared, request.rendering, phase),
      ];
      camera = ClipCameraFitter.fitFrames(
        raw.map((frame) => ClipCameraFitter.frameBounds(frame.state.layers)),
        canvasWidth: canvas.width,
        canvasHeight: canvas.height,
      );
      cameraCache.put(key, camera);
      selected = raw[request.phase % cameraSampleCount];
      selected.state.metadata['cameraCache'] = <String, Object>{
        'hit': false,
        'sampleCount': cameraSampleCount,
        'entries': cameraCache.length,
      };
    }

    return RigPipelineClip(
      prepared: prepared,
      camera: camera,
      frames: <RigPipelineFrame>[
        _cropAndValidate(prepared, selected, camera),
      ],
    );
  }

  _RawRigFrame _renderRaw(
    RigPreparedAvatar prepared,
    AvatarRenderSettings rendering,
    int phase,
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
    _bindRig(context, state);
    final image = compositor.compose(state.layers);
    return _RawRigFrame(
      phase: phase,
      state: state,
      image: image,
      guard: guard,
    );
  }

  void _bindRig(AvatarRenderContext context, AvatarRenderState state) {
    for (var index = 0; index < state.layers.length; index++) {
      final layer = state.layers[index];
      final binding = RigLayerBinding.resolve(
        layer.id,
        layer.localOrder,
        layer.meta,
      );
      final preserveRendererNode =
          layer.meta['rigSegment'] != null ||
              layer.meta['attachmentKind'] != null;
      state.layers[index] = layer.copyWith(
        nodeId: preserveRendererNode ? layer.nodeId : binding.nodeId,
        slot: preserveRendererNode ? layer.slot : binding.slot,
        localOrder: binding.localOrder,
      );
    }

    for (final entry in CanonicalRig.parents.entries) {
      if (!state.nodeParents.containsKey(entry.key)) {
        state.parentNode(entry.key, entry.value);
      }
    }
    const WearableAttachmentPolicy().apply(context, state);

    final backgrounds = <String, PixelMask>{
      for (final layer in state.layers)
        if (layer.slot == RenderSlot.background) layer.id: layer.mask,
    };

    final graph = const RuntimeRigBuilder().build(
      context.layout,
      state,
      offsetX: canvas.offsetX,
      offsetY: canvas.offsetY,
    );

    canvas.embedState(state);
    for (var index = 0; index < state.layers.length; index++) {
      final layer = state.layers[index];
      final original = backgrounds[layer.id];
      if (original != null) {
        state.layers[index] = layer.copyWith(mask: _embedBackground(original));
      }
    }

    final controller = const RigAnimationController();
    final expressive = const ExpressiveMotionPolicy().augment(
      context,
      controller.sample(context),
    );
    final sample = const SemanticGesturePolicy().augment(context, expressive);
    final requestedPose = RigPose(sample.transforms);
    final solvedPose = const RigPoseApplier().solveAndApply(
      state,
      graph,
      requestedPose,
    );
    final constraintQuality =
        const RigQualityEvaluator().evaluate(graph, solvedPose);

    const WorldSmokeEmitterRenderer().render(context, state);
    const RainFieldRenderer().render(context, state);
    const SceneVisualBudgetRenderer().render(context, state);

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
      ..['rigGraph'] = graph.toJson();
  }

  RigPipelineFrame _cropAndValidate(
    RigPreparedAvatar prepared,
    _RawRigFrame raw,
    ClipCamera camera,
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
        'width': canvas.width,
        'height': canvas.height,
      };
    state.nodeParents.addAll(raw.state.nodeParents);
    state.nodeAnchors.addAll(raw.state.nodeAnchors);
    state.nodeTransforms.addAll(raw.state.nodeTransforms);
    final image = camera.cropImage(raw.image);
    validator.validate(state, image, raw.guard);
    final runtimeQuality = const RigValidationEntries().evaluate(raw.state, camera);
    return RigPipelineFrame(
      phase: raw.phase,
      state: state,
      image: image,
      camera: camera,
      validation: ValidationReport(<ValidationEntry>[
        ...prepared.baseValidation,
        ...raw.guard.entries,
        ...runtimeQuality,
      ]),
    );
  }

  PixelMask _embedBackground(PixelMask source) {
    final output = PixelMask(width: canvas.width, height: canvas.height);
    for (var y = 0; y < canvas.height; y++) {
      for (var x = 0; x < canvas.width; x++) {
        final sx = (x - canvas.offsetX).clamp(0, source.width - 1).toInt();
        final sy = (y - canvas.offsetY).clamp(0, source.height - 1).toInt();
        if (source.get(sx, sy) != 0) output.set(x, y);
      }
    }
    return output;
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
