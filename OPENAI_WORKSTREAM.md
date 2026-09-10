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

BrickStorm Foundation **0.3.7** is the current byte-authoritative, clean-extracted, Godot-tested OpenAI baseline.

0.3.7 preserves the accepted opening and expands north into the first county-road chase. It also improves the molded-minifigure silhouette, separates pelvis/torso presentation, offsets arm cadence from the legs, and proves the generalized `InteractionGraph` on the new road-beacon/barrier chain without replacing the known-good generator/cage opening.

Exact-package verification for 0.3.7 includes:

- source manifest: 341/341 entries;
- 59/59 behavior contracts;
- real Godot 4.7.2 import/runtime/core/lifecycle/content/character/stud/opening/road-chase gates;
- 600-frame soak;
- graphical touch tests at 1280x720, 1920x1080, and 2400x1080;
- full clean-extracted source and engine re-test of the exact sealed ZIP.

Archive SHA-256: `3d8556d19caa0e75dd7fb76388025403b0c93c68924611674d3e7f4534a75dca`

## Protected wins / regression floors

- Truck heading control: 5/5
- Road crossing: 5/5
- Storm-probe build rhythm: 5/5
- Generator/sensor-cage opening: reference slice

Protected means comparison floor, not museum glass. Improvements are welcome when they clearly preserve or beat the known-good play result.

## Current development focus: demo-first movement and environment study

The user-supplied 2008 brick-adventure demo is the primary clean-room reference for the next development cycle.

Narrow archaeology to two questions:

1. **Character movement/presentation**: how a shared locomotion motor is layered with waist/pelvis lead, torso/shoulder presentation, head behavior, action timing, tool-carry variants, footsteps, pivots, landings, and authored traversal.
2. **Environment architecture**: how static scenery, render groups, collision proxies, special/gameplay objects, destructible profiles, camera anchors, interaction graphs, navigation, and spectacle budgets remain separate while forming one readable level.

Do not spend time on unrelated demo archaeology unless it materially sharpens one of those two questions.

Movement target from user feedback: stronger shoulder sway and a classic waist-led gait that feels as though the minifigure is being pulled from the beltline, while preserving rigid toy articulation and planted movement.

Environment target from user feedback: **permanent world shell + LEGO attachment layer**. Ordinary building wall mass can be non-LEGO, while roofs, windows, doors, signs, selected trim/porch/utility pieces, interactables, and hero destruction elements form the LEGO-active layer. This is a BrickStorm art decision supported by the demo's separation of static scenery, special objects, collision, and destruction systems; do not misrepresent it as a literal recovered reference-game rule.

See `docs/DEMO_MOVEMENT_ENVIRONMENT_FOCUS.md`, `docs/LEVEL_BUILDING_CONSTRUCTION_STRATEGY.md`, `docs/STATIC_RENDER_CLUSTER_STRATEGY.md`, and the clean-room archaeology notes.

Canonical physical stud currency remains silver 10, gold 100, blue 1,000, purple 10,000.

## Repository completeness

The GitHub branch is a curated implementation/history mirror. The sealed 0.3.7 ZIP and its 341-entry manifest remain the byte-authoritative complete source snapshot unless a full repository mirror is separately verified.

## Release discipline

A candidate is not considered sealed until source validation passes, real Godot 4.7.2 tests pass, the exact ZIP is clean-extracted and retested, and its manifest hashes remain unchanged after those tests. The physical phone remains the acceptance device for Android rendering, audio, performance, and subjective game feel, not the compiler.
