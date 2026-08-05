# Changelog

## 2.0.0-rc.2 — 2026-08-05

### Release hardening

- Made every `AvatarRequest` constructor deeply immutable and removed constant
  request construction from executable sources.
- Made palettes, layouts, graphs, nested genome values, validation reports,
  layer metadata and effective adjustments own immutable data.
- Made `AvatarResult` isolate every mutable dependency from callers while
  retaining zero-copy getters for already immutable domain models.
- Added canonical fingerprints and hit/miss metrics to result, genome, layout and
  camera caches, plus one public cache-clearing operation.
- Moved exact phase handling into `RigClipPipeline.renderSingle`; high phases no
  longer allocate every preceding animation frame or use modulo 16.
- Bounded camera plans to at most the 16-phase envelope plus the requested phase,
  and aligned reduced-motion cache plans with the pipeline.
- Removed the duplicate visual-correction pass and its obsolete exact-phase
  extension.
- Made the split scenic/cosmic/weather atmosphere the default owned directly by
  `RigClipPipeline`, with a regression comparison against the legacy renderer.
- Replaced the legacy HTTP monolith with a focused editor application, reusable
  request handler, bounded batch controller and atomic save repository.
- Removed wildcard CORS and internal exception text from HTTP responses; origin
  matching now enforces scheme, host and effective port.
- Added bounded concurrent request handling, an atomic pre-read batch lock,
  allowed-origin tests, token-gated save tests and real HTTP integration coverage
  on an ephemeral port.
- Added a deterministic TTL artifact store, standalone ZIP encoder and defensive
  snapshots for retained batch PNG/manifest data.
- Extended batch planning to reserve final/shard/PNG buffers, full diagnostics
  and per-isolate heap overhead before accepting work.
- Preserved configured remote hostnames for `HttpServer.bind` while keeping
  loopback and remote-bind safety checks.
- Separated property registry/binder exports into `avatar_genome_editor.dart` and
  repaired the advanced entry point after removing the exact-phase shim.
- Added release-audit source scanning for stale request constructors, old rig
  generator names, modulo phase truncation, missing exports and server ownership
  regressions.
- Added a repository-wide test that validates every local Dart import/export/part
  target before release.
- Updated the deterministic generator contract to `4.7.0-dart.2`.

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

The detailed development history before these release candidates remains available
in [`docs/CHANGELOG_PRE_2_0.md`](docs/CHANGELOG_PRE_2_0.md).

## 1.1.0

- Added the metadata-driven local editor server and dynamic property bindings.
- Added strict editor request validation and generic edit/lock/reroll operations.
- Added live preview, JSON import/export and PNG/SVG output.

## 1.0.0

- Initial pure-Dart extraction of the deterministic Avatar Graph generator.
- Added deterministic genome generation, indexed rendering, animation, validation
  and serialization.
