# Visual noise budget

The scene uses one bounded visual-noise score and one dominant full-scene
channel.

## Dominant scene channels

The following fields are mutually exclusive after genome resolution:

- `v4.weather`;
- `v4.cosmicLayer`;
- `v4.backFlames`;
- `v4.ambientOverlay`;
- `v4.backgroundEvent`;
- `v4.effect`.

A request may contain several values, but only one survives. Explicit values of
a higher source priority win first. Equal-priority conflicts use this semantic
order:

1. weather;
2. cosmic layer;
3. ambient overlay;
4. rear flames;
5. general particles/effect;
6. transient background event.

This keeps named tracks stable: Storm remains rain, Fire remains flames and
Cosmic remains a cosmic layer.

## Scores

`targetScore` is deterministic for a seed but probabilistically distributed
between 24 and 40. Complexity and chaotic modes raise the target slightly.

`hardLimit` is always 42.

The score includes:

- background complexity;
- the selected dominant channel;
- channel density, depth, intensity or frequency;
- symbol overlays;
- actor-relative aura and halo presence.

The budget first clamps channel-specific density fields, then lowers them toward
the target. If the hard limit is still exceeded, low-priority soft overlays are
removed. As a final guard, the dominant channel itself is removed rather than
allowing a score above 42.

## Runtime gate

`SceneVisualBudgetRenderer` runs after all scene renderers. It removes any layer
that does not belong to the selected dominant channel. This protects custom
pipelines and manual genomes that bypass the default generator decorator.

Runtime diagnostics are available under `rig.visualNoise`:

- `targetScore`;
- `hardLimit`;
- `configuredScore` and `finalScore`;
- `structuralPressure`;
- `activeChannel` and `activeChannelCount`;
- effect layer and component counts;
- edge density;
- removed layer identifiers.

`structuralPressure` is descriptive and is not a second unbounded score.

## Framing

Camera zoom is driven only by the readable core:

- head and face;
- neck;
- torso, clothing and armor;
- front hair and facial hair.

Arms, hands, rear hair, head equipment, companions, wings, capes, halos, horns
and effects are safety bounds. They may nudge the viewport by at most three
source pixels but may not shrink the readable core.

The core target is 47 pixels wide by 45 pixels high in the public 48x48 frame.
Camera scale is clamped to `0.88..1.65`. Static preview and a sixteen-frame clip
use the same aggregate core/safety bounds.
