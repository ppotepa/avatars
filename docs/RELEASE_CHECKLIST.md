# Release checklist

This checklist is the manual release gate for `2.0.0-rc.2`.

## Contract

- [ ] `pubspec.yaml`, `CHANGELOG.md`, `PROJECT_MANIFEST.md` and `AvatarGenomeVersion` agree.
- [ ] Catalog reports exactly 30 categories and 275 fields.
- [ ] Request/result schemas remain 1/2.
- [ ] Every `AvatarRequest` owns deeply immutable collections.
- [ ] Result image, masks, palette, layout, graph and validation are immutable.
- [ ] Core entry point has no `dart:io`, Flutter, DOM or `dart:ui` dependency.
- [ ] Editor registry and binder are imported from `avatar_genome_editor.dart`.

## Golden approval

1. Run all tests and inspect representative avatars in the editor.
2. Generate the current vector outputs without approval:

```bash
dart run tool/update_contract_vectors.dart
```

3. Review the generated hashes and representative 48/64/80/96 images.
4. Approve the exact outputs:

```bash
dart run tool/update_contract_vectors.dart --approve
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

## Performance

- [ ] Static unique-seed, same-seed, animation and batch benchmarks are recorded.
- [ ] Reduced-motion requests use one camera sample.
- [ ] Exact high phases use at most 17 camera samples.
- [ ] Genome, layout, camera and result caches remain bounded.
- [ ] Cache hit/miss counters and shared clearing behave correctly.
- [ ] Batch requests exceeding avatar, memory or worker budgets are rejected.

## Server

- [ ] Loopback is the default bind address.
- [ ] Remote bind requires `--allow-remote`.
- [ ] Cross-origin POST requests are rejected unless explicitly allowed.
- [ ] `/api/save` is disabled by default and requires the configured token.
- [ ] Saves are written atomically through temporary files.
- [ ] Concurrent requests are bounded.
- [ ] Internal server errors do not expose exception text or stack traces.
- [ ] Health, catalog, avatar, animation, batch, manifest, ZIP and save HTTP tests pass.

## Local verification

```bash
dart format --output=none --set-exit-if-changed lib test bin tool example benchmark
dart analyze --fatal-infos
dart test --reporter expanded
dart run tool/update_contract_vectors.dart --approve
dart run tool/release_audit.dart
dart run benchmark/avatar_benchmark.dart
```

CI is not required for this release process; these commands are intended for the maintainer's local machine.
