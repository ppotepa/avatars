import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('overscan and camera support expressive wide motion', () {
    final pipeline = File('lib/src/rendering/rig_clip_pipeline.dart')
        .readAsStringSync();
    final camera =
        File('lib/src/rendering/clip_camera.dart').readAsStringSync();

    expect(pipeline, contains('width: 72'));
    expect(pipeline, contains('height: 72'));
    expect(pipeline, contains('offsetX: 12'));
    expect(pipeline, contains('offsetY: 12'));
    expect(camera, contains('CameraFramingProfile.portrait'));
    expect(camera, contains('CameraFramingProfile.expressive'));
    expect(camera, contains('CameraFramingProfile.wide'));
    expect(camera, contains('activeGesture'));
  });

  test('canonical rig contains complete articulated arm chains', () {
    final rig = File('lib/src/rendering/canonical_rig.dart').readAsStringSync();
    final runtime =
        File('lib/src/rendering/runtime_rig_builder.dart').readAsStringSync();

    for (final side in const <String>['left', 'right']) {
      expect(rig, contains("'${side}Forearm': '${side}Arm'"));
      expect(rig, contains("'${side}Wrist': '${side}Forearm'"));
      expect(rig, contains("'${side}Hand': '${side}Wrist'"));
      expect(runtime, contains("'$side-arm-to-forearm'"));
      expect(runtime, contains("'$side-forearm-to-wrist'"));
      expect(runtime, contains("'$side-wrist-to-hand'"));
    }
  });

  test('arm segmentation follows a bone axis with seam overlap', () {
    final segmentation = File(
      'lib/src/rendering/parts/forearm_segmentation_renderer.dart',
    ).readAsStringSync();

    expect(segmentation, contains('boneAxis'));
    expect(segmentation, contains('projection'));
    expect(segmentation, contains('overlap'));
    expect(segmentation, isNot(contains('bounds.height * .48')));
  });

  test('scene and wearable paint groups are semantically separated', () {
    final model = File('lib/src/rendering/rig_model.dart').readAsStringSync();
    final binding =
        File('lib/src/rendering/rig_layer_binding.dart').readAsStringSync();
    final wearables = File(
      'lib/src/rendering/wearable_attachment_policy.dart',
    ).readAsStringSync();

    expect(model, contains('backgroundBase'));
    expect(model, contains('backgroundDetail'));
    expect(model, contains('atmosphereBack'));
    expect(model, contains('neckJewelry'));
    expect(model, contains('earJewelryBack'));
    expect(model, contains('earJewelryFront'));
    expect(binding, contains("meta['attachmentTarget']"));
    expect(binding, contains("meta['occlusionGroup']"));
    expect(binding, isNot(contains('localOrder: order')));
    expect(wearables, contains('backWearableFront'));
    expect(wearables, contains("'attachmentTarget'"));
    expect(wearables, contains("'occlusionGroup'"));
  });

  test('final scene clarity and clipping are measured after posing', () {
    final pipeline = File('lib/src/rendering/rig_clip_pipeline.dart')
        .readAsStringSync();
    final pose = pipeline.indexOf('RigPoseApplier().solveAndApply');
    final smoke = pipeline.indexOf('WorldSmokeEmitterRenderer().render');
    final rain = pipeline.indexOf('RainFieldRenderer().render');
    final clarity = pipeline.indexOf('_protectFaceClarity');
    final gate = pipeline.indexOf('SceneVisualBudgetRenderer().render');
    final masks = pipeline.indexOf('_rebuildSemanticMasks');
    final clipping = pipeline.indexOf('_recordPreCameraClipping');

    expect(pose, greaterThanOrEqualTo(0));
    expect(smoke, greaterThan(pose));
    expect(rain, greaterThan(smoke));
    expect(clarity, greaterThan(rain));
    expect(gate, greaterThan(clarity));
    expect(masks, greaterThan(gate));
    expect(clipping, greaterThan(masks));
    expect(pipeline, contains('backgroundClarity'));
    expect(pipeline, contains('preCameraClipping'));
  });
}
