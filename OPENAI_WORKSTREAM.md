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

BrickStorm Foundation **0.4.4** is the current byte-authoritative, clean-extracted, Godot-tested OpenAI baseline.

Sealed archive: `brickstorm_foundation_v0_4_4.zip`

SHA-256: `f2318818c2c9ae2431b33acaee8df0ddc69a5aacf89ee344239eb6a23939ffdb`

Exact-package verification includes:

- source manifest: **418/418** entries unchanged after clean-extracted testing;
- source/static release gate;
- deep audit: **99 GDScripts / 51 scenes / 46 global class_name symbols**;
- **76/76** behavior contracts;
- strict-parser negative tests: **10/10**;
- real Godot `4.7.2.stable.official.ed1daf0bf` import/runtime/core/lifecycle/content gates;
- character LEGO-feel and hybrid-building gates;
- **phone QA lab and runtime telemetry gate**;
- canonical stud identity;
- authored opening slice;
- preserved county-road chase;
- Wakita first-block vertical slice;
- 600-frame main-scene soak;
- graphical touch at 1280x720, 1920x1080, and 2400x1080.

At 2400x1080, the `xvfb-run` wrapper could hang after the Godot child had already completed. Final release grading used Xvfb managed directly; the Godot process exited 0, printed `BRICKSTORM TOUCH INPUT ENGINE TEST: PASS`, and emitted no engine error markers.

The sealed ZIP stored in the LEGO: Twister Library is the byte authority. The GitHub branch remains a curated implementation/history mirror unless a full-repository mirror is separately verified.

## 0.4.4 phone-first QA layer

The user has no development PC, so BrickStorm's QA workflow must work from the Android build itself rather than assuming access to the Godot desktop editor.

0.4.4 adds:

- a compact in-game **QA** launcher that does not replace or shift the protected movement/action controls;
- a hidden-by-default **PERF HUD** for live gameplay;
- a dedicated **QA LABS** scene;
- real-project MINIFIG, HOUSE, and BUILDABLE benches rather than mock assets;
- stable visual checkpoint IDs for repeatable screenshots;
- house opening/receiving-geometry inspection without triggering physics destruction;
- buildable hopping preview plus real build-sequence triggering;
- runtime metrics for FPS, frame/process/physics cost, draw and visible-object pressure, active 3D bodies, storm debris, and buildables.

Stable checkpoint IDs include:

- `RUN-3Q-01`, `RUN-SIDE-01`, `RUN-FRONT-01`, `RUN-GAME-01`;
- `HOUSE-ROAD-FRONT-01`, `HOUSE-ROAD-3Q-01`, `HOUSE-FARM-FRONT-01`, `HOUSE-FARM-3Q-01`;
- `BUILD-FRONT-01`, `BUILD-3Q-01`, `BUILD-GAME-01`.

This infrastructure is intended to make Android-only visual QA reproducible and shorten the loop between noticing a defect and reproducing it.

## Physical-phone baseline and demo parity

The user-supplied 2008 classic brick-adventure demo remains the **5/5 measurement stick**. Automated PASS results prove stability and protected behavior, not visual parity.

The most recent completed physical Android full-round rating remains **0.4.2 = 3.8/5**, with the user explicitly saying the round was fun. 0.4.3 corrected the reported torso-swagger and phone-visible house-fit defects but has not yet received a replacement phone score.

0.4.4 is measurement infrastructure. It **does not receive an automatic demo-parity increase**.

Current pending-phone working estimates remain:

- visual parity: approximately **3.8/5**;
- gameplay parity: approximately **3.4/5**;
- verdict: **ACCEPT AS FOUNDATION ONLY**.

Biggest remaining visual giveaway: authored mesh quality, edge treatment, materials/texture richness, prop specificity, lighting composition, and environmental dressing remain below the shipped reference.

Biggest remaining gameplay giveaway: contextual actions, companion/character-role behavior, semantic feedback density, alternate solutions, secrets, and Story/Free Play depth remain below the reference.

## Protected wins / regression floors

- Truck heading control: **5/5**
- Road crossing: **5/5**
- Storm-probe build rhythm: **5/5**
- Generator/sensor-cage opening: protected reference slice
- County-road / production InteractionGraph chase: protected
- 0.4.2 hopping buildable identification: protected
- 0.4.3 torso swagger: protected
- 0.4.3 roadside/farmhouse prop nesting: protected
- Wakita objective/checkpoint/camera/tornado-route ownership: protected
- Canonical stud denomination identity and mobile destruction budgets: protected

Protected means comparison floor, not museum glass. Improvements are welcome only when the play result clearly remains equal or better.

## Mandatory pass review

Every meaningful pass reports:

1. visual parity /5 versus the demo;
2. gameplay parity /5 versus the demo;
3. strongest improvement;
4. biggest remaining visual giveaway;
5. biggest remaining gameplay giveaway;
6. protected regressions checked;
7. explicit verdict: ACCEPT, ACCEPT AS FOUNDATION ONLY, or REWORK BEFORE EXPANSION.

## Release discipline

A candidate is not sealed until source validation passes, real Godot 4.7.2 tests pass, the exact ZIP is clean-extracted and retested, and source-manifest hashes remain unchanged after testing. Physical Android remains authoritative for rendering, audio, performance, thermals, thumb feel, character swagger, prop nesting, QA usability, and overall classic-LEGO impression.