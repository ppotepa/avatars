#!/usr/bin/env python3
"""Dependency-free structural audit for environments without a Dart SDK.

This is intentionally not a replacement for `dart analyze` or `dart test`.
It checks the preserved V4.1 catalog, the additive V4.2 extension, local imports,
lexical delimiter balance and direct library references for every field.
"""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LIB = ROOT / "lib"
CATALOG = ROOT / "tool" / "catalog_v41.json"
GENERATED = ROOT / "lib" / "src" / "catalog" / "generated_catalog_json.dart"
EXTENSION = ROOT / "lib" / "src" / "catalog" / "catalog_v42_extension.dart"


def dart_files() -> list[Path]:
    roots = [
        LIB,
        ROOT / "test",
        ROOT / "example",
        ROOT / "benchmark",
        ROOT / "tool",
        ROOT / "bin",
    ]
    return sorted(
        path
        for directory in roots
        if directory.is_dir()
        for path in directory.rglob("*.dart")
    )


def strip_comments_and_strings(source: str) -> str:
    output: list[str] = []
    i = 0
    state = "code"
    quote = ""
    triple = False
    while i < len(source):
        c = source[i]
        n = source[i + 1] if i + 1 < len(source) else ""
        if state == "code":
            if c == "/" and n == "/":
                state = "line_comment"
                output.extend("  ")
                i += 2
                continue
            if c == "/" and n == "*":
                state = "block_comment"
                output.extend("  ")
                i += 2
                continue
            if c in "'\"":
                quote = c
                triple = source[i : i + 3] == c * 3
                state = "string"
                length = 3 if triple else 1
                output.extend(" " * length)
                i += length
                continue
            output.append(c)
            i += 1
            continue
        if state == "line_comment":
            if c == "\n":
                state = "code"
                output.append(c)
            else:
                output.append(" ")
            i += 1
            continue
        if state == "block_comment":
            if c == "*" and n == "/":
                state = "code"
                output.extend("  ")
                i += 2
            else:
                output.append("\n" if c == "\n" else " ")
                i += 1
            continue
        delimiter = quote * (3 if triple else 1)
        if source.startswith(delimiter, i):
            output.extend(" " * len(delimiter))
            i += len(delimiter)
            state = "code"
            continue
        if c == "\\" and i + 1 < len(source):
            output.extend("  ")
            i += 2
            continue
        output.append("\n" if c == "\n" else " ")
        i += 1
    return "".join(output)


def delimiter_errors(path: Path) -> list[str]:
    source = strip_comments_and_strings(path.read_text(encoding="utf-8"))
    pairs = {")": "(", "]": "[", "}": "{"}
    stack: list[tuple[str, int]] = []
    errors: list[str] = []
    for index, char in enumerate(source):
        if char in "([{":
            stack.append((char, index))
        elif char in ")]}":
            if not stack or stack[-1][0] != pairs[char]:
                line = source.count("\n", 0, index) + 1
                errors.append(f"{path.relative_to(ROOT)}:{line}: unmatched {char}")
                continue
            stack.pop()
    for char, index in stack:
        line = source.count("\n", 0, index) + 1
        errors.append(f"{path.relative_to(ROOT)}:{line}: unclosed {char}")
    return errors


def import_errors(path: Path) -> list[str]:
    errors: list[str] = []
    text = path.read_text(encoding="utf-8")
    for match in re.finditer(r"^import\s+['\"]([^'\"]+)['\"]", text, re.M):
        target = match.group(1)
        if target.startswith(("dart:", "package:")):
            continue
        resolved = (path.parent / target).resolve()
        if not resolved.is_file():
            errors.append(f"{path.relative_to(ROOT)}: missing import {target}")
    return errors


def embedded_json(path: Path) -> object:
    source = path.read_text(encoding="utf-8")
    match = re.search(r"r'''\s*(.*?)\s*''';", source, re.S)
    if match is None:
        raise ValueError(f"raw JSON string was not found in {path.relative_to(ROOT)}")
    return json.loads(match.group(1))


def catalog_errors() -> tuple[list[str], list[str]]:
    base = json.loads(CATALOG.read_text(encoding="utf-8"))
    extension = embedded_json(EXTENSION)
    base_categories = base["categories"]
    extension_categories = extension["categories"]
    base_fields = [field for category in base_categories for field in category["fields"]]
    extension_fields = [
        field for category in extension_categories for field in category["fields"]
    ]
    errors: list[str] = []

    if len(base_categories) != 26:
        errors.append(f"base catalog categories: expected 26, got {len(base_categories)}")
    if len(base_fields) != 224:
        errors.append(f"base catalog fields: expected 224, got {len(base_fields)}")
    if len(extension_categories) != 4:
        errors.append(
            f"V4.2 extension categories: expected 4, got {len(extension_categories)}"
        )
    if len(extension_fields) != 51:
        errors.append(
            f"V4.2 extension fields: expected 51, got {len(extension_fields)}"
        )

    all_fields = [*base_fields, *extension_fields]
    ids = [field["id"] for field in all_fields]
    if len(ids) != 275:
        errors.append(f"merged catalog fields: expected 275, got {len(ids)}")
    if len(ids) != len(set(ids)):
        errors.append("merged catalog contains duplicate field identifiers")

    base_by_id = {field["id"]: field for field in base_fields}
    for field_id, additions in extension.get("fieldOptions", {}).items():
        target = base_by_id.get(field_id)
        if target is None:
            errors.append(f"V4.2 option patch targets unknown field: {field_id}")
            continue
        values = [option["value"] for option in target.get("options", [])]
        values.extend(option["value"] for option in additions)
        if len(values) != len(set(values)):
            errors.append(f"V4.2 option patch duplicates values for {field_id}")

    embedded = embedded_json(GENERATED)
    if embedded != base:
        errors.append("generated V4.1 catalog JSON does not match tool/catalog_v41.json")

    library_text = "\n".join(
        path.read_text(encoding="utf-8")
        for path in (LIB / "src").rglob("*.dart")
        if path not in {GENERATED, EXTENSION}
    )
    unreferenced = [
        field_id
        for field_id in ids
        if f"'{field_id}'" not in library_text and f'"{field_id}"' not in library_text
    ]
    if unreferenced:
        errors.append(
            "catalog fields without a direct library reference: "
            + ", ".join(unreferenced)
        )
    return errors, ids


def project_contract_errors(field_ids: list[str]) -> list[str]:
    required = [
        ROOT / "lib" / "avatar_genome.dart",
        ROOT / "lib" / "avatar_genome_io.dart",
        ROOT / "lib" / "src" / "catalog" / "catalog_v42_extension.dart",
        ROOT / "lib" / "src" / "rendering" / "parts" / "v42_features_renderer.dart",
        ROOT / "lib" / "src" / "rendering" / "parts" / "v42_motion_renderer.dart",
        ROOT / "lib" / "src" / "rendering" / "parts" / "v42_detail_renderer.dart",
        ROOT / "lib" / "src" / "rendering" / "parts" / "v42_scenic_light_renderer.dart",
        ROOT / "lib" / "src" / "rendering" / "parts" / "natural_particle_renderer.dart",
        ROOT / "lib" / "src" / "rendering" / "parts" / "procedural_mask_renderer.dart",
        ROOT / "lib" / "src" / "rendering" / "parts" / "procedural_surface_renderer.dart",
        ROOT / "test" / "v42_features_test.dart",
        ROOT / "test" / "player_ui_contract_test.dart",
        ROOT / "test" / "procedural_variation_test.dart",
        ROOT / "test" / "resolution_symmetry_test.dart",
        ROOT / "test" / "surface_variation_test.dart",
        ROOT / ".github" / "workflows" / "dart-ci.yml",
        ROOT / "README.md",
        ROOT / "docs" / "ARCHITECTURE.md",
        ROOT / "docs" / "MIGRATION_FROM_HTML.md",
        ROOT / "docs" / "PARAMETERS.md",
        ROOT / "docs" / "VALIDATION.md",
        ROOT / "docs" / "EDITOR_SERVER.md",
        ROOT / "docs" / "BINDING_ARCHITECTURE.md",
        ROOT / "bin" / "avatar_editor_server.dart",
        ROOT / "web" / "index.html",
        ROOT / "web" / "app.js",
        ROOT / "web" / "player.js",
        ROOT / "web" / "styles.css",
        ROOT / "web" / "player.css",
    ]
    errors = [
        f"missing required file: {path.relative_to(ROOT)}"
        for path in required
        if not path.is_file()
    ]

    rendering = "\n".join(
        path.read_text(encoding="utf-8")
        for path in (LIB / "src" / "rendering").rglob("*.dart")
    )
    animation_options = {
        "blink",
        "lookAround",
        "idle",
        "smoke",
        "hairWind",
        "jewelrySwing",
        "glowPulse",
        "auraPulse",
        "particles",
    }
    missing_animations = sorted(
        option
        for option in animation_options
        if f"'{option}'" not in rendering and f'"{option}"' not in rendering
    )
    if missing_animations:
        errors.append(
            "animation options without a renderer reference: "
            + ", ".join(missing_animations)
        )

    server_path = ROOT / "bin" / "avatar_editor_server.dart"
    server = server_path.read_text(encoding="utf-8") if server_path.is_file() else ""
    for route in (
        "/api/catalog",
        "/api/default-request",
        "/api/avatar",
        "/api/animation/clip",
        "/api/export/png",
        "/api/export/svg",
        "/api/save",
    ):
        if route not in server:
            errors.append(f"server route missing: {route}")
    for asset in ("/player.js", "/player.css"):
        if asset not in server:
            errors.append(f"server static asset missing: {asset}")

    html_path = ROOT / "web" / "index.html"
    html = html_path.read_text(encoding="utf-8") if html_path.is_file() else ""
    # The avatar player remains SVG-based. A canvas is permitted only for the
    # explicit batch-export preview, where it is the output buffer.
    if "<canvas" in html.lower() and 'id="batch-canvas"' not in html:
        errors.append("web editor canvas is not limited to batch export")
    for control in (
        "frame-rewind-button",
        "frame-forward-button",
        "animation-scrubber",
        "animation-loop",
        "animation-track",
        "preview-zoom",
    ):
        if f'id="{control}"' not in html:
            errors.append(f"compact player control missing: {control}")

    app_path = ROOT / "web" / "app.js"
    app_js = app_path.read_text(encoding="utf-8") if app_path.is_file() else ""
    quick_controls = {"colors.paletteStyle", "colors.colorBudget"}
    hardcoded = [
        field_id
        for field_id in field_ids
        if field_id in app_js and field_id not in quick_controls
    ]
    if hardcoded:
        errors.append(
            "frontend hardcodes catalog fields instead of using bindings: "
            + ", ".join(hardcoded[:10])
        )
    for obsolete in ("function toggleAnimation", "function startAnimation"):
        if obsolete in app_js:
            errors.append(f"obsolete duplicate player controller remains: {obsolete}")

    player_path = ROOT / "web" / "player.js"
    player_js = (
        player_path.read_text(encoding="utf-8") if player_path.is_file() else ""
    )
    if "MutationObserver" in player_js:
        errors.append("player must not synchronize state through MutationObserver")
    if "/api/animation/clip" not in player_js:
        errors.append("player does not use the animation clip endpoint")
    return errors


def main() -> int:
    errors, field_ids = catalog_errors()
    errors.extend(project_contract_errors(field_ids))
    for path in dart_files():
        errors.extend(delimiter_errors(path))
        errors.extend(import_errors(path))
    if errors:
        print("STATIC AUDIT FAILED")
        for error in errors:
            print(f"- {error}")
        return 1
    print("STATIC AUDIT PASSED")
    print("- 30 merged categories")
    print("- 275 referenced fields")
    print(f"- {len(dart_files())} Dart files with balanced delimiters")
    print("- all relative imports resolve")
    print("- compact player and animation clip contract present")
    print("- procedural variation and natural particle renderers present")
    print(
        "Run `dart analyze` and `dart test` in a Dart SDK environment "
        "for compiler-level validation."
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
