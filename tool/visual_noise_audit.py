#!/usr/bin/env python3
"""Structural audit for scene-noise budgeting and core framing."""
from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
POLICY = ROOT / "lib/src/quality/scene_visual_noise.dart"
BUDGETED = ROOT / "lib/src/genome/budgeted_genome_generator.dart"
RENDERER = ROOT / "lib/src/rendering/scene_visual_budget_renderer.dart"
CAMERA = ROOT / "lib/src/rendering/clip_camera.dart"
PIPELINE = ROOT / "lib/src/rendering/rig_clip_pipeline.dart"
RIG_GENERATOR = ROOT / "lib/src/api/rig_avatar_generator.dart"
TEST = ROOT / "test/visual_noise_budget_test.dart"


def read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def main() -> int:
    errors: list[str] = []
    required = [POLICY, BUDGETED, RENDERER, CAMERA, PIPELINE, RIG_GENERATOR, TEST]
    for path in required:
        if not path.is_file():
            errors.append(f"missing visual-noise file: {path.relative_to(ROOT)}")
    if errors:
        return fail(errors)

    policy = read(POLICY)
    budgeted = read(BUDGETED)
    renderer = read(RENDERER)
    camera = read(CAMERA)
    pipeline = read(PIPELINE)
    rig_generator = read(RIG_GENERATOR)
    test = read(TEST)

    for channel in (
        "v4.weather",
        "v4.cosmicLayer",
        "v4.backFlames",
        "v4.ambientOverlay",
        "v4.backgroundEvent",
        "v4.effect",
    ):
        if f"'{channel}'" not in policy:
            errors.append(f"dominant scene channel missing from policy: {channel}")

    for expression in (
        "hardLimit = 42",
        "probabilisticTarget",
        "activeChannels",
        "sceneVisualNoiseHardLimit",
    ):
        if expression not in policy:
            errors.append(f"visual-noise policy contract missing: {expression}")

    for expression in (
        "_resolveSceneConflicts",
        "'v4.weather' => 6",
        "BudgetedGenomeGenerator",
    ):
        if expression not in budgeted:
            errors.append(f"budgeted generator contract missing: {expression}")

    for expression in (
        "SceneVisualBudgetRenderer",
        "activeChannelCount",
        "configuredScore",
        "removedLayers",
    ):
        if expression not in renderer:
            errors.append(f"runtime scene gate contract missing: {expression}")

    for expression in (
        "ClipFrameBounds",
        "fitFrames",
        "safetyCoverage",
        "targetWidth = 47",
        "targetHeight = 45",
        "1.65",
    ):
        if expression not in camera:
            errors.append(f"camera framing contract missing: {expression}")

    for expression in (
        "SceneVisualBudgetRenderer()",
        "ClipCameraFitter.fitFrames",
        "ClipCameraFitter.frameBounds",
    ):
        if expression not in pipeline:
            errors.append(f"pipeline integration missing: {expression}")

    for expression in (
        "rig.visualNoise",
        "safetyCoverage",
        "visualNoise",
    ):
        if expression not in rig_generator:
            errors.append(f"rig diagnostics contract missing: {expression}")

    for expression in (
        "lessThanOrEqualTo(SceneVisualNoise.hardLimit)",
        "<String>['v4.weather']",
        "greaterThanOrEqualTo(.72)",
        "safetyCoverage",
    ):
        if expression not in test:
            errors.append(f"visual-noise regression test missing: {expression}")

    if errors:
        return fail(errors)
    print("VISUAL NOISE AUDIT PASSED")
    print("- one dominant full-scene channel")
    print("- probabilistic target with hard limit 42")
    print("- render-time layer gate and diagnostics")
    print("- core/safety framing with occupancy tests")
    return 0


def fail(errors: list[str]) -> int:
    print("VISUAL NOISE AUDIT FAILED")
    for error in errors:
        print(f"- {error}")
    return 1


if __name__ == "__main__":
    sys.exit(main())
