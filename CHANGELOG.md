# Changelog

## 2.0.0-rc.1 — 2026-08-05

### Correctness and API contracts

- Restored the complete default genome chain with design-intent processing.
- Added strict validation to every public generation request.
- Reject unknown overrides, locks, categories, nonces and invalid ranges.
- Preserve exact animation phases beyond the camera sampling window.
- Removed the ignored `renderer` argument and added explicit custom renderer parts.
- Reject ambiguous dependency injection when a complete pipeline is supplied.
- Added separate core, advanced, editor, IO and server entry points.

### Immutability

- Made catalog categories, fields, options, presets and lookup maps immutable.
- Encapsulated indexed image storage and added frozen image snapshots.
- Encapsulated pixel-mask storage and added frozen mask snapshots.
- Generated results now own immutable copies of images, palettes, layers and metadata.
- Result hashes are calculated from the owned snapshot and validated when supplied.

### Architecture

- Extracted `AvatarResultAssembler`, `AvatarMetricsAnalyzer` and
  `RigLayoutSnapshotBuilder`.
- Extracted a deterministic visual-correction stage.
- Split scenic, cosmic, ambient, flame, weather and background-event rendering
  into focused atmosphere components.
- Added bounded genome, layout and final-result caches with validation replay.
- Added a motion-aware camera sampling policy with a reduced-motion fast path.

### Server and resource safety

- Moved the legacy HTTP application into the library layer.
- Made the secure bootstrap the default executable.
- Added explicit origin allowlists and remote-bind opt-in.
- Disabled disk writes by default and require a token when enabled.
- Added bounded batch count, memory and worker planning policies.

### Release engineering

- Updated the package to `2.0.0-rc.1`.
- Updated the deterministic generator contract to `4.7.0-dart.1`.
- Aligned the manifest to request/result schemas `1`/`2`, catalog `4.4`,
  30 categories and 275 fields.
- Added release-contract tests, benchmark scenarios and a local release audit.

The detailed development history before this release candidate remains available
in [`docs/CHANGELOG_PRE_2_0.md`](docs/CHANGELOG_PRE_2_0.md).

## 1.1.0

- Added the metadata-driven local editor server and dynamic property bindings.
- Added strict editor request validation and generic edit/lock/reroll operations.
- Added live preview, JSON import/export and PNG/SVG output.

## 1.0.0

- Initial pure-Dart extraction of the deterministic Avatar Graph generator.
- Added deterministic genome generation, indexed rendering, animation, validation
  and serialization.
