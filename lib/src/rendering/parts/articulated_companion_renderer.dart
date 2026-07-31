import '../../geometry/point.dart';
import '../../pixels/pixel_mask.dart';
import '../../util/math_utils.dart';
import '../render_helpers.dart';
import '../render_model.dart';
import '../rig_anchor_resolver.dart';
import '../rig_model.dart';

/// Rebuilds shoulder companions as articulated subtrees attached to a shoulder.
final class ArticulatedCompanionRenderer implements AvatarPartRenderer {
  const ArticulatedCompanionRenderer({
    this.anchorResolver = const RigAnchorResolver(),
  });

  final RigAnchorResolver anchorResolver;

  @override
  void render(AvatarRenderContext context, AvatarRenderState state) {
    final primary = context.string('v4.shoulderProp');
    final extra = context.string('v4.extraShoulderProp');
    final style = primary != 'none' ? primary : extra;
    if (style == 'none') return;

    final side = context.integer('v4.propSide') == 0
        ? (context.random('companion.rig.side').nextBool() ? -1 : 1)
        : context.integer('v4.propSide').sign;
    final anchors = <String, PixelPoint>{
      for (final anchor in anchorResolver.resolve(context.layout, state))
        anchor.id: anchor.localPosition,
    };
    final shoulder = anchors[
      side < 0 ? 'leftShoulder.joint' : 'rightShoulder.joint'
    ];
    if (shoulder == null) return;

    final attachment = side < 0
        ? 'leftShoulderAttachment'
        : 'rightShoulderAttachment';
    state
      ..parentNode('shoulderCompanion', attachment)
      ..parentNode('companionBody', 'shoulderCompanion')
      ..parentNode('companionHead', 'companionBody')
      ..parentNode('companionWings', 'companionBody')
      ..parentNode('companionTail', 'companionBody')
      ..parentNode('companionEars', 'companionHead')
      ..parentNode('companionEyes', 'companionHead')
      ..parentNode('companionBeak', 'companionHead')
      ..anchorNode('shoulderCompanion',
          side < 0 ? 'leftShoulder.joint' : 'rightShoulder.joint');

    state.layers.removeWhere((layer) =>
        layer.id.startsWith('shoulderProp.') ||
        layer.id.startsWith('companion.v42'));

    final rootX = shoulder.x + (side < 0 ? -1 : 1);
    final rootY = shoulder.y - 1;
    final body = PixelMask();
    final head = PixelMask();
    final wings = PixelMask();
    final tail = PixelMask();
    final ears = PixelMask();
    final eyes = PixelMask();
    final beak = PixelMask();
    final shadow = PixelMask();
    final light = PixelMask();

    _draw(
      style,
      side,
      rootX,
      rootY,
      body,
      head,
      wings,
      tail,
      ears,
      eyes,
      beak,
      shadow,
      light,
    );

    final active = context.string('v4.animation') != 'none' ||
        context.string('v4.faceAnimation') != 'none';
    final speed = clampInt(context.integer('v4.animationSpeed', 3), 1, 6);
    final period = animationPeriod(speed, slow: 22, fast: 9);
    final phase = context.phase;
    final rootDy = active && cyclicOffset(phase - 2, period, 1) > 0 ? 1 : 0;
    final headDx = active ? cyclicOffset(phase - 3, period * 2, 1) : 0;
    final headDy = active ? (cyclicOffset(phase, period, 1) > 0 ? -1 : 0) : 0;
    final wingDx = active ? cyclicOffset(phase, clampInt(period ~/ 2, 4, period), 2) : 0;
    final tailDx = active ? cyclicOffset(phase - 4, period, 2) : 0;
    final earDy = active && positiveMod(phase, period) < 2 ? -1 : 0;
    final speaking = <String>{'talk', 'laugh', 'happy'}
        .contains(context.string('v4.faceAnimation'));
    final beakDy = speaking ? positiveMod(phase, 2) : 0;

    PixelMask moved(PixelMask source, int dx, int dy) =>
        source.translated(dx, dy + rootDy);

    final bodyMoved = moved(body, 0, 0);
    final headMoved = moved(head, headDx, headDy);
    final wingsMoved = moved(wings, wingDx * side, 0);
    final tailMoved = moved(tail, tailDx * side, 0);
    final earsMoved = moved(ears, headDx, headDy + earDy);
    final eyesMoved = moved(eyes, headDx, headDy);
    final beakMoved = moved(beak, headDx, headDy + beakDy);
    final shadowMoved = moved(shadow, 0, 0);
    final lightMoved = moved(light, 0, 0);

    _add(
      context,
      state,
      'companion.rig.body',
      'companionBody',
      bodyMoved,
      context.color('clothAccent'),
      195,
    );
    _add(
      context,
      state,
      'companion.rig.shadow',
      'companionBody',
      shadowMoved,
      context.color('clothDark'),
      196,
    );
    _add(
      context,
      state,
      'companion.rig.wings',
      'companionWings',
      wingsMoved,
      context.color('clothLight'),
      196,
    );
    _add(
      context,
      state,
      'companion.rig.tail',
      'companionTail',
      tailMoved,
      context.color('clothAccent'),
      196,
    );
    _add(
      context,
      state,
      'companion.rig.head',
      'companionHead',
      headMoved,
      context.color('clothAccent'),
      197,
    );
    _add(
      context,
      state,
      'companion.rig.ears',
      'companionEars',
      earsMoved,
      context.color('clothAccent'),
      198,
    );
    _add(
      context,
      state,
      'companion.rig.beak',
      'companionBeak',
      beakMoved,
      context.color('clothLight'),
      198,
    );
    _add(
      context,
      state,
      'companion.rig.eyes',
      'companionEyes',
      eyesMoved,
      context.color('fantasyLight'),
      199,
    );
    _add(
      context,
      state,
      'companion.rig.light',
      'companionBody',
      lightMoved,
      context.color('fantasyLight'),
      199,
    );

    state
      ..putMask('companion.body', bodyMoved)
      ..putMask('companion.head', headMoved)
      ..putMask('companion.wings', wingsMoved)
      ..putMask('companion.tail', tailMoved)
      ..putMask('companion.ears', earsMoved)
      ..putMask('companion.beak', beakMoved)
      ..putMask('companion.eyes', eyesMoved);

    state.metadata['companionRig'] = <String, Object>{
      'style': style,
      'side': side,
      'anchor': shoulder.toJson(),
      'rootOffsetY': rootDy,
      'head': <String, int>{'dx': headDx, 'dy': headDy},
      'wingDx': wingDx * side,
      'tailDx': tailDx * side,
      'earDy': earDy,
      'beakDy': beakDy,
    };
  }

  void _draw(
    String style,
    int side,
    int x,
    int y,
    PixelMask body,
    PixelMask head,
    PixelMask wings,
    PixelMask tail,
    PixelMask ears,
    PixelMask eyes,
    PixelMask beak,
    PixelMask shadow,
    PixelMask light,
  ) {
    if (<String>{'parrot', 'owl', 'crow', 'raven'}.contains(style)) {
      body.fillEllipse(x, y - 4, 4, 6);
      head.fillEllipse(x - side, y - 11, 3, 3);
      wings.fillEllipse(x + side, y - 5, 2, 4);
      tail
        ..line(x, y, x + side * 2, y + 7, thickness: 2)
        ..line(x - side, y, x, y + 6);
      beak.fillTriangle(
        (x: x - side * 3, y: y - 12),
        (x: x - side * 7, y: y - 10),
        (x: x - side * 3, y: y - 9),
      );
      eyes.set(x - side * 2, y - 12);
      light.set(x, y - 13);
    } else if (style == 'cat') {
      body.fillEllipse(x, y - 3, 5, 5);
      head.fillEllipse(x, y - 10, 4, 4);
      ears
        ..fillTriangle(
          (x: x - 4, y: y - 12),
          (x: x - 1, y: y - 11),
          (x: x - 3, y: y - 16),
        )
        ..fillTriangle(
          (x: x + 1, y: y - 11),
          (x: x + 4, y: y - 12),
          (x: x + 3, y: y - 16),
        );
      tail
        ..line(x + side * 4, y - 1, x + side * 8, y - 4, thickness: 2)
        ..line(x + side * 8, y - 4, x + side * 7, y - 9, thickness: 2);
      eyes.set(x - 2, y - 11).set(x + 2, y - 11);
      light.set(x, y - 8);
    } else if (style == 'smallDragon' || style == 'bat') {
      body.fillEllipse(x, y - 5, 4, 6);
      head.fillEllipse(x + side * 2, y - 12, 3, 3);
      wings
        ..fillTriangle(
          (x: x, y: y - 8),
          (x: x - side * 10, y: y - 15),
          (x: x - side * 5, y: y - 3),
        )
        ..line(x, y - 8, x - side * 7, y - 11);
      tail.line(x - side, y, x - side * 8, y + 6, thickness: 2);
      ears.fillTriangle(
        (x: x + side, y: y - 14),
        (x: x + side * 3, y: y - 14),
        (x: x + side * 2, y: y - 18),
      );
      eyes.set(x + side * 3, y - 13);
      light.set(x + side, y - 14);
    } else if (style == 'shoulderRobot' || style == 'miniDrone') {
      body.fillRect(x - 4, y - 9, 8, 8);
      head.fillRect(x - 3, y - 14, 6, 5);
      ears
        ..line(x, y - 14, x + side * 3, y - 18)
        ..set(x + side * 3, y - 19);
      eyes.set(x - 1, y - 12).set(x + 1, y - 12);
      shadow.vLine(x, y - 8, y - 3);
      light.hLine(x - 2, x + 2, y - 10);
    } else if (style == 'ghost' || style == 'cloudSpirit') {
      head.fillEllipse(x, y - 12, 5, 4);
      body.fillRect(x - 5, y - 12, 11, 8);
      for (var offset = -4; offset <= 4; offset += 2) {
        tail.fillTriangle(
          (x: x + offset - 1, y: y - 5),
          (x: x + offset + 1, y: y - 5),
          (x: x + offset, y: y),
        );
      }
      eyes.set(x - 2, y - 12).set(x + 2, y - 12);
    } else if (style == 'insect') {
      body.fillEllipse(x, y - 6, 2, 4);
      head.fillEllipse(x, y - 11, 2, 2);
      wings
        ..fillEllipse(x - 3, y - 7, 3, 2)
        ..fillEllipse(x + 3, y - 7, 3, 2);
      ears
        ..line(x - 1, y - 12, x - 3, y - 16)
        ..line(x + 1, y - 12, x + 3, y - 16);
      eyes.set(x, y - 12);
      light.set(x, y - 10);
    } else if (style == 'snake') {
      body
        ..line(x, y, x + side * 5, y - 8, thickness: 2)
        ..line(x + side * 5, y - 8, x, y - 15, thickness: 2);
      head.fillEllipse(x, y - 16, 3, 2);
      eyes.set(x + side, y - 17);
      tail.set(x - side, y + 1);
    } else {
      body.fillEllipse(x, y - 5, 5, 5);
      head.fillEllipse(x, y - 11, 4, 3);
      eyes.set(x - 2, y - 12).set(x + 2, y - 12);
      light.set(x, y - 8);
    }
    shadow.data.setAll(0, body.outline(diagonal: true).intersect(body.dilated()).data);
  }

  void _add(
    AvatarRenderContext context,
    AvatarRenderState state,
    String id,
    String nodeId,
    PixelMask mask,
    int color,
    int order,
  ) {
    state.addLayer(
      id,
      order,
      mask,
      color,
      nodeId: nodeId,
      slot: RenderSlot.shoulderCompanion,
      meta: const <String, Object?>{'part': 'shoulderCompanion'},
    );
  }
}
