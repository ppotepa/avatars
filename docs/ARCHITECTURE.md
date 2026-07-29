# Architecture

## Goals

The library is designed for deterministic generation on Android, iOS, Windows, macOS and Linux while remaining independent of Flutter. The core uses integer geometry, typed pixel buffers, stable ordering and a versioned parameter catalog.

## Modules

### API

`AvatarRequest` and `AvatarResult` form the stable boundary. Application code should not need to instantiate internal masks or renderers.

### Catalog

`ParameterCatalog.v41` is generated from the V4.1 HTML prototype. It contains 26 categories and 223 fields, with labels, ranges, allowed options and presets. An editor can build controls directly from this metadata.

### Genome

`V41GenomeGenerator` resolves every field using:

1. locked parameter;
2. locked category snapshot;
3. manual/preset override;
4. deterministic automatic value.

Each value records its source and priority. Morphological profiles correlate related dimensions without removing manual control. V4 optional features are selected through a composition budget rather than independently enabling every accessory.

### Random streams

`RandomStream` is a defined 32-bit PRNG. Streams are forked by stable namespaces:

```text
root seed
  ├── profile
  ├── category:nonce:field
  ├── V4 identity
  ├── V4 feature groups
  └── renderer-local animation/effect streams
```

This prevents unrelated parameters from changing when another generator consumes an additional random number.

### Layout graph

`V41LayoutResolver` creates a typed dependency graph and derives:

- torso and shoulder positions;
- neck attachment points;
- head bounds;
- eye, nose and mouth landmarks;
- hair bounds;
- attachment slots for headwear, eyewear, props and back items.

Changes propagate through dependencies rather than absolute independent positions.

### Renderers

Each renderer implements `AvatarPartRenderer` and contributes named masks and layers:

- `BackgroundRenderer`
- `AnatomyRenderer`
- `ArmorRenderer`
- `FaceRenderer`
- `HairRenderer`
- `AccessoriesRenderer`
- `PropsRenderer`
- `AvatarMotionRenderer`
- `ForegroundEffectsRenderer`

The default `CompositeAvatarRenderer` can be replaced or extended by dependency injection.

### Composition

`IndexedAvatarCompositor` sorts layers stably by `z` and identifier, then writes palette indices to a 48×48 `IndexedImage`. It does not use a platform drawing API or antialiasing.

### Validation

`V41AvatarValidator` checks attachments, bounds, collisions, component continuity, palette limits and excessive isolated pixels. `ConstraintEngine` records corrections and violations. Disabling the guard also disables corrections, which is useful for diagnostics but not recommended for production.

### Encoding

Core codecs:

- JSON
- SVG
- raw RGBA

IO codecs:

- PNG
- PNG sprite sheet

The core entry point does not import `dart:io`.

## Extension examples

### Add a renderer

```dart
final generator = AvatarGenerator(
  renderer: CompositeAvatarRenderer(
    parts: <AvatarPartRenderer>[
      ...CompositeAvatarRenderer.defaultParts,
      MyBadgeRenderer(),
    ],
  ),
);
```

For a public extension package, expose a renderer that reads namespaced genome fields and adds masks through `AvatarRenderState`.

### Replace palette generation

Implement `PaletteFactory` and inject it into `AvatarGenerator`.

### Replace validation

Compose a validator that delegates to `V41AvatarValidator` and then checks application-specific constraints.

## Threading

The core stores no global mutable state. Create one generator per isolate or reuse one instance inside an isolate. For galleries, animation export or bulk generation, run work in a background isolate and return compact image bytes or serialized results.
