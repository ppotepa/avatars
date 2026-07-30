import '../../geometry/pixel_rect.dart';
import '../../pixels/pixel_mask.dart';
import '../../util/math_utils.dart';
import '../render_model.dart';

/// Applies animation channels that affect the already composed avatar body.
///
/// Local channels such as blinking, eye movement, hair wind and jewelry swing
/// are owned by their respective part renderers. This renderer handles only
/// whole-avatar transforms, preserving single responsibility and allowing it
/// to be replaced by an application-specific animation policy.
final class AvatarMotionRenderer implements AvatarPartRenderer {
  const AvatarMotionRenderer();

  @override
  void render(AvatarRenderContext context, AvatarRenderState state) {
    _sleepEffect(context, state);
    _shockEffect(context, state);
    _emotionEffect(context, state);
    _utilityEffect(context, state);
    _applyArmGesture(context, state);
    _applyCompanionMotion(context, state);

    if (_usesLayeredMotion(context.animation.id)) {
      _applyLayeredMotion(context, state);
      return;
    }

    final dy = _feedSafeDy(state, context.animation.headBobY());
    if (dy == 0) return;

    state.translateNode('actor', dx: 0, dy: dy);
  }

  bool _usesLayeredMotion(String id) => const <String>{
        'lookAround',
        'talking',
        'laughing',
        'scared',
        'surprised',
        'angry',
        'sad',
        'happy',
        'thinking',
        'confused',
        'hurt',
        'celebration',
        'sleeping',
      }.contains(id);

  void _applyArmGesture(AvatarRenderContext context, AvatarRenderState state) {
    final animation = context.animation;
    final swing = animation.traitSwingX();
    final pulse = animation.pulse(basePeriod: 8, peak: 2);
    final gesture = switch (animation.id) {
      'talking' => (
          leftDegrees: swing * 4,
          rightDegrees: -12 - pulse * 5,
        ),
      'laughing' => (
          leftDegrees: 18 + pulse * 5,
          rightDegrees: -18 - pulse * 5,
        ),
      'scared' => (
          leftDegrees: -48 - pulse * 5,
          rightDegrees: 48 + pulse * 5,
        ),
      'angry' => (
          leftDegrees: -18 - pulse * 3,
          rightDegrees: 18 + pulse * 3,
        ),
      'sad' => (
          leftDegrees: -8 - pulse * 2,
          rightDegrees: 8 + pulse * 2,
        ),
      'thinking' => (
          leftDegrees: 0,
          rightDegrees: 62 + pulse * 5,
        ),
      'confused' => (
          leftDegrees: 25 + swing * 3,
          rightDegrees: -18 + swing * 3,
        ),
      'hurt' => (
          leftDegrees: -30 - pulse * 4,
          rightDegrees: 30 + pulse * 4,
        ),
      'sleeping' => (
          leftDegrees: -5,
          rightDegrees: 5,
        ),
      'celebration' => (
          leftDegrees: 58 + pulse * 8,
          rightDegrees: -58 - pulse * 8,
        ),
      _ => (leftDegrees: 0, rightDegrees: 0),
    };

    void rotateArm(String nodeId, int degrees, {required bool isLeft}) {
      if (degrees == 0) return;
      final bounds = state.buildRenderGraph().byId[nodeId]?.bounds;
      if (bounds == null) return;
      state.rotateNode(
        nodeId,
        degrees: degrees,
        pivotX: isLeft ? bounds.right : bounds.left,
        pivotY: bounds.top + 1,
      );
    }

    rotateArm('leftArm', gesture.leftDegrees, isLeft: true);
    rotateArm('rightArm', gesture.rightDegrees, isLeft: false);
  }

  void _applyCompanionMotion(
      AvatarRenderContext context, AvatarRenderState state) {
    final style = context.string('v4.shoulderProp');
    final animated = const <String>{
      'cat',
      'parrot',
      'smallDragon',
      'ghost',
      'insect',
      'shoulderRobot',
    }.contains(style);
    if (!animated) {
      final requestedDx = context.animation.propSwingX();
      state.translateNode(
        'shoulderObject',
        dx: _feedSafeDxFor(
          state,
          requestedDx,
          includeLayer: (layer) =>
              _isNodeOrChild(state, layer.nodeId, 'shoulderObject'),
        ),
        dy: 0,
      );
      return;
    }
    final animation = context.animation;
    final requestedRootDx = animation.propSwingX();
    final requestedRootDy =
        animation.id == 'celebration' ? positiveMod(animation.phase, 2) : 0;
    state.translateNode(
      'shoulderCompanion',
      dx: _feedSafeDxFor(
        state,
        requestedRootDx,
        includeLayer: (layer) =>
            _isNodeOrChild(state, layer.nodeId, 'shoulderCompanion'),
      ),
      dy: _feedSafeDyFor(
        state,
        requestedRootDy,
        includeLayer: (layer) =>
            _isNodeOrChild(state, layer.nodeId, 'shoulderCompanion'),
      ),
    );

    void rotatePart(
      String nodeId,
      int degrees, {
      required ({int x, int y}) Function(PixelRect bounds) pivotFor,
    }) {
      if (degrees == 0) return;
      final bounds = state.buildRenderGraph().byId[nodeId]?.bounds;
      if (bounds == null) return;
      final pivot = pivotFor(bounds);
      state.rotateNode(
        nodeId,
        degrees: degrees,
        pivotX: pivot.x,
        pivotY: pivot.y,
      );
    }

    rotatePart(
      'companionHead',
      animation.oscillate(basePeriod: 10, amplitudeScale: 1) * 7,
      pivotFor: (bounds) => (x: bounds.center.x, y: bounds.bottom),
    );
    rotatePart(
      'companionWings',
      animation.oscillate(basePeriod: 6, amplitudeScale: 1) * 16,
      pivotFor: (bounds) => (x: bounds.center.x, y: bounds.center.y),
    );
    rotatePart(
      'companionTail',
      animation.oscillate(basePeriod: 8, amplitudeScale: 1) * 14,
      pivotFor: (bounds) => (x: bounds.center.x, y: bounds.top),
    );
    rotatePart(
      'companionEars',
      animation.oscillate(basePeriod: 12, amplitudeScale: 1) * 8,
      pivotFor: (bounds) => (x: bounds.center.x, y: bounds.bottom),
    );
    if (style == 'parrot') {
      final speaking = animation.id == 'talking' ||
          animation.id == 'laughing' ||
          animation.id == 'happy';
      state.translateNode(
        'companionBeak',
        dx: 0,
        dy: speaking
            ? positiveMod(animation.phase, 2)
            : (positiveMod(animation.phase, 12) == 0 ? 1 : 0),
      );
    }
  }

  void _applyLayeredMotion(
    AvatarRenderContext context,
    AvatarRenderState state,
  ) {
    final animation = context.animation;
    if (animation.id == 'lookAround') {
      final bounds = state.buildRenderGraph().byId['head']?.bounds;
      if (bounds != null) {
        state.rotateNode(
          'head',
          degrees: animation.eyeOffsetX() * 3,
          pivotX: bounds.center.x,
          pivotY: bounds.bottom,
        );
      }
      return;
    }
    final headDy = _feedSafeDyFor(
      state,
      animation.headBobY(),
      includeLayer: (layer) => _isNodeOrChild(state, layer.nodeId, 'head'),
    );
    final requestedHeadDx = switch (animation.id) {
      'laughing' ||
      'scared' ||
      'confused' ||
      'celebration' =>
        animation.traitSwingX(),
      'angry' ||
      'happy' ||
      'thinking' ||
      'surprised' =>
        animation.traitSwingX() ~/ 2,
      'hurt' => -animation.pulse(basePeriod: 8, peak: 1),
      _ => 0,
    };
    final headDx = _feedSafeDxFor(
      state,
      requestedHeadDx,
      includeLayer: (layer) => _isNodeOrChild(state, layer.nodeId, 'head'),
    );
    state.translateNode('head', dx: headDx, dy: headDy);

    final torsoDy = switch (animation.id) {
      'laughing' => -(animation.headBobY() ~/ 2),
      'scared' => animation.headBobY() ~/ 2,
      'surprised' => animation.headBobY() ~/ 3,
      'celebration' => -(animation.headBobY() ~/ 2),
      'talking' || 'happy' => -(animation.headBobY() ~/ 3),
      'angry' || 'confused' || 'hurt' => animation.headBobY() ~/ 3,
      'sad' || 'thinking' || 'sleeping' => -(animation.headBobY() ~/ 3),
      _ => 0,
    };
    final safeTorsoDy = _feedSafeDyFor(
      state,
      torsoDy,
      includeLayer: (layer) => _isNodeOrChild(state, layer.nodeId, 'torso'),
    );
    final requestedTorsoDx =
        animation.id == 'scared' || animation.id == 'confused'
            ? -(headDx ~/ 2)
            : 0;
    final torsoDx = _feedSafeDxFor(
      state,
      requestedTorsoDx,
      includeLayer: (layer) => _isNodeOrChild(state, layer.nodeId, 'torso'),
    );
    state.translateNode('torso', dx: torsoDx, dy: safeTorsoDy);

    if (<String>{'laughing', 'celebration', 'scared', 'confused'}
        .contains(animation.id)) {
      final hatLift = animation.pulse(
        basePeriod: animation.id == 'celebration' ? 4 : 6,
        peak: animation.id == 'celebration' ? 2 : 1,
      );
      final requestedHatDx =
          animation.id == 'scared' ? -headDx : -(headDx ~/ 2);
      final hatDx = _feedSafeDxFor(
        state,
        requestedHatDx,
        includeLayer: (layer) => layer.nodeId == 'headwear',
      );
      final hatDy = _feedSafeDyFor(
        state,
        -hatLift,
        includeLayer: (layer) => layer.nodeId == 'headwear',
      );
      state.translateNode('headwear', dx: hatDx, dy: hatDy);
    }
  }

  bool _isNodeOrChild(AvatarRenderState state, String nodeId, String root) {
    final nodes = state.buildRenderGraph().byId;
    var current = nodes[nodeId];
    while (current != null) {
      if (current.id == root) return true;
      current = current.parentId == null ? null : nodes[current.parentId!];
    }
    return false;
  }

  int _feedSafeDy(AvatarRenderState state, int requestedDy) {
    return _feedSafeDyFor(
      state,
      requestedDy,
      includeLayer: (layer) =>
          layer.nodeId != 'background' &&
          layer.nodeId != 'aura' &&
          layer.nodeId != 'emotionEffects' &&
          layer.nodeId != 'foreground',
    );
  }

  int _feedSafeDyFor(
    AvatarRenderState state,
    int requestedDy, {
    required bool Function(RenderLayer layer) includeLayer,
  }) {
    if (requestedDy == 0) return 0;
    final canvasHeight =
        state.layers.isEmpty ? 54 : state.layers.first.mask.height;
    var minY = canvasHeight;
    var maxY = -1;
    for (final layer in state.layers) {
      if (!includeLayer(layer)) continue;
      final bounds = layer.mask.bounds;
      if (bounds == null) continue;
      if (bounds.y < minY) minY = bounds.y;
      if (bounds.bottom > maxY) maxY = bounds.bottom;
    }
    if (maxY < 0) return 0;
    final upwardLimit = -minY;
    final downwardLimit = canvasHeight - 1 - maxY;
    return clampInt(requestedDy, upwardLimit, downwardLimit);
  }

  int _feedSafeDxFor(
    AvatarRenderState state,
    int requestedDx, {
    required bool Function(RenderLayer layer) includeLayer,
  }) {
    if (requestedDx == 0) return 0;
    final canvasWidth =
        state.layers.isEmpty ? 48 : state.layers.first.mask.width;
    var minX = canvasWidth;
    var maxX = -1;
    for (final layer in state.layers) {
      if (!includeLayer(layer)) continue;
      final bounds = layer.mask.bounds;
      if (bounds == null) continue;
      if (bounds.x < minX) minX = bounds.x;
      if (bounds.right > maxX) maxX = bounds.right;
    }
    if (maxX < 0) return 0;
    return clampInt(requestedDx, -minX, canvasWidth - 1 - maxX);
  }

  void _sleepEffect(AvatarRenderContext context, AvatarRenderState state) {
    if (context.animation.id != 'sleeping') return;
    final mask = PixelMask();
    state.parentNode('emotionEffects', 'head');
    final swingX = context.animation.traitSwingX();
    final rise = context.animation.pulse(basePeriod: 14, peak: 1);
    final baseX = 30 + swingX;
    final baseY = clampInt(context.integer('head.topY') - 2 - rise, 6, 18);
    _drawZ(mask, baseX, baseY, 2);
    _drawZ(mask, baseX + 3, baseY - 4, 3);
    _drawZ(mask, baseX + 7, baseY - 9, 4);
    state.addLayer('effect.sleep', 210, mask, context.color('white'),
        meta: const {'part': 'sleep'});
  }

  void _drawZ(PixelMask mask, int x, int y, int size) {
    mask
      ..hLine(x, x + size - 1, y)
      ..line(x + size - 1, y, x, y + size - 1)
      ..hLine(x, x + size - 1, y + size - 1);
  }

  void _shockEffect(AvatarRenderContext context, AvatarRenderState state) {
    if (context.animation.id != 'scared' &&
        context.animation.id != 'surprised') {
      return;
    }
    final pulse = context.animation.pulse(basePeriod: 6, peak: 2);
    if (pulse == 0) return;
    state.parentNode('emotionEffects', 'head');
    final head = state.mask('head').bounds;
    if (head == null) return;
    state.parentNode('emotionEffects', 'head');
    final mask = PixelMask();
    final top = clampInt(head.top - 4 - pulse, 4, 42);
    final left = clampInt(head.left - 4 - pulse, 2, 44);
    final right = clampInt(head.right + 4 + pulse, 3, 45);
    mask
      ..line(left, top + 1, left - 2, top - 1)
      ..line(right, top + 1, right + 2, top - 1)
      ..line(left + 3, top - 1, left + 2, top - 4)
      ..line(right - 3, top - 1, right - 2, top - 4);
    state.addLayer(
      'effect.shock',
      211,
      mask,
      context.color('white'),
      meta: const {'part': 'emotion', 'emotion': 'shock'},
    );
  }

  void _emotionEffect(
    AvatarRenderContext context,
    AvatarRenderState state,
  ) {
    final id = context.animation.id;
    if (!const <String>{
      'talking',
      'angry',
      'sad',
      'happy',
      'thinking',
      'confused',
      'hurt',
      'celebration',
    }.contains(id)) {
      return;
    }
    if (id == 'blink' || id == 'lookAround') return;
    if (id == 'hairWind' && state.mask('hairFront').count == 0) return;
    if (id == 'jewelrySwing' &&
        !state.layers.any((layer) => layer.id.startsWith('jewelry.'))) {
      return;
    }
    if (id == 'smoke' &&
        (context.string('v4.mouthProp') == 'none' ||
            context.integer('v4.smokeAmount') <= 0)) {
      return;
    }
    if (id == 'auraPulse' && context.string('v4.aura') == 'none') return;
    if (id == 'glowPulse' &&
        context.string('v4.aura') == 'none' &&
        context.string('v4.effect') == 'none') {
      return;
    }
    final head = state.mask('head').bounds;
    if (head == null) return;
    final mask = PixelMask();
    final pulse = context.animation.pulse(basePeriod: 8, peak: 2);
    final left = clampInt(head.left - 4, 2, 42);
    final right = clampInt(head.right + 4, 5, 45);
    final top = clampInt(head.top - 4, 5, 40);
    final midY = clampInt(head.y + head.height ~/ 2, 5, 42);

    switch (id) {
      case 'talking':
        mask
          ..line(right, midY - 2, right + 2 + pulse, midY - 3)
          ..line(right, midY + 1, right + 2 + pulse, midY + 2);
      case 'angry':
        mask
          ..line(left, top, left - 2, top - 3)
          ..line(left + 2, top, left + 1, top - 4)
          ..line(right, top, right + 2, top - 3);
      case 'sad':
        final tearY = clampInt(midY + pulse, 4, 45);
        mask
          ..set(clampInt(head.left + 3, 1, 46), tearY)
          ..vLine(clampInt(head.left + 2, 1, 46), tearY + 1, tearY + 2);
      case 'happy':
        mask
          ..line(left, top + 1, left - 2, top - 1)
          ..line(right, top + 1, right + 2, top - 1);
      case 'thinking':
        final y = clampInt(top - pulse, 2, 43);
        mask
          ..set(right, y + 4)
          ..fillRect(right + 2, y + 1, 2, 2)
          ..fillRect(right + 5, y - 2, 3, 3);
      case 'confused':
        _drawQuestionMark(mask, right, clampInt(top - pulse, 1, 38));
      case 'hurt':
        final x = left - 1;
        final y = top + 1;
        mask
          ..line(x - 2, y, x + 2, y)
          ..line(x, y - 2, x, y + 2)
          ..line(x - 1, y - 1, x + 1, y + 1)
          ..line(x + 1, y - 1, x - 1, y + 1);
      case 'celebration':
        mask
          ..line(left, top + 2, left - 2 - pulse, top)
          ..line(right, top + 2, right + 2 + pulse, top)
          ..line(head.x + head.width ~/ 2, top, head.x + head.width ~/ 2,
              top - 3 - pulse);
    }

    state.addLayer(
      'effect.emotion.$id',
      212,
      mask,
      context.color(id == 'angry' || id == 'hurt' ? 'clothAccent' : 'white'),
      meta: <String, Object?>{'part': 'emotion', 'emotion': id},
    );
  }

  void _drawQuestionMark(PixelMask mask, int x, int y) {
    mask
      ..hLine(x, x + 2, y)
      ..vLine(x + 2, y + 1, y + 2)
      ..hLine(x, x + 2, y + 3)
      ..set(x, y + 4)
      ..set(x, y + 6);
  }

  void _utilityEffect(
    AvatarRenderContext context,
    AvatarRenderState state,
  ) {
    final id = context.animation.id;
    if (!const <String>{
      'blink',
      'lookAround',
      'smoke',
      'hairWind',
      'jewelrySwing',
      'glowPulse',
      'auraPulse',
      'particles',
    }.contains(id)) {
      return;
    }
    final head = state.mask('head').bounds;
    final torso = state.mask('torso').bounds;
    if (head == null && torso == null) return;
    final anchor = head ?? torso!;
    final mask = PixelMask();
    final pulse = context.animation.pulse(basePeriod: 8, peak: 2);
    final swing = context.animation.oscillate(
      basePeriod: 10,
      amplitudeScale: 1,
    );
    final centerX = anchor.x + anchor.width ~/ 2;
    final top = clampInt(anchor.top - 3, 4, 40);
    final midY = clampInt(
      anchor.y + anchor.height ~/ 2,
      5,
      42,
    );

    switch (id) {
      case 'blink':
        final y = clampInt(midY - 2, 3, 44);
        mask
          ..hLine(centerX - 7 - pulse, centerX - 4, y)
          ..hLine(centerX + 4, centerX + 7 + pulse, y);
      case 'lookAround':
        mask
          ..line(centerX - 11 + swing, midY, centerX - 9 + swing, midY - 1)
          ..line(centerX + 11 + swing, midY, centerX + 9 + swing, midY - 1);
      case 'smoke':
        final x = clampInt(centerX + 10 + swing, 4, 42);
        final y = clampInt(midY - 2 - pulse, 5, 42);
        mask
          ..fillEllipse(x, y, 1, 1)
          ..fillEllipse(x + 2, y - 3, 2, 1)
          ..fillEllipse(x + 1, y - 6, 2 + pulse ~/ 2, 2);
      case 'hairWind':
        final y = clampInt(top + 4, 4, 42);
        mask
          ..hLine(3 + pulse, 10 + pulse, y)
          ..hLine(1, 8, y + 3)
          ..hLine(5 + pulse, 12 + pulse, y + 6);
      case 'jewelrySwing':
        final x = clampInt(centerX + 11 + swing, 3, 44);
        mask
          ..line(x, midY + 3, x + swing, midY + 6)
          ..set(x + swing, midY + 7);
      case 'glowPulse':
        final radius = 1 + pulse;
        mask
          ..fillEllipse(centerX - 13, top + 3, radius, radius)
          ..fillEllipse(centerX + 13, top + 3, radius, radius);
      case 'auraPulse':
        final spread = 2 + pulse;
        mask
          ..line(centerX - 12, top + 4, centerX - 12 - spread, top + 2)
          ..line(centerX + 12, top + 4, centerX + 12 + spread, top + 2)
          ..vLine(centerX, top, top - spread);
      case 'particles':
        final phase = positiveMod(context.phase, 6);
        mask
          ..set(5 + phase, 9)
          ..set(39 - phase, 14)
          ..set(8 + phase, 25)
          ..set(42 - phase, 33)
          ..set(3 + phase, 41);
    }

    state.addLayer(
      'effect.utility.$id',
      213,
      mask,
      context.color(
        id == 'glowPulse' || id == 'auraPulse' ? 'fantasyLight' : 'white',
      ),
      meta: <String, Object?>{'part': 'animation', 'animation': id},
    );
  }
}
