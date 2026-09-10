# OpenAI BrickStorm Workstream

This branch is owned by the ChatGPT/OpenAI implementation of BrickStorm.

## Branch policy

- Active branch: `openai/brickstorm`
- Construction feature branch: `openai/construction-library`
- Do not commit Claude or other independent implementations to these branches.
- Do not merge this branch into `main` without explicit project-owner approval.
- Treat `main` as neutral coordination territory while independent implementations coexist.

## Creative identity

The game is **LEGO: Twister**. `BrickStorm` is only the development codename. Read `PROJECT_MEMORY.md`, `docs/NORTH_STAR.md`, `docs/NO_DRIFT_POLICY.md`, and `docs/DEMO_PARITY_GATE.md` before substantial design or implementation work.

## Current sealed baseline

BrickStorm Foundation **0.4.1** is the current byte-authoritative, clean-extracted, Godot-tested OpenAI baseline.

Sealed archive: `brickstorm_foundation_v0_4_1.zip`

SHA-256: `f01491d61138a8ec95d65b5968dafc9a5472c0665609e55e943235dfa77e2e69`

Exact-package verification includes:

- source manifest: **388/388** entries unchanged before and after clean-extracted testing;
- source/static release gate;
- **70/70** behavior contracts;
- strict-parser negative tests: **10/10**;
- real Godot `4.7.2.stable.official.ed1daf0bf` import/runtime/core/lifecycle/content gates;
- character LEGO-feel + minifigure-silhouette gate;
- hybrid-building + precision architectural-mating gate;
- canonical stud identity;
- authored opening slice;
- preserved county-road chase;
- Wakita first-block vertical slice;
- 600-frame main-scene soak;
- graphical touch tests at 1280x720, 1920x1080, and 2400x1080.

The sealed ZIP stored in the LEGO: Twister Library is the byte authority. The GitHub branch remains a curated implementation/history mirror unless a full-repository mirror is separately verified.

## Demo parity is now mandatory

The user-supplied 2008 classic brick-adventure demo is the **5/5 measurement stick**. A pass is not accepted merely because it improves on the previous BrickStorm build or because automated engine tests are green.

Every meaningful pass must report separately:

1. visual parity /5 versus the demo;
2. gameplay parity /5 versus the demo;
3. strongest improvement;
4. biggest remaining visual giveaway;
5. biggest remaining gameplay giveaway;
6. protected regressions checked;
7. explicit verdict: ACCEPT, ACCEPT AS FOUNDATION ONLY, or REWORK BEFORE EXPANSION.

Current 0.4.1 demo-parity classification:

- overall visual: approximately **3.4/5**;
- minifigure silhouette: approximately **3.6/5**, up from 2.0/5 in 0.4.0;
- door/window/roof fit: approximately **4.2/5**, up from 2.0/5;
- overall gameplay: approximately **3.0/5**, intentionally unchanged by the visual correction pass;
- verdict: **ACCEPT AS FOUNDATION ONLY**.

The remaining visual gap is primarily authored model/material/surface richness and production-level environmental detail. The remaining gameplay gap is semantic feedback density, contextual character/companion roles, alternate solutions, and Story/Free Play depth.

## 0.4.1 correction contracts

### Character

Keep one authoritative on-foot motor. Visible presentation remains:

`travel/root -> pelvis/waist lead -> restrained torso follow -> broader delayed shoulder sway -> rigid arms -> head settle`

0.4.1 hardens the center-screen silhouette with a compact minifigure-style head/torso/hip/leg/foot relationship, broad hip bridge, shorter block legs, deeper feet, permanently bent molded arm construction, bridged C-grip hands, and stronger molded-plastic response.

### Buildings

Building grammar remains **permanent world shell + LEGO attachment layer**.

0.4.1 replaces independent hand-tuned hole/socket offsets with one shared mating specification. Wall openings, socket planes, window/door frames, facade attachment plane, roof overhang, eave height, and ridge convergence derive from the same measurements. Engine tests measure fit tolerances; socket existence alone is no longer sufficient.

## Protected wins / regression floors

- Truck heading control: **5/5**
- Road crossing: **5/5**
- Storm-probe build rhythm: **5/5**
- Generator/sensor-cage opening: protected reference slice
- County-road / production InteractionGraph chase: protected
- Wakita objective/checkpoint/camera/tornado-route ownership: protected
- Canonical stud denomination identity and mobile destruction budgets: protected

Protected means comparison floor, not museum glass. Improvements are welcome only when the play result clearly remains equal or better.

## Next production pressure

Do not expand Wakita acreage merely to show progress. The next pass should improve the things that still make BrickStorm easy to distinguish from the demo:

- authored model/material/surface richness;
- finer minifigure molding/presentation polish at gameplay distance;
- contextual animation and semantic audio density;
- character-role and companion behavior;
- alternate solutions and Free Play/replay hooks;
- interactions per minute and authored LEGO-game comedy.

## Release discipline

A candidate is not sealed until source validation passes, real Godot 4.7.2 tests pass, the exact ZIP is clean-extracted and retested, and its source-manifest hashes remain unchanged after those tests. Physical Android remains the subjective acceptance device for rendering, performance, audio, thermals, thumb feel, character motion, and final gameplay presentation.