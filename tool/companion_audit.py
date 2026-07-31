#!/usr/bin/env python3
"""Structural companion V2 audit for CI environments.

Compiler-level correctness remains covered by dart analyze and dart test. This
script protects the catalog/registry relationship and the articulated-node
contract even when the Dart SDK is unavailable.
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MODEL = ROOT / "lib/src/rendering/companion/companion_rig_v2_model.dart"
REGISTRY = ROOT / "lib/src/rendering/companion/companion_style_registry.dart"
CATALOG = ROOT / "lib/src/catalog/companion_catalog_extension.dart"
RENDERER = ROOT / "lib/src/rendering/companion/articulated_companion_v2_renderer.dart"
NATURAL = ROOT / "lib/src/rendering/companion/companion_styles_natural_fantasy.dart"
TEST = ROOT / "test/companion_v2_test.dart"
DOC = ROOT / "docs/COMPANION_RIG_V2.md"


def read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def style_set_from_registry(source: str) -> set[str]:
    match = re.search(
        r"kArticulatedCompanionStyles\s*=\s*<String>\{(.*?)\};",
        source,
        re.S,
    )
    if match is None:
        return set()
    return set(re.findall(r"'([^']+)'", match.group(1)))


def style_set_from_catalog(source: str) -> set[str]:
    return set(re.findall(r"\{'value':\s*'([^']+)'", source))


def main() -> int:
    errors: list[str] = []
    required = [MODEL, REGISTRY, CATALOG, RENDERER, NATURAL, TEST, DOC]
    for path in required:
        if not path.is_file():
            errors.append(f"missing required companion file: {path.relative_to(ROOT)}")
    if errors:
        return fail(errors)

    model = read(MODEL)
    registry = read(REGISTRY)
    catalog = read(CATALOG)
    renderer = read(RENDERER)
    natural = read(NATURAL)
    test = read(TEST)

    registry_styles = style_set_from_registry(registry)
    catalog_styles = style_set_from_catalog(catalog)
    if len(registry_styles) < 55:
        errors.append(
            f"expected at least 55 articulated styles, got {len(registry_styles)}"
        )
    missing_catalog = sorted(registry_styles - catalog_styles)
    if missing_catalog:
        errors.append(
            "registry styles missing from catalog patch: " + ", ".join(missing_catalog)
        )

    required_nodes = {
        "companionLeftWing",
        "companionRightWing",
        "companionLeftArm",
        "companionRightArm",
        "companionLeftLeg",
        "companionRightLeg",
        "companionLeftEar",
        "companionRightEar",
        "companionLeftAntenna",
        "companionRightAntenna",
        "companionLeftTentacle",
        "companionRightTentacle",
    }
    for node in sorted(required_nodes):
        if node not in model:
            errors.append(f"companion node missing from model: {node}")

    for expression in (
        "anchor(CompanionNode.leftWing",
        "anchor(CompanionNode.rightWing",
        "anchor(CompanionNode.leftLeg",
        "anchor(CompanionNode.rightLeg",
    ):
        if expression not in natural:
            errors.append(f"natural companion anchor contract missing: {expression}")

    for expression in (
        "RigMatrix.rotationAround",
        "companionLeftWing",
        "companionRightWing",
        "runtimeAnchors",
        "companionRig",
    ):
        if expression not in renderer:
            errors.append(f"V2 renderer contract missing: {expression}")

    for expression in (
        "body.dilated().intersect(leftWing)",
        "body.dilated().intersect(rightWing)",
        "leftSignatures.length",
        "rightSignatures.length",
    ):
        if expression not in test:
            errors.append(f"wing continuity test missing: {expression}")

    if errors:
        return fail(errors)
    print("COMPANION AUDIT PASSED")
    print(f"- {len(registry_styles)} articulated styles")
    print("- independent wing, limb, ear, antenna and tentacle nodes")
    print("- registry styles exposed through catalog metadata")
    print("- wing motion and attachment tests present")
    return 0


def fail(errors: list[str]) -> int:
    print("COMPANION AUDIT FAILED")
    for error in errors:
        print(f"- {error}")
    return 1


if __name__ == "__main__":
    sys.exit(main())
