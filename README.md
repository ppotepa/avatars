# Avatar Genome

A deterministic, reusable Dart library for generating layered 48×48 pixel-art avatars from a textual **genome seed**.

The package is a domain-oriented port of the Avatar Graph V4.1 HTML prototype. It retains the complete V4.1 parameter catalog: **26 categories, 223 fields, category presets, whole-avatar presets, anatomy, hair, facial hair, clothing, armor, headwear, eyewear, face masks, jewelry, props, cybernetics, backgrounds, effects and deterministic animation phases**.

The generator core has no Flutter, DOM, `dart:ui` or platform-channel dependency.

## Local web editor

This iteration also includes a small dependency-free Dart HTTP server and a
metadata-driven browser editor. Run:

```powershell
scripts/run_server.ps1
```

Then open `http://127.0.0.1:8080`. Linux/macOS users can run
`./scripts/run_server.sh`.

The frontend does not contain a handwritten list of avatar properties.
`AvatarPropertyRegistry` exposes eight request/settings bindings and creates a
generic binding for every one of the 223 fields in `ParameterCatalog.v41`. The
server publishes the resulting grouped schema through `GET /api/catalog`, and
the UI creates controls, presets, locks, automatic values and source labels from
that schema.

Dart runtime mirrors are deliberately not used because they are unavailable in
Flutter AOT. The metadata registry preserves reflection-like automatic discovery
while remaining compatible with Android, iOS and desktop builds.

The editor persists `AvatarRequest`, not only the resolved genome. It supports
live SVG preview, request/result JSON, PNG/SVG downloads, category rerolls,
parameter/category locks, whole/category presets and optional server-side save
packages under `output/avatars`. See
[docs/EDITOR_SERVER.md](docs/EDITOR_SERVER.md) and
[docs/BINDING_ARCHITECTURE.md](docs/BINDING_ARCHITECTURE.md).

## Package entry points

```dart
import 'package:avatar_genome/avatar_genome.dart';
```

Use this entry point for the platform-independent generator, indexed image buffers, JSON, SVG and RGBA output.

```dart
import 'package:avatar_genome/avatar_genome_io.dart';
```

Use this entry point on Android, iOS and desktop when PNG and sprite-sheet encoding are required. It adds the small `dart:io` adapter without coupling the generator core to it.

## Generate an avatar

```dart
final generator = AvatarGenerator();

final result = generator.generate(
  const AvatarRequest(
    seed: 'player-42',
    settings: GenomeSettings(
      presentation: AvatarPresentation.neutral,
      fantasy: FantasyLevel.moderate,
    ),
  ),
);

print(result.imageHash);
print(result.genome.values['hair.preset']);
print(result.validation.isValid);
```

The same request produces the same genome and indexed pixel buffer on every supported Dart platform.

## Result contract

`AvatarResult` contains:

- `AvatarGenome` — all resolved parameter values and their sources;
- `AvatarLayout` — derived landmarks, attachment slots and graph snapshot;
- `AvatarPalette` — a semantic 32-color palette;
- `IndexedImage` — a compact 48×48 buffer of palette indices;
- render layers and masks metadata;
- guard corrections and violations;
- quality metrics;
- a deterministic image hash.

The indexed image stores 2304 bytes plus the palette. PNG is an export format, not the generator's internal representation.

## Manual parameters

```dart
const request = AvatarRequest(
  seed: 'customized-user',
  overrides: <String, Object>{
    'eyes.shape': 'almond',
    'eyes.width': 4,
    'ears.shape': 'elfMedium',
    'hair.preset': 'undercut',
    'v4.eyewear': 'roundGlasses',
    'v4.armor': 'leatherArmor',
  },
);
```

Values are checked against `ParameterCatalog.v41`. Invalid values fail immediately instead of silently producing an undefined avatar.

## Presets

```dart
final presets = AvatarPresetService();
var request = const AvatarRequest(seed: 'preset-user');

request = presets.applyWholePreset(request, 'cyberpunk');
request = presets.applyCategoryPreset(request, 'eyes', 'robotic');

final result = AvatarGenerator().generate(request);
```

The preset service only modifies immutable requests. It does not know about Flutter widgets or editor state.

## Locks and category rerolls

```dart
final generator = AvatarGenerator();
final locks = AvatarLockService();
final presets = AvatarPresetService();

var request = const AvatarRequest(seed: 'first-seed');
final original = generator.generate(request);

request = locks.lockCategory(request, original.genome, 'hair');
request = request.copyWith(seed: 'second-seed');

// Hair stays fixed while all unlocked parameters use the new seed.
final changed = generator.generate(request);

// Reroll only the eyes without replacing the global seed.
request = presets.rerollCategory(request, 'eyes');
```

Each field uses a namespaced random stream derived from the root seed, category nonce and field identifier. Adding a new parameter does not shift every later random choice.

## Animation

Animation is represented as deterministic render phases, not as GIF data inside the core. The V4.1 channels include blinking, eye movement, idle motion, smoke, hair wind, jewelry swing, glow/aura pulses and particles.

```dart
final animation = AvatarGenerator().generateAnimation(
  const AvatarRequest(
    seed: 'smoker',
    overrides: <String, Object>{
      'v4.mouthProp': 'cigarette',
      'v4.effect': 'smoke',
      'v4.animation': 'smoke',
    },
  ),
  frameCount: 8,
  frameDuration: const Duration(milliseconds: 120),
);
```

For runtime playback, convert frames to Flutter images or a texture atlas. For export, `AvatarSpriteSheetCodec` produces a PNG sprite sheet and metadata.

## Flutter integration

Keep Flutter code outside the generator package. One possible adapter:

```dart
import 'dart:ui' as ui;
import 'package:avatar_genome/avatar_genome.dart';

Future<ui.Image> toFlutterImage(AvatarResult result) async {
  final rgba = const AvatarRgbaCodec().encode(result);
  final descriptor = ui.ImageDescriptor.raw(
    await ui.ImmutableBuffer.fromUint8List(rgba),
    width: result.image.width,
    height: result.image.height,
    pixelFormat: ui.PixelFormat.rgba8888,
  );
  final codec = await descriptor.instantiateCodec();
  return (await codec.getNextFrame()).image;
}
```

Display it through `RawImage` with `FilterQuality.none`. Do not create one widget per pixel.

## Export

```dart
import 'dart:io';
import 'package:avatar_genome/avatar_genome_io.dart';

final result = AvatarGenerator().generate(
  const AvatarRequest(seed: 'export-user'),
);

await File('avatar.png').writeAsBytes(
  const AvatarPngCodec(scale: 8).encode(result),
);
await File('avatar.svg').writeAsString(
  const AvatarSvgCodec(scale: 8).encode(result),
);
await File('avatar.json').writeAsString(
  const AvatarJsonCodec().encode(result),
);
```

Run the included command-line tool:

```bash
dart run tool/generate.dart --seed player-42 --scale 8 --frames 8
```

## Architecture

The dependency direction is deliberately one-way:

```text
AvatarRequest
    ↓
GenomeGenerator
    ↓
AvatarGenome
    ↓
LayoutResolver / dependency graph
    ↓
AvatarPartRenderer implementations
    ↓
AvatarCompositor
    ↓
IndexedImage
    ↓
Validator and optional codecs
```

SOLID boundaries:

- **Single responsibility:** randomization, catalog, layout, individual part renderers, composition, validation and encoding are separate modules.
- **Open/closed:** add an `AvatarPartRenderer`, `AvatarCodec`, `PaletteFactory`, `GenomeGenerator` or `AvatarValidator` without changing the public request/result contract.
- **Liskov substitution:** the generator depends on interfaces, not concrete renderers.
- **Interface segregation:** small interfaces expose only one operation.
- **Dependency inversion:** `AvatarGenerator` receives all major strategies through constructor injection.

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md), [docs/MIGRATION_FROM_HTML.md](docs/MIGRATION_FROM_HTML.md) and [docs/VALIDATION.md](docs/VALIDATION.md).

## Tests and benchmarks

```bash
dart pub get
dart analyze
dart test
dart run benchmark/avatar_benchmark.dart
```

The test suite covers catalog completeness, deterministic output, locks, presets, JSON round-trips, codecs, animation and a 256-seed invariant sample.

Generate companion and clothing animation review sheets with:

```bash
dart run tool/render_graph_matrix.dart
```

The PNGs are written to `build/render-graph-matrix`.

## Compatibility promise

Persist all of these values:

```json
{
  "schemaVersion": 1,
  "generatorVersion": "4.1.0-dart.2",
  "seed": "player-42",
  "settings": {},
  "overrides": {},
  "lockedParameters": {},
  "lockedCategories": {},
  "categoryNonces": {}
}
```

A future generator version may intentionally produce different pixels. Keep `generatorVersion` alongside the genome when long-term visual identity is required.
