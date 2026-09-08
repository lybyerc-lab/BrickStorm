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

BrickStorm Foundation **0.3.5** is the current clean-package-tested OpenAI release candidate.

0.3.5 is the first deliberately authored classic-brick-adventure opening slice. It turns the opening farm into a short consequence chain: stud guidance → readable wrench → staged generator build → wrench repair → powered sensor-cage reveal → first storm-sensor kit. A reactive second storm chaser changes callouts through the sequence. The build also adds original gameplay audio, short authored camera reveals, a compact level-progress HUD, explicit idle/start/run/pivot/air/land character poses, and a stylized non-brick Oklahoma backdrop that keeps bright brick interactables conspicuous.

Exact-package verification for 0.3.5 completed with:

- 72 tagged GDScripts
- 40 authored scene/resource files
- 55/55 behavior contracts
- real Godot 4.7.2 import/runtime/content/character-feel/currency/opening-slice/soak gates
- graphical touch tests at 1280x720, 1920x1080, and 2400x1080
- 301/301 manifest entries unchanged after clean-package source validation and Godot testing

Archive SHA-256: `457bc04a797ca90b2572da85c6cc834c112ffc968500cfa662f9a58af4f0ec0a`

## Protected wins

- Truck heading control: 5/5
- Road crossing: 5/5
- Storm-probe build rhythm: 5/5

Do not silently change these while tuning on-foot character feel or expanding authored story gameplay.

## Current development focus

Use the 0.3.5 opening chain as the pacing template for the next content, not as an excuse to remain on the farm forever. Expand toward Twister-specific authored situations such as storm-chaser convoy beats, drive-in destruction, Wakita, larger storm consequences, character-role abilities, and Free Play routes.

The environment rule is now explicit: the Oklahoma backdrop may be stylized and non-brick while characters, vehicles, tools, smashables, rebuildables, secrets, and consequence objects form the bright brick gameplay layer. Roblox-like capsule motion or generic block-sandbox composition remains a regression condition.

Canonical physical stud currency remains silver 10, gold 100, blue 1,000, purple 10,000.

## Repository completeness

This GitHub branch is still a curated workstream mirror, not yet a byte-for-byte mirror of the entire packaged 0.3.5 source tree. Do not claim otherwise. The sealed ZIP and its 301-entry manifest remain the authoritative complete release snapshot until full repository migration is explicitly completed and verified.

## Release discipline

A candidate is not considered sealed until source validation passes, real Godot 4.7.2 tests pass, the exact ZIP is clean-extracted and retested, and its manifest hashes remain unchanged after those tests. The physical phone is an acceptance device for Android rendering, audio, and subjective game feel, not the compiler.
