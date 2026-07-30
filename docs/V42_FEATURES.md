# Expressive V4.2 feature system

V4.2 is an additive extension over the preserved Avatar Graph V4.1 catalog. The
base 26 categories and 223 fields remain intact. Four metadata-driven categories
add 51 fields, producing a merged catalog of 30 categories and 274 fields.

The browser editor does not contain a handwritten list of these controls.
`ParameterCatalog.v41` merges the V4.2 extension at startup,
`AvatarPropertyRegistry` creates bindings for every merged field, and
`GET /api/catalog` exposes those bindings to the server application. Adding or
removing a V4.2 field therefore changes the editor automatically.

## Expression

The `expressionV42` category coordinates eyes, eyebrows, mouth shape and emotion
marks. Its high-level `v4.expression` presets can be left on automatic generation
or overridden independently through:

- `v4.eyeExpression`
- `v4.browExpression`
- `v4.mouthExpression`
- `v4.emotionMark`
- `v4.expressionIntensity`
- `v4.mouthOpen`
- `v4.cheekLift`
- `v4.tearAmount`

Facial motion uses `v4.faceAnimation`, `v4.mouthMotionStyle`,
`v4.blinkStyle` and `v4.expressionSpeed`. Talking cycles through compact
phoneme-like mouth shapes. Laughing, anger, sleep, surprise and smirking use
coordinated eye, brow and mouth changes without moving the complete sprite.

## Halos, horns and adornments

The `adornmentV42` category adds:

- twenty halo styles with size, height, tilt, glow, breakage and orbit controls;
- expanded ram, bull, antelope, deer, moose, demon, dragon, crystal,
  mechanical, neon, coral and ice horn geometry;
- forehead adornments and side-head anatomy;
- creature traits such as fangs, tusks, whiskers, gills, scales, crystal growth
  and void cracks;
- symbolic rings, runes, targeting marks, music, stars, chains and thorns;
- additional wings, packs, banners, capes and back-mounted structures;
- shoulder companions and familiars;
- relics, chains, beads, pendants, seals and medals.

The generator uses world-aware probability weights and a composition budget.
These features are possible but do not all appear simultaneously.

## Weather and cinematic backgrounds

The `atmosphereV42` category separates the base scene from weather, cosmic
content, rear flames, ambient overlays and occasional events. The combination
space is therefore much larger than a single background selector.

Weather includes rain, heavy rain, drizzle, snow, blizzards, embers, ash, dust,
fog, petals, leaves, sparks, bubbles, sandstorms, meteors, fireflies and glitch
noise. Weather can occupy rear and foreground layers with independent density
and drift.

Cinematic events include lightning flashes and branches, fire and lava bursts,
portal pulses, neon flicker, scan lines, alarms, comets, star bursts, eclipses,
ghost passes and shadow sweeps. Event frequency and intensity are deterministic
for the seed and render phase.

Cosmic layers include sparse and dense stars, nebulae, galaxies, planets,
constellations, aurora, black holes, asteroid fields and holographic stars.
Rear flame styles cover ritual fire, hellfire, energy fire and smoke-and-fire
compositions.

The expanded background field also includes natural, urban, fantasy, science
fiction and horror scenes such as moonlit forests, desert dunes, oceans,
volcanic skies, castles, throne rooms, cathedral windows, portals, floating
islands, crystal caves, space stations, alien planets, graveyards and blood
moons.

## Safe expressive motion

The `motionV42` category adds gaze, eyebrow, pose and event motion. These effects
are deliberately implemented as local overlays inside existing eye, face and
torso masks. They never translate the whole 48x48 composition, preserving stable
sprite-sheet framing and preventing clipped bodies or empty edge strips.

## Determinism and versioning

V4.2 results use catalog version `4.2` and generator version
`4.2.0-dart.2`. The same request, seed and phase produce the same genome and
rendered frame. Phase-dependent weather, facial motion and background events
remain deterministic.

## Verification

The repository contains:

- catalog tests for all 30 categories and 274 unique fields;
- reachability tests for every select option and numeric endpoint;
- V4.2 layer and animation tests;
- stable-frame tests for idle and expressive animation;
- a structural Python audit for the base catalog, extension JSON, imports and
  field references;
- GitHub Actions running the audit, Dart formatting, `dart analyze` and
  `dart test` for pushes to `main`.
