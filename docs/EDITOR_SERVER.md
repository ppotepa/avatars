# Local editor server

The project includes a dependency-free local HTTP server written with `dart:io`.
It serves a metadata-driven web editor and uses the existing `AvatarGenerator`
directly.

## Run

Windows PowerShell:

```powershell
scripts/run_server.ps1
```

Windows CMD:

```bat
scripts\run_server.bat
```

Linux/macOS:

```bash
./scripts/run_server.sh
```

Open `http://127.0.0.1:8080`.

## Compact media player

The left editor panel contains one media-style animation deck. It provides:

- fixed first, rewind, previous, play/pause, stop, next, forward and last
  controls;
- a scrubber, frame/time display and loop switch;
- current, idle, talk, laugh, storm and fire preview tracks;
- keyboard control with Space, arrows, Shift+arrows, Home and End;
- one render-resolution selector and an independent fit/1x/2x/4x preview zoom.

The player requests a complete animation clip once through
`POST /api/animation/clip`. Playback and seeking then operate entirely on the
returned SVG frame cache, so normal playback does not issue one avatar request
per frame.

## Binding instead of mirrors

`dart:mirrors` is not available in Flutter AOT builds. The editor therefore uses
`AvatarPropertyRegistry`, a metadata-driven binding registry:

- fourteen bindings expose `AvatarRequest`, `GenomeSettings` and
  `AvatarRenderSettings` properties;
- all 274 merged V4.1 + V4.2 catalog fields automatically become generic
  `CatalogPropertyBinding` instances;
- the frontend receives the schema from `GET /api/catalog` and never contains a
  handwritten anatomy, expression, atmosphere or wearables field list;
- `AvatarRequestBinder` performs generic set, reset, lock and unlock operations;
- `AvatarPropertyRegistry.stateToJson` exposes resolved values and their
  automatic/manual/locked source.

Adding a field or category preset to the catalog automatically exposes it in the
server UI. V4.2 therefore adds expression, halo, adornment, weather, cosmic,
flame, cinematic-event and expressive-motion controls without a parallel
frontend implementation.

## V4.2 editor categories

The server groups the additive controls into:

- `expressionV42` — face, eyes, eyebrows, mouth, emotion marks and face motion;
- `adornmentV42` — halos, head details, creature traits, symbols, wings,
  companions and relics;
- `atmosphereV42` — weather, cosmic layers, flames, ambient overlays and events;
- `motionV42` — gaze, eyebrow, pose and event motion.

Each category includes presets. For example, the expression category exposes
happy, laugh, angry, sleepy and smug presets, while the atmosphere category
exposes storm, inferno, cosmic and dream combinations.

## API

### `GET /api/health`

Returns generator version `4.2.0-dart.3`, catalog version `4.2` and the merged
field count.

### `GET /api/catalog`

Returns request bindings, all 30 grouped catalog categories, field metadata,
options, ranges, category presets and whole-avatar presets.

### `GET /api/default-request`

Returns a serializable default `AvatarRequest`.

### `POST /api/avatar`

Accepts either a raw `AvatarRequest` or a wrapper:

```json
{
  "request": {},
  "actions": [
    {"op": "set", "id": "v4.expression", "value": "laugh"},
    {"op": "set", "id": "v4.halo", "value": "runicHalo"},
    {"op": "categoryPreset", "category": "atmosphereV42", "preset": "storm"},
    {"op": "rerollCategory", "category": "expressionV42"}
  ],
  "svgScale": 8,
  "includePixels": false
}
```

Supported actions:

- `set`, `reset`, `lock`, `unlock`;
- `wholePreset`, `categoryPreset`;
- `resetCategory`, `rerollCategory`;
- `lockCategory`, `unlockCategory`;
- `resetOverrides`, `resetLocks`.

The response contains the normalized request, resolved genome, result metadata,
SVG preview, validation report and property state for all bindings.

### `POST /api/animation/clip`

Returns a complete SVG animation clip in one JSON response.

```json
{
  "request": {},
  "frameCount": 16,
  "frameDurationMs": 140,
  "loop": true,
  "svgScale": 1
}
```

The response contains `width`, `height`, frame timing, loop state and an ordered
`frames` array. Every frame includes `index`, `phase`, `imageHash` and `svg`.

The result metrics also expose final-composition visibility for semantic parts.
The browser editor displays these ratios, face readability and visibility
warnings.

The preview exposes 48, 64, 80 and 96 pixel render profiles,
basic/enhanced/rich detail, directional lighting, shading strength, animated
backgrounds and reduced motion. Render resolution changes the generated buffer;
preview zoom changes only its CSS display size.

### `POST /api/export/png`

Returns `image/png`. The body accepts `request` and optional `scale`.

### `POST /api/export/svg`

Returns `image/svg+xml`.

### `POST /api/export/spritesheet`

Returns an animated PNG sprite sheet. The body accepts `request`,
`frameCount` (1–64), `frameDurationMs`, `columns` and `scale`. Local expressive
motion preserves stable frame bounds and does not translate the complete sprite.

### `POST /api/save`

Writes `request.json`, `avatar.json`, `avatar.svg` and `avatar.png` under
`output/avatars/<id>`.

## Procedural quality guarantees

The current generator includes automated contracts for:

- deterministic but varied face-mask construction;
- seed-level variation of armor, headwear, capes, cybernetics, props,
  companions and relics;
- particle lifetime, drift and depth without wrap-around teleportation;
- fog patches that do not become full-width scan lines;
- horizontally symmetric source-cell allocation for 64, 80 and 96 pixel
  rendering;
- stable avatar framing throughout expressive animation.

## Validation

`AvatarRequestValidator` rejects:

- unknown parameter/category identifiers;
- values outside range or select options;
- category locks containing fields from another category;
- negative category nonces;
- invalid request binding values.
