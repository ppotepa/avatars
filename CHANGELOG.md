## Unreleased

- Kept idle animation inside stable sprite bounds by removing whole-avatar canvas
  translation; local blink, hair, jewelry, smoke, aura and particle motion remains.
- Added a regression test that verifies anatomical layers stay pixel-aligned across
  idle frames, preventing clipping and empty edge strips in sprite sheets.
- Made every catalogued background reachable through automatic generation while
  preserving world-aware preferences and removing invalid post-apocalyptic
  background candidates.
- Added generator reachability tests that render every selectable option and
  both numeric endpoints for every range field.
- Expanded deterministic image identifiers from 32 to 48 bits. Result hashes now
  cover canvas dimensions, transparency, indexed pixels and the complete RGBA
  palette, so color-only variants receive different 12-character identifiers.
- Added native 48×48, 64×64, 80×80 and 96×96 rendering profiles without
  changing seed/genome identity.
- Added basic, enhanced and rich detail profiles with directional edge light,
  material highlights, shadow ramps and deterministic dithering.
- Added independently animated neon, rain, forest, space, dungeon, laboratory,
  flame and atmospheric background details plus a reduced-motion setting.
- Added browser controls for resolution, detail, animation length and playback
  speed, and exposed all rendering controls through the generic property UI.
- Added native-size PNG/SVG export and configurable animation sprite-sheet
  export through the local server.
- Added final-composition visibility metrics for semantic render parts.
- Added eye and mouth readability validation after all occluding layers.
- Added visible eye outlines and dithered eyewear lenses so clear glasses no
  longer erase facial features.
- Reworked the composition budget to select a limited number of salient
  accessories inside each group instead of enabling every member.
- Added contact shadows below front hair and more distinct, body-anchored
  necklace, amulet, dog-tag and royal-medallion geometry.
- Added web-editor animation playback and a live readability diagnostics panel.
- Improved the base renderer without introducing a parallel V2 mode.
- Composed subtle blink, hair, jewelry, smoke, aura and particle channels into
  the existing idle animation.
- Corrected animation speed semantics and lengthened motion curves for smoother
  loops at the 48×48 working resolution.
- Added staged eyelid motion, delayed hair-tip motion and contextual secondary
  animation channels.
- Increased visible variation between robotic, rectangular, realistic, round
  and oval eyes.
- Added deterministic seed-level variation to uneven and choppy fringes.
- Added palette outline contrast correction for more readable silhouettes and
  overlapping facial, hair and clothing details.

## 1.1.0

- Added a local `dart:io` avatar editor server with static web UI.
- Added metadata-driven property bindings for all request fields and all 223 catalog fields.
- Added generic set/reset/lock/unlock actions and category preset/reroll/lock operations.
- Added strict `AvatarRequestValidator` validation for API requests.
- Added live SVG preview, JSON import/export, PNG/SVG downloads and server-side save bundles.
- Added Windows PowerShell/CMD and Linux/macOS launch scripts.
- Added editor service and binding contract tests and documentation.

## 1.0.0

- Initial pure-Dart extraction of Avatar Graph V4.1.
- Deterministic genome generation from a seed.
- 26 parameter categories and 223 catalogued fields.
- 48x48 indexed pixel renderer with 32-color semantic palette.
- Anatomy, face, hair, facial hair, fantasy features, clothing, armor,
  headwear, eyewear, masks, jewelry, props, cybernetics, backgrounds,
  atmospheric effects, and deterministic animation phases.
- Implemented all catalogued V4.1 animation channels: blink, look-around,
  idle, smoke, hair wind, jewelry swing, glow/aura pulse and particles.
- Replaced runtime trigonometry with a fixed integer animation lookup table.
- Constraint reporting, graph snapshot, JSON/SVG/PNG export, and tests.
