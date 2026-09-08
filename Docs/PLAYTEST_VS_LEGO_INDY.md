# Playtest: one full round, measured against LEGO Indiana Jones

**Date:** 2026-09-08 · **Build:** `294a53d` · **Method:** 150-second autopilot
round, every player-facing event timestamped (`--playthrough`,
`[BS:QA:PLAYTHROUGH]`). Raw log: `Docs/playthrough-2026-09-08.log`.

**Caveat, stated first:** the autopilot is not a player. It never hesitates,
explores, backtracks or gets bored. Its numbers are an **upper bound on event
density** and a **lower bound on dead time**. A human would score worse on both.

---

## The round, in numbers

| | |
|---|---|
| Duration | 150 s |
| Final score | 4,159 studs |
| Bricks torn | 507 |
| Phase reached | BUILD (2 of 5) — never completed |
| TRUE CHASER earned at | **t ≈ 7 s** |
| BUILD unlocked at | **t = 6.95 s** |
| Longest silence | **14.3 s** (from t = 88.9) |

| Event | Count | Per minute |
|---|---|---|
| STUD | 369 | 147.5 |
| RAM | 8 | 3.2 |
| SMASH | 7 | 2.8 |
| TUMBLE | 6 | 2.4 |
| GAG | 3 | 1.2 |
| PHASE | 1 | 0.4 |
| RATING | 1 | 0.4 |

---

## Six findings

### 1. The level eats itself

507 bricks torn. By **t ≈ 90 s the map is bare** — see
`Docs/shots/06-empty-map-t108.png`: one outhouse, a fence, two trucks, and a
hundred metres of empty grass. The remaining 60 seconds have nothing in them.

A LEGO Indiana Jones level is a **hand-authored set you travel through**, gated
into sections, with fresh scenery arriving as you progress. It cannot be
exhausted, because you are moving through it rather than standing in an arena
while it is consumed.

Ours is an arena, and the tornado empties it. **This is the single biggest
structural difference**, and it is upstream of everything else in this list.

### 2. Progression is over in seven seconds

BUILD unlocks at t = 6.95 s. TRUE CHASER — the level's top rating — is earned at
t ≈ 7 s, before a player has finished learning the controls.

In LEGO Indy, True Adventurer is calibrated across a 15–30 minute level and is
typically reached near the end of a thorough run. The threshold's job is to stay
*just* out of reach so it pulls you through the whole level.

`TRUE_CHASER = 1400` against an observed rate of ~4,400 studs/minute is roughly
**twenty to thirty times too low**. `STUD_GOAL = 400` for the build gate is worse.

### 3. The event mix is inverted

369 stud pickups against **15 player-verb events** (7 smashes, 8 rams). Roughly
**96% of everything that happens to the player is passive collection.**

The LEGO games are the other way round: the loop is *you smash a thing → studs
come out → you smash the next thing*. Studs are the **consequence** of acting.
Here they are the activity, and the player is a vacuum cleaner standing near a
fan.

### 4. There is only one denomination

Every payout in the log is +10, +20 or +30 — base ten times the band multiplier.
369 near-identical events.

LEGO Indy has **silver 10 / gold 100 / blue 1,000 / purple 10,000**. Finding a
big one is a small event in itself, and the varying pitch and value make the
stud stream feel like it has texture. Ours is flat: no jackpots, no surprises,
nothing worth crossing a room for.

### 5. Fourteen seconds of nothing

The longest gap with zero player-facing feedback is 14.3 s, and the whole back
half of the round is sparse (buckets at t=30, 40, 120, 140 are nearly empty).

In a LEGO game you are essentially never without feedback, because **everything
is smashable**. Idle time does not exist — if there is nothing to do, you hit a
bench and studs come out. Our world has too few objects to support that.

### 6. The objective chain is one link long

The round never advanced past BUILD. There is one goal; when it stalls, there is
no second thing to be doing.

LEGO Indy runs a near-continuous chain: ability gate → build → set piece →
hazard → gate. Something is always both available and blocked, which is what
gives a level its shape.

---

## What LEGO Indy has that we have not built at all

- **Minikits** (10 per level) — the exploration layer. No equivalent exists, so
  there is no reason to leave the funnel.
- **Free Play** — the second pass with the full roster. Nothing is currently
  placed to be unreachable-then-reachable.
- **Enemies and hazards** as continuous low-stakes interaction.
- **Cutscene gags** bookending the level.
- **A hub** to spend studs in. Ours are earned and then nothing happens to them.

---

## Recommended order of work

Ranked by how much each closes the gap, not by effort:

1. **Stop the level consuming itself.** Either make the world far larger and
   denser and move the player through it, or have the funnel travel a route with
   fresh set-pieces ahead of it. Everything else is cosmetic until an arena stops
   being empty at 90 seconds.
2. **Recalibrate the economy.** `TRUE_CHASER` up by 10–20×; gate BUILD on
   reaching a place or completing an act, not on a stud count that trips in
   seconds.
3. **Make everything smashable.** Fences, mailboxes, bins, crops, signs — the
   cheap furniture that removes dead time and makes SMASH the default verb.
4. **Add stud denominations** so payouts have texture and jackpots exist.
5. **Build the sensor-ball collectible layer** — the minikit slot the design
   already specifies.
6. **Chain the objectives** so something is always available and something is
   always blocked.

Items 1 and 3 together are the honest answer to "it doesn't identify as a
classic LEGO game". The art pass helped; the *structure* is the gap.
