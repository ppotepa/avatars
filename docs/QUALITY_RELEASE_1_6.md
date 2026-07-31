# Avatar Genome 1.6 quality release

Version: package `1.6.0`, generator `4.6.0-dart.1`, catalog `4.4`.

## Completed scope

This release closes the stabilization and quality pass across generation,
rendering, rigging, effects and validation.

### Framing and composition

- 72×72 overscan work canvas for a 48×48 public viewport.
- Automatic portrait, expressive and wide camera profiles.
- Core occupancy and safety coverage diagnostics.
- Pre-camera clipping detection.
- Separate semantic slots for background base/detail, atmosphere, jewelry,
  rear/front arms and foreground effects.
- Explicit attachment and occlusion metadata for wearables.

### Rigging and gestures

- Complete shoulder → arm → forearm → wrist → hand hierarchy.
- Bone-axis segmentation shared by skin, clothing, armor and highlights.
- Elbow and wrist anchors with attach constraints.
- Semantic hand shapes and deterministic emotional gestures.
- Articulated companion V2 mini-rigs with independent appendage pivots.

### Readability

- Face clearance removes busy background detail behind the readable face area.
- One-bit silhouette, icon downscale and face-visibility validation.
- Scene visual-noise budget and one dominant environmental channel.
- Semantic masks rebuilt from final transformed layers.

### High-resolution output

The identity silhouette remains defined in logical 48-space for deterministic
compatibility. Sizes 64, 80 and 96 use:

- centered destination sampling;
- increasing semantic detail budgets;
- material-aware skin, hair, cloth, metal, glass and background treatment;
- regional detail priority favouring face, eyes, mouth, hair and hands;
- a bounded immutable LRU cache for destination-grid rendering.

This is a completed hybrid multi-resolution pipeline. It deliberately does not
claim that every silhouette is independently authored at every output size.
Instead it preserves one deterministic identity while adding meaningful
resolution-specific information.

## Quality gates

Tests cover:

- overscan and camera profiles;
- layer ordering and semantic slots;
- forearm/wrist hierarchy and constraints;
- wearable attachment metadata;
- clipping and background clarity stages;
- resolution detail budgets and material detail passes;
- visual-noise and semantic mask ownership.

GitHub Actions status must still be treated as external evidence. A missing run
or status is not equivalent to a successful build.
