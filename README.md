# Avatar Genome

A deterministic, reusable Dart library for generating layered pixel-art avatars
at native 48×48, 64×64, 80×80 or 96×96 resolution from a textual **genome seed**.

The package preserves the complete Avatar Graph V4.1 catalog and adds an
expressive V4.2 extension. The merged generator exposes **30 categories and 274
fields** covering anatomy, hair, facial hair, clothing, armor, headwear,
eyewear, masks, jewelry, props, cybernetics, expressions, halos, extended horns,
creature traits, weather, cosmic layers, cinematic background events and
stable deterministic animation.

The generator core has no Flutter, DOM, `dart:ui` or platform-channel dependency.

## Local web editor

This repository includes a dependency-free Dart HTTP server and a
metadata-driven browser editor. Run:

```powershell
scripts/run_server.ps1
```

Then open `http://127.0.0.1:8080`. Linux/macOS users can run
`./scripts/run_server.sh`.

The frontend does not contain a handwritten list of avatar properties.
`AvatarPropertyRegistry` exposes the fixed request/settings/rendering bindings
and creates a generic binding for every one of the 274 merged catalog fields.
The server publishes the grouped schema through `GET /api/catalog`, and the UI
creates controls, presets, locks, automatic values and source labels from that
schema. Expression, halo, weather, cosmic, flame and motion controls therefore
appear in the server application automatically.

Dart runtime mirrors are deliberately not used because they are unavailable in
Flutter AOT. The metadata registry preserves reflection-like automatic discovery
while remaining compatible with Android, iOS and desktop builds.

The editor persists `AvatarRequest`, not only the resolved genome. It supports
live SVG preview, request/result JSON, PNG/SVG downloads, category rerolls,
parameter/category locks, whole/category presets, resolution-aware rendering,
animation sprite-sheet export and optional server-side save packages under
`output/avatars`.

See:

- [Editor server](docs/EDITOR_SERVER.md)
- [Binding architecture](docs/BINDING_ARCHITECTURE.md)
- [Expressive V4.2 features](docs/V42_FEATURES.md)

## Package entry points

```dart
import 'package:avatar_genome/avatar_genome.dart';
```

Use this entry point for the platform-independent generator, indexed image
buffers, JSON, SVG and RGBA output.

```dart
import 'package:avatar_genome/avatar_genome_io.dart';
```

Use this entry point on Android, iOS and desktop when PNG and sprite-sheet
encoding are required. It adds the small `dart:io` adapter without coupling the
generator core to it.

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
    rendering: AvatarRenderSettings(
      size: 96,
      detailLevel: AvatarDetailLevel.rich,
      lightingDirection: AvatarLightingDirection.upperLeft,
      shadingStrength: 3,
    ),
  ),
);

print(result.imageHash);
print(result.genome.values['v4.expression']);
print(result.validation.isValid);
```

The same request produces the same genome and indexed pixel buffer on every
supported Dart platform.

## Expressive V4.2 example

```dart
const request = AvatarRequest(
  seed: 'storm-laughing-mage',
  settings: GenomeSettings(
    fantasy: FantasyLevel.strong,
    symmetry: false,
  ),
  overrides: <String, Object>{
    'v4.expression': 'laugh',
    'v4.faceAnimation': 'laugh',
    'v4.mouthMotionStyle': 'laughLoop',
    'v4.halo': 'runicHalo',
    'fantasy.hornStyle': 'crystalHorns',
    'v4.weather': 'heavyRain',
    'v4.backgroundEvent': 'lightningBranch',
    'v4.cosmicLayer': 'starsDense',
    'v4.backFlames': 'blueFire',
  },
);

final animation = AvatarGenerator().generateAnimation(
  request,
  frameCount: 24,
  frameDuration: const Duration(milliseconds: 100),
);
```

The face, weather and event layers animate while the anatomical sprite remains
anchored inside a stable frame.

## Result contract

`AvatarResult` contains:

- `AvatarGenome` — all resolved parameter values and their sources;
- `AvatarLayout` — derived landmarks, attachment slots and graph snapshot;
- `AvatarPalette` — a semantic 32-color palette;
- `IndexedImage` — a compact 48×48, 64×64, 80×80 or 96×96 buffer of palette indices;
- render layers and masks metadata;
- guard corrections and violations;
- quality metrics;
- a deterministic 48-bit image hash represented by 12 hexadecimal characters.

The result-level hash covers canvas dimensions, transparency, the complete RGBA
palette and every indexed pixel. It therefore distinguishes color-only variants
as well as geometry and resolution changes. Expanding the hash from 32 to 48
bits increases the identifier space and reduces collision risk; it does not
change how genomes or avatar variations are generated.

The classic indexed image stores 2304 bytes plus the palette. Larger render
profiles retain the same genome and 32-color semantic palette while adding
resolution-aware edge lighting, material highlights and ordered dithering.

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
    'v4.expression': 'confident',
    'v4.halo': 'thinHalo',
  },
);
```

Values are checked against `ParameterCatalog.v41`, which now represents the
merged V4.1 + V4.2 catalog. Invalid values fail immediately instead of silently
producing an undefined avatar.

## Presets

```dart
final presets = AvatarPresetService();
var request = const AvatarRequest(seed: 'preset-user');

request = presets.applyWholePreset(request, 'cyberpunk');
request = presets.applyCategoryPreset(request, 'eyes', 'robotic');
request = presets.applyCategoryPreset(request, 'expressionV42', 'happy');
request = presets.applyCategoryPreset(request, 'atmosphereV42', 'storm');

final result = AvatarGenerator().generate(request);
```

The preset service only modifies immutable requests. It does not know about
Flutter widgets or editor state.

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

// Reroll only the atmosphere without replacing the global seed.
request = presets.rerollCategory(request, 'atmosphereV42');
```

Each field uses a namespaced random stream derived from the root seed, category
nonce and field identifier. Adding a new parameter does not shift every later
random choice.

## Animation

Animation is represented as deterministic render phases, not as GIF data inside
the core. V4.1 channels include blinking, eye movement, idle motion, smoke, hair
wind, jewelry swing, glow/aura pulses and particles. V4.2 adds talking and
laughing mouths, coordinated expressions, gaze and brow motion, breathing,
halos, weather, flames, cosmic motion and occasional cinematic events.

```dart
final animation = AvatarGenerator().generateAnimation(
  const AvatarRequest(
    seed: 'smoker',
    overrides: <String, Object>{
      'v4.mouthProp': 'cigarette',
      'v4.effect': 'smoke',
      'v4.animation': 'smoke',
      'v4.expression': 'smirkLeft',
    },
  ),
  frameCount: 8,
  frameDuration: const Duration(milliseconds: 120),
);
```

For runtime playback, convert frames to Flutter images or a texture atlas. For
export, `AvatarSpriteSheetCodec` produces a PNG sprite sheet and metadata.
Whole-sprite vertical translation is deliberately disabled, so animated frames
retain stable bounds.

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

Display it through `RawImage` with `FilterQuality.none`. Do not create one widget
per pixel.

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
dart run tool/generate.dart --seed player-42 --render-size 96 --detail rich --scale 1 --frames 16
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
ResolutionAwareRenderer
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

See [architecture](docs/ARCHITECTURE.md),
[migration](docs/MIGRATION_FROM_HTML.md), [validation](docs/VALIDATION.md) and
[V4.2 features](docs/V42_FEATURES.md).

## Tests and benchmarks

```bash
dart pub get
python3 tool/static_audit.py
dart analyze
dart test
dart run benchmark/avatar_benchmark.dart
```

The test suite covers catalog completeness, all selectable options and numeric
endpoints, deterministic output, locks, presets, server bindings, JSON
round-trips, codecs, expressions, weather, cinematic events, stable animation
framing and a 256-seed invariant sample. GitHub Actions runs the structural
audit, formatter, analyzer and tests for every push to `main`.

## Compatibility promise

Persist all of these values:

```json
{
  "schemaVersion": 1,
  "generatorVersion": "4.2.0-dart.2",
  "seed": "player-42",
  "settings": {},
  "overrides": {},
  "lockedParameters": {},
  "lockedCategories": {},
  "categoryNonces": {}
}
```

A future generator version may intentionally produce different pixels. Keep
`generatorVersion` alongside the genome when long-term visual identity is
required.
