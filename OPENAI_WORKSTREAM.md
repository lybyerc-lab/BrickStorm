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

BrickStorm Foundation **0.3.3** is the current clean-package-tested OpenAI release candidate.

0.3.3 preserves the user-rated 5/5 truck control, 5/5 road crossing, and 5/5 storm-probe build rhythm while adding the first complete contextual-tool and usable-buildable loop: acquire a wrench, build the farm generator, use the wrench through ACTION, power the generator, and permanently open a gated equipment cache. Built weather machines also remain useful after assembly.

Exact-package verification for 0.3.3 completed with:

- 63 tagged GDScripts
- 36 authored scene/resource files
- 46/46 behavior contracts
- real Godot 4.7.2 import/runtime/content/soak gates
- graphical touch tests at 1280x720, 1920x1080, and 2400x1080
- 247/247 manifest entries unchanged after clean-package validation and Godot testing

Archive SHA-256: `4bc3aa2bb134f359df972af513a56f52a207f63dcd19dc4c654baea5120b3d54`

## Current development focus

Turn more successful LEGO-style build sequences into useful machines, tools, traversal changes, secrets, and later mission dependencies. Contextual tools should remain simple world abilities rather than inventory simulation, and the existing ACTION input should be preferred on mobile when it stays readable.

Latest physical-device ratings before 0.3.3 are barn destruction 4/5, storm-probe build 5/5, LEGO-game feel 4/5, truck control 5/5, and road crossing 5/5.

## Repository completeness

This GitHub branch is still a curated workstream mirror, not yet a byte-for-byte mirror of the entire packaged 0.3.3 source tree. Do not claim otherwise. The sealed ZIP and its manifest remain the authoritative complete release snapshot until full repository migration is explicitly completed and verified.

## Release discipline

A candidate is not considered sealed until source validation passes, real Godot 4.7.2 tests pass, the exact ZIP is clean-extracted and retested, and its manifest hashes remain unchanged after those tests. The physical phone is an acceptance device for Android rendering and subjective game feel, not the compiler.
