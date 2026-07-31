# Native resolution and semantic gestures

Version: package `1.5.0`, generator `4.5.0-dart.1`, catalog `4.4`.

## Resolution profiles

The canonical identity remains defined in logical 48-space. Output sizes now use
`ResolutionProfile` and `RenderGrid`:

- 48×48: classic geometry, detail budget 0.
- 64×64: semantic detail budget 1.
- 80×80: semantic detail budget 2.
- 96×96: semantic detail budget 3.

Large renders are no longer limited to repeated source colors. A semantic detail
pass enriches visible eyes, mouth, hair, clothing, metal, jewelry and cybernetic
surfaces. Detail is region-budgeted: face and hair receive information before
clothing surfaces, companions or backgrounds.

This is an incremental hybrid renderer. Identity-defining silhouettes still
originate in canonical 48-space, while additional semantic information is
rasterized directly on the destination image. Future part renderers can adopt
`RenderGrid` individually without changing the request schema.

## Design intent

Automatic genomes pass through an internal design grammar selecting a coherent:

- silhouette profile;
- material direction;
- contrast focus.

Only automatic values may be adjusted. Manual overrides, parameter locks and
category locks remain authoritative. Adjusted values receive a `designIntent.*`
source in the final genome.

## Arm hierarchy

Arms now expose:

```text
shoulder
└── upper arm
    └── forearm
        └── hand
```

The hand geometry supports:

- relaxed;
- fist;
- open;
- pointing;
- grip;
- covering.

## Gesture variants

Semantic gesture selection is deterministic per seed.

- Laugh: open hands, belly laugh or one hand covering the mouth.
- Angry: boxer guard, fists down or pointing.
- Surprised: hands toward the cheeks.
- Proud: hands on hips.
- Sad: self-hug or relaxed lowered hands.
- Bashful: hand toward the cheek.
- Talk: occasional open-hand punctuation.

Gesture transforms are added after the base emotional body pose, so breathing,
head movement, facial motion and secondary inertia remain active.

## Readability validation

Runtime validation now includes soft diagnostics for:

- fragmented one-bit silhouettes;
- loss of coherence at 24×24 and 12×12;
- sparse visible face regions;
- low viewport occupancy;
- poor safety coverage;
- rig constraint error;
- visual-noise limit violations.

These diagnostics do not invalidate generation. They surface seeds or manual
configurations that may benefit from a local repair or reroll.
