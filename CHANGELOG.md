## Unreleased

- Rebuilt the browser animation controls as a compact media deck with fixed SVG
  transport buttons, first/previous/rewind/play/pause/stop/forward/next/last
  semantics, a scrubber, frame/time readouts, loop mode and animation tracks.
- Removed the duplicate animation controller from `app.js`; `player.js` is now the
  single owner of playback, cancellation, seeking, caching and UI state.
- Added `POST /api/animation/clip`, allowing the player to prepare an entire SVG
  clip in one request and perform playback locally without a render request per
  frame.
- Fixed missing static routes for `player.js` and `player.css` in the local server.
- Consolidated render resolution into one visible control and added independent
  preview zoom modes: fit, 1x, 2x and 4x.
- Centered and mirrored 64x64, 80x80 and 96x96 raster sampling so non-integer
  profiles distribute narrow source cells symmetrically instead of deforming one
  side of the avatar.
- Replaced wrap-around weather/effect particles with deterministic lifetime-based
  fields using off-canvas spawning, independent speed, drift, sway, size, shape
  and front/back depth.
- Added deterministic procedural construction to face masks, including varied
  hockey-mask vents, stripes, emblems, panels, seams, filters, asymmetry and wear.
- Added procedural seams, panels, rivets, organic texture, highlights and damage
  to armor, headwear, capes, cybernetics, shoulder props, companions and relics.
- Added player, server route, resolution symmetry, particle continuity, fog shape,
  mask entropy and wearable-surface entropy tests, plus JavaScript syntax checks
  in CI.
- Added the additive V4.2 catalog extension with four metadata-driven categories
  and 51 fields, bringing the server-visible catalog to 30 categories and 274
  fields without a handwritten frontend control list.
- Added coordinated facial expressions with independent eye, eyebrow and mouth
  states, emotion marks, cheek lift, tears, talking mouth cycles, laughter,
  smirking, anger, sleep, surprise and configurable blink behavior.
- Added safe expressive gaze, eyebrow, breathing and pose overlays that preserve
  stable 48×48 sprite framing and never translate the complete avatar canvas.
- Added twenty halo styles with glow, tilt, breakage and orbit controls, plus
  symbolic overlays, forehead adornments, side-head features, creature traits,
  relics, familiars, wings, packs, banners and back-mounted structures.
- Expanded horn and antler geometry with ram, bull, antelope, deer, moose, demon,
  dragon, broken, unicorn, crystal, mechanical, neon, coral and ice variants.
- Added natural, urban, fantasy, science-fiction and horror backgrounds including
  moonlit forests, oceans, volcanic skies, castles, portals, floating islands,
  crystal caves, space stations, alien planets, graveyards and blood moons.
- Added layered weather, ambient haze, cosmic skies, rear flames and deterministic
  cinematic events such as lightning, fire bursts, portal pulses, neon flicker,
  comets, star bursts, eclipses, ghost passes and shadow sweeps.
- Added world-aware V4.2 composition weights so the expanded features remain
  coherent and do not all appear simultaneously.
- Added V4.2 catalog, server binding, rendering, determinism, animation and stable
  framing tests, plus GitHub Actions for structural audit, formatting, analysis
  and tests on every push to `main`.
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
