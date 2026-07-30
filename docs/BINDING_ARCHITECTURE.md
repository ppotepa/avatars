# Property binding architecture

The editor treats three concepts separately:

1. `ParameterCatalog` is metadata and describes every generated property.
2. `AvatarRequest` is the editable, serializable intent.
3. `AvatarGenome` is the resolved result and source information.

`AvatarPropertyRegistry` unifies them for editor clients. It creates generic
bindings for all catalog fields and declarative bindings for the small fixed
request contract. This avoids runtime reflection while retaining the key
property of reflection: a new catalog field appears automatically in clients.

The preserved V4.1 source contributes 26 categories and 223 fields. The additive
V4.2 extension contributes four categories and 51 fields. The merged registry
therefore exposes 30 categories and 274 catalog bindings without adding a
handwritten control to the Dart server, HTML or JavaScript application.

Dependency direction:

```text
V4.1 catalog ─┐
              ├──→ ParameterCatalog ──→ AvatarPropertyRegistry ──→ HTTP schema / UI
V4.2 extension┘
AvatarRequest ─────→ AvatarRequestBinder ─────→ set/reset/lock
AvatarGenome ──────→ property state ──────────→ resolved values/sources
```

The browser submits binding actions rather than knowing whether a value belongs
to `settings`, the request root or `overrides`. Category presets for expressions,
halos, weather and expressive motion are delivered by the same catalog response.
