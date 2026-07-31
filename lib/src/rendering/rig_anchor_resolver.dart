import '../geometry/avatar_layout.dart';
import '../geometry/point.dart';
import '../pixels/pixel_mask.dart';
import '../util/math_utils.dart';
import 'render_model.dart';
import 'rig_model.dart';

/// Derives attachment points from resolved geometry rather than fixed pixels.
final class RigAnchorResolver {
  const RigAnchorResolver();

  List<RigAnchor> resolve(AvatarLayout layout, AvatarRenderState state) {
    final torso = state.mask('torso');
    final head = state.mask('head');
    final neck = state.mask('neck');
    final ears = state.mask('ears');
    final hair = state.mask('hair.all');

    final torsoBounds = torso.bounds;
    final headBounds = head.bounds;
    final neckBounds = neck.bounds;
    final earBounds = ears.bounds;
    final hairBounds = hair.bounds;

    final shoulderY = _resolvedShoulderY(layout, torso);
    final shoulderRow = _rowExtents(torso, shoulderY) ??
        (left: torsoBounds?.left ?? 8, right: torsoBounds?.right ?? 39);
    final leftShoulder = PixelPoint(shoulderRow.left, shoulderY);
    final rightShoulder = PixelPoint(shoulderRow.right, shoulderY);

    final torsoCenterX = torsoBounds?.center.x ?? 24;
    final torsoTop = torsoBounds?.top ?? layout.integer('torso.topY', 35);
    final torsoBottom = torsoBounds?.bottom ?? 47;
    final leftClavicle = PixelPoint(
      clampInt(
        torsoCenterX - (shoulderRow.right - shoulderRow.left) ~/ 5,
        shoulderRow.left,
        torsoCenterX,
      ),
      clampInt(shoulderY + 1, torsoTop, torsoBottom),
    );
    final rightClavicle = PixelPoint(
      clampInt(
        torsoCenterX + (shoulderRow.right - shoulderRow.left) ~/ 5,
        torsoCenterX,
        shoulderRow.right,
      ),
      clampInt(shoulderY + 1, torsoTop, torsoBottom),
    );

    final neckBase = _centerOfBottomRows(neck) ??
        layout.landmarks['body.neckBase'] ??
        PixelPoint(torsoCenterX, shoulderY + 3);
    final neckTop = _centerOfTopRows(neck) ??
        layout.landmarks['body.neckTop'] ??
        PixelPoint(torsoCenterX, shoulderY - 2);
    final headAttach = _centerOfBottomRows(head) ??
        layout.landmarks['head.neckAttach'] ??
        PixelPoint(torsoCenterX, neckTop.y);
    final headCenter = headBounds?.center ?? const PixelPoint(24, 20);
    final headTop = PixelPoint(headCenter.x, headBounds?.top ?? 4);

    final leftEar = _sideCenter(ears, left: true) ??
        PixelPoint(
          headBounds?.left ?? 12,
          layout.integer('ears.centerY', 20),
        );
    final rightEar = _sideCenter(ears, left: false) ??
        PixelPoint(
          headBounds?.right ?? 35,
          layout.integer('ears.centerY', 20),
        );

    final hairRootY = clampInt(
      layout.integer('head.topY', headBounds?.top ?? 4),
      0,
      47,
    );
    final hairRootRow = _rowExtents(
          hair.count > 0 ? hair : head,
          clampInt(hairRootY + 1, 0, 47),
        ) ??
        (left: headBounds?.left ?? 14, right: headBounds?.right ?? 34);

    final upperSpine = PixelPoint(
      torsoCenterX,
      clampInt(torsoTop + 2, 0, 47),
    );
    final midSpine = PixelPoint(
      torsoCenterX,
      clampInt((torsoTop + torsoBottom) ~/ 2, 0, 47),
    );
    final capeLeft = PixelPoint(
      clampInt(leftShoulder.x + 2, leftShoulder.x, torsoCenterX),
      clampInt(leftShoulder.y + 1, 0, 47),
    );
    final capeRight = PixelPoint(
      clampInt(rightShoulder.x - 2, torsoCenterX, rightShoulder.x),
      clampInt(rightShoulder.y + 1, 0, 47),
    );

    final mouth = layout.landmarks['face.mouth'] ??
        PixelPoint(headCenter.x, layout.integer('face.mouthY', 27));
    final leftEye = layout.landmarks['face.leftEye'] ??
        PixelPoint(
          layout.integer('face.leftEyeX', 19),
          layout.integer('face.eyeY', 18),
        );
    final rightEye = layout.landmarks['face.rightEye'] ??
        PixelPoint(
          layout.integer('face.rightEyeX', 29),
          layout.integer('face.eyeY', 18),
        );

    final output = <RigAnchor>[
      RigAnchor(
        id: 'torso.center',
        nodeId: 'torso',
        localPosition: torsoBounds?.center ?? PixelPoint(torsoCenterX, torsoTop),
      ),
      RigAnchor(
        id: 'torso.top',
        nodeId: 'torso',
        localPosition: PixelPoint(torsoCenterX, torsoTop),
      ),
      RigAnchor(
        id: 'torso.bottom',
        nodeId: 'torso',
        localPosition: PixelPoint(torsoCenterX, torsoBottom),
      ),
      RigAnchor(id: 'neck.base', nodeId: 'neck', localPosition: neckBase),
      RigAnchor(id: 'neck.top', nodeId: 'neck', localPosition: neckTop),
      RigAnchor(
        id: 'head.neckJoint',
        nodeId: 'head',
        localPosition: headAttach,
      ),
      RigAnchor(
        id: 'head.center',
        nodeId: 'head',
        localPosition: headCenter,
      ),
      RigAnchor(id: 'head.top', nodeId: 'head', localPosition: headTop),
      RigAnchor(
        id: 'head.left',
        nodeId: 'head',
        localPosition: PixelPoint(headBounds?.left ?? 12, headCenter.y),
      ),
      RigAnchor(
        id: 'head.right',
        nodeId: 'head',
        localPosition: PixelPoint(headBounds?.right ?? 35, headCenter.y),
      ),
      RigAnchor(
        id: 'leftShoulder.joint',
        nodeId: 'leftShoulder',
        localPosition: leftShoulder,
      ),
      RigAnchor(
        id: 'rightShoulder.joint',
        nodeId: 'rightShoulder',
        localPosition: rightShoulder,
      ),
      RigAnchor(
        id: 'leftClavicle',
        nodeId: 'torso',
        localPosition: leftClavicle,
      ),
      RigAnchor(
        id: 'rightClavicle',
        nodeId: 'torso',
        localPosition: rightClavicle,
      ),
      RigAnchor(
        id: 'upperSpine',
        nodeId: 'torso',
        localPosition: upperSpine,
      ),
      RigAnchor(
        id: 'midSpine',
        nodeId: 'torso',
        localPosition: midSpine,
      ),
      RigAnchor(
        id: 'leftEar.center',
        nodeId: 'leftEar',
        localPosition: leftEar,
      ),
      RigAnchor(
        id: 'rightEar.center',
        nodeId: 'rightEar',
        localPosition: rightEar,
      ),
      RigAnchor(
        id: 'mouth.center',
        nodeId: 'mouth',
        localPosition: mouth,
      ),
      RigAnchor(
        id: 'leftEye.center',
        nodeId: 'eyes',
        localPosition: leftEye,
      ),
      RigAnchor(
        id: 'rightEye.center',
        nodeId: 'eyes',
        localPosition: rightEye,
      ),
      RigAnchor(
        id: 'hair.rootLeft',
        nodeId: 'hairBackRoot',
        localPosition: PixelPoint(hairRootRow.left, hairRootY),
      ),
      RigAnchor(
        id: 'hair.rootCenter',
        nodeId: 'hairBackRoot',
        localPosition: PixelPoint(
          (hairRootRow.left + hairRootRow.right) ~/ 2,
          hairRootY,
        ),
      ),
      RigAnchor(
        id: 'hair.rootRight',
        nodeId: 'hairBackRoot',
        localPosition: PixelPoint(hairRootRow.right, hairRootY),
      ),
      RigAnchor(
        id: 'cape.leftRoot',
        nodeId: 'capeLeftRoot',
        localPosition: capeLeft,
      ),
      RigAnchor(
        id: 'cape.rightRoot',
        nodeId: 'capeRightRoot',
        localPosition: capeRight,
      ),
      RigAnchor(
        id: 'cape.center',
        nodeId: 'capeCenter',
        localPosition: upperSpine,
      ),
      RigAnchor(
        id: 'back.upper',
        nodeId: 'backAdornment',
        localPosition: upperSpine,
      ),
      RigAnchor(
        id: 'back.middle',
        nodeId: 'backAdornment',
        localPosition: midSpine,
      ),
    ];

    final existing = output.map((anchor) => anchor.id).toSet();
    final runtime = state.metadata['runtimeAnchors'];
    if (runtime is List) {
      for (final raw in runtime) {
        if (raw is! Map) continue;
        final id = raw['id']?.toString();
        final nodeId = raw['nodeId']?.toString();
        final x = raw['x'];
        final y = raw['y'];
        if (id == null ||
            nodeId == null ||
            x is! num ||
            y is! num ||
            !existing.add(id)) {
          continue;
        }
        output.add(RigAnchor(
          id: id,
          nodeId: nodeId,
          localPosition: PixelPoint(x.toInt(), y.toInt()),
        ));
      }
    }
    return output;
  }

  int _resolvedShoulderY(AvatarLayout layout, PixelMask torso) {
    final requested = layout.integer('body.shoulderY', 35);
    for (var radius = 0; radius <= 4; radius++) {
      for (final y in <int>[requested - radius, requested + radius]) {
        if (y >= 0 && y < torso.height && _rowExtents(torso, y) != null) {
          return y;
        }
      }
    }
    return torso.bounds?.top ?? requested;
  }

  ({int left, int right})? _rowExtents(PixelMask mask, int y) {
    if (y < 0 || y >= mask.height) return null;
    var left = mask.width;
    var right = -1;
    for (var x = 0; x < mask.width; x++) {
      if (mask.get(x, y) == 0) continue;
      if (x < left) left = x;
      if (x > right) right = x;
    }
    return right < left ? null : (left: left, right: right);
  }

  PixelPoint? _centerOfTopRows(PixelMask mask) {
    final bounds = mask.bounds;
    if (bounds == null) return null;
    for (var y = bounds.top;
        y <= clampInt(bounds.top + 2, 0, bounds.bottom);
        y++) {
      final row = _rowExtents(mask, y);
      if (row != null) return PixelPoint((row.left + row.right) ~/ 2, y);
    }
    return bounds.center;
  }

  PixelPoint? _centerOfBottomRows(PixelMask mask) {
    final bounds = mask.bounds;
    if (bounds == null) return null;
    for (var y = bounds.bottom;
        y >= clampInt(bounds.bottom - 2, bounds.top, 47);
        y--) {
      final row = _rowExtents(mask, y);
      if (row != null) return PixelPoint((row.left + row.right) ~/ 2, y);
    }
    return bounds.center;
  }

  PixelPoint? _sideCenter(PixelMask mask, {required bool left}) {
    final bounds = mask.bounds;
    if (bounds == null) return null;
    final centerX = bounds.center.x;
    final side = PixelMask(width: mask.width, height: mask.height);
    for (var y = bounds.top; y <= bounds.bottom; y++) {
      for (var x = bounds.left; x <= bounds.right; x++) {
        if (mask.get(x, y) != 0 && (left ? x <= centerX : x >= centerX)) {
          side.set(x, y);
        }
      }
    }
    return side.bounds?.center;
  }
}
