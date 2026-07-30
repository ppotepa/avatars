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

Returns generator version `4.2.0-dart.2`, catalog version `4.2` and the merged
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

The result metrics also expose final-composition visibility for semantic parts.
The browser editor displays these ratios, face readability and visibility
warnings, and can advance `request.phase` continuously to preview face motion,
weather, flames, halos and cinematic background events without a separate
animation API.

The preview exposes native 48, 64, 80 and 96 pixel canvases, basic/enhanced/rich
detail, directional lighting, shading strength, animated backgrounds and
reduced motion. These presentation settings live under `request.rendering` and
do not change the generated genome.

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

## Validation

`AvatarRequestValidator` rejects:

- unknown parameter/category identifiers;
- values outside range or select options;
- category locks containing fields from another category;
- negative category nonces;
- invalid request binding values.
