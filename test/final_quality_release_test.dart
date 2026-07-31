import 'dart:io';

import 'package:avatar_genome/avatar_genome.dart';
import 'package:test/test.dart';

void main() {
  test('final quality architecture remains connected', () {
    final pipeline = File('lib/src/rendering/rig_clip_pipeline.dart').readAsStringSync();
    final camera = File('lib/src/rendering/clip_camera.dart').readAsStringSync();
    final rig = File('lib/src/rendering/canonical_rig.dart').readAsStringSync();
    final binding = File('lib/src/rendering/rig_layer_binding.dart').readAsStringSync();
    final detail = File('lib/src/rendering/native_detail_renderer.dart').readAsStringSync();

    expect(pipeline, contains('width: 72'));
    expect(pipeline, contains('_protectFaceClarity'));
    expect(pipeline, contains('_recordPreCameraClipping'));
    expect(camera, contains('CameraFramingProfile.portrait'));
    expect(camera, contains('CameraFramingProfile.expressive'));
    expect(camera, contains('CameraFramingProfile.wide'));
    expect(rig, contains("'leftForearm': 'leftArm'"));
    expect(rig, contains("'leftWrist': 'leftForearm'"));
    expect(rig, contains("'leftHand': 'leftWrist'"));
    expect(binding, contains("meta['attachmentTarget']"));
    expect(binding, contains("meta['occlusionGroup']"));
    expect(binding, isNot(contains('localOrder: legacyOrder')));
    expect(detail, contains("owner == 'eyes'"));
    expect(detail, contains("owner == 'mouth'"));
    expect(detail, contains("owner == 'clothing'"));
    expect(detail, contains("owner == 'armor'"));
    expect(detail, contains("owner == 'hair'"));
  });

  test('large render profiles provide increasing semantic detail', () {
    expect(ResolutionProfile.forSize(48).detailBudget, 0);
    expect(ResolutionProfile.forSize(64).detailBudget, greaterThan(0));
    expect(
      ResolutionProfile.forSize(80).detailBudget,
      greaterThan(ResolutionProfile.forSize(64).detailBudget),
    );
    expect(
      ResolutionProfile.forSize(96).detailBudget,
      greaterThan(ResolutionProfile.forSize(80).detailBudget),
    );
  });
}
