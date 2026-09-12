# Decision Log

Append-only. Newest first. A decision that is not written here did not happen.

Entries record what changed, who decided, why, and **what it supersedes** — so a
future reader can tell a deliberate reversal from drift.

---

## 2026-09-08 — Device feedback: movement, mix, and LEGO identity

**Decided by:** director, from hands-on play of the run #4 APK
**Supersedes:** nothing. Three defects and one identity gap.

### "The movement is terrible"

A real bug, introduced by me two commits earlier. When the camera was changed to
orbit the player, movement kept using raw WORLD axes. Pushing the stick "up"
sent the character along world -Z regardless of where the camera was pointing,
so the control direction and the screen direction drifted apart as the camera
swung. Disorienting, exactly as reported.

Input is now rotated into the camera's frame: the stick is a screen direction,
so up-screen is always away from the camera. Autopilot and self-test inputs are
world-space by design and deliberately bypass the transform.

The self-test now gates it — it asserts that stick-up moves away from the camera
and that the resulting world direction reverses when the camera orbits to the
opposite side. Verified to fail when the transform is removed.

To be explicit about the director's other note: the character moves in whatever
direction the stick points. There is no forward-plus-turn scheme for the
character, and there never was; the bug was the frame of reference, not the
control model.

### "The sound effects aren't leveled very well"

Levels were set per call site with no structure behind them. Now there is a bus
layout — impacts on SFX, the storm bed on Storm — because those two are balanced
against each other constantly and one flat level cannot serve both a continuous
bed and transient peaks. A hard limiter sits on Master: this game stacks sound
violently, a barn can fire a dozen impacts in one frame, and that sums into
clipping, which is most of what "badly levelled" sounds like.

Every level was rebalanced downward, and the stud pitch ladder was shortened
from 22 steps to 14 and its step reduced, because it was reaching roughly double
pitch by the top of a streak and turning shrill.

### "This still doesn't identify as a classic LEGO game"

The most useful note of the three, and the least finished.

Fixed this round:

- **The minifig now walks.** Legs and arms swing in opposition from hip and
  shoulder pivots, with a bob. A sliding block reads as a physics prop, not a
  character, and no amount of shading fixes that. `[BS:PLAYER:WALK_CYCLE]`
- **The arms were buried inside the torso.** Shoulders sat at ±0.30 on a body
  1.0 wide, so the limbs were hidden and the silhouette was a stack of boxes.
- **It has a face** — the classic two dots and a smile.
- **The hair was a box floating above the skull**, the single most obvious tell
  that a model is not a minifig. It now caps the head.
- **The camera came in closer and lower**, so the minifig is the subject rather
  than a speck on a battlefield.

And one self-inflicted regression caught by looking at a capture: making the
brick material glossy applied to the 420m ground plane too, turning the whole
floor into a mirror with a specular sun the size of a building in frame.
Terrain now has its own matte material. The world had also drifted grey and
washed out, against pillar 2 which says the world stays bright and only the sky
darkens; light, fog and palette were corrected.

**Still not there, and honestly not close:** the environment is a sparse open
field where a LEGO game would be a dense built set, the camera is still further
out than the genre's, there are no idle animations, no cutscenes, no stud
shower on destruction, and the world does not reward close inspection. Those are
the next block of work, not a polish pass.

### Verification

New capture modes were added because none of the above could be judged from a
gameplay screenshot: a posed three-quarter closeup and a head-on face shot, both
with the HUD hidden, the player frozen and the camera locked. Three separate
framing bugs were found and fixed using them before the rig could be assessed at
all — which is the point.

Import clean, ANCHORS OK 54/54, SELFTEST OK, captures inspected.

---

## 2026-09-08 — Audio from CC0 sources, and TT Games research applied

**Decided by:** director ("work on the audio also, but let's not invent what we
can find available open source"; "gather any info or source information from the
telltale games")
**Supersedes:** nothing. Fills the gap named as the top priority in the previous
session summary.

### Naming

The director said Telltale; the LEGO games are TT Games / Traveller's Tales.
Telltale made *The Walking Dead* and never made a LEGO game. Researched TT Games
and flagged the distinction rather than guessing.
See `Docs/TT_GAMES_REFERENCE.md`.

### Audio: found, not invented

All 21 sounds are CC0 1.0, sourced from `lavenderdotpet/CC0-Public-Domain-Sounds`
(largely Kenney's CC0 packs), with full provenance in `ATTRIBUTION.md`. Nothing
synthesised, nothing from a commercial game.

The network egress proxy blocks opengameart, kenney.nl, freesound, archive.org
and every general web host; only `raw.githubusercontent.com` with an explicit
file path was reachable, so the search was for CC0 audio mirrored into a public
GitHub repository.

`scripts/audio.gd` names events by what happened rather than by file, so a sound
can be swapped without touching a caller. The funnel's roar is the primary risk
signal - readable with the screen ignored, which matters because the whole game
is about proximity and the player's eyes are busy looting. Stud pickups climb a
pitch ladder through a streak and reset after a pause, which is a TT Games
signature and the reward loop's whole voice.

**No cow.** The source collection's animal folders hold growls, nothing bovine.
Rather than pass a growl off as a moo, the cow gag keeps only its on-screen
popup and the gap is recorded in `ATTRIBUTION.md`.

### A check that could not fail

The audio assertion was written to load every declared stream and check its
length. Removing a source `.ogg` and re-running it still passed.

`load()` resolves out of `.godot/imported/`, so a deleted source file still
"loads" from a stale import cache. The assertion was testing the cache, not the
shipped asset - precisely the failure mode `Docs/NO_DRIFT_POLICY.md` warns about,
committed by the person who wrote that warning.

Fixed to check `FileAccess.file_exists` on the source path as well as the loaded
stream, and re-verified by hiding a file and confirming a non-zero exit.

### Two TT Games findings, implemented

Both were sourced, both were wrong in our build:

1. **A crossed threshold is never taken back.** In LEGO Star Wars, True Jedi
   cannot be lost however low your studs fall afterwards. Our tumble takes 20%
   of the player's studs and could therefore have dropped them back below a
   TRUE CHASER threshold they had already earned. Now latched
   (`[BS:ECONOMY:THRESHOLD_LOCK]`). This is the load-bearing rule behind the
   whole risk economy: the currency is soft, the achievement is hard, and that
   is what keeps players willing to take risks.
2. **Respawn grants temporary invincibility.** We had none, so a player caught
   in the red band could be tumbled repeatedly with no way out - the exact
   punishment the no-fail design exists to prevent. Now a three-second flickering
   grace period after every tumble.

Both are asserted in `--selftest`, each able to fail independently.

### Verification

Import clean, ANCHORS OK 51/51, SELFTEST OK - 21 sounds present and non-empty,
drove 13.6m, ram tore 128 bricks, smash tore 30, funnel tore 272 - captures
re-taken and inspected.

---

## 2026-09-08 — Three action buttons, drivable vehicles, and comedy as a pillar

**Decided by:** director
**Supersedes:** North Star pillar 6 (single context button), the inversion
statement's treatment of player destruction, and `Docs/GAME_CONCEPT.md` §11
open question 1 (vehicles).

### The decision

1. **Vehicles are drivable.** Not scripted, not on-rails. You get in, you steer,
   you drive through a barn.
2. **Three action buttons: SMASH, BUILD, JUMP.** Replacing the single context
   button.
3. **Smashing everything, and the humour, are pillars** — the director's words:
   "the best part of the Lego games is smashing everything and the humor. we
   need to emulate those as much as possible."

### Why this was raised as a conflict first

The North Star, committed hours earlier, said the player "is never promoted back
to primary agent of destruction", that there is exactly one action button, and
that Bill's smash "must never grow into" a destruction model. The policy says
changes to the North Star require explicit director approval and never arrive as
a side effect of implementation. This is that approval, recorded rather than
silently applied.

### How the inversion survives

The inversion did not have to die to satisfy this.

- **Player smash** is ungated, always available, and pays at the player's
  current band — which, away from the funnel, is ×1.
- **Funnel debris** pays ×2 to ×5.

So the player smashes everything constantly, and the risk economy is untouched:
the multiplier is still the reason to go near the storm. What changed is that
destruction is no longer *only* the storm's job. What did not change is that the
storm is still where the money is.

The inversion statement in the North Star has been rewritten to say this
directly rather than being deleted.

### What was built

- `scripts/vehicle.gd` — arcade handling where the stick is a heading, not a
  wheel; ramming tears scenery with force scaled by speed; boarding syncs the
  driver's position so risk band, wind, magnet and camera all keep working
  unchanged, and driving into the red band pays exactly like walking into it.
- `scripts/comedy.gd` — floating comic-book onomatopoeia at the point of impact,
  plus the running gags: cows moo when the funnel throws them, and the outhouse
  has an occupant.
- Three buttons in `scripts/hud.gd`. SMASH and JUMP never change meaning; only
  BUILD is contextual (BUILD / GRAB / DEPLOY / DRIVE / EXIT).
- **BRACE became automatic** — release the stick in high wind and the player
  digs in. The button budget was spent on SMASH/BUILD/JUMP, and this removes a
  control rather than adding a fourth.

### Verification

The self-test was extended to cover the new systems rather than left to cover
only the old ones. It now asserts the truck moves under throttle, that ramming
tears bricks, that player smash tears bricks, and that JUMP leaves the ground —
each able to fail independently.

It did fail on first run: `JUMP did not leave the ground`. The cause was the
test, not the code — a lingering tumble from the preceding smash phase was
refusing the jump, making the assert order-dependent. Fixed by parking the
funnel and clearing the tumble before the jump phase. Recorded because "the gate
caught something and it turned out to be the gate's fault" is exactly the kind
of event that gets quietly deleted from history.

Measured on the commit that landed this: drove 13.6m, ram tore 128 bricks,
player smash tore 30, funnel tore 262, 2,308 studs banked.

---

## 2026-09-09 — The sub-area becomes the unit

Supersedes the arrangement in which the streamer, the set piece, the camera and
the audio each answered "where does one part of the world end?" separately, or
not at all.

### Why

`Docs/TT_ENGINE_NOTES.md` section 8: a TT level divides into lettered
sub-areas, and camera files, music zones and level data all key off **that same
division**. Before this change BRICKSTORM had three answers and two absences:

- the streamer had a bare float frontier, `_stream_z`, advancing by `BLOCK_DEPTH`
- the set piece had `_is_reserved()`, open-coded arithmetic against a magic Z
  with its own `-10.0` and `+28.0` margins that matched nothing else
- the camera had no spatial awareness at all
- the ambience bed did not exist; `wind` and `rumble` sat unused in the bank

### What was built

`SubArea` (`scripts/sub_area.gd`) — one named division: bounds, kind
(PROCEDURAL or AUTHORED), the structures it owns, framing hints, and an
intensity state.

`AreaMap` (`scripts/area_map.gd`) — the single authority on the division.
Owns the frontier, creates areas, hands only PROCEDURAL ones to the populator,
retires whole areas behind the storm, and answers `area_at` / `framing_at`.

Then all three systems were moved onto it:

- **Streaming.** `_stream_z`, `_block_seed` and `_is_reserved` are gone.
  `_spawn_block(z)` became `_populate_area(area)`. Reclaim retires areas rather
  than testing every structure every pass.
- **Camera.** Framing hints come from the area, faded in over its range of
  effect — TT's `CamRangeOfEffect`. Procedural areas carry no hint, so the
  automatic camera is untouched over the great majority of the corridor. The
  authored yard pulls back 5m and lifts 2.6m so its composition reads.
  Automatic by default, authored where it matters.
- **Audio.** The area carries an intensity — AMBIENT, QUIET, ACTION, TT's three
  states — and the ambience bed follows it, ducking when the storm arrives so
  it never competes with the roar.

The starting town is now a `START` sub-area rather than the one stretch of
world that nothing owned.

### What is NOT built, and is not pretended to be

TT quantise music transitions to authored markers in the track (`IX` points), so
a fight ending never cuts the music mid-phrase. We have no composed music, so
the ambience bed uses a rate-limited fade instead. That is a stand-in, and it is
recorded here as one rather than described as the same thing.

### Verification

Six new assertions, each verified to fail by breaking the rule it guards:

- tiling has no gap or overlap — broken by advancing the frontier past `z1()`
- authored ground is never populated — broken by passing authored areas to the
  populator inside `ensure_ahead`
- the authored area applies a framing hint, and it does not leak far outside
- a structure thrown ahead outlives its birth area, and one left behind does not
- the ambience bed ducks rather than swells
- **the corridor is never bare**

The last one exists because of a mistake made writing these. The first version
of the re-homing check drove `retire_behind` on the LIVE map, which retired the
starting area and deleted the town. `torn` fell from 290 to 70 and the run still
reported **SELFTEST OK**, because nothing asserted that the world stays
populated. The check was rewritten to run on a throwaway map, and a density
floor was added — the streamer's entire promise is that you are never more than
a couple of paces from something that breaks, and until now nothing checked it.

A second bug surfaced the same way: the near cache is rebuilt on a timer, so it
can outlive a structure freed since the last refresh. It had never fired because
the only source of freeing was reclaim 95m behind the storm, far outside the
cache. Freeing one next to the player found it immediately. All three cache
consumers now validate.

Measured on the commit that landed this: torn=289, ram_torn=172, smash_torn=31,
studs=239, sensors 3/3 — unchanged from before the refactor, which is the point.

---

## 2026-09-09 — Bricks stop being cardboard

From `Docs/TT_ENGINE_NOTES.md` section 10, the two shading facts most likely to
change our screenshots.

### Ambient is the sky, not a colour

A flat ambient term lights every face of a brick identically, which is the
flattest thing a renderer can do. TT sample a diffuse environment cube by world
normal, so a brick's top takes the sky and its underside takes the ground.
Godot gives us the same thing for the price of three lines:
`AMBIENT_SOURCE_SKY`, full sky contribution, and `REFLECTION_SOURCE_SKY`.
Energy is the single global dimmer TT drive with `sceneAmbientColor.a`.

### Rim is the fresnel term, and it is what makes plastic plastic

TT scale specular by an explicit fresnel factor. A dielectric throws back far
more light at grazing angles than head-on, and without that a brick reads as a
flat-shaded box however the lights are placed. Godot's `rim` is that term.
It is **bricks only** — a grazing-angle response on a 420m ground plane is the
horizon, which is the same lesson as the specular blowout recorded above.

### The bug this uncovered, which was the real problem

The first pass changed `BrickLib.mat()` and the screenshots came back "slightly
brighter". `Structure`'s MultiMesh batch material — which is what **every**
building, fence, tree and vehicle in the game actually draws through — carried
its own hand-copied roughness and specular, and never got the fresnel term. Two
definitions of what plastic looks like, and the change landed on the one that
covers the minifig and loose debris.

There is now one definition, `BrickLib.apply_plastic()`, and a check that fails
if the two drift apart again.

### Captures are seeded

Judging any of this was impossible at first because `randomize()` gave a
different world every run: the first "after" shot had a barn in it that the
"before" shot did not, and the measured difference was mostly the barn.
`--capture` now seeds, so two shots from different commits are of the same
world. Screenshots are evidence (`Docs/NO_DRIFT_POLICY.md`) and evidence has to
be comparable.

### Measured, on identical seeds

| | before | after |
|---|---|---|
| shadow fill (darkest decile) | 34.7–45.5 | 27.9–36.9 |
| clipped white | 0.12–1.08% | 0.11–1.11% |

Shadows did not simply get brighter — contrast rose. Faces separate from each
other, the fence rail has a lit top edge instead of being a white slab, and the
studs catch a highlight. Clipping did not increase, which was the risk.

### Not done

TT also scale specular by a LOD factor so distant geometry loses its highlight
entirely — cheaper, and it kills shimmer. Godot's `StandardMaterial3D` has no
per-distance specular, and a custom shader for MultiMesh-batched bricks is a
larger change than this one. Recorded as absent rather than quietly skipped.

---

## 2026-09-09 — The trees move

`Docs/TT_ENGINE_NOTES.md` section 12: TT drive foliage from a per-vertex bend
weight the artist paints, a per-plant random seed, and a wind field sampled in
**world space** so every plant agrees on the wind and a gust sweeps across a
field. We were making a tornado game in which nothing bent.

### What was built

`shaders/brick.gdshader` — one shader for every brick in the world. It carries
the plastic look (values taken from `BrickLib`, not retyped) and a vertex wind.

**Bend is per brick, in the instance colour's alpha.** Zero is rigid, which is
every building, fence and vehicle. Foliage is authored with bend rising toward
the tips: a tree trunk is 0.0, the canopy 0.45, then 0.70, then 1.0 at the top
tuft; a crop stalk is 0.85 because it is nearly all tip. Our generator *is* our
modelling tool, so it emits the weight TT paint by hand.

A brick displaces **rigidly**. It is a LEGO brick; it does not shear.

The wind is the ambient breeze plus the storm. The breeze is evaluated
analytically in world space rather than sampled from a scrolling texture — same
idea, no asset, no sampler in a vertex shader. The storm's shape and constants
come from `Tornado`, passed in as uniforms rather than retyped, because foliage
leaning one way while the player is pushed another would stop the world being
one place.

### Three things the checks caught

**The trunk slid along the ground.** Bend is per brick and a brick cannot taper,
so any bend at all on a one-brick trunk moves its base. It is 0.0 now, and the
tree reads correctly: leaves rustle, trunk planted.

**The storm leaned the foliage but did not move it.** The storm's field is a
function of position alone, so it displaced each plant to a new place and held
it there. A lean is not motion. Turbulence scaled by local wind magnitude fixed
it — nothing on a calm day, violent at the funnel.

**The first measurement was too blunt to see the fix.** Counting pixels that
changed between two frames saturates as soon as motion exceeds a pixel or two:
it rated a tornado at 1.9x a calm breeze. Measuring the *swept silhouette* —
union minus intersection over several frames — separates them properly.

### Verification

`--selftest` cannot see this: the wind is a vertex shader and the self-test is
headless. So `tools/wind_probe.gd` renders a tree and a barn side by side with
a locked camera and measures how far each silhouette sweeps:

```
WINDPROBE swept: breeze_tree=5.9% storm_tree=23.3% barn=0.0%
```

The breeze rustles the tree, the storm moves it nearly four times as far, and
the barn does not move at all. It fails if foliage is static, if a building
moves, or if the storm moves foliage less than twice as far as a calm day.
It runs in CI.

`--selftest` covers what it can reach: that both material paths match the
plastic constants, that the shader's storm constants match `Tornado`'s, that the
shader is looking at where the storm actually is, that a tree canopy has bend
and its trunk has none, and that a barn has none anywhere.

`tools/verify_anchors.gd` now scans `.gdshader` as well as `.gd`, and accepts
`//` comments. A shader carrying load-bearing invariants that the verifier
cannot see is a rule that quietly rots.

---

## 2026-09-09 — "It feels like Roblox with mega blocks in it"

Device feedback, and it was right. Three causes, all of them structural rather
than a matter of taste.

**Every brick was a bare `BoxMesh`.** A LEGO brick is injection-moulded and
every edge carries a chamfer; that chamfer catches a different light angle from
either face it joins, so an edge reads as an edge from any direction. A sharp
box gives one flat tone per face and reads as a primitive. `BrickLib.brick_mesh`
is now a chamfered cube - 44 triangles instead of 12, one shared mesh so the
MultiMesh batching is untouched. The chamfer is proportional rather than
absolute, because an absolute one would need a mesh per brick size and would
multiply the draw calls the batching exists to remove.

**The ground was a smooth 420m plane.** It is half of every frame, and a world
where nothing the bricks stand on is itself a brick reads as a game with blocks
in it. It is a baseplate now: studs on the real stud pitch, locked to world
space so they line up with what is built on them, plate seams every 16 studs,
and the studs fade out with distance because at 80m they are only aliasing.
They are shaded, not modelled - a 420m plane of real stud geometry is millions
of triangles for something never seen in silhouette.

**The minifig had no stud on its head.** That is the single most identifying
feature a minifig has. It also had a plain box for a torso where the real part
is a trapezoid, and pegs for hands where the real part is a C-shaped clip. All
three are fixed. This is a first pass, not a finished character.

### The bug this uncovered, and how badly it was chased

The chamfered mesh shipped with **16 of its 44 triangles wound backwards** -
hand-tracking the orientation of six faces, twelve edges and eight corners.
A backwards face means you see through the brick, and it went into a screenshot
before it was spotted. The winding is now derived from the geometry rather than
asserted by hand: the part is convex and every face is built with its true
outward normal, so it can simply be asked which way round it goes.
`--selftest` checks the mesh is closed, correctly wound and actually chamfered.

Then every stud in the world rendered as a dark disc. Three wrong theories were
chased in order - the sky ambient (the storm sky is dark overhead, so up-facing
surfaces are dim), a material cache collision, and specular aliasing on tiny
curved geometry - before a controlled probe at gameplay distance with shadows
on and off showed it in one image. **A stud stands 6cm proud of a large flat
brick top. That brick casts into the shadow map, and at the stud's texel the
recorded depth is the brick top, so the stud's own surface is classified as
being behind a caster.** Studs no longer cast or receive shadows; they are 6cm
bumps and no shadow that matters falls on one alone.

The magenta test is worth recording as a technique: setting the sky and ground
to saturated primaries and re-rendering showed the studs taking the sky colour,
which said "these surfaces are lit only by ambient" and ruled out the material
in one shot.

### What is NOT proven

`tools/stud_probe.gd` renders that exact case and passes. **It could not be
made to fail by reverting the fix**, so it is a smoke test and not a verified
regression gate, and it is deliberately not wired into CI as one. Recorded as
unproven rather than described as a guard.

### Still not done

Part variety. Every prop is still assembled from rectangular boxes - no slopes,
no tiles, no arches, no round bricks. A LEGO roof is made of 45-degree slope
bricks and ours is made of boxes, which is the remaining half of "mega blocks".
That is content work across every prop in `prop_builder.gd`, not a material
change, and it is the next thing.

---

## 2026-09-10 — The character, measured against the demo

Goal restated by the user: *"I want people to think, wow I didn't know they made
a LEGO Twister game."* So the demo is the reference, not our previous build.

### Two numbers, both of them the Roblox tell

Captured close reference of the demo's Indy and measured our figure against
canonical minifig dimensions in the same millimetres the bricks already use.

- **Ours was 2.91 brick-heights tall. A minifig is 4.17.** 30% short - or, put
  the other way, our bricks were 43% oversized relative to the figure. That is
  most of the "mega blocks" read: chunky bricks beside a stumpy figure.
- **Its head was half the size it should be.** Head-to-torso width was 0.39
  where a minifig is 0.75. A small head on a short body is the Roblox
  silhouette exactly; a minifig is short-legged with a BIG head.

Both are now built from the canonical figures - legs 17.6mm, torso 15.4mm,
head 9.6mm tall and 12mm across, arms outside the torso - converted once from
`STUD / 8.0`.

### The face is printed, not modelled

Built as geometry the features floated off a curved surface, cast their own
little shadows and poked past the head's silhouette. The demo's face is
pad-printed and perfectly flat. Ours is now a generated texture: brows with
lifted outer ends, small eyes with a pupil highlight, a mouth curve, and
stubble. **Brows are what carry the expression** - the demo's Indy is brows
first, and without them a minifig looks vacant.

The texture is laid out in real minifig millimetres rather than pixels, so it
stays correct if the head is ever resized.

### This cost far more than it should have

The face wrap took six wrong turns: it printed on the back of the head, then
inside-out, then compressed into a sliver at the centre, twice. Throughout,
**the per-vertex UV dump looked correct** - u ran 0.5 at the front, linearly to
1.0 at the back - because the error was in how the range wrapped BETWEEN
vertices, not in any single value. Numeric dumps could not see it.

What settled it in one render was a **banded diagnostic texture**: eight
coloured stripes across u, applied to the head. The bands showed instantly that
u ran backwards and that the seam sat dead ahead. That is the technique to
reach for first next time a texture maps wrongly, before any dump.

The wrap is now computed from the vertex position in a shader rather than
authored on the mesh, so the whole class of bug is gone. The half-turn offset
was then set empirically from the band test rather than reasoned about, and the
reasoning that said otherwise is not trusted.

Also recorded: flipping the head's facing by one sign inverted every triangle
and turned it inside out - the identical mistake already written down for the
brick mesh, made a second time. Both meshes now derive winding from the normal.

### Not done

- **Torso printing.** The demo's Indy has a jacket, a shirt and a satchel strap
  printed on the torso. Ours is flat colour. This is the single biggest
  remaining gap on the character.
- The hair still shows a band across the forehead where its underside meets the
  head.
- Buildings are untouched: still rectangular boxes, no slopes or tiles.

---

## 2026-09-10 — The render was blown out, and the metric that found it was nearly wrong too

The user compared our minifig against the demo reference and said it was "way
off". It was, and the cause was not the model.

### Measured

Isolating the head in each image and comparing:

| | ours | demo |
|---|---|---|
| clipped to pure white | **97.5%** | **0.0%** |
| tonal spread across the face | 2.1% | 20.9% |

Ninety-seven per cent of the head was sitting at clipping. There was no shading
on it at all - a flat blown-out yellow where the demo's face has a full falloff.
A surface with no tonal range reads as a toy rather than as a photographed
model, and no amount of work on the geometry would have fixed it.

Two causes: **no tonemapper** (Godot defaults to linear, so everything above
1.0 simply flatlines) and **the sun was about four times too strong** - 1.45,
on a palette whose brightest albedos are 0.94-0.96. Now: ACES tonemapping,
sun 0.35, ambient 0.75.

Whole-frame targets taken from the demo's own daylight scenes for reference:
Cairo street sits at median 122, p95 175, 0.00% clipped. Ours reaches p95 193
with 0.1% clipped; our median is lower because our sky and baseplate are their
own colours rather than because of the lights.

### The instrument was wrong twice before it was right

Worth recording, because the wrong numbers were convincing:

1. **A byte-for-byte comparison of the two PNGs returned 0.41% matching.** That
   is what two unrelated files score - PNG is DEFLATE-compressed, so byte
   identity measures nothing about the image.
2. **The first head mask thresholded on BRIGHTNESS.** So when the lights were
   dimmed the mask simply selected fewer, brighter pixels and every statistic
   stayed pinned - halving the sun "changed nothing", which is impossible. The
   mask now selects by hue, and a mask image is dumped and looked at before any
   number from it is believed.
3. **The second mask admitted the green baseplate** (green also has r > b) and
   inflated the sample to 92% of the crop.

### And the final numbers are noisy

The same settings measured 0.0% clipped on one run and 10.4% on the next,
because captures are seeded for world LAYOUT but physics still diverges, so the
figure stands somewhere different and catches the sun differently. Run-to-run
variance on head clipping is around ten percentage points.

So: the move from 97% to under 10% is real and far outside the noise. The
difference between 0% and 10% is not, and the last few calibration passes were
fitting noise. Recorded rather than presented as precision.

---

## 2026-09-10 — Torso printing

The torso was flat colour where the demo's Indy carries a jacket, a shirt V, a
satchel strap and pocket seams. Two changes.

**One part, not a stack.** It was two boxes stacked to fake a taper, which left
a visible step across the chest and had nowhere to print. It is now a single
tapered part - full width at the waist, cut back at the shoulders - with a
rounded-rectangle cross-section carrying exact per-face normals.

**The print is ink-line artwork.** Every LEGO torso print is bold black
outlines with flat fills - no shading, no gradients. Looking closely at the
demo's Indy: heavy linework defining a jacket, a V of shirt showing through,
lapel folds, and a strap drawn as a band with an outline on each edge. Soft
airbrushed detail reads as a video-game texture; line art reads as a printed
part. Ours is laid out in real minifig millimetres like the face.

### Three bugs, and one that is only worked around

1. **`generate_tangents()` on a mesh with no real UVs corrupted its normals.**
   This mesh addresses its print from local position, so every UV is zero, and
   asking SurfaceTool to derive tangents from degenerate UVs destroyed the
   normals it had been given. Removed - there is no normal map here to want
   tangents for.
2. **`NORMAL` in `vertex()` never reached the varying** under the compatibility
   renderer. The mesh's normals were dumped and confirmed correct, yet the
   front-face test read zero everywhere while `u` and `v` derived from
   `VERTEX` in the same function were exact. Front-ness is now taken from
   position instead.
3. **The visible surface reports `v_local.z = -0.25`** - the camera sees the
   FAR face. Measured, not assumed. That strongly suggests these generated
   meshes are wound inside-out, and that the head's empirically-determined face
   offset has been quietly compensating for the same thing.

   **This is not fixed.** The print is applied to whichever flat +/-Z face is
   being looked at, with `u` mirrored so the asymmetric strap reads correctly
   from either side. That makes the part correct without pretending the
   winding question is answered, and it is recorded here so the next person
   does not conclude the meshes are sound.

The method that found all three was the same one that cracked the face wrap:
render a diagnostic that outputs the intermediate values as colour and read the
pixels. Reasoning about the camera basis was wrong twice; the pixel dump was
right immediately.

### Not done

- The jacket reads much darker than the arms, which still use the flat shirt
  colour. They should be the jacket colour, or the jacket lightened.
- The hair still bands across the forehead.
- Buildings remain rectangular boxes.

---

## 2026-09-10 — The meshes were inside-out, and the buildings are made of parts

Two things, and the first one had to be settled before the second could be
built on top of it.

### The winding question from the torso work is answered: they were inside-out

The previous entry recorded, as unresolved, that the surface the camera
actually shades on the torso reports `v_local.z = -0.25` — the far face. That
is now proven, and it was true of **every generated mesh in the game**: the
brick, the head, the torso.

**Godot's front face is CLOCKWISE seen from the front.** `BrickLib._tri`,
`_emit_tri` and `_torso_band` each carried their own copy of the same three
lines, and all three ordered vertices *counter*-clockwise from the outward
normal. Back-face culling therefore threw away the surface nearest the camera
and drew the one behind it.

The evidence is `tools/winding_probe.gd`, and it is two measurements, not an
argument:

1. Two quads, both facing the camera, one wound by `BrickLib.wind_cw` and one
   deliberately reversed. Exactly one survives culling. Before the fix the
   reversed one was the survivor; after it, ours is.
2. A marker sphere at the dead centre of a real brick. Before: 5,551 pixels of
   marker visible **through** the brick — a hole punched clean through a solid
   part, and the brick's own pixel count rose by exactly that number once the
   hole closed. After: zero.

It never looked obviously broken because a closed convex part still fills its
own silhouette. What was wrong was subtler and everywhere: the depth, the
silhouette and the lighting were all coming off the wrong surface.

Both printed parts had "empirical" offsets in their shaders that were really
compensating for this, and both are now undone:

- `face.gdshader` gets its half-turn offset **back**. Dropping it had put the
  face in the right place for entirely the wrong reason — the fragment in front
  of you was the far surface, already half a turn round.
- `torso.gdshader`'s front test is **signed** again. Selecting `+Z` alone had
  left the torso blank because the shaded surface was the back of the part.

The convention now lives in exactly one place, `BS:BUILD:WINDING`. It was wrong
in three copies at once; one place cannot drift from itself.

**The self-test was asserting the wrong thing.** The mesh-integrity gate tested
`geo · normal < 0` — the inverted condition — so it passed cleanly for weeks
while every brick in the game drew its far side. A gate can be green and wrong.
It now checks all eight parts, in the right direction, and also that each is a
closed solid within the unit cube.

### The part library: the buildings are no longer boxes

The note on the last build was *"it feels like ROBLOX mini… just a game with
mega blocks in it"*, and the honest reading was that every prop in the town was
assembled from one shape. `BS:BUILD:PARTS` adds seven more: slope, inverted
slope, cheese slope, tile, round brick, cone, arch.

All eight — the brick included — come out of one generic chamfered-extrusion
builder. The brick's hand-written "six inset faces, twelve edge chamfers, eight
corner triangles" is deleted; it was measured against the generic builder
first, and they agree exactly: **44 triangles, 5.750 surface area, 0.9929
volume, identical bounds**. `tools/part_probe.gd` still asserts those numbers,
so a change to the shared chamfer rules that reshapes every brick in the game
cannot land quietly.

Two geometry bugs the probe caught that a screenshot would not have:

- **Oblique corners broke the end caps.** Offsetting each edge's own endpoints
  inward only lands in the right place at a right angle. On every slope the cap
  outline crossed itself, the triangulator rejected it outright, and the
  fallback fan filled a shape that was not the part. Caps are now built from
  proper miter points, which also collapses the corner patch back to the single
  triangle the brick always had.
- **`generate_tangents()` on parts with no UVs** — the same trap that hid the
  torso print for two rounds of debugging. Not called.

`SLOPE_LEDGE` is a half, not a third, because a real 45° slope brick is **two
studs deep**: one stud of slope, one of studded flat behind it. That flat stud
is what the next course sits on, and it is why a LEGO roof has no exposed studs
on its face. At a third, the courses stepped in one stud and left every ledge
showing — which is a roof faked from slabs, just with more steps.

Roofs go through `_stepped_roof`, which lays real slope courses. The barn gets
a gambrel (three steep courses, then four shallow); the farmhouse a 45° gable
with inverted-slope eaves. Both are sized to the **outside** of the walls, not
to `hw`: `_wall` straddles the corner it is given, so the walls stand a stud
proud, and a roof sized to `hw` left a band of bare studded wall-top showing
all the way round. Evidence: `Docs/shots/14-slope-roofs.png`, orthographic,
because whether a roof face is a continuous pitch or a staircase is a
silhouette question that a three-quarter view hides either way.

Round things are round parts now — trunks, silo drums, tank, tower legs,
wheels, barrels, tyres, hay bales. The silo was ten little boxes per course in
a staggered ring, every one with two corners outside the circle; it read as a
castellated tower. Smooth things are tiles: the drive-in screen (a cinema
screen with a grid of studs across it was the loudest wrong note in the set),
bench seats, fence rails, road signs.

**Part variety is not free.** `Structure` now allocates one MultiMesh per part
kind a prop actually uses, so a prop's palette is a draw-call budget. The
self-test caps it at six per prop and the farmhouse sits exactly on the cap —
deliberately uncomfortable, because it is a hero building that appears twice in
a corridor, while anything the scatter places by the dozen should be nearer
three.

Round parts also cost destructibility: the silo went from 72 pieces to 4 before
the courses were made plate-thick. It doubles as the set piece's heavy gate, and
at four thick rings the gate came apart in three grabs. Barrels and bins got
the same treatment for the same reason — a smashable exists to come apart.

### A third instrument error, caught this time

The first version of the tear-mapping gate called `_hide_instance` and read the
instance transform back off the MultiMesh. It passed. It also read **identity
for every instance**, including ones just written with a scale: `--selftest`
runs headless, where the dummy renderer keeps no per-instance buffer, so that
test could only ever pass.

Split in two, and both halves confirmed:

- `--selftest` checks the bookkeeping `_hide_instance` and `tear()` index with —
  within each kind, slots must be exactly `0..n-1`. A repeated slot is what
  blanks the wrong brick.
- `tools/part_probe.gd` does the rendered version, where the buffer reads back
  `(1.0, 0.6, 1.0)` as written and hiding part 3 blanks exactly part 3. It
  fails itself if the buffer reads empty, rather than reporting a pass.

That is three measurement-instrument errors in this project so far, and the
pattern in all three is the same: **the instrument reported no change when the
thing it measured was broken.** Validate the instrument before trusting the
number.

### Gates, each proven to fail

Every gate below was checked by deliberately breaking the rule it guards:

- reversed `wind_cw` → all eight parts reported inward-facing
- a cone pushed past the unit cube → "spills outside the unit cube"
- a cap fan removed → "not a closed solid" on both round parts
- studs given to tiles → "'tile' 2x2 offers 4 stud slots, expected 0"
- batch slots collided → "tearing one part would blank another"
- the barn roof reverted to a tilted slab → "prop 'barn' uses no slope"

One correction to the *test* was needed on the way: the closed-solid edge key
formatted coordinates directly, and `cos()` at a right angle returns
-1.8e-16, which prints as `-0.0000` while the same corner reached from another
triangle prints `0.0000`. Two keys for one edge, and every round part reported
as an open shell. That was the test being wrong, not the mesh.

### Not done

- The jacket still reads much darker than the arms, which use the flat shirt
  colour. Unchanged from the last entry.
- The hair still bands across the forehead, and is still a plain box.
- **The open question for the director stands, and it is not mine to settle.**
  In the demo the environment is largely *not* brick-built — cliffs, buildings
  and terrain are sculpted textured meshes, and LEGO plastic is reserved for
  characters, vehicles and destructibles. This work took the other road,
  because North Star pillar 1 says everything in the world is built from real
  brick shapes and that pillar changes only by director decision. Worth
  deciding explicitly rather than by default.

---

## 2026-09-10 (later) — Director decisions: the hybrid, saturation, and the loop

Three decisions came back from the director, and two of them change a pillar.

### Pillar 1 is amended: the line is smashability

> *"Only environment that's supposed to be smashable needs to be Lego, anything
> else doesn't need to be. The hybrid system will work great here."*

`Docs/NORTH_STAR.md` pillar 1 previously read "everything in the world is built
from real brick shapes; if it cannot be built from parts, it is not in the
game." It now reads: **if it is smashable it is brick-built; if it is not, it
does not have to be a brick at all.**

The evidence for asking was measured, not stylistic. In the demo, LEGO is a
**figure-ground relationship** — minifigs, vehicles and destructibles read as
moulded plastic because they sit against sculpted rock, plaster and cobbles that
are not plastic. This project had made everything plastic, ground included, so
nothing had anything to read against.

**The first thing to go is the studded baseplate.** A 420m plate of shaded studs
was half of every frame, and it was added on exactly the theory the director has
now overturned. `shaders/ground.gdshader` replaces it with textured earth:
three-octave value noise, no texture asset, patches at field scale, mottling at
metre scale, and a fine grain that fades out before it can shimmer.

### Pillar 2 is clarified: saturation belongs to the plastic

Bricks stay punchy; ground, terrain and sky come down so the bricks have
something to be bright against. This is explicitly **not** permission to darken
the world, and the first attempt broke exactly that rule — see below.

### Two instrument lessons, both caught by measuring

**The studded baseplate was carrying our detail score.** Removing it sent flat
8x8 tiles from 22.7% to **57.0%** — far worse than before. The stud grid had
been supplying the high-frequency variation the metric counts. That is a real
limitation of the measure: *a repeating geometric pattern is not surface
texture*, and the demo's 12.5% comes from irregular material detail while our
old 22.7% came from a stamped grid. The metric still usefully answers "is this
surface one flat tone", but it cannot tell plastic studs from plaster.

**Desaturating by lowering value is darkening.** The first ground pass took the
frame median from 93 to 66, which is the one thing pillar 2 forbids in as many
words. Two causes: albedo pulled down along with saturation, and — less
obviously — specular dropped 0.35 to 0.12 with roughness pushed 0.62 to 0.78,
which took a surprising amount of light out of half the frame on its own.

After correcting both, on the **set-piece yard**, which is a fixed camera at a
fixed place and therefore the only frame comparable between runs:

| | before the ground change | after |
|---|---|---|
| median luma | 112.8 | **110.0** |
| mean saturation | 0.706 | **0.569** |
| flat 8x8 tiles | 24.6% | **8.7%** |
| detail | 11.66 | 9.58 |

Same brightness, less saturated, and flatter-than-the-demo turned into
better-than-the-demo. The demo's daylight exteriors sit at 12.5-18.2% flat.

**The gameplay frame is not a controlled measurement** and should not be read as
one: `world.png` is grabbed wherever the autopilot happens to be at t=29, and
across three runs it has framed three different places. The set-piece yard is
the controlled one.

### The loop

The playtest's finding 3 was that 96% of everything happening to the player is
passive collection, and finding 4 was that there is only one denomination.
Both are now addressed, and neither by adding a new verb.

**Studs already came from destruction** — a torn brick becomes debris, and
debris becomes studs when it ages out. The problem was that `BRICK_LIFETIME` is
six seconds, so the reward for a smash arrived long after the smash. Debris the
player knocked loose now lives `PLAYER_BRICK_LIFETIME` — 0.55s — so the payout
belongs to the hit that caused it. The funnel keeps the long lifetime, because
its debris is meant to fly and the flight is the spectacle.

**Denominations are silver 10 / gold 100 / blue 1000**, silver common as in the
LEGO games, with size and colour following value so a jackpot can be picked out
of a field of silver. Denomination *multiplies* with the band at collection, so
`BS:ECONOMY:STUD_VALUE`'s invariant is intact and a gold stud sitting in the red
band is worth going in for.

**A big stud is earned, not rolled.** Gold and blue are not a random weight on
rubble — they drop when a structure is *finished off* (`BS:ECONOMY:FINISH_BONUS`),
so a jackpot has a location and the reward is for completing a smash rather than
starting one. Half-smashing six props used to pay exactly as well as levelling
one, which is why the round played as grazing. Blue for a building (50+ parts),
gold for anything else, paid once per structure whoever finished it.

The bonus is a **stud on the ground, not score**: it has to be collected, so a
jackpot dropping inside the red band is a decision rather than a gift.

### Gates, each proven to fail

- denomination dropped on spawn -> "a 100 stud came back carrying denom 10"
- the `paid_finish` latch removed -> "paid 3 times for one structure"
- player debris lifetime equalised -> "the smash no longer pays before the storm"
- gold sized like silver -> "a 100 stud is not bigger than a silver one"

One correction to the gate itself on the way, and it is the same mistake this
log already records once: the first version spawned its test studs into the
**live** StudField and then called `clear_all()`, wiping the player's
uncollected loot mid-round. The summary line went from 240 studs to 53 and still
said OK. It now runs against a throwaway field and a structure that never joins
the corridor.

### Measured, four rounds at each setting

| | before the loop work | finish bonus unrestricted | restricted (shipping) |
|---|---|---|---|
| final score | 1,495 – 2,622 | 3,406 – 6,470 | **1,545 – 2,638** |
| TRUE CHASER earned | never | **all four rounds** | never |
| gold studs collected | 0 | 51 – 61 | **3 – 6** |
| blue jackpots | 0 | 1 – 2 | **0 – 1** |
| finish bonuses paid | 0 | 92 – 97 | **14** |
| SMASH / min | 5.4 – 11.4 | 2.4 – 5.7 | 5.4 – 12.3 |
| longest silence | 6.1 – 30.3 s | 4.1 – 5.8 s | 10.0 – 17.6 s |

**What landed.** The stud stream has texture: three to six gold and up to one
blue per round, uncommon enough to be worth crossing a room for, and they come
from finishing something rather than from a dice roll. Score is back at the
pre-change baseline and TRUE CHASER is out of reach again, so the rating did not
quietly become free.

**What did NOT land, stated plainly because the middle column is a trap.** With
the bonus unrestricted, dead time looked solved — 4.1 to 5.8 seconds, tight
across all four rounds, against a 6-to-30-second spread before. It was not
solved. **That improvement was bought with jackpot spam:** 92 to 97 finish
bonuses a round is one every 2.2 seconds, and every one of them was a
player-facing event filling the gaps. Restrict the bonus to things worth
announcing and the gaps come straight back, 10.0 to 17.6 seconds.

So the six-second payout delay was real and worth fixing, but it was never what
made the round go quiet. **Dead time is a level-density problem, not a reward-
timing one.** The evidence is that the gaps recur at the same points: two of the
four rounds report 17.6 s starting at t=26.5, and the other two report 10-11.7 s
starting at t≈112. Reproducible timing on an unseeded generator means the storm's
route puts the player in open ground at those points, and the fix is content
ahead of the funnel rather than anything to do with studs.

The SMASH/min difference between the middle and right columns is most likely the
autopilot responding to a changed reward landscape rather than a player-facing
change, and it should not be read as a result.

---

## 2026-09-10 (later still) — "This doesn't scream Oklahoma"

The director's note on the first hybrid build, before playing it. It was right,
and the diagnosis was not subtle once looked for: the frame contained a **white
picket fence** and a **Dutch windmill**. Wrong continent, twice, in one shot.

The rest of it was generic rather than wrong. A barn, a silo and a water tower
on rolling green grass is *any* farm, anywhere. What makes the Great Plains the
Great Plains is specific and mostly absent:

- **The land is surveyed on a grid.** Enormous geometric blocks of different
  crops, separated by dead-straight dirt roads, with the plough rows running
  visibly across each block. Ours was one continuous lawn-green field.
- **The palette is wheat, sage, stubble and RED DIRT.** Oklahoma's soil is
  famously red and storm season is gold and dust. Emerald green is England.
- **Utility poles marching to a flat horizon** — arguably *the* Plains image,
  and the thing chaser footage always has in frame. We had none.
- **Barbed wire on leaning posts**, not pickets.
- **Trees in shelterbelt rows**, planted as windbreaks along a field edge and
  clustered at the farmstead. Scattering them singly across open sections reads
  as a park and, worse, stops the open land reading as open.
- **A grain elevator on the skyline**, visible from further than anything else.
- **A lattice aermotor** with a many-bladed fan and a tail vane.

### What changed

Most of it is in `shaders/ground.gdshader`, because most of it is the ground.
The section grid, the crop blocks, the dirt roads, the plough rows and the
turned headland at each field margin are all procedural and world-locked.

**That also fixed a bug nobody had noticed.** The crop variation used to be
sixteen meshes scattered once within 150m of the origin — while the storm
travels 600m. The back two thirds of every round ran on bare ground. A
procedural function has no such edge.

The grid is offset half a pitch so the section roads fall at x = +/-24 rather
than through the origin: the storm runs down x = 0, and a road there would be
destroyed on every pass and never seen intact.

New props, all smashable and therefore brick-built under the revised pillar 1:
`power_line` (poles, crossarms, insulators, and wires that sag), and
`grain_elevator` (forty plate-thick courses per cell so the funnel takes it down
in rings). `windmill` was rebuilt from a Dutch mill into a splayed lattice
aermotor with diagonal bracing. `fence_run` is barbed wire.

### Three things the renders caught that the code looked fine for

- **The power line's crossarms lay parallel to the line.** `yaw` puts a tile's
  long axis across a run and `yaw + PI/2` puts it along; the crossarm had been
  given the wire's rotation.
- **The wires were 7.5m tiles floating in 14m spans**, leaving three metres of
  air at each end. They read as planks hanging in the sky. Two half-span
  segments per span, tilted, now both reach the poles and sag.
- **Barbed wire tore off as a blizzard of near-black confetti.** Galvanised wire
  is light grey in reality, so this was wrong twice over.

And three self-test failures, all of them the gate correctly encoding the *old*
design: the fence no longer uses a cheese slope because it has no pickets, the
windmill no longer uses a cone because it is not Dutch, and the finish-bonus
check tore an 8m fence with a 6m radius, reached the end of what was in range
and stopped - so the structure never became rubble and the bonus never paid.
That last one was the test being too small, not the code being wrong.

### Measured, set-piece yard (the only fixed-camera frame)

| | olive hybrid | Oklahoma |
|---|---|---|
| median luma | 110.0 | 97.5 |
| IQR | 25.4 | **52.1** |
| flat 8x8 tiles | 8.7% | **4.9%** |
| mean saturation | 0.569 | 0.652 |

Tonal range roughly doubled — the fields give the frame contrast it did not
have — and flat tiles halved again, now well under the demo's 12.5-18.2%.

**Saturation went UP, and that is a deliberate acceptance rather than a
regression.** Wheat gold and red earth are more saturated hues than olive
green; what changed is that they are now *earth* hues. A desaturated lawn is
still a lawn. If the director wants it lower, the wheat and dirt colours are one
line each in the shader.

### Not done

- The sky is still a narrow pale band. Big sky country means the sky is most of
  the frame, and ours sits about a fifth from the top. That is a camera pitch
  change and it affects gameplay framing, so it is not a thing to slip in.
- Corn you can lose a minifig in. `crop_patch` is ankle height.
- Cows are correct, for the record: white, black legs, black patch.

---

## 2026-09-10 (late) — Linearity, the swagger, and a dead zone I built myself

### The corridor was periodic, not straight

Asked whether the game feels extremely linear. It does, and the first
diagnosis was wrong: the funnel is **not** a straight line — it already weaves
+/-31m across a +/-46m corridor on a ~39-second cycle. Reading
`global_position.z += move_speed * delta` and stopping there missed the next
line.

The real faults were underneath:

- **Landmarks came from `b % 7`.** A player travelling 600m saw the same seven
  buildings in the same order, twice. The funnel already weaved; if every block
  is the same recipe there is nothing to weave BETWEEN.
- **Constant speed.** At a fixed 3 m/s the player's relationship to the storm
  never changes: no build, no lull, no chase.
- **No lateral reason to choose.** Props were smeared uniformly, so left and
  right were interchangeable.

Blocks now have a KIND, hashed off the index so the sequence never repeats:
farmstead, town edge, open section, highway. The kind changes the whole recipe
rather than swapping one building. And the storm has a pace that stalls and
surges.

### Then measurement found the dead zone, and it was mine

Four rounds after the block work reported a **25-26 second stretch with no
player-facing event of any kind, in every round, starting at t=125 every
time.** The consistency was the diagnosis: `pace()` is a function of TIME ONLY,
so the hole landed at the identical moment whatever the world seed.

A storm at half speed sits over ground it has already stripped - every
structure in reach is rubble, every stud collected - and the autopilot orbits
an empty circle. **A deterministic dead zone is the one thing a procedural
world should never be able to produce**, and the storm rhythm added to fix
linearity is what produced it.

Worse on inspection: breaking the new gate deliberately showed the old pace
bottoming at **0.28**, not the 0.5 quoted from hand-sampled timestamps. The
sampling missed the true minimum.

Floor raised to 0.70; the curve now runs 0.76-1.35. Two gates, both proven to
fail: one for the floor, and one requiring the pace to actually VARY - so a
future fix for a stall cannot just flatten the curve and quietly restore the
treadmill.

### And a second self-inflicted one: the storm kept missing the value

Clustering each block's buildings 11-33m off centre gave the player a lateral
choice and **starved the funnel**. Bricks torn fell 144-149 to 88-100 while
live structures ROSE 159 to 184: more being built, less being destroyed,
because the funnel weaves on its own schedule and the clusters were placed by a
hash. The two do not correlate. In a game where funnel debris is where the
money is, that is not a stylistic choice. Clusters now sit 2-19m off centre,
where the funnel actually spends its time; the choice survives, nearer the
middle.

### Measured, four rounds at each stage

| | b%7 corridor | block character | + cluster fix | + pace floor |
|---|---|---|---|---|
| longest silence | 10.0-17.6s | 8.5-20.4s | 25.1-26.0s* | **5.6-7.9s** |
| bricks torn | 144-149 | 88-100 | 163-169 | **383-410** |
| STUD/min | 57-114 | 93-142 | 81-128 | **185-237** |
| live structures | 159 | 184 | 211 | 201 (peak 242) |
| distance | 600m | 583m | 583m | 658m |

\* all four at t≈125 — the deterministic hole.

Dead time at 5.6-7.9s is the best this project has measured, and unlike the
earlier false positive it is not bought with jackpot spam: the timing now
VARIES between rounds, which is what says the determinism is gone.

**Knock-on, stated rather than left to be found:** a healthy storm doubles the
stud rate, so score is now 10,000-16,000 and TRUE CHASER trips in all four
rounds. That is playtest finding 2 for the third time. `TRUE_CHASER` is still
NOT retuned - it has been set from autopilot numbers twice and been wrong
twice - but it is now definitively too low rather than merely suspect.

### The swagger

Director note: TT's men half-run led from the shoulders, their women from the
hips. Exactly right, and the rig could not express it: Torso, Shoulders and
Hips were flat siblings, so there was nothing to lead FROM. Both characters
walked identically and the swap was invisible below the neck.

A minifig cannot bend a knee or an elbow - the parts are rigid - so unlike
almost any other character animation, **the only place personality can live is
where the motion originates**. The rig is split at the waist (`Pelvis`,
`Upper`) and driven against itself: Jo rolls and shifts the pelvis with quiet
shoulders; Bill rolls the upper body nearly 4x as hard, twists twice as much
against the hips, and throws the arms nearly twice as wide. Torso twist runs
COUNTER to the hips, as a real gait does.

Gated three ways - the table must differ, the rig must have the pivots, and the
two must strike measurably different poses mid-stride - and proven to fail.

**One gate needed fixing first, and it is worth recording.** The pose check
dereferenced a null pivot when the rig was broken, which does not fail a Godot
run: it abandons the self-test part-way and the game loops until the harness
timeout. The structural check had already found the real fault; the behavioural
one swallowed it into a hang. **A gate that hangs CI is worse than one that
fails**, because a timeout says nothing about what broke.

**A pre-existing bug fell out of building the probe:** the arms were 5.9mm wide
and flared 0.20 radians outward, reading as shoulder pads with daylight between
them and the torso. The real part is about 4mm and hangs nearly vertical.
Only visible in a dedicated front render of the rest pose - a walk cycle strip
would not have shown it, and a gameplay screenshot never did.

### The API audit

Asked whether we are underusing Godot. Three real answers:

- **CI had never been checked.** Four probes wired in across five pushes, with
  "wired into CI" in the commit messages, and not one run ever verified. All 27
  are green and every probe step executes - but that was luck, not diligence.
  What makes it trustworthy rather than assumed is that part_probe.gd fails
  itself when the MultiMesh buffer reads back empty, which is exactly what a
  missing renderer looks like. It passes, so a renderer is genuinely there.
- **Loose studs are drawn the way this project banned.** `StudField` makes a
  Node3D per stud and `stud_visual()` puts TWO MeshInstance3Ds in each: 480
  draw calls at the 240 cap, in a codebase that batched every structure into
  MultiMeshes to avoid precisely this, for the most numerous objects in the
  game. Not yet fixed.
- **Zero particles anywhere.** No GPUParticles3D or CPUParticles3D. The
  tornado is the headline visual of a tornado game and has no dust skirt, no
  dirt streaming up the vortex, no motes, no rain or hail.

Also unused and worth having: `visibility_range` (Godot implements the LOD
falloff TT_ENGINE_NOTES records as "not implemented"), `AnimationTree` (the
hand-driven gait will not blend idle/walk/run/carry/brace as if-chains), and
`Path3D` for authoring set pieces along the storm's route. Correctly absent on
the compatibility renderer: Decal, volumetric fog, SDFGI.

### Not done

- **Iconic scenes.** The storm cellar and the chase rig are PROPS, not scenes.
  The drive-in, the barn you drive through, and the sisters are the three that
  would make someone say "that's Twister", and the authored-area machinery
  already exists and is used exactly once, at the start.
- Studs to a MultiMesh; particles on the funnel.
- No CLAUDE.md, so the no-drift policy and the anchor discipline do not load
  into a future session automatically.

## 2026-09-10 — The scenes

Three hand-composed set pieces now sit along the corridor: **the drive-in**,
**the barn you run through**, and **the cow field**. The authored-area
machinery had existed for weeks and was used exactly once, at the start of the
level; everything after the first forty metres was procedural, which is most of
why the corridor read as linear.

They are placed every **165 m**, occupying a **46 m** reserved slot, rotating in
a fixed order. `AreaMap.reserve()` claims the ground ahead of the streaming
frontier and marks it AUTHORED; the dressing happens after `ensure_ahead`, in a
separate pass, so **`populate` is still never handed an authored area** — the
reservation rule stays exactly as it was, and `_authored_populated` still counts
every violation at zero.

### What each scene is for

- **The drive-in** — a screen, three ranks of pickups facing it, a booth, a
  speaker post per car, and a cow standing on top of the screen. It is the one
  scene built around a single joke.
- **The barn run** — a barn open at both ends with a chase rig parked square
  with the opening, fences funnelling toward it, and hay and crates inside on
  the centreline so going through beats going round.
- **The cow field** — a fenced pasture, a windmill, a storm cellar, and a herd
  of nine. Law 1 (cows fly, cows land, cows are never destroyed) is what makes
  the flying cow a joke rather than a casualty, and this is the scene that
  exists to land it.

### The barn was a gateway, and the picture said so

The first barn was 12 × 20 studs. Rendered from the road it read as an *arch*:
the field beyond filled the whole opening, and there was no tunnel to be inside
of. Measured, that is 10.5 m deep against 6.0 m wide — 1.75:1. At 12 × 30 it is
15.0 m against 6.0 m and it reads as what it is. **The self-test now asserts
2:1**, and the failure message says why rather than quoting a number.

The white trim took three tries, all decided by looking at a render head-on:

1. A band flush to both ends terminated at the opening and read as a **white
   patch stuck to each corner**.
2. Full-height corner boards — which is where a real barn's white actually is —
   turned it into a **gazebo with two bright columns** flanking the hole.
3. A band right round the top, sides and both ends **frames the doorway**.

Trim that runs horizontally frames a hole; trim that runs vertically competes
with it. That is the whole lesson and it took a picture to see.

### The cow read as a table

Nine cows in a pasture, and every one of them a white slab on four black legs
with a single patch on its spine. From a road — and from the air, thrown past
at head height, which is the *point* of the cow — what an animal shows is its
**side**. Patches moved to the flanks, plus a muzzle, ears and a tail. The
silhouette is now a cow at fifty metres, which is the only distance that
matters for the gag.

### Four gates, and the one that found a real bug

`--selftest` now builds all three scenes and asserts:

- each has at least 10 structures and 150 parts;
- **every part lands inside the slot the map reserved** — `[-SCENE_LEAD,
  SCENE_DEPTH - SCENE_LEAD]` in Z and inside the corridor in X;
- the barn's centreline is clear end to end, sampled at three heights;
- the barn is at least twice as deep as it is wide.

All four were proven to fail: by walling the barn's far end (6 of 123 sample
points blocked), by gutting a scene to three structures, and by shrinking the
barn back to 20 studs.

**The bounds gate found a real bug on its first run.** `barn_run` parked its
truck at z = −6 with the scene origin only 4 m into the slot, so the truck sat
two metres inside the *previous* area, where the streamer had already scattered
procedural props. Nothing crashes when that happens; you just get a truck in
somebody's wheat. The lead is now a named constant, `SCENE_LEAD = 8.0`, used
both by the placer and by the gate, so the two cannot drift apart.

A second bug, found by reading rather than measuring: the scene rotation was
`_scene_built.size() % 3`, which worked only because that dictionary happens to
be pre-seeded with exactly two entries. Adding a third pre-seed would have
silently reordered the entire level. It has its own counter now.

### The probe that renders, and the threshold I guessed

A scene can build perfectly — right structure count, right part count, every
bound inside its slot — and **draw nothing**, if the geometry ends up behind the
camera or under the ground. `--selftest` never renders, so it cannot see that.
`tools/scene_probe.gd` now differences each scene's road view against an empty
frame of the same ground and fails a scene that changes too little of it. Proven
by sinking the scenes 400 m: all three still reported full structure, part and
cow counts while covering 0.000 of the frame.

**The comparator is validated before it is trusted.** Two empty frames are taken
several frames apart and differenced first; if the ground drifted between frames
or the read-back returned something that was not the picture, the drift would be
non-zero and the probe fails *itself* rather than reporting a number nobody
should believe. It measures 0.0000. A brightness-thresholded mask and a PNG byte
comparison have both lied to this project before.

**And I set the threshold before measuring anything.** MIN_COVER went in at 0.04
and failed `barn_run` (0.028) and `cow_field` (0.023) — two scenes that were
drawing perfectly well. A threshold set above the thing it is meant to admit
tests nothing except the author's guess. It is 0.010 now, chosen from the
measured spread: real scenes cover 0.023–0.040, a scene that does not draw
covers 0.000.

### The anchor verifier could not see a dangling reference

`verify_anchors.gd` checked that every anchor in the code is registered and
every registered anchor exists — in both directions — and still could not see
that a comment saying "see BS:PLAYER:GAIT" pointed at an anchor folded into its
parent months ago. **Nothing searches for a reference, so a reference rots
silently.** The verifier now resolves every cross-reference in the code, and
found six:

| reference | reality |
| --- | --- |
| `BS:PLAYER:GAIT` | folded into `BS:PLAYER:WALK_CYCLE` |
| `BS:BUILD:PLAINS` | folded into `BS:BUILD:TOWN` |
| `BS:RENDER:LOOK` | never existed; meant `BS:WORLD:ENVIRONMENT` |
| `BS:CONTENT:BARN_RUN` | mine, from this session; meant `BS:CONTENT:SCENES` |
| `BS:PROP:OPEN_BARN` | mine, from this session; the barn lives in `BS:BUILD:TOWN` |
| `BS:WORLD:AREA_MAP` | **the anchor was genuinely missing** |

The last one mattered. `scripts/area_map.gd` is the single authority on where
one part of the world ends and the next begins, it carries the reservation rule
the whole scene system depends on, and it had **no anchor at all** — so the one
invariant that keeps hand-composed ground from being scattered with procedural
props was written down nowhere the verifier could check. It has one now
(78 anchors). Prose in `Docs/` is exempt: a decision log legitimately names a
retired anchor when recording that it was retired.
