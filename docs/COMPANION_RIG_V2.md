# Companion Rig V2

Companion Rig V2 renders every living shoulder companion as an articulated
subtree. A companion is never represented by one translated mask.

## Node contract

The shared rig can contain:

- `companionBody`;
- `companionHead`, `companionEyes`, `companionMouth`, `companionBeak`;
- `companionLeftWing`, `companionRightWing`;
- `companionLeftArm`, `companionRightArm`;
- `companionLeftLeg`, `companionRightLeg`;
- `companionTail`;
- `companionLeftEar`, `companionRightEar`;
- `companionLeftAntenna`, `companionRightAntenna`;
- `companionLeftTentacle`, `companionRightTentacle`;
- `companionHeldItem` and `companionTrail`.

Only parts used by a style produce layers. Every produced appendage has a pivot
stored in `companionRig.anchors` and exposed through `rig.anchors` as a runtime
anchor.

The complete subtree inherits the selected left or right shoulder attachment.
Local appendage animation is evaluated around the companion pivots before the
avatar-level rig applies the shoulder transform.

## Motion profiles

- **Bird** — independent left/right wing rotation, head turn, tail inertia,
  ear movement and beak opening.
- **Quadruped** — head and ear reactions, tail swing and alternating legs.
- **Humanoid** — independent arms and legs, held-item motion, head acting and
  mouth movement.
- **Floating** — hover, head movement, arm/tentacle drift and trailing effects.
- **Mechanical** — rotor or wing motion, antenna correction, tools and robotic
  arm gestures.
- **Tentacled** — independently delayed tentacles, tail and mouth movement.
- **Slime** — body wobble, eye drift and asymmetric pseudopods.
- **Arcade** — stepped rotation, limb movement, mouth cycles and pixel trails.

## Added families

### Undead

Sheet ghost, mini skeleton, skull with hands, mini reaper, zombie head and
vampire bat.

### Cosmic

Grey alien, alien blob, mini UFO, cosmic parasite, mini astronaut and cosmic
jellyfish.

### Arcade

Arcade chomper, arcade ghost, joystick buddy, pixel heart, mini arcade cabinet
and dice buddy. These are original arcade-inspired designs rather than copies of
licensed characters.

### Technology

Service robot, scout drone, robot spider, hologram assistant and radio buddy.

### Fantasy

Mini griffin, fairy, mandrake, mini golem, mini mimic, fire sprite and floating
eye, in addition to the existing dragon, familiar book and mushroom companion.

### Natural

Rat, raccoon, chameleon, gecko, mini octopus and snail, in addition to existing
birds, cat, frog, snake, insect and bat companions.

### Abstract and humorous

Storm cloud, flame orb, mini black hole, slime, coffee buddy, donut buddy, emoji
orb and black-cat cloud.

## Anchor guarantees

- Birds always expose distinct `companionLeftWing` and `companionRightWing`
  anchors.
- Humanoid companions expose separate arm and leg anchors when those limbs are
  visible.
- Tentacled companions expose left and right tentacle anchors.
- Antennas and ears use independent head-relative pivots.
- Held items are parented to the carrying arm.
- The root remains parented to the selected shoulder; canonical defaults may not
  overwrite a right-side attachment.

## Catalog integration

All styles are appended to both `v4.shoulderProp` and
`v4.extraShoulderProp`. The local editor discovers them from catalog metadata,
so no handwritten frontend option list is required.
