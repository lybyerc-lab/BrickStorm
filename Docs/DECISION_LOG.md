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
