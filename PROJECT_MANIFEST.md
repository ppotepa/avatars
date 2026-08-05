# Project manifest

- Package: `avatar_genome`
- Package version: `2.0.0-rc.2`
- Generator version: `4.7.0-dart.2`
- Request/result schemas: `1` / `2`
- Catalog version: `4.4`
- Palette version: `p32.dynamic.1`
- Native canvases: `48 × 48`, `64 × 64`, `80 × 80`, `96 × 96`
- Palette limit: `32` colors
- Catalog: `30` categories / `275` fields
- Runtime dependencies: none
- Local editor: dependency-free `dart:io` HTTP server + vanilla HTML/CSS/JavaScript
- Secure server: strict HTTP origin matching, remote-bind opt-in, bounded concurrency and token-gated atomic writes
- Editor bindings: `14` request/settings/rendering fields + `275` catalog fields
- Core platform dependencies: none (`dart:ui`, Flutter and DOM are not imported)
- Optional IO entry point: PNG and sprite-sheet encoding through `dart:io`
- Optional editor entry point: `avatar_genome_editor.dart`
- Optional server entry point: `avatar_genome_server.dart`
- Request contract: deeply immutable collections in every constructor
- Result contract: frozen image, masks, palette, layout, graph, nested metadata and validation report
- Caches: canonical bounded LRU caches with hit/miss metrics and shared clearing
- Camera policy: exact phases with at most 16 envelope samples plus the requested phase
- Batch policy: bounded avatar count, sheet bytes, total working memory, isolate count and retained artifacts

## Included capabilities

- deterministic namespaced genome generation;
- presentation, age, fantasy and symmetry settings;
- overrides, whole/category presets, parameter/category locks and category rerolls;
- dependency graph, landmarks and wearable slots;
- anatomy, face, eyes, brows, nose, mouth and ears;
- modular hair, balding, facial hair and fantasy anatomy;
- clothing, armor, headwear, eyewear, masks and jewelry;
- mouth/shoulder props, cybernetics, markings, backgrounds, aura and effects;
- blink, look-around, idle, smoke, hair-wind, jewelry-swing, pulse and particle phases;
- indexed image, RGBA, SVG, JSON, PNG and sprite-sheet output;
- resolution-aware detail, material highlights, directional shading and dithering;
- layered animated background accents and reduced-motion playback;
- constraint reporting and quality metrics;
- split result assembly, metric analysis and rig layout snapshots;
- scenic, cosmic, ambient, flame, event and weather renderers owned by the default pipeline;
- focused server routing, bounded batch controller, TTL artifact store, ZIP encoder and atomic save repository;
- unit, contract, source-integrity and real HTTP integration tests;
- benchmark, CLI tools, golden-vector updater, release audit and catalog-generation tool.

See `docs/RELEASE_CHECKLIST.md` for local verification before tagging.
