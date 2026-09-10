# OpenAI BrickStorm Workstream

This branch is owned by the ChatGPT/OpenAI implementation of BrickStorm.

## Branch policy

- Active branch: `openai/brickstorm`
- Construction feature branch: `openai/construction-library`
- Do not commit Claude or other independent implementations to these branches.
- Do not merge this branch into `main` without explicit project-owner approval.
- Treat `main` as a neutral coordination point while independent versions coexist.

## Creative identity

The game is **LEGO: Twister**. `BrickStorm` is only the development codename. Read `PROJECT_MEMORY.md`, `docs/NORTH_STAR.md`, and `docs/NO_DRIFT_POLICY.md` before substantial design or implementation work.

## Current sealed baseline

BrickStorm Foundation **0.3.8** is the current byte-authoritative, clean-extracted, Godot-tested OpenAI baseline.

0.3.8 preserves the accepted opening and 0.3.7 county-road chase while converting the focused reference-demo study into two production grammars: a waist-led minifigure presentation hierarchy and hybrid Oklahoma buildings with permanent world shells plus independently storm-active LEGO attachments.

Exact-package verification for 0.3.8 includes:

- source manifest: 354/354 entries, verified before and after clean-extracted testing;
- 61/61 behavior contracts;
- real Godot 4.7.2 import/runtime/core/lifecycle/content/character/hybrid-building/stud/opening/road-chase gates;
- 600-frame soak;
- graphical touch tests at 1280x720, 1920x1080, and 2400x1080;
- full clean-extracted source and engine re-test of the exact sealed ZIP.

Archive SHA-256: `9315994ea869ae30ab41f22ffecc179205603d4abe8ba2f6c81b88f441367e63`

## Protected wins / regression floors

- Truck heading control: 5/5
- Road crossing: 5/5
- Storm-probe build rhythm: 5/5
- Generator/sensor-cage opening: reference slice
- 0.3.7 road-chase / first production InteractionGraph chain: known-good content baseline

Protected means comparison floor, not museum glass. Improvements are welcome when they clearly preserve or beat the known-good play result.

## Current production focus: buildings and levels

The demo-first movement/environment pass has now produced a playable implementation rather than remaining research.

Character presentation rule:

`travel/root -> pelvis/waist lead -> restrained torso follow -> broader delayed shoulder sway -> rigid arms -> head settle`

Keep the accepted locomotion motor authoritative and continue subjective tuning from the phone rather than fragmenting movement into character-specific controllers.

Building rule:

**permanent world shell + LEGO attachment layer**.

Ordinary building wall/foundation/gable mass can remain stylized non-LEGO static world geometry. Roofs, windows, doors, signs, selected trim/porch/utility pieces, interactables, secrets, and hero destruction elements form the LEGO-active layer. Tornado destruction promotes only authored attachments/clusters into physics as needed.

The next major content step is to turn the proven `HybridRoadsideHouse` pattern into reusable Oklahoma building kits and begin actual Wakita/level production. Use modular authoring and static clustering for inert scenery, but never cluster away gameplay or tornado identity.

See `docs/BUILD_CANDIDATE_0_3_8.md`, `docs/FOUNDATION_HARDENING_0_3_8.md`, `docs/DEMO_MOVEMENT_ENVIRONMENT_FOCUS.md`, `docs/LEVEL_BUILDING_CONSTRUCTION_STRATEGY.md`, and `docs/STATIC_RENDER_CLUSTER_STRATEGY.md`.

Canonical physical stud currency remains silver 10, gold 100, blue 1,000, purple 10,000.

## Repository completeness

The GitHub branch is a curated implementation/history mirror. The sealed 0.3.8 ZIP and its 354-entry manifest are the byte-authoritative complete source snapshot unless a full repository mirror is separately verified.

## Release discipline

A candidate is not considered sealed until source validation passes, real Godot 4.7.2 tests pass, the exact ZIP is clean-extracted and retested, and its manifest hashes remain unchanged after those tests. The physical phone remains the acceptance device for Android rendering, audio, performance, and subjective game feel, not the compiler.
