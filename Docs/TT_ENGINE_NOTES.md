# TT Engine Notes

What the LEGO Indiana Jones demo revealed about **how the game is built**, as
opposed to how its design works. Design reasoning lives in
`Docs/TT_GAMES_REFERENCE.md`; this file is structure, vocabulary and numbers.

## Provenance and the line

Everything here came from files that ship in plain sight in the demo: two text
config files, the strings in the executable, and source paths left embedded in
the data archives. Nothing was decompiled, no archive was unpacked, no asset was
extracted, and nothing from the demo is in this repository. **Identifier names
and structural observations are not assets.** The rule in
`Docs/TT_GAMES_REFERENCE.md`, "The line we do not cross", is unchanged.

Where a finding is a *number they chose*, it is worth more than any opinion in
this repo, and it is marked **[their number]**.

---

## 1. The engine is NU2, and one codebase serves three franchises

The shaders carry `#pragma nu2_declare` / `#pragma nu2_use` directives and a
`ShaderBuilder` that generates permutations from HLSL with a custom
preprocessor. The music format is "NuMusic".

The Indy executable still contains **LEGO Star Wars achievement text** ("Destroy
300 stormtroopers", "Perform 200 perfect lightsaber deflections", "Break Jar Jar
20 times") **and a LEGO Batman event flag** (`BeenHitByBatarang`). Indy shipped
June 2008, Batman that September. So this is one engine and one game codebase,
re-skinned per franchise, with the previous franchise's data left in the binary.

*What this means for us:* the thing being reused across LEGO games is not a
library of levels, it is a **vocabulary of verbs**. That vocabulary is below.

---

## 2. Character abilities are a flat table of booleans

Not a class hierarchy. Not components. Twenty-odd independent flags:

```
CanAttack              CanOpenDoors           CanShootObstructions
CanDefend              CanPullLevers          CanShootOffScreen
CanUse                 CanTriggerObstacle     CanHitForceObjects
CanUseWeapon           CanHelpWithTriggers    CanBeTargettedByCable
CanBeCarried           CanGetToNode           CanMoveWhenDeactivated
CanUseSupercarry       CanCollideWithObjects  CanHearRadio
CanTurn                CanSeeBehind
```

An obstacle asks for one flag; a character either has it or does not. That is
the entire Free Play gate. It is flat, it is inspectable, and a designer can
answer "who can open this?" by reading one row.

*Act on this:* BRICKSTORM's `heavy` ability gate on structures is the first
entry in a table like this, and it should be built as a table now, while there
is one entry, rather than as a growing pile of special cases later.

---

## 3. The camera is authored per zone, and its tilt is a function

Level data contains per-sub-area camera files - `LostTemple_D_CAM_PC.GSC`,
`..._E_CAM_...`, `..._G_CAM_...`. Only *some* sub-areas have one. So the camera
is automatic by default and **hand-authored where it matters**.

The tuning vocabulary says how the automatic one behaves:

| Identifier | What it implies |
|---|---|
| `CamRangeOfEffect` | authored cameras have a radius; you blend in and out of them |
| `CamMinDist` | a hard floor on distance to the subject |
| `CamTiltDist`, `CamTiltHeight` | pitch is a **function of distance and height**, not a constant |
| `CamTiltAngChange`, `CamTiltAngRate` | and the angular change is **rate-limited** |
| `CamCharCloseLift` | when the character gets close, lift the camera |
| `CameraShake` vs `JudderGameCamera` | two distinct impact feedbacks, not one |
| `CameraCut` vs `DynamicCameraCut` | scripted cuts and dynamic cuts are separate systems |
| `CamCutPlayerReset` | a cut resets the player's frame of reference |

*Act on this:* `CamCharCloseLift` and `CamMinDist` are precisely the two rules
whose absence put our camera inside the funnel. And `CamCutPlayerReset` names a
bug we already fixed by hand: after a camera cut, a screen-relative stick has to
be re-based or the player walks the wrong way.

---

## 4. "Context" is their word for a staged interaction

`InContext`, `NoContext`, `OpponentContext`, `EitherPlayerInContext`,
`ContextSetAnimation`, `ContextAnimationFrame`, `IsContextAnimationFinished`,
`ResetContext`, `ResetContextAIAnimation`, `OverrideAnimation`.

A character *enters a context* - a lever, a build, a fight - and the animation is
then driven by the context rather than by locomotion. `OpponentContext` means
two characters can be in the same context, which is how paired fight animations
and co-op builds work.

Alongside it: `AnimTimeRandom` and `AnimSpeedMul`. The same anti-repetition
principle as the audio config's pitch randomisation, applied to animation.

*Act on this:* our BUILD is currently an instant state change. A context with a
finish event (`BuildItComplete`) is what makes it feel like an action.

---

## 5. Build spots are called "Build-its", and there are 100 in the game

**[their number]** An achievement reads *"Make 100 Build-its throughout the
game."* The engine has `BuildIt`, `BuildItComplete`, and seven distinct visual
variants `BUILD_IT1`..`BUILD_IT7`.

One hundred, across a game with roughly 18 story levels plus a hub - so **on the
order of five build spots per level**. Build-its are a *punctuation mark*, not a
texture. Our own playtest counted build opportunities as the thing we most
needed to measure; this is the target to measure against.

Also **[their number]**: *"Perform 20 unblockable combo attacks"* - combat has
authored combo strings, not just a mash.

---

## 6. Music is three states per zone, with authored transition points

`Music.CFG` is plain text and documents its own format. Four keywords:

- `QUIET` - the exploration bed
- `ACTION` - the combat variant
- `NOMUSIC` - the ambience-only bed
- `CUTSCENE` - a one-shot cue

Tracks sharing an `ID` are one logical cue with several intensities. **[their
number]** in the shipped config: **75 QUIET, 68 ACTION, 82 NOMUSIC, 96
CUTSCENE**. One level (Lost Temple) uses seven zone IDs, so roughly **seven
music zones per level**.

The important mechanism is `IX`: each track carries a list of timestamps, and
those are the **only points at which the engine may transition**. A fight ending
does not cut the music; the engine waits for the next `IX` marker. **[their
number]** the gaps between markers run from about 5 to 32 seconds, and one cue
is visible in the file having been re-cut from ~16s gaps to ~5-10s gaps, with
the old line left commented and marked `old`. They tightened musical latency
during development.

Two more things the file shows plainly:

- `STRICT` - "causes any errors to stop execution - during development". A
  build-time gate on audio data, which is the same doctrine as
  `Docs/NO_DRIFT_POLICY.md`.
- Heavy reuse: one ambience bed serves six zones across **two different films**,
  and one zone's quiet track is simply another zone's, the bespoke version
  having been cut. Placeholder entries ("PLACE-HOLDER In-Game Music") shipped in
  the retail data.

*Act on this:* our storm roar is a continuous bed with no state. Three states
and a transition-point rule is a bigger win for feel than any new sample.

---

## 7. The sound bank is authored, exhaustively

From `Audio.CFG` (full numbers and the acted-on consequences are in
`Docs/TT_GAMES_REFERENCE.md`, § Observed):

**[their numbers]** 1,421 sample entries; 1,337 with pitch randomisation (median
+/-10%); 793 with volume randomisation that is **always negative**; 156 with an
explicit voice priority; 221 marked non-positional; 198 loops; 127 multi-variant
groups. Only 24 carry custom near/far attenuation, so one default curve covers
the rest.

Two details worth stealing outright:

- A **dummy sample in slot 0 at volume 0**, commented "to avoid uninitialised
  sound IDs playing the first sample in the list".
- **Rumble is authored on the sound**, not on the gameplay event, with an
  envelope: `rumble [buzzTime rumbleStr rumbleSustain rumbleRelease]`. For a
  phone, haptics should be defined next to the SFX and share its shape.

---

## 8. Asset and level layout

Source paths embedded in the archives give the project tree:

```
LEVELS/<FILM>/<LEVEL>/<LEVEL>_<PLATFORM>.GSC
LEVELS/<FILM>/<LEVEL>/<LEVEL>_<SUBAREA>/<...>_CAM_<PLATFORM>.GSC
INDY_DATA/CHARS/<NAME>/<NAME>_<PLATFORM>.GHG
INDY_DATA/CHARS/<NAME>/<NAME>_LR_<PLATFORM>.GHG
```

- Two formats only: **`.GSC`** (scenes, props, icons, title screens) and
  **`.GHG`** (rigged characters). Archives are `MkDat V3.26`.
- **Every asset is per-platform.** `_PC` is in the filename. They did not scale
  one build across platforms; they exported per platform.
- **`_LR` is a separate low-resolution file**, not runtime decimation. Even a
  crocodile ships in two LODs.
- **The whip and the rope are characters**, in `CHARS/`, with skeletons - not
  props.
- Levels divide into lettered **sub-areas** (A, B, D1, D2F, E, G), and sub-areas
  are the unit that camera files and music zones are attached to. This is the
  same unit at every layer.
- Localisation is per-asset, not per-string: nine separate authored demo screens
  (`demo_english_PC.GSC`, `demo_usspanish_PC.GSC`, ...).
- `AREA_PLAYERSAFE` exists as a level volume - safe areas are authored geometry.

*Act on this:* "the sub-area is the unit" is the strongest structural idea here.
Camera, music and streaming all key off the same division. BRICKSTORM's
corridor already streams in segments; those segments should become the named
unit that camera and audio state also key off, rather than three systems each
inventing their own boundaries.

---

## 9. The unlock roster is enormous, and costumes count

**[their number]** The demo executable carries icon references for roughly **133
characters** - the full retail roster, left in a demo build.

The composition matters more than the count:

- **Costume variants are separate unlocks.** Indiana Jones alone has about
  eleven; two other leads have six and five. A new hat is a new purchase.
- **Vehicles and animals are in the same roster** as characters, with icons in
  the same directory.
- **Joke and cameo unlocks** sit beside the real ones - Star Wars cameos from
  the LucasArts connection, a Santa, and plain colour minifigs. The humour layer
  is expressed as things you can buy.
- Duplicate and misspelled entries shipped (two spellings of one villain's name;
  one costume with a typo'd filename shipped alongside the corrected one).
  Their naming convention was not tool-enforced. Ours is, via
  `tools/verify_anchors.gd` - keep it that way.

*Act on this:* the absurdly generous stud shower only works because there are
133 things to spend on. A generous economy with a thin shop is just noise. This
is a hard constraint on our own unlock design, and we currently have no shop at
all.

---

## 10. The shading model, which is the answer to "it doesn't look like a LEGO game"

About 200KB of HLSL ships as readable source inside the executable, with 257
declared uniforms. It is a permutation system: a preprocessor
(`#pragma nu2_declare` / `nu2_use`) plus a `ShaderBuilder` that compiles the
combination each material asks for. The pipeline per pixel is

```
fresnelStage -> reflectivityStage -> lightingStage -> tweakStage
             -> envmapStage -> refractionStage
```

Four lighting models are selectable per material: **Lambert, Phong, Ward**
(anisotropic) and **Gooch** (non-photorealistic). Not one shader with knobs -
four models.

What actually produces the look, in order of how much it would change ours:

- **A shading term smuggled into the LENGTH of the vertex normal.** The dapple
  factor is literally `length(varying_normal.xyz)`, and it multiplies surface
  colour. Interpolation shortens a normal wherever adjacent vertex normals
  diverge, so creases and curvature darken **for free** - no extra attribute, no
  texture, no second pass - and the exporter can shorten normals deliberately to
  author darkening. Normalisation throws this quantity away in every renderer
  that does not think to look. *(The mechanism is explicit in the code; that
  they used it for contact shading is my inference.)*
- **Glow LERPs toward white, it does not add.**
  `diffuseLight = lerp(diffuseLight, 1.0, incandescentGlow.rgb)`. A glowing
  stud is a surface washed to full brightness, per channel, with no bloom pass
  anywhere. Additive glow blows out and looks like a bug; this cannot.
- **Three directional lights, and specular has its own colours.**
  `lightColor0..2` for diffuse and **separate** `specLightColor0..2` for
  specular, evaluated in parallel by packing three dot products into one
  `half4`. Separate colours are what let plastic be shiny without the diffuse
  going pale - which is exactly the "specular blowout" we hit and solved by
  splitting materials instead.
- **Ambient is a diffuse environment cube, not a flat colour.**
  `texCUBE(diffenvmap_samplerCube, worldNormal)` with an `envRotation`. The top
  of a brick picks up sky and its underside picks up ground. A constant ambient
  term is the single flattest thing a renderer can do, and it is what we do.
- **Specular is multiplied by `fresnel * fs_lodFactor`.** Grazing angles get the
  highlight (the plastic read), and distant geometry loses it entirely - which
  kills shimmer and costs nothing.
- **Two ambient terms and one global dimmer.** Per-material `ambientColor` plus
  global `sceneAmbientColor`, and under `MODULATE_AMB_INC` the scene's alpha
  scales material ambient *and* glow together. One knob dims every self-lit
  surface in the level at once - walking into a dark interior is a single value.

*Act on this, in this order:* the environment-cube ambient and the
fresnel-scaled specular are the two that would change our screenshots most, and
Godot gives us both almost for free. The normal-length trick is worth stealing
for authored props. Nothing here needs an asset.

---

## 11. Systems we have no equivalent of

Straight from the engine's vocabulary. Each of these is a named subsystem in
their code and an absence in ours.

- **Authored gameplay volumes.** `AREA_PLAYERSAFE` and `NoFightingZone` are
  level data - places the designer marks as safe, or where combat is switched
  off. We now have `SubArea`; these are the obvious next fields on it, and they
  are cheap.
- **Hints are stateful, tagged and cancellable.** `SetHint`, `CurrentHintId`,
  `HintAvailable`, `TagHint`, `HintComplete`, `CancelHint`. A hint is raised,
  becomes available, is satisfied, or is *withdrawn* when it stops being
  relevant. Not a tooltip. We have nothing.
- **"Attracto" - the magnet has a target, not just a player.** `AttractoTarget`
  and `AttractoDeposit` alongside `Attracto`. Collectibles fly to a
  *destination*, which is what makes a deposit-the-loot beat possible. Our
  magnet only ever pulls to the player.
- **Co-op is in the trigger vocabulary, not layered on top.** Nearly every
  trigger has an "either player" form: `EitherPlayerInTriggerArea`,
  `EitherPlayerPullingLever`, `EitherPlayerPushingSpinner`,
  `EitherPlayerOnForcePlatform`, `EitherPlayerSuperCarrying`. And **"party" is
  its own entity** - `PartyUnderCover`, `AnyPartyOnRideObject`,
  `PartyCanBeUnderCover` - distinct from either individual player. Cooperation
  has explicit verbs too: `HelpWithCarry`, `CanHelpWithTriggers`.
- **Traversal is a named move set, and ledges are terrain.** `GrapSwing`,
  `WHIPSWING`, `RappelDownRope`, `TightropeCatch`, `LEDGEMOVE`, and
  `LedgeTerrain` - a ledge is a *terrain type*, not a collider bolted to each
  prop. `SuperCarry` is the two-handed heavy carry, with its own drop, throw and
  blow-up cases.
- **Per-instance overrides everywhere.** `AwkwardShapeOverride`,
  `SetScaleOverride`, `ConveyorOverride`, `AIOverrideControl`,
  `OverrideAnimation`. A designer can break any rule on one object without
  touching the system - which is how a hand-authored set piece stays hand-
  authored.

They also shipped a flag called `DisableNarrowSocks`, which is offered here
without further comment.
