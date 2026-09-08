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

BrickStorm Foundation **0.3.4** is the current clean-package-tested OpenAI release candidate.

0.3.4 directly addresses physical-phone feedback that the 0.3.3 tool loop was only 3/5 because tools were hard to recognize before pickup and unclear after pickup, and that movement/environment still felt too Roblox-like. It adds loud in-world tool identity, visible carried tools, a second pry-bar tool loop with a storm-cellar secret, canonical stud denomination/color identity, a hard-start/hard-stop/pivot-focused on-foot controller, a separately owned brick-chaser visual/animation component, and less rectangular farm dressing while preserving the accepted continuous road collision surface.

Exact-package verification for 0.3.4 completed with:

- 68 tagged GDScripts
- 39 authored scene/resource files
- 51/51 behavior contracts
- real Godot 4.7.2 import/runtime/content/character-feel/currency/soak gates
- graphical touch tests at 1280x720, 1920x1080, and 2400x1080
- 265/265 manifest entries unchanged after clean-package validation and Godot testing

Archive SHA-256: `6e08c6d88e8d37b35aeec4ff53012c849fdcae19c2fa9f7f06939620fa9d1aef`

## Protected wins

- Truck heading control: 5/5
- Road crossing: 5/5
- Storm-probe build rhythm: 5/5

Do not silently change these while tuning on-foot character feel, tool readability, or environmental presentation.

## Current development focus

Get physical-device character movement, tool readability, and environment/LEGO feel above the current 4/5 ceiling. Continue growing useful buildables and contextual tools rather than inventory simulation. The wrench and pry bar are first examples; future families can include digging, cutting, levering, repair, science/scanning, and character-role abilities for story/Free Play routes.

Canonical physical stud currency is silver 10, gold 100, blue 1,000, purple 10,000. Color must communicate value immediately.

Roblox-like capsule movement and generic bright block-sandbox terrain are explicit regression conditions, not acceptable long-term placeholders.

## Repository completeness

This GitHub branch is still a curated workstream mirror, not yet a byte-for-byte mirror of the entire packaged 0.3.4 source tree. Do not claim otherwise. The sealed ZIP and its manifest remain the authoritative complete release snapshot until full repository migration is explicitly completed and verified.

## Release discipline

A candidate is not considered sealed until source validation passes, real Godot 4.7.2 tests pass, the exact ZIP is clean-extracted and retested, and its manifest hashes remain unchanged after those tests. The physical phone is an acceptance device for Android rendering and subjective game feel, not the compiler.
