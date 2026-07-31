# Rig quality contract

This document defines the runtime guarantees introduced in package 1.3.1 and
generator 4.3.0-dart.2.

## Framing

- The readable actor core is head, neck, torso, clothing, armor and face.
- Halos, horns, head adornments, auras, capes, wings, companions and
  screen-space effects are soft bounds and may not shrink the actor core.
- The target actor height is approximately 40-44 pixels inside the public
  48x48 viewport.
- Camera scale is clamped to 0.90-1.32.
- A static preview samples the same first sixteen animation phases used by the
  default player clip, so autoplay does not change framing.

## Transform ownership

Each pixel layer has exactly one rig node. Parent transforms are resolved to one
world matrix and each layer is transformed exactly once. Sequential subtree
translations are forbidden.

Flexible geometry that already contains phase-dependent articulation is removed
from the central secondary-motion pose. This prevents double movement for:

- long-hair segments while local hair wind is active;
- necklace and earring constraints;
- companion body parts;
- cape and wing segments.

When local hair wind is not active, expressive animation may still add delayed
hair inertia for laugh, angry, surprised and other body-driven profiles.

## Anchors and constraints

Runtime anchors are moved into overscan coordinates before pose solving.
Renderer-defined parents override canonical defaults. This is required for
right-side companions and asymmetric shoulder objects.

Required attachment constraints include:

- neck top to head joint;
- shoulder to arm;
- arm to hand;
- mouth to mouth prop;
- selected shoulder to companion or rigid shoulder object;
- ear to earring;
- clavicles to necklace/pendant;
- shoulders to cape roots;
- root/middle/tip seams for flexible geometry.

Constraint corrections are converted from world space into the coordinate space
of the child's parent, so anchors remain valid below rotated necks and shoulders.
Runtime diagnostics report maximum attachment and distance errors per frame.

Head and limb rotations must use anatomical pivots, never `(0, 0)` or an
arbitrary layer bounding-box corner.

## Wearables

Wearables are assigned by semantic style, not only layer prefix:

- chest reactor -> torso;
- neck ports -> neck;
- artificial ear -> ear;
- face cybernetics -> head;
- rigid back objects -> upper spine;
- energy backpacks, jetpacks and crystal clusters -> torso/back emitter;
- screen overlays -> scene;
- forehead symbols -> head.

Living companions and rigid shoulder objects use separate rigs.

Back equipment uses one of three explicit strategies:

- rigid wearable for backpacks, weapons, tubes and structural equipment;
- cloth chain for capes, cloaks, scrolls and spirit ribbons;
- articulated wing chain for angelic, demonic, dragon and mechanical wings.

## Rain

Rain uses a dedicated field instead of the generic particle renderer.

- All drops share one global wind vector with small local jitter.
- Streak direction is derived from the same velocity used for movement.
- Back, middle and front depth bands use different speeds and streak lengths.
- Drops respawn continuously using deterministic cycle seeds.
- Foreground drops can create short splashes at actor surfaces and the lower
  viewport edge.
- The final rain field is evaluated after the actor pose on the active overscan
  dimensions, so collisions follow the visible head, shoulders, arms and hands.
- Rain, fog, snow, embers and lightning use semantic weather palette roles.

## Other particles and emitters

Non-rain effects use profile-specific gravity, buoyancy, drag, wind and
oscillation. Snow, fog, smoke, ash, sparks, embers, leaves, dust, bubbles,
meteors and fireflies may not share one generic trajectory.

Smoke from a cigarette, cigar, pipe or match is rebuilt after posing. The
emitter follows the transformed mouth prop, while emitted particles are stored
in world space instead of remaining children of the mouth.

## Tests

The test suite must cover:

- affine parent/child transforms, including rotated parents;
- attachment and fixed-distance constraints;
- frame occupancy and stable clip camera;
- dynamic left/right attachment parents;
- articulated arms and independently owned hand pixels;
- wearable ownership and rigid/cloth/wing back strategies;
- absence of legacy particle-v2 layers;
- rain streak/velocity agreement;
- post-pose world-space smoke;
- rigid shoulder objects not becoming companions.
