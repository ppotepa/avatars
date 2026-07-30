import '../pixels/indexed_image.dart';
import '../pixels/pixel_mask.dart';
import '../rendering/render_helpers.dart';
import '../rendering/render_model.dart';
import 'validation.dart';

abstract interface class AvatarValidator {
  void validate(
    AvatarRenderState state,
    IndexedImage image,
    ConstraintEngine guard,
  );
}

final class V41AvatarValidator implements AvatarValidator {
  const V41AvatarValidator();

  @override
  void validate(
    AvatarRenderState state,
    IndexedImage image,
    ConstraintEngine guard,
  ) {
    final head = state.mask('head');
    final neck = state.mask('neck');
    final torso = state.mask('torso');
    final eyes = state.mask('eyes');
    final mouth = state.mask('mouth');
    final nose = state.mask('nose');
    final brows = _layerMask(state, 'brows');
    final hair = state.mask('hair.all');
    final facialHair = state.mask('facialHair');
    final faceMask = state.mask('faceMask');
    final eyewear = state.mask('eyewear');

    if (!masksTouch(head, neck)) {
      guard.violation('attachment.headNeck', 'Head does not touch the neck.');
    }
    if (!masksTouch(neck, torso)) {
      guard.violation('attachment.neckTorso', 'Neck does not touch the torso.');
    }
    if (eyes.subtract(head).count > 0) {
      guard.violation('bounds.eyes', 'Eye pixels left the head mask.');
    }
    if (nose.intersect(eyes.dilated()).count > 0) {
      guard.violation(
          'collision.noseEyes', 'Nose overlaps the eye safety zone.');
    }
    if (brows.intersect(eyes).count > 0) {
      guard.violation('collision.browsEyes', 'Brows overlap eye pixels.');
    }
    if (facialHair.intersect(mouth).count > 0) {
      guard.violation(
          'collision.facialHairMouth', 'Facial hair covers the mouth.');
    }
    if (hair.intersect(mouth.union(nose)).count > 0) {
      guard.violation(
        'collision.hairCentralFace',
        'Hair covers nose or mouth.',
        severity: ValidationSeverity.soft,
      );
    }
    if (faceMask.count > 0 && state.mask('mouthProp').count > 0) {
      guard.violation(
          'conflict.maskMouthProp', 'A mouth prop is active with a face mask.');
    }
    if (state.mask('headwear').count > 0 &&
        eyewear.count > 0 &&
        countOverlap(state.mask('headwear'), eyewear) > eyewear.count * .65) {
      guard.violation(
          'collision.headwearEyewear', 'Headwear obscures most of the eyewear.',
          severity: ValidationSeverity.soft);
    }
    if (image.usedColorCount > 32) {
      guard.violation('palette.limit', 'Image uses more than 32 colors.');
    }
    if (head.connectedComponents().length != 1) {
      guard.violation('topology.head', 'Head mask is not a single component.');
    }
    final sourceByPart = <String, int>{};
    final visibleByPart = <String, int>{};
    for (final layer in state.layers) {
      final part = layer.meta['part'];
      if (part is! String || part.isEmpty) continue;
      final source = layer.sourcePixelCount ?? layer.mask.count;
      final visible = layer.visiblePixelCount ?? source;
      sourceByPart[part] = (sourceByPart[part] ?? 0) + source;
      visibleByPart[part] = (visibleByPart[part] ?? 0) + visible;
    }
    for (final entry in sourceByPart.entries) {
      if (entry.value == 0) continue;
      if ((visibleByPart[entry.key] ?? 0) == 0) {
        guard.violation('visibility.${entry.key}',
            '${entry.key} rendered but is fully occluded.',
            severity: ValidationSeverity.soft);
      }
    }
    for (final id in const <String>['eyes', 'nose', 'mouth']) {
      final requested = state.metadata['featureRequested.$id'];
      if (requested is bool && !requested) continue;
      final mask = state.mask(id);
      if (mask.count == 0) {
        guard.violation(
            'empty.$id', '$id did not produce any visible geometry.');
      }
    }
    for (final id in const <String>[
      'hair.all',
      'facialHair',
      'headwear',
      'armor'
    ]) {
      final mask = state.mask(id);
      if (mask.count == 0) continue;
      final tiny = mask
          .connectedComponents()
          .where((component) => component.length == 1)
          .length;
      if (tiny > 5) {
        guard.violation('noise.$id', '$id contains excessive isolated pixels.',
            severity: ValidationSeverity.style);
      }
    }
  }

  PixelMask _layerMask(AvatarRenderState state, String id) {
    var output = PixelMask();
    for (final layer in state.layers.where((layer) => layer.id == id)) {
      output = output.union(layer.mask);
    }
    return output;
  }
}
