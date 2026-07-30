import '../../pixels/pixel_mask.dart';
import '../../util/math_utils.dart';
import '../render_helpers.dart';
import '../render_model.dart';

/// Adds expressive motion without translating the complete sprite.
///
/// Gaze, brow and breathing overlays remain inside existing face and torso masks,
/// so all animation frames preserve stable 48x48 framing.
final class ExpressiveMotionOverlayRenderer implements AvatarPartRenderer {
  const ExpressiveMotionOverlayRenderer();

  @override
  void render(AvatarRenderContext context, AvatarRenderState state) {
    final intensity = clampInt(context.integer('v4.motionIntensity'), 0, 5);
    if (intensity == 0) return;
    final speed = clampInt(context.integer('v4.motionSpeed'), 1, 6);
    final phase = context.phase + context.integer('v4.motionPhaseOffset');
    final period = animationPeriod(speed, slow: 24, fast: 10);
    final pose = context.string('v4.poseMotion');
    final gaze = context.string('v4.gazeMotion');
    final browMotion = context.string('v4.browMotion');

    var gazeX = 0;
    var gazeY = 0;
    if (gaze == 'leftRight') {
      gazeX = cyclicOffset(phase, period, clampInt(intensity, 1, 2));
    } else if (gaze == 'lookUp') {
      gazeY = -1;
    } else if (gaze == 'lookDown') {
      gazeY = 1;
    } else if (gaze == 'suspicious') {
      gazeX = cyclicOffset(phase, period * 2, 1);
      gazeY = phase % period < period ~/ 2 ? 0 : -1;
    } else if (gaze == 'curious') {
      gazeX = cyclicOffset(phase, period, 1);
      gazeY = -1;
    }

    if (pose == 'shyLookAway') {
      gazeX = phase % period < period ~/ 2 ? -1 : 1;
      gazeY = 1;
    } else if (pose == 'proudPose') {
      gazeY = -1;
    } else if (pose == 'headTilt') {
      gazeX += cyclicOffset(phase, period * 2, 1);
    } else if (pose == 'tinyShake') {
      gazeX += cyclicOffset(phase, clampInt(period ~/ 2, 4, period), 1);
    } else if (pose == 'headNod') {
      gazeY += cyclicOffset(phase, period, 1);
    }

    final eyeCover = PixelMask();
    final pupils = PixelMask();
    final eyeLight = PixelMask();
    final eyeMask = state.mask('eyes');
    for (final centerX in <int>[
      context.integer('face.leftEyeX'),
      context.integer('face.rightEyeX'),
    ]) {
      final centerY = context.integer('face.eyeY');
      final targetX = centerX + gazeX;
      final targetY = centerY + gazeY;
      final local = maskRect(centerX - 1, centerY - 1, 3, 3).intersect(eyeMask);
      eyeCover.data.setAll(0, eyeCover.union(local).data);
      if (eyeMask.get(targetX, targetY) != 0) {
        pupils.set(targetX, targetY);
        if (intensity >= 4) eyeLight.set(targetX - 1, targetY - 1);
      } else if (eyeMask.get(centerX, centerY) != 0) {
        pupils.set(centerX, centerY);
      }
    }

    final brows = PixelMask();
    final eyeY = context.integer('face.eyeY');
    final leftX = context.integer('face.leftEyeX');
    final rightX = context.integer('face.rightEyeX');
    if (browMotion == 'raiseLeft') {
      brows.hLine(leftX - 3, leftX + 3, eyeY - 6);
    } else if (browMotion == 'raiseRight') {
      brows.hLine(rightX - 3, rightX + 3, eyeY - 6);
    } else if (browMotion == 'bounce') {
      final offset = cyclicOffset(phase, period, 1);
      brows
        ..hLine(leftX - 3, leftX + 3, eyeY - 4 - offset)
        ..hLine(rightX - 3, rightX + 3, eyeY - 4 - offset);
    } else if (browMotion == 'angry') {
      brows
        ..line(leftX - 3, eyeY - 5, leftX + 3, eyeY - 3)
        ..line(rightX - 3, eyeY - 3, rightX + 3, eyeY - 5);
    } else if (browMotion == 'sad') {
      brows
        ..line(leftX - 3, eyeY - 3, leftX + 3, eyeY - 5)
        ..line(rightX - 3, eyeY - 5, rightX + 3, eyeY - 3);
    }

    final breathDark = PixelMask();
    final breathLight = PixelMask();
    if (pose == 'breathe' || pose == 'proudPose') {
      final torso = state.mask('torso');
      final torsoTop = context.integer('torso.topY');
      final pulse = pose == 'breathe'
          ? cyclicOffset(phase, period, clampInt((intensity + 1) ~/ 2, 1, 2))
          : -1;
      final y = clampInt(torsoTop + 3 + pulse, torsoTop, 47);
      breathLight.data.setAll(
        0,
        torso.intersect(maskFromPredicate((x, yy) =>
          yy == y && x >= 17 && x <= 30,
        )).data,
      );
      if (pose == 'proudPose') {
        breathDark.data.setAll(
          0,
          torso.intersect(maskFromPredicate((x, yy) =>
            yy == y + 2 && (x < 18 || x > 29),
          )).data,
        );
      }
    }

    final gesture = PixelMask();
    if (pose == 'shyLookAway') {
      gesture.data.setAll(
        0,
        orderedDither(
          state.mask('lowerCheekLeftZone')
              .union(state.mask('lowerCheekRightZone')),
          3,
          phase: phase,
        ).data,
      );
    } else if (pose == 'headTilt') {
      final direction = cyclicOffset(phase, period * 2, 1);
      gesture.line(
        direction < 0 ? leftX - 4 : rightX + 4,
        eyeY - 2,
        direction < 0 ? leftX - 5 : rightX + 5,
        eyeY + 2,
      );
    } else if (pose == 'tinyShake') {
      final direction = cyclicOffset(phase, clampInt(period ~/ 2, 4, period), 1);
      if (direction != 0) {
        gesture
          ..line(11, eyeY - 2, 8, eyeY - 4)
          ..line(37, eyeY - 2, 40, eyeY - 4);
      }
    } else if (pose == 'headNod') {
      gesture.hLine(21, 27, eyeY - 7 + cyclicOffset(phase, period, 1));
    }

    state
      ..addLayer(
        'motion.v42.eyeCover',
        104,
        eyeCover,
        context.color('irisBase'),
        meta: const {'part': 'motion'},
      )
      ..addLayer(
        'motion.v42.pupils',
        105,
        pupils,
        context.color('pupil'),
        meta: const {'part': 'motion'},
      )
      ..addLayer(
        'motion.v42.eyeLight',
        106,
        eyeLight,
        context.color('white'),
        meta: const {'part': 'motion'},
      )
      ..addLayer(
        'motion.v42.brows',
        126,
        brows,
        context.color('hairShadow'),
        meta: const {'part': 'motion'},
      )
      ..addLayer(
        'motion.v42.gesture',
        127,
        gesture,
        context.color('skinAccent'),
        meta: const {'part': 'motion'},
      )
      ..addLayer(
        'motion.v42.breathDark',
        160,
        breathDark,
        context.color('clothDark'),
        meta: const {'part': 'motion'},
      )
      ..addLayer(
        'motion.v42.breathLight',
        161,
        breathLight,
        context.color('clothLight'),
        meta: const {'part': 'motion'},
      );
  }
}
