import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('weather and effect particles use separate layer namespaces', () {
    final particles =
        File('lib/src/rendering/parts/natural_particle_renderer.dart')
            .readAsStringSync();
    final gate = File('lib/src/rendering/scene_visual_budget_renderer.dart')
        .readAsStringSync();

    expect(particles, contains("'particle.v3.\$namespace.back.dark'"));
    expect(particles, contains("namespace: 'effect'"));
    expect(particles, contains("namespace: 'weather'"));
    expect(gate, contains("'particle.v3.weather.'"));
    expect(gate, contains("'particle.v3.effect.'"));
  });

  test('world emitters and the final scene gate run after posing', () {
    final pipeline = File('lib/src/rendering/rig_clip_pipeline.dart')
        .readAsStringSync();
    final pose = pipeline.indexOf('RigPoseApplier().solveAndApply');
    final smoke = pipeline.indexOf('WorldSmokeEmitterRenderer().render');
    final rain = pipeline.indexOf('RainFieldRenderer().render');
    final gate = pipeline.indexOf('SceneVisualBudgetRenderer().render');

    expect(pose, greaterThanOrEqualTo(0));
    expect(smoke, greaterThan(pose));
    expect(rain, greaterThan(smoke));
    expect(gate, greaterThan(rain));
  });
}
