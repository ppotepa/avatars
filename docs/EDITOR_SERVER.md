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

- eight bindings expose `AvatarRequest` and `GenomeSettings` properties;
- every field in `ParameterCatalog.v41` automatically becomes a generic
  `CatalogPropertyBinding`;
- the frontend receives the schema from `GET /api/catalog` and never contains a
  handwritten anatomy/wearables field list;
- `AvatarRequestBinder` performs generic set, reset, lock and unlock operations;
- `AvatarPropertyRegistry.stateToJson` exposes resolved values and their
  automatic/manual/locked source.

Adding a field to the catalog automatically exposes it in the server UI.

## API

### `GET /api/health`

Returns the generator/catalog version and field count.

### `GET /api/catalog`

Returns request bindings, grouped catalog categories, field metadata, options,
ranges, category presets and whole-avatar presets.

### `GET /api/default-request`

Returns a serializable default `AvatarRequest`.

### `POST /api/avatar`

Accepts either a raw `AvatarRequest` or a wrapper:

```json
{
  "request": {},
  "actions": [
    {"op": "set", "id": "hair.length", "value": 5},
    {"op": "reset", "id": "eyes.width"},
    {"op": "rerollCategory", "category": "hair"}
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
warnings, and can advance `request.phase` continuously to preview the selected
animation without a separate animation API.

### `POST /api/export/png`

Returns `image/png`. The body accepts `request` and optional `scale`.

### `POST /api/export/svg`

Returns `image/svg+xml`.

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
