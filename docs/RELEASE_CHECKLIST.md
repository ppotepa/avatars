# Release checklist

This checklist is the manual release gate for `2.0.0-rc.2`.

## One-command Windows gate

Run from the repository root after reviewing representative avatars:

```powershell
.\scripts\release_gate.bat -ApproveGolden
```

The gate resolves dependencies, verifies formatting, runs static analysis and all tests, records approved golden vectors, runs the release audit and benchmark, then starts the server and checks `/api/health`.

Run without `-ApproveGolden` to refresh the vectors without approving them. The script intentionally stops after writing unapproved values so visual review cannot be skipped.

Use `-SkipBenchmark` only for an intermediate verification run. A final release run must include the benchmark.

## Contract

- [ ] `pubspec.yaml`, `CHANGELOG.md`, `PROJECT_MANIFEST.md` and `AvatarGenomeVersion` agree.
- [ ] Catalog reports exactly 30 categories and 275 fields.
- [ ] Request/result schemas remain 1/2.
- [ ] Every `AvatarRequest` owns deeply immutable collections.
- [ ] Result image, masks, palette, layout, graph, metadata and validation are immutable.
- [ ] Core entry point has no `dart:io`, Flutter, DOM or `dart:ui` dependency.
- [ ] Every local Dart `import`, `export` and `part` target exists.
- [ ] Advanced, editor, IO and server entry points compile independently.

## Golden approval

1. Run all tests and inspect representative avatars in the editor.
2. Refresh vectors without approval:

```powershell
.\scripts\release_gate.bat -SkipBenchmark
```

3. Review the generated hashes and representative 48/64/80/96 images.
4. Run the final gate with approval:

```powershell
.\scripts\release_gate.bat -ApproveGolden
```

- [ ] Every vector contains `expected.imageHash` and `expected.genomeFingerprint`.
- [ ] The fixture has `"approved": true`.
- [ ] Windows and Linux produce identical approved values.

## Correctness

- [ ] Same request produces the same genome and image hash in repeated runs.
- [ ] Direct `RigClipPipeline.renderSingle` matches clip phases 16 and above.
- [ ] Unknown overrides, locks, categories and nonces fail immediately.
- [ ] Custom renderer parts are honored and pipeline/dependency conflicts are rejected.
- [ ] Visual corrections run exactly once per raw frame.
- [ ] Split atmosphere is the default pipeline renderer and matches the legacy output.

## Performance

- [ ] Static unique-seed, same-seed, animation and batch benchmarks are recorded.
- [ ] Reduced-motion requests use one camera sample.
- [ ] Exact high phases use at most 17 camera samples.
- [ ] Genome, layout, camera and result caches remain bounded.
- [ ] Cache hit/miss counters and shared clearing behave correctly.
- [ ] Batch requests exceeding avatar, sheet or total working-memory budgets are rejected.

## Server

- [ ] Loopback is the default bind address.
- [ ] Remote bind requires `--allow-remote` and preserves valid hostnames.
- [ ] Cross-origin requests are rejected unless explicitly allowed.
- [ ] HTTP and HTTPS origins are not treated as the same origin.
- [ ] `/api/save` is disabled by default and requires the configured token.
- [ ] Save bundles are serialized per ID and files are replaced atomically.
- [ ] Concurrent requests and concurrent batches are bounded.
- [ ] Internal server errors do not expose exception text or stack traces.
- [ ] Health, catalog, avatar, animation, batch, manifest, ZIP and save HTTP tests pass.

## Equivalent manual commands

```powershell
dart pub get
dart format --output=none --set-exit-if-changed lib test bin tool example benchmark
dart analyze --fatal-infos
dart test --reporter expanded
dart run tool/update_contract_vectors.dart --approve
dart run tool/release_audit.dart
dart run benchmark/avatar_benchmark.dart
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\smoke_server.ps1
```

CI is not required for this release process; these commands are intended for the maintainer's local machine.
