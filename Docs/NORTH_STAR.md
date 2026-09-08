# BRICKSTORM North Star

The immovable target. Everything in this repository is measured against this
document. If a change cannot be justified against a pillar below, it is drift —
see `Docs/NO_DRIFT_POLICY.md`.

This document changes only by explicit director approval, and never as a side
effect of implementation work.

---

## One-sentence target

**A brick-built farm town torn apart by a living tornado, where the player is
paid to work inside the blast radius — and the closer they dare to stand, the
more it pays.**

---

## The inversion this game exists to deliver

The LEGO games let the player smash the world. **BRICKSTORM makes the tornado
smash it, and pays the player to loot the debris while it is still moving.**

That single reversal is the reason this project exists. It is not a stylistic
preference and it is not negotiable. Any proposal that returns the player to
being the primary agent of destruction — a bigger smash attack, a destruction
combo meter, a "power up the tornado" mechanic — has quietly rebuilt a different
game and must be refused at the design stage, not fixed later.

Bill's shoulder-charge exists **only** as a character ability gate. It is not the
game's destruction model and must never grow into one.

---

## Visual and design pillars

### 1. True brick construction

Everything in the world is built from real brick shapes at a real stud pitch,
with studs visible on top surfaces. If it cannot be built from parts, it is not
in the game. The one deliberate exception is the funnel itself (pillar 3).

### 2. The world stays cheerful; the sky carries the dread

The ground-level palette stays bright and saturated — classic brick colours,
flat-leaning shading. The sky goes green-black. That contrast **is** the visual
identity. Darkening the world to signal danger destroys it and is forbidden.

### 3. The funnel reads as a force, not an object

The tornado is the only thing not made of bricks: dark, smooth, rotating, and
visibly writhing. Scenery comes apart *into* it. It must never acquire a face, a
health bar, a name, or any other property that makes it read as a creature.

### 4. Destruction is physical, readable, and paid for

A structure comes apart brick by brick, the bricks are really simulated, and they
really become the currency. The player must be able to look at any pile of
rubble and understand what it used to be.

### 5. Risk is legible at a glance

The value gradient around the funnel is drawn on the ground in colour, and the
current multiplier is the largest element on the HUD. A player must never have
to guess what a position is worth.

### 6. Mobile is the primary design target

Not a port target. Two thumbs, no camera control, one context button. Any
mechanic that cannot be operated by a thumb on a phone held in landscape is not
finished, regardless of how well it plays on a desktop.

---

## The two laws

These are enforced in code, not maintained by memory. See
`Docs/CODE_ANCHORS.md` for where.

### Law 1 — Nothing that moves is ever destroyed

People, minifigs, cows, dogs, horses, and every future moving actor can be
lifted, spun, flung and landed. They are never damaged, never scored as damage,
and never removed. **Only scenery comes apart.**

This is what lets a tornado game be joyful rather than grim, and it is the single
most load-bearing tonal decision in the project.

Enforcement: debris lives on its own collision layer and cannot touch an actor —
a new hazard cannot bypass the law by existing. `[BS:LAW:NO_HARM]`

### Law 2 — There is no fail state, only a toll

Getting caught costs a share of the player's studs, which scatter and can be
re-collected. The player is carried up, spun, and set down. There is no game
over, no lives, no retry screen, and no progress loss.

This is what makes the game playable one-handed, on a bus, by a child, and it is
why the player will take risks at all. `[BS:LAW:NO_FAIL]`

---

## What "done" looks like

### For the current vertical slice

Already met. A funnel that dismantles a town in real time, distance-scaled stud
value with visible bands, wind pressure and BRACE, two characters with real
ability gates, and a build-and-deploy objective that closes the loop.

### For v1.0

- The seven-level campaign along the Fujita scale (`Docs/GAME_CONCEPT.md` §6)
- Sensor balls (10/level), Extreme Bricks, and the True Chaser threshold
- Free Play with the full roster
- A hub the studs are spent in
- Audio: a roar that scales with proximity, and silent-comedy pantomime
- Physically accepted on the target Android device in landscape

---

## Target screenshot checklist

A screenshot is only on-target if it shows:

- a structure mid-disassembly, with individual bricks identifiable
- studs visible on brick top surfaces
- at least one intact structure for scale contrast
- the funnel reading as a force, not a shape sitting on the ground
- the risk bands drawn on the ground
- the multiplier legible as the dominant HUD element
- a bright, saturated world under a threatening sky
- no dead empty ground filling more than a third of frame
- HUD that supports the scene rather than covering it

---

## What this game is NOT

Listed because each has been proposed for games like this and each would quietly
replace it:

- **Not a management or tower-defence game.** The player is on the ground, in the
  wind, in the blast radius. Not above it choosing placements.
- **Not a survival game.** No hunger, no durability, no permadeath. See Law 2.
- **Not a weather simulator.** The funnel obeys drama, not meteorology.
- **Not a combat game.** There are no enemies. The response to the storm is a
  media circus, not a battle.
- **Not a builder.** Building is a reward beat with a jingle, not a creative mode.
- **Not photorealistic.** It is a brick toy, deliberately.
- **Not a licensed product.** See "Naming" below.

---

## Settled decisions

Do not relitigate these without director approval:

| Decision | Settled |
|---|---|
| Engine | Godot 4.7.2 |
| Renderer | `gl_compatibility` — fastest on low-end Android, and the only path that works in a browser without cross-origin isolation headers |
| Orientation | Landscape only |
| Primary platform | Android; web is the fast playtest lane |
| Camera | Auto-framed, fixed angle, no player control |
| Destruction model | Cheap visuals until torn; `RigidBody3D` only once loose |
| Vortex forces | Accelerations, not forces — the mass factor cancels |
| Branch policy | `main` neutral; this is the Claude branch; `openai/*` untouched |

---

## Naming

*LEGO* and *Twister* are trademarks of the LEGO Group and Warner Bros.
respectively. This is an unlicensed prototype and a design exercise.
**BRICKSTORM**, and the character and level names throughout, are placeholders.
They must be replaced before publication anywhere.

The design does not depend on them. The risk-band economy works exactly as well
with an original storm-chaser cast, and replacing the names costs nothing but a
find-and-replace. Not replacing them costs the project.
