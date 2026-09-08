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

BrickStorm Foundation **0.3.2** is the current clean-package-tested OpenAI release candidate.

The 0.3.2 feel-first pass preserves the accepted 5/5 truck control and road crossing while adding cause-aware barn destruction choreography, staged stud spills, visible scattered storm-probe parts and multi-phase assembly, persistent opening stud trails, smashable scarecrows, and a more readable original brick-toy player silhouette.

Exact-package verification for 0.3.2 completed with:

- 59 tagged GDScripts
- 33 scenes
- 43/43 behavior contracts
- real Godot 4.7.2 import/runtime/content/soak gates
- graphical touch tests at 1280x720, 1920x1080, and 2400x1080
- 231/231 manifest entries unchanged after clean-package validation and Godot testing

Archive SHA-256: `e45af121f4d3d5a5c7c422e56ec937a5145fcba479dbe033bccae8a4c7ddddb3`

## Current development focus

Raise the subjective LEGO-game feel above the user's 0.3.1 ratings of 3/5 for barn destruction, probe build, and overall feel. Favor readable authored spectacle, construction/destruction rhythm, environmental density, secrets, and Twister-specific set pieces over additional foundation abstraction.

## Repository completeness

This GitHub branch is still a curated workstream mirror, not yet a byte-for-byte mirror of the entire packaged 0.3.2 source tree. Do not claim otherwise. The sealed ZIP and its manifest remain the authoritative complete release snapshot until full repository migration is explicitly completed and verified.

## Release discipline

A candidate is not considered sealed until source validation passes, real Godot 4.7.2 tests pass, the exact ZIP is clean-extracted and retested, and its manifest hashes remain unchanged after those tests. The physical phone is an acceptance device for Android rendering and subjective game feel, not the compiler.
