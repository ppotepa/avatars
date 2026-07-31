# Final render stability contract

Version: package 1.5.1, catalog 4.4, generator 4.5.0-dart.2.

## Working canvas and camera

The public viewport remains 48x48, while actor geometry is composed on a 72x72
overscan canvas with a centered 12-pixel margin. Camera fitting uses three
automatically selected profiles:

- `portrait` for restrained head-and-torso motion;
- `expressive` for hand gestures and wider body motion;
- `wide` for wings, companions and very wide safety bounds.

The camera prioritizes the readable core while keeping active hands and rigid
attachments inside the safety region. `preCameraClipping` diagnostics report
nodes and edge pixels that still reach the working-canvas boundary.

## Rig hierarchy

Both arms use the same canonical chain:

```
shoulder -> upper arm -> forearm -> wrist -> hand
```

Runtime constraints preserve the shoulder, elbow, wrist and hand attachment
points. Forearm segmentation follows a bone axis and uses an overlap seam so
skin, sleeves, armor, outlines and highlights do not separate during rotation.

## Layer order

The compositor uses semantic slots rather than historical z values. Scene slots
are separated into background base, background detail and rear atmosphere.
Jewelry uses dedicated neck and front/back ear groups. Wearables may explicitly
set `attachmentTarget` and `occlusionGroup`; prefix inference is only a fallback.
Rigid back equipment is split into a rear body and a front strap/highlight layer.

## Semantic masks

After posing and final environment rendering, semantic masks are rebuilt from the
transformed render layers. Legacy aliases remain available for validators, but
visible layer ownership is the source of truth for current node masks.

## Background clarity

Busy background detail is reduced inside a padded face region after rig posing
and world-space emitters. The base background remains intact. The final visual
noise gate runs after smoke, rain and local face protection.

## Diagnostics

The result metadata exposes:

- `preCameraClipping`;
- `backgroundClarity`;
- camera profile, occupancy and safety coverage;
- runtime anchors and constraints;
- semantic mask ownership;
- effective visual-noise information.

## Regression coverage

`test/final_render_stability_test.dart` guards the minimum overscan, camera
profiles, complete arm chains, axis-based segmentation, semantic scene slots,
wearable ownership metadata and the final post-pose rendering order.
