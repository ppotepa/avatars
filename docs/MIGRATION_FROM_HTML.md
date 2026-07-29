# Migration from the V4.1 HTML prototype

## What was retained

- the complete 26-category, 223-field parameter catalog;
- whole-avatar and category presets;
- deterministic seed generation;
- category reroll nonces;
- parameter and category locks;
- presentation, age, fantasy and symmetry settings;
- anatomy and face geometry;
- hair, balding, facial hair and skin details;
- clothing, armor, headwear, eyewear, masks and jewelry;
- props, cybernetics, markings, effects, backgrounds and animation phases;
- dependency graph, landmarks, layers, palette and guard reports;
- PNG, SVG, JSON and sprite-sheet output.

## What changed

### DOM was removed

The HTML prototype used DOM elements for its preview. The Dart core only returns an indexed pixel buffer. Flutter or another host decides how to display it.

### UI state was removed

Sliders, collapsible panels and buttons do not belong to the generator. The catalog exposes enough metadata for an application to rebuild the editor.

### Export became adapters

JSON, SVG, RGBA and PNG are separate codecs. Generation never creates a file or calls a platform API.

### JavaScript objects became immutable contracts

Requests, genomes, layouts and results are typed Dart models. Locks and presets create new requests rather than mutating shared UI state.

### Randomization became namespaced

Every automatic field uses a stable stream derived from the seed and field ID. Category rerolls only advance that category's nonce.

## Pixel compatibility

This is a functional port, not a byte-for-byte execution of JavaScript. It preserves the V4.1 domain model, available options and procedural behavior, but the rewritten integer rasterizers are the source of truth for the Dart generator version. Persist `generatorVersion` when exact historical reproduction is required.

## Suggested Flutter package layout

```text
packages/
  avatar_genome/         # this package
  avatar_genome_flutter/ # optional ui.Image and widget adapters
apps/
  avatar_editor/
```

The Flutter adapter should depend on this package, never the reverse.
