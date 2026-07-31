# Avatar Genome 1.6 quality release

Version: package `1.6.1`, generator `4.6.0-dart.2`, catalog `4.4`.

## Completed scope

This release closes the stabilization and quality pass across generation,
rendering, rigging, effects and validation.

### Framing and composition

- 72×72 overscan work canvas for a 48×48 public viewport.
- Automatic portrait, expressive and wide camera profiles.
- Core occupancy, safety coverage and critical-gesture coverage diagnostics.
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
- Background detail belongs to scene/atmosphere ownership and is never counted
  as actor geometry.

### Native high-resolution output

The identity remains defined in logical 48-space for deterministic
compatibility. Sizes 64, 80 and 96 now use a native semantic raster pipeline:

1. Every render layer is independently rasterized on the destination grid.
2. Layer ownership, render slots and local paint order remain intact.
3. Selected contours gain destination-grid diagonal and corner bridges.
4. Material-aware directional lighting runs on the native geometry.
5. Regional semantic detail enriches face, eyes, mouth, hair, hands, clothing,
   armor, jewelry, cybernetics, companions and backgrounds.

This replaces enlargement of a flattened 48×48 image. The main identity model
is still shared between resolutions, but the destination image is composed from
semantic layers rather than copied final pixels.

### Resolution diagnostics

Every result exposes:

- `metrics.nativeGeometryPixelCount`;
- `metrics.nativeGeometryPixelRatio`;
- `metrics.geometryProfile`.

The first two values compare the final render with a nearest-neighbour baseline.
They make the resolution-specific information gain measurable in API responses
and tests. Profiles use names such as `canonical48`, `native64.budget1`,
`native80.budget2` and `native96.budget3`.

### Caching

- Destination-grid renders use a bounded immutable LRU cache.
- Cached images are cloned on read and write.
- Cache keys include source appearance, destination settings, animation phase,
  semantic layer ownership, slot, order, pixel count and bounds.
- Resolution diagnostics are retained by final image hash in a separate bounded
  registry, including cache-hit results.

## Quality gates

Tests cover:

- overscan and camera profiles;
- layer ordering and semantic slots;
- forearm/wrist hierarchy and constraints;
- wearable attachment metadata;
- clipping and background clarity stages;
- native semantic layer rasterization;
- measurable differences from nearest-neighbour enlargement;
- deterministic repeated rendering and cache behaviour;
- native resolution metrics in both objects and serialized results;
- visual-noise and semantic mask ownership.

GitHub Actions status must still be treated as external evidence. A missing run
or status is not equivalent to a successful build.
