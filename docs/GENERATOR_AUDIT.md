# Generator reachability and consistency audit

Date: 2026-07-30

## Scope

This audit reviews the current `main` implementation of Avatar Genome V4.1 with emphasis on:

- whether catalog options can be selected automatically;
- whether catalog options have distinct renderer behavior;
- whether planner, catalog and renderer names agree;
- whether post-processing silently removes generated features;
- whether numeric ranges expose values that automatic generation cannot reach;
- whether tests can detect regressions in reachability and rendering.

The project currently exposes 26 categories and 223 fields. The audit covered the parameter catalog, `V41GenomeGenerator`, layout resolution, anatomy, face, hair, fantasy, accessories, armor, props, backgrounds, effects, animation helpers, presets and current tests.

## Executive summary

The generator is structurally deterministic and most selectable values have a positive probability. However, the catalog is not yet fully represented by automatic generation or distinct visual behavior.

Confirmed findings:

1. **Six background variants are unreachable through automatic generation.**
2. **The post-apocalyptic background pool contains two invalid values.**
3. **Two neck variants use names that do not match the catalog, so their intended geometry is never applied.**
4. **Several catalog variants are visual aliases or have no dedicated renderer branch.**
5. **Default settings intentionally eliminate a large part of fantasy and asymmetry variation.**
6. **The composition budget strongly suppresses combinations of accessories, effects and equipment.**
7. **Numeric catalog domains are wider than automatic generation domains, so many legal values require manual overrides.**
8. **Current tests validate structure but not full option reachability or visual distinctness.**

No evidence was found that the random stream itself produces zero-probability options for ordinary select fields. Standard select options start with a positive weight, and optional V4 features retain a positive minimum weight once their group is selected.

---

## P0 — correctness defects

### 1. Unreachable automatic backgrounds

`v4.background` contains 22 options:

- `solid`
- `blockGradient`
- `verticalSplit`
- `horizontalSplit`
- `diagonalStripes`
- `checker`
- `dots`
- `pixelNoise`
- `sunset`
- `night`
- `neonCity`
- `forest`
- `space`
- `dungeon`
- `laboratory`
- `spaceship`
- `flames`
- `snowField`
- `rainCity`
- `magicAura`
- `terminal`
- `factionSymbol`

The automatic planner selects backgrounds only from fixed world-specific pools. The following valid renderer-supported values are absent from every pool and therefore cannot appear from normal seed generation:

- `diagonalStripes`
- `dots`
- `pixelNoise`
- `sunset`
- `snowField`
- `factionSymbol`

They remain available through manual overrides and presets, but not through ordinary generation.

**Recommendation:** build the background weight map from all catalog options, then apply world-specific boosts rather than replacing the candidate set with a closed list.

### 2. Invalid post-apocalyptic background candidates

The `postApocalyptic` pool contains `rust` and `dust`. Neither is a valid `v4.background` option:

- `rust` is a background color value;
- `dust` is an atmospheric effect value.

The planner filters these values out silently, leaving only `flames` and `solid`. This unintentionally reduces post-apocalyptic variety to two backgrounds.

**Recommendation:** replace invalid entries with valid thematic backgrounds such as `pixelNoise`, `sunset`, `factionSymbol`, `rainCity`, `night` or `checker`, while using `dust` through `v4.effect`.

### 3. Neck variant naming mismatch

The catalog defines neck variants:

- `tapered`
- `flared`

The anatomy renderer checks:

- `taperUp`
- `flareDown`

Those renderer branches can never execute because the strings do not exist in the catalog. Consequently, `tapered` and `flared` currently fall through to default geometry.

**Recommendation:** rename renderer cases to `tapered` and `flared`, then add targeted visual tests.

---

## P1 — reachability and variety limitations

### 4. Default fantasy setting removes automatic fantasy anatomy

The default `GenomeSettings.fantasy` is `FantasyLevel.none`. Under that setting, post-processing replaces or removes automatically selected:

- fantasy ears;
- horns;
- antennae.

This means the catalog contains many fantasy options that effectively have zero probability under the default user experience. They become available only when fantasy level is raised or when a manual override is preserved.

**Recommendation:** consider making `FantasyLevel.subtle` the default for a playful generator, or add a separate generation mode such as `classic`, `adventurous` and `anythingGoes`.

### 5. Default symmetry disables all automatic asymmetry

The default `symmetry` setting is `true`. Post-processing zeroes:

- `head.asymmetry`
- `ears.asymmetry`
- `eyes.asymmetry`
- `brows.asymmetry`
- `nose.asymmetry`
- `mouth.asymmetry`
- `shoulders.asymmetry`
- `fantasy.hornAsymmetry`
- `v4.accessoryAsymmetry`

Thus all automatic asymmetry domains are unreachable in default generation.

**Recommendation:** keep symmetry as a quality guard but introduce a low-probability natural asymmetry mode, or default to symmetry with small exceptions such as ±1 facial and accessory offsets.

### 6. Composition budget suppresses feature combinations

The planner divides optional V4 features into seven groups:

- head;
- face;
- jewelry;
- armor;
- props;
- marks;
- effects.

Depending on complexity and random mode, only a subset of groups is selected. Unselected groups are forced to `none`. Within selected groups, most groups allow only one active member; jewelry, armor and effects allow two only at high complexity.

This design improves readability, but it also means users rarely see combinations such as:

- eyewear plus a face mask;
- armor plus cape at ordinary complexity;
- effect plus aura at ordinary complexity;
- cybernetics plus scar plus marking;
- mouth prop plus shoulder prop.

**Recommendation:** replace hard group exclusion with a soft point budget. Give every feature an activation cost and permit more combinations in `diverse`, `chaotic` and `rareHeavy` modes.

### 7. Closed helmets and masks remove secondary features

Automatic conflict resolution forces:

- closed helmet → no eyewear and no ear jewelry;
- full-face mask → no mouth prop and no face piercing;
- any face mask → no mouth prop.

These constraints are sensible for readability, but some combinations could remain visually valid, for example:

- visor integrated with a futuristic helmet;
- external targeting lens on a helmet;
- ear jewelry visible below selected helmets;
- respirator with forehead or eyebrow piercing.

**Recommendation:** use compatibility matrices instead of broad all-or-nothing sets.

### 8. Legal numeric values are often not automatically reachable

Range fields define both a full legal domain and a narrower automatic domain. Examples include:

- `body.width`: legal 26–47, automatic 30–44;
- `body.mass`: legal 0–6, automatic 1–5;
- `head.width`: legal 18–30, automatic 20–28;
- `v4.complexity`: legal 0–100, automatic 25–82;
- `v4.rarityBias`: legal 0–100, automatic 5–65.

Profiles, age and bias can extend some results, but they do not guarantee all legal values become reachable.

This is not a correctness error, but it means the catalog overstates the natural generation space.

**Recommendation:** explicitly classify domains as:

- safe automatic range;
- rare automatic extremes;
- manual-only range.

For maximum variety, add a low-probability tail distribution that can reach every legal value.

---

## P1 — renderer semantic gaps and aliases

### 9. Neck variants without distinct implementation

Beyond the naming mismatch, several neck variants do not directly alter neck geometry:

- `veryShort`
- `short`
- `standard`
- `long`
- `veryLong`
- `straight`

Length is controlled independently by `neck.length`, so these select values can become labels without a guaranteed visible effect.

**Recommendation:** map each named variant to deterministic adjustments of length, width, taper and tilt, blended with numeric parameters.

### 10. Some eye shape names converge to the same fallback geometry

The face renderer has dedicated branches for many eye shapes, but remaining shapes use ellipse-based fallback geometry. Depending on width and height, options such as `oval`, `wide`, `cartoon` and some default shapes can become visually close or identical.

**Recommendation:** create a visual signature test for each eye shape and require a minimum pixel difference between named variants at a reference request.

### 11. Clothing neckline aliases

`round` is handled by the generic/default ellipse branch, as are some high-neck cases. This makes `round`, `high` and parts of the default behavior less distinct than their catalog labels imply.

**Recommendation:** add dedicated masks for `round`, `high` and `turtleneck`, with distinct depth and collar treatment.

### 12. Armor variants share a generic base

Every advanced armor or garment begins as a clone of the same torso mask. Many variants differ only through a small accent pattern. This is valid technically, but several catalog choices may feel like palette/detail aliases rather than distinct silhouettes.

Most affected are ordinary garments without dedicated geometry beyond a seam or accent:

- `tshirt`
- `sweater`
- `turtleneck`
- `shirt`
- `blazer`
- `uniform`
- `vest`

**Recommendation:** add silhouette-level differences: sleeves, collars, lapels, shoulder cuts, hems and bulk profiles.

### 13. Headwear fallback makes helmet families similar

Non-hat headwear falls into a shared helmet renderer. Individual helmet options receive some accents, but many use the same ellipse and rectangle base.

**Recommendation:** define helmet silhouette families and require each catalog helmet to select a family explicitly.

### 14. Aura variants partly share identical base geometry

All non-`none` auras start from the same ring. Only selected styles add extra details. `soft` and `dark`, for example, primarily differ through palette/layer interpretation rather than geometry.

**Recommendation:** give each aura family a unique topology: halo, smoke shell, spikes, runes, arcs, flames or frost shards.

### 15. Effects use a generic fallback

Known atmospheric effects have dedicated branches, while unhandled values fall back to generic 2×2 particles. Current catalog options are mostly handled, but this fallback can conceal future catalog/renderer drift.

**Recommendation:** replace the fallback with an explicit assertion in tests and require every effect option to be enumerated.

---

## P2 — probability and user-experience observations

### 16. Fantasy options technically have positive weight before correction

Ordinary select options start with weight 10. Fantasy ears, horns and antennae are multiplied down in realistic mode but remain positive before post-processing. Post-processing then removes them under `FantasyLevel.none`.

The effective probability is therefore zero despite a nonzero sampling weight, which wastes random choices and complicates reasoning.

**Recommendation:** apply eligibility before sampling. Do not sample an option that will certainly be removed.

### 17. Optional features have positive conditional probability

When an optional group/member is selected, `_featureChoice` assigns each non-`none`, non-`auto` option a base weight of 1 and clamps final weights to at least 0.05. Therefore all listed optional values are conditionally reachable.

The limiting factor is group/member activation, not option weight.

### 18. Archetypes remain reachable through fallback weight

Every archetype option receives either an explicit contextual weight or fallback weight 1. No archetype was found to be mathematically unreachable.

However, world-specific weighting means some archetypes can be extremely rare outside their intended worlds.

### 19. Hashing and deterministic forks are structurally stable

Each field uses a namespaced random stream derived from generator version, seed, category nonce and field identifier. Adding fields should not shift unrelated choices. This is a strong design decision for reproducibility.

A remaining risk is that the root seed space is still based on a 32-bit FNV hash even though rendered image identifiers are now 48-bit. Distinct textual seeds can collide at the generator root and produce identical genomes.

**Recommendation:** migrate root seed derivation to a wider deterministic state, with an explicit generator version bump because output compatibility will change.

---

## Test coverage gaps

Current tests verify catalog size, unique field IDs, non-empty select options, valid automatic ranges, determinism and various renderer invariants. They do not establish full reachability.

The following tests should be added:

### A. Catalog-to-renderer option coverage

For every select field:

1. override the field with every catalog option;
2. generate at 48, 64, 80 and 96;
3. assert no exception and no hard validation violation;
4. assert the resulting value remains catalog-valid;
5. for visual fields, assert a non-empty semantic mask or a documented intentional no-op.

### B. Automatic reachability sampling

Generate a large deterministic seed corpus across:

- every fantasy level;
- symmetry on/off;
- every presentation;
- age bands;
- random modes;
- complexity and rarity bands.

Track every select option observed. The test should report unobserved values rather than rely only on a hard seed count.

### C. Planner domain validation

Every literal candidate inserted by planner maps must be checked against the corresponding catalog field at test time. This would have caught `rust` and `dust` in the background pool.

### D. Visual distinctness snapshots

For each named visual option, compare rendered pixel hashes against sibling variants under a controlled request. Intentional aliases must be documented; accidental identical outputs should fail.

### E. Preset validation

For every category and whole-avatar preset:

- every field ID must exist;
- every value must be accepted by the catalog;
- the request must generate without a hard violation;
- the preset should change at least one rendered pixel compared with a baseline.

### F. Extreme range generation

For each numeric field, test legal minimum and maximum through manual overrides. This is needed because many limits interact and may be corrected by geometry guards.

### G. Fuzz/invariant test

Run at least 10,000 deterministic requests and assert:

- no exceptions;
- valid dimensions;
- palette indices remain in range;
- no hard violations for automatically generated requests;
- eyes and mouth remain within declared safety thresholds when visible;
- layer and component counts stay within configured budgets;
- identical requests produce identical results.

---

## Recommended implementation order

### Phase 1 — correctness

1. Fix `tapered` / `flared` neck renderer names.
2. Replace invalid post-apocalyptic background values.
3. Make all background catalog options eligible with positive probability.
4. Add planner candidate validation tests.

### Phase 2 — reachability assurance

5. Add full catalog override generation tests.
6. Add automatic reachability reporting over a deterministic seed matrix.
7. Add preset validation for all category and whole-avatar presets.
8. Add a 10,000-request invariant fuzz test suitable for CI or nightly execution.

### Phase 3 — more playful output

9. Introduce soft point-based composition instead of hard group exclusion.
10. Add an `anythingGoes` or `adventurous` generation profile.
11. Permit low-level natural asymmetry by default.
12. Give visual aliases distinct geometry.
13. Add rare tails to numeric generation so every legal value can occur.

### Phase 4 — seed-space improvement

14. Replace 32-bit root seed derivation with a wider deterministic seed state.
15. Bump generator version and document the visual compatibility break.

---

## Final assessment

The generator has a solid deterministic architecture and a broad catalog, but it does not yet deliver the full advertised combinatorial space through ordinary random generation.

The most important distinction is:

- **catalog-reachable manually:** nearly all options;
- **automatically reachable:** most options, with confirmed background exceptions and settings-dependent exclusions;
- **visually distinct:** not guaranteed for every named variant;
- **fully regression-tested:** not yet.

Addressing Phase 1 and Phase 2 will make reachability measurable and prevent future drift. Phase 3 will have the greatest effect on user enjoyment and perceived variety.