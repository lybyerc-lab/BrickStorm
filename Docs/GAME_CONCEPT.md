# BRICKSTORM
### A LEGO-formula action game built on *Twister* (1996)

**Working title:** BRICKSTORM
**Platform:** Mobile-first (Android landscape), web build for playtesting
**Engine:** Godot 4.6
**Model:** Single-player, drop-in second character, arcade campaign

---

## 1. The one-line pitch

> The LEGO games let you smash the world.
> **BRICKSTORM makes the tornado smash it — and pays you to loot the debris while it's still moving.**

That inversion is the whole design. Everything below serves it.

---

## 2. Why this movie, and why it works

*Twister* is a nearly perfect fit for the TT Games formula, and almost nobody notices why:

| The LEGO formula needs | *Twister* already has it |
|---|---|
| A small cast with hard-coded specialities | A chase team where everyone has one job |
| A recurring "get the thing into the place" objective | **DOROTHY.** Deploy the pod into the funnel. Every act. |
| Escalating set pieces | The Fujita scale. F1 → F5, built into the source material. |
| Big destructible scenery | A movie whose entire budget was destructible scenery |
| Collectibles that make in-world sense | Dorothy's sensor balls. Hundreds of little spheres, by design. |
| A slapstick tone that survives disaster | See §3 |
| A ragtag hub | The convoy of antenna-covered vans |

The film is a chase movie about *getting closer to the dangerous thing on purpose.*
That is a risk/reward economy sitting in plain sight.

---

## 3. The tonal problem, and the solve

*Twister* is a disaster movie. People die in it. LEGO games are joyful.

The LEGO formula solves this for free, and we lean on it hard:

**Nobody dies. Minifigs pop apart into their own studs and reassemble, dusting themselves off.**

That is not a compromise — it is the single most important design law in the project, because
it's what makes a tornado game *playful* instead of grim. When Bill takes an F4 to the chest he
explodes into a pile of bricks, the pieces hop back together, and he does the little annoyed
shrug. The audience laughs. Nothing is lost but studs.

**Design Law #1 — Nothing that moves is ever destroyed.**
Minifigs, cows, dogs, and horses can be lifted, spun, flung a quarter mile, and landed. They are
never damaged, never scored as damage, and never removed. Only *scenery* comes apart.
Enforce this in code at the single point where damage is applied, not by convention — an
invariant that everyone has to remember is an invariant that will break silently.

**Design Law #2 — There is no fail state, only a toll.**
Get caught by the funnel and you're carried up, spun, and dropped somewhere safe, minus a
fraction of your studs (which scatter and can be re-collected). No game over. No retry screen.
No lives. This is what makes it playable one-handed on a bus.

---

## 4. Core loop

```
        ┌─────────────────────────────────────────────┐
        │  The tornado wanders the level in real time  │
        │  and converts scenery into flying bricks     │
        └───────────────────────┬─────────────────────┘
                                ▼
        ┌─────────────────────────────────────────────┐
        │  Debris becomes loose studs on the ground    │
        └───────────────────────┬─────────────────────┘
                                ▼
        ┌─────────────────────────────────────────────┐
        │  Studs are worth MORE the closer to the      │
        │  funnel you collect them  ◄── the whole game │
        └───────────────────────┬─────────────────────┘
                                ▼
        ┌─────────────────────────────────────────────┐
        │  Studs buy the build you need to deploy      │
        │  DOROTHY — which requires standing in the    │
        │  most dangerous band on the map              │
        └─────────────────────────────────────────────┘
```

You are not fighting the tornado. You are **farming** it. It is a moving, screaming,
extremely dangerous resource node, and the game is about how close you dare to stand.

### The risk bands

Concentric rings around the funnel, always visible, colour-coded on the ground:

| Band | Distance | Multiplier | Feel |
|---|---|---|---|
| **GREEN** | outside 34m | ×1 | Safe. Boring. |
| **YELLOW** | 34m | ×2 | Wind pushes you. Hats come off. |
| **ORANGE** | 22m | ×3 | You must BRACE to hold ground. |
| **RED** | 12m | ×5 | Only Bill can stand here. Debris everywhere. |

The multiplier is a giant number on the HUD that climbs as you walk toward death.
It is the combo meter, and the movie's entire thesis, in one UI element.

---

## 5. The cast as ability gates

Classic TT design: each character has exactly one verb nobody else has, and levels are
built as locks for those keys. Swap is instant, one tap.

| Character | Verb | Gate it opens |
|---|---|---|
| **Jo** — the Reader | **READ THE SKY.** Reveals the funnel's next path as ghost markers, and doubles stud magnet range. | Planning gates: routes that are only survivable if you know where it's going. |
| **Bill** — the Extreme | **BRACED.** Heavy. Walks in the RED band without being lifted; shoulder-charges scenery to smash it himself. | The ×5 band. The high-value loot is where only Bill can stand. |
| **Dusty** — the Rigger | **FAST BUILD.** Builds at triple speed and can repair a wrecked build spot. | Timed builds — the anchor that must exist before the funnel arrives. |
| **Melissa** — the Outsider | **PANIC RUN.** Fastest movement in the game, but she cannot stop voluntarily and drops what she's carrying. | Distance gates. Pure comedy. She is terrified and she is *quick.* |
| **Aunt Meg** — the Cook | **STEAK AND EGGS.** Hub-only. Buffs that persist one level. | Hub economy. |
| **Jonas** — the Rival | Corporate telemetry; opens black-panel gates. | **Free Play unlock only.** |

Melissa deserves defending as a mechanic: a character whose special ability is *running away
very fast and screaming* is exactly the kind of joke the early LEGO games were built on, and
it's genuinely useful. She is the traversal character.

---

## 6. Campaign — seven levels, one per Fujita step

| # | Level | Scale | Beat | New mechanic |
|---|---|---|---|---|
| 1 | **Wakita Warm-Up** | F1 | Aunt Meg's yard. Tutorial. | Smash, build, swap |
| 2 | **The Drive-In** | F2 | The screen comes down mid-feature. | Rescue-carry (protected actors) |
| 3 | **Cow Country** | F2→F3 | *"We got cows."* | Livestock physics; moving cover |
| 4 | **Barn Burner** | F3 | Dusty's convoy. Night chase. | Vehicle section |
| 5 | **Refinery Row** | F3 | Fuel and fire. | Hazard chains |
| 6 | **Aunt Meg's** | F4 | The house goes. Sculpture garden debris. | Escort under load |
| 7 | **The Finger of God** | F5 | The pipe. The belts. | The full-band deployment |

**Hub:** the staging field — parked convoy, Meg's kitchen, the garage where studs are spent.

---

## 7. Collectibles (the replay layer)

- **Sensor Balls** — 10 per level. *This is the minikit slot, and the movie handed it to us.*
  Collect all 10 and you rebuild a working Dorothy pod in the hub.
- **Extreme Bricks** — the red-brick slot. Stud multipliers, big-head mode, disco tornado.
- **True Chaser** — the stud threshold per level. Movie-accurate bragging rights.
- **Free Play** — return with the full roster, including Jonas, to open what you couldn't.

---

## 8. Mobile controls — the part everyone gets wrong

LEGO console games are 3D platformers with a free camera. Ported to a phone, that is
miserable: two sticks, a camera fighting you, and tiny buttons. **We do not port it. We
design for the thumb.**

**Two thumbs. No camera control. One context button.**

```
   ┌──────────────────────────────────────────────────┐
   │  ×3   STUDS 1,240              [JO] [BILL]       │
   │                                                   │
   │                                                   │
   │        (game)                                     │
   │                                                   │
   │     ⊙                                    ◉        │
   │   stick                                CONTEXT    │
   └──────────────────────────────────────────────────┘
```

- **Left thumb:** virtual stick, move. That's all it ever does.
- **Right thumb:** three buttons in a cluster.
  **SMASH** (always live — smashing everything is the point; double-tap for ability) ·
  **JUMP** (always live) ·
  **BUILD** (the only contextual one, labelled live:
  BUILD / GRAB / DEPLOY / DRIVE / EXIT).
- **BRACE is not a button.** Release the stick in high wind and you dig in.
- **Character swap:** tap the portrait. No menu.
- **Camera:** auto-framed. It always keeps you and the funnel in shot, pulling back as the
  funnel closes. The camera is a director, not a control.

No aiming. No jump button (auto-vault). Nothing that needs a second hand or a precise tap.

---

## 9. Art direction

- True brick construction — everything built from real LEGO part shapes at real stud pitch,
  studs visible on every top surface. If it can't be built from parts, it isn't in the game.
- Flat, bright, unlit-leaning shading. Big readable colour blocks. Classic palette:
  bright red, bright yellow, bright blue, dark green, white, light grey, reddish brown, tan.
- The *sky* carries the drama, not the shading — the world stays cheerful and saturated while
  the sky goes green-black. That contrast is the whole visual identity.
- The tornado is the one thing not made of bricks: a dark, smooth, rotating shape that
  scenery visibly comes apart into. It reads as a force, not an object.
- Silent-comedy pantomime. No dialogue, only mumbles and grunts.

---

## 10. Scope: what the prototype in this repo proves

A design doc can't prove feel. The playable slice in `/scripts` demonstrates, in order of
importance:

1. **A tornado that dismantles the world in real time** into physics debris → the hook
2. **Distance-scaled stud value with visible risk bands** → the economy
3. **Wind pressure and BRACE** → why standing close is a decision, not a formality
4. **Two characters with real ability gates** → the LEGO verb
5. **A build spot and a Dorothy deployment** → the objective shape
6. **One-stick + context-button touch control in landscape** → the platform

Everything else in this document is campaign content built on top of those six things.

---

## 11. Open questions for the director

1. ~~**Vehicles** — full driving levels, or scripted chase sections?~~
   **Resolved 2026-09-08: fully drivable.** The stick is a heading, not a wheel,
   so it costs no extra control surface. Ramming tears scenery with force scaled
   by speed. See `Docs/DECISION_LOG.md`.
2. **Co-op** — the LEGO games are couch co-op. On mobile that means either same-device
   split (bad) or nothing. Recommendation: ship single-player with instant AI swap, and treat
   co-op as a stretch on tablet.
3. **Level length** — console LEGO levels run 20-30 minutes. Mobile sessions want 4-6.
   Recommendation: chapters within a level, each independently completable.

---

## 12. Naming note

*LEGO* and *Twister* are trademarks of the LEGO Group and Warner Bros. respectively.
This project is an unlicensed prototype built as a design exercise. **BRICKSTORM** is the
working title, and character/level names are placeholders for the design's own vocabulary —
they should be replaced before anything is published anywhere.
