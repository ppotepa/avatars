# Project manifest

- Package: `avatar_genome`
- Package version: `2.0.0-rc.1`
- Generator version: `4.7.0-dart.1`
- Request/result schemas: `1` / `2`
- Catalog version: `4.4`
- Palette version: `p32.dynamic.1`
- Native canvases: `48 × 48`, `64 × 64`, `80 × 80`, `96 × 96`
- Palette limit: `32` colors
- Catalog: `30` categories / `275` fields
- Runtime dependencies: none
- Local editor: dependency-free `dart:io` HTTP server + vanilla HTML/CSS/JavaScript
- Secure server entry point: origin allowlist, remote-bind opt-in, token-gated disk writes
- Editor bindings: `14` request/settings/rendering fields + `275` catalog fields
- Core platform dependencies: none (`dart:ui`, Flutter and DOM are not imported)
- Optional IO entry point: PNG and sprite-sheet encoding through `dart:io`
- Optional server entry point: `avatar_genome_server.dart`
- Result cache: bounded deterministic LRU, disabled with `cacheCapacity: 0`
- Camera policy: animation-safe envelope plus reduced-motion single-frame path

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
- immutable catalog and generated result snapshots;
- split result assembly, metric analysis, rig layout snapshots and atmosphere rendering;
- tests, benchmark, CLI tool, release audit and catalog-generation tool;
- local API, dynamic property editor, import/export and save bundle scripts.

See `docs/RELEASE_CHECKLIST.md` for local verification before tagging.
