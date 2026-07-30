## Unreleased

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
