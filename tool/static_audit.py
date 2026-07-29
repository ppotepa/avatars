#!/usr/bin/env python3
"""Dependency-free structural audit for environments without a Dart SDK.

This is intentionally not a replacement for `dart analyze` or `dart test`.
It checks the generated catalog, local imports, lexical delimiter balance and
that every V4.1 parameter identifier is referenced outside the generated JSON.
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


def dart_files() -> list[Path]:
    return sorted([*LIB.rglob("*.dart"), *(ROOT / "test").rglob("*.dart"), *(ROOT / "example").rglob("*.dart"), *(ROOT / "benchmark").rglob("*.dart"), *(ROOT / "tool").glob("*.dart"), *(ROOT / "bin").glob("*.dart")])


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
                state = "line_comment"; output.extend("  "); i += 2; continue
            if c == "/" and n == "*":
                state = "block_comment"; output.extend("  "); i += 2; continue
            if c in "'\"":
                quote = c
                triple = source[i:i + 3] == c * 3
                state = "string"
                length = 3 if triple else 1
                output.extend(" " * length); i += length; continue
            output.append(c); i += 1; continue
        if state == "line_comment":
            if c == "\n": state = "code"; output.append(c)
            else: output.append(" ")
            i += 1; continue
        if state == "block_comment":
            if c == "*" and n == "/":
                state = "code"; output.extend("  "); i += 2
            else:
                output.append("\n" if c == "\n" else " "); i += 1
            continue
        if state == "string":
            delimiter = quote * (3 if triple else 1)
            if source.startswith(delimiter, i):
                output.extend(" " * len(delimiter)); i += len(delimiter); state = "code"; continue
            if c == "\\" and i + 1 < len(source):
                output.extend("  "); i += 2; continue
            output.append("\n" if c == "\n" else " "); i += 1
    return "".join(output)


def delimiter_errors(path: Path) -> list[str]:
    source = strip_comments_and_strings(path.read_text(encoding="utf-8"))
    pairs = {')': '(', ']': '[', '}': '{'}
    stack: list[tuple[str, int]] = []
    errors: list[str] = []
    for index, char in enumerate(source):
        if char in "([{": stack.append((char, index))
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


def catalog_errors() -> list[str]:
    data = json.loads(CATALOG.read_text(encoding="utf-8"))
    categories = data["categories"]
    fields = [field for category in categories for field in category["fields"]]
    errors: list[str] = []
    ids = [field["id"] for field in fields]
    if len(categories) != 26: errors.append(f"catalog categories: expected 26, got {len(categories)}")
    if len(fields) != 223: errors.append(f"catalog fields: expected 223, got {len(fields)}")
    if len(ids) != len(set(ids)): errors.append("catalog contains duplicate field identifiers")

    library_text = "\n".join(
        path.read_text(encoding="utf-8")
        for path in (LIB / "src").rglob("*.dart")
        if path != GENERATED
    )
    unreferenced = [field_id for field_id in ids if f"'{field_id}'" not in library_text and f'"{field_id}"' not in library_text]
    if unreferenced:
        errors.append("catalog fields without a direct library reference: " + ", ".join(unreferenced))

    generated = GENERATED.read_text(encoding="utf-8")
    match = re.search(r"r\'\'\'\n(.*)\n\'\'\';", generated, re.S)
    if match is None:
        errors.append("generated catalog JSON raw string was not found")
    else:
        embedded = json.loads(match.group(1))
        if embedded != data:
            errors.append("generated catalog JSON does not match tool/catalog_v41.json")
    return errors


def project_contract_errors() -> list[str]:
    required: list[Path] = [
        ROOT / "lib" / "avatar_genome.dart",
        ROOT / "lib" / "avatar_genome_io.dart",
        ROOT / "README.md",
        ROOT / "docs" / "ARCHITECTURE.md",
        ROOT / "docs" / "MIGRATION_FROM_HTML.md",
        ROOT / "docs" / "PARAMETERS.md",
        ROOT / "docs" / "VALIDATION.md",
        ROOT / "docs" / "reference" / "avatar-generator-v4.1.html",
        ROOT / "docs" / "EDITOR_SERVER.md",
        ROOT / "docs" / "BINDING_ARCHITECTURE.md",
        ROOT / "bin" / "avatar_editor_server.dart",
        ROOT / "web" / "index.html",
        ROOT / "web" / "app.js",
        ROOT / "web" / "styles.css",
        ROOT / "scripts" / "run_server.ps1",
        ROOT / "scripts" / "run_server.bat",
        ROOT / "scripts" / "run_server.sh",
    ]
    errors = [f"missing required file: {path.relative_to(ROOT)}" for path in required if not path.is_file()]

    rendering = "\n".join(
        path.read_text(encoding="utf-8")
        for path in (LIB / "src" / "rendering").rglob("*.dart")
    )
    animation_options = {
        "blink", "lookAround", "idle", "smoke", "hairWind",
        "jewelrySwing", "glowPulse", "auraPulse", "particles",
    }
    missing_animations = sorted(
        option for option in animation_options
        if f"'{option}'" not in rendering and f'"{option}"' not in rendering
    )
    if missing_animations:
        errors.append("animation options without a renderer reference: " + ", ".join(missing_animations))

    server = (ROOT / "bin" / "avatar_editor_server.dart").read_text(encoding="utf-8") if (ROOT / "bin" / "avatar_editor_server.dart").is_file() else ""
    for route in ("/api/catalog", "/api/default-request", "/api/avatar", "/api/export/png", "/api/export/svg", "/api/save"):
        if route not in server:
            errors.append(f"server route missing: {route}")

    html = (ROOT / "web" / "index.html").read_text(encoding="utf-8") if (ROOT / "web" / "index.html").is_file() else ""
    if "<canvas" in html.lower():
        errors.append("web editor must not use canvas")

    app_js = (ROOT / "web" / "app.js").read_text(encoding="utf-8") if (ROOT / "web" / "app.js").is_file() else ""
    data = json.loads(CATALOG.read_text(encoding="utf-8"))
    field_ids = [field["id"] for category in data["categories"] for field in category["fields"]]
    hardcoded = [field_id for field_id in field_ids if field_id in app_js]
    if hardcoded:
        errors.append("frontend hardcodes catalog fields instead of using bindings: " + ", ".join(hardcoded[:10]))
    return errors


def main() -> int:
    errors = catalog_errors()
    errors.extend(project_contract_errors())
    for path in dart_files():
        errors.extend(delimiter_errors(path))
        errors.extend(import_errors(path))
    if errors:
        print("STATIC AUDIT FAILED")
        for error in errors: print(f"- {error}")
        return 1
    print("STATIC AUDIT PASSED")
    print("- 26 categories")
    print("- 223 referenced fields")
    print(f"- {len(dart_files())} Dart files with balanced delimiters")
    print("- all relative imports resolve")
    print("Run `dart analyze` and `dart test` in a Dart SDK environment for compiler-level validation.")
    return 0

if __name__ == "__main__":
    sys.exit(main())
