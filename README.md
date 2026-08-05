# Avatar Genome

Deterministic, reusable Dart library for generating layered pixel-art avatars from a textual seed. Native output sizes are 48×48, 64×64, 80×80 and 96×96.

Current release candidate:

- package: `2.0.0-rc.1`;
- generator: `4.7.0-dart.1`;
- catalog: `4.4`;
- request/result schemas: `1` / `2`;
- catalog size: 30 categories and 275 fields.

The generator core has no Flutter, DOM, `dart:ui` or platform-channel dependency.

## Entry points

```dart
import 'package:avatar_genome/avatar_genome.dart';
```

Core generator, request/result models, catalog, validation and platform-independent codecs.

```dart
import 'package:avatar_genome/avatar_genome_advanced.dart';
```

Advanced rendering, masks, rig, camera and custom renderer contracts.

```dart
import 'package:avatar_genome/avatar_genome_editor.dart';
```

Metadata-driven editor bindings and editor service.

```dart
import 'package:avatar_genome/avatar_genome_io.dart';
```

PNG and sprite-sheet encoding through `dart:io`.

```dart
import 'package:avatar_genome/avatar_genome_server.dart';
```

Local-server configuration, origin policy and bounded batch controller.

## Generate an avatar

```dart
final generator = AvatarGenerator();
final result = generator.generate(
  const AvatarRequest(
    seed: 'player-42',
    settings: GenomeSettings(
      fantasy: FantasyLevel.moderate,
    ),
    rendering: AvatarRenderSettings(
      size: 96,
      detailLevel: AvatarDetailLevel.rich,
      shadingStrength: 3,
    ),
  ),
);

print(result.imageHash);
print(result.validation.isValid);
```

The same request and generator version produce the same genome and indexed image on every supported Dart platform.

## Runtime-owned maps

Use `AvatarRequest.frozen` when request maps come from mutable application state:

```dart
final request = AvatarRequest.frozen(
  seed: 'custom-user',
  overrides: formValues,
  lockedParameters: lockedValues,
  lockedCategories: categorySnapshots,
  categoryNonces: rerollCounters,
);
```

`AvatarRequest.fromJson`, `copyWith` and all public generator boundaries also create deeply frozen snapshots. Constant requests remain convenient when all collection arguments are constant literals.

## Overrides, locks and rerolls

```dart
var request = const AvatarRequest(seed: 'first-seed');
final generator = AvatarGenerator();
final locks = AvatarLockService();
final presets = AvatarPresetService();

final original = generator.generate(request);
request = locks.lockCategory(request, original.genome, 'hair');
request = request.copyWith(seed: 'second-seed');
request = presets.rerollCategory(request, 'atmosphereV42');

final changed = generator.generate(request);
```

Unknown field IDs, categories, nonce keys and invalid values fail at the public API boundary.

## Animation

```dart
final animation = AvatarGenerator().generateAnimation(
  const AvatarRequest(
    seed: 'storm-mage',
    overrides: <String, Object>{
      'v4.faceAnimation': 'laugh',
      'v4.weather': 'heavyRain',
      'v4.backgroundEvent': 'lightningBranch',
    },
  ),
  frameCount: 24,
  frameDuration: const Duration(milliseconds: 100),
);
```

Direct requests for phases above 15 resolve to the matching animation frame. Reduced-motion phase zero uses a single-frame camera sampling path.

## Custom renderers

```dart
final generator = AvatarGenerator(
  parts: <AvatarPartRenderer>[
    ...RigClipPipeline.defaultParts,
    const MyBadgeRenderer(),
  ],
);
```

Passing a complete `RigClipPipeline` together with pipeline-owned dependencies or `parts` is rejected instead of silently creating an inconsistent dependency graph.

## Result contract

`AvatarResult` contains the resolved genome, layout and graph snapshot, palette, indexed image, frozen render layers, validation report, quality metrics, effective adjustments and a deterministic 48-bit image hash.

Generated images, masks, palettes, metadata and animation frame lists are exposed as independent snapshots. Caller mutations cannot invalidate an existing result hash.

## Local web editor

Start the server:

```bash
dart run bin/avatar_editor_server.dart
```

Then open `http://127.0.0.1:8080`.

Security defaults:

- loopback bind only;
- remote bind requires `--allow-remote`;
- no wildcard CORS;
- cross-origin requests require an explicit `--allow-origin`;
- `/api/save` is disabled unless `--enable-save` and a minimum 16-character `--save-token` are supplied;
- batch rendering is limited by avatar count, RGBA memory and worker budgets.

Example:

```bash
dart run bin/avatar_editor_server.dart \
  --enable-save \
  --save-token local-development-token
```

## Architecture

```text
AvatarRequest
    ↓
AvatarRequestValidator
    ↓
CachedGenomeGenerator → GenomeGenerator
    ↓
CachedLayoutResolver → LayoutResolver
    ↓
AvatarPartRenderer composition
    ↓
RigClipPipeline / camera
    ↓
AvatarResultAssembler
    ├─ RigLayoutSnapshotBuilder
    └─ AvatarMetricsAnalyzer
    ↓
immutable AvatarResult snapshot
```

The V4.2 atmosphere is split into scenic, cosmic, ambient, flame, weather and event renderers. Result assembly, metrics and rig graph snapshots are separate services. Caches are bounded and can be disabled for tests with `cacheCapacity: 0`.

## Local release verification

No CI pipeline is required for the release process. Run locally:

```bash
dart pub get
dart format --output=none --set-exit-if-changed lib test bin tool benchmark
dart analyze --fatal-infos
dart test --reporter expanded
dart run tool/release_audit.dart
dart run benchmark/avatar_benchmark.dart
```

See `docs/RELEASE_CHECKLIST.md`, `PROJECT_MANIFEST.md` and `CHANGELOG.md`.

## Compatibility

Persist the request JSON together with these identifiers:

```json
{
  "requestSchema": 1,
  "resultSchema": 2,
  "generatorVersion": "4.7.0-dart.1",
  "catalogVersion": "4.4",
  "seed": "player-42"
}
```

A future generator version may intentionally produce different pixels. Keep the generator version alongside persisted identities that require long-term visual stability.
