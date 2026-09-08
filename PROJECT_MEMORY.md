# BrickStorm Project Memory

This file is durable project memory for the OpenAI/ChatGPT implementation. Read it before changing gameplay, architecture, art direction, controls, levels, or content.

## Identity

- The game concept is LEGO: Twister.
- BrickStorm is only the development codename.
- The target feel is a classic early Traveller's Tales-style LEGO adaptation of the original Twister film.
- Recognizable Twister situations, slapstick comedy, smashable scenery, studs, rebuilds, character abilities, arcade vehicles, secrets, replay, and a tornado that rearranges the world are the creative center.
- A technically impressive feature that makes the game more generic but less recognizably LEGO: Twister is a regression.

## Primary gameplay language

The recurring verbs are smash, collect, build, interact, drive, discover, switch abilities, and replay.

The world should reward curiosity with studs, jokes, secrets, alternate routes, destructible set pieces, unlocks, and Free Play-style reasons to revisit completed levels.

## Twister-specific direction

Prioritize Wakita, the storm-chaser convoy, Dorothy-style probe equipment, Oklahoma farms and roads, barns, utilities, roadside structures, drive-in destruction, storm aftermath, escalating tornado encounters, and the F5 finale.

The tornado is not background weather. It is the moving villain and world-rearrangement system.

Movie moments come first. Mechanics should support those moments rather than replace them with arbitrary mission filler.

## Construction and destruction

The world should look built to be touched and smashed in a traditional LEGO game. The shared construction library supports studs, plates, bricks, tiles, slopes, arches, posts, round parts, wheels, structural modules, intact states, build animation, authored break clusters, and rebuild states.

Large hero structures should break in readable authored stages while staying inside mobile fragment and stud budgets.

The storm-probe construction sequence is user-rated **5/5** and is now regression-sensitive. Preserve its readable staged snap/build rhythm as the reference for important rebuildables.

A successful build animation is not the end of a buildable. Whenever it fits the level, the completed object should become a usable machine, tool target, traversal change, puzzle state, secret route, or later-level dependency. Building should change what the player can do.

Contextual tools are part of the game language. Prefer classic LEGO-style world interactions such as wrench repairs, scanning, digging, cutting, levering, or assembling over inventory-heavy simulation. On mobile, use the existing contextual ACTION path where possible instead of multiplying permanent buttons.

## Character feel and stud currency

- Collectible score studs use four stable color/value tiers: **silver = 10, gold = 100, blue = 1,000, purple = 10,000**.
- Do not reintroduce arbitrary collectible-stud values that make color stop communicating value.
- On-foot movement must read as a classic brick-action character, not a Roblox-like capsule avatar.
- Favor fast starts, hard stops, quick pivots, planted articulated strides, readable limb swing, and toy-weight jumping/landing over smooth inertial glide.
- Character movement is still open for tuning until the user explicitly accepts it. Do not protect a merely functional movement model just because it passes automated tests.

## Approved technical decisions

- Engine: Godot 4.7.2 stable.
- Platform priority: Android/mobile first, landscape.
- The phone is an acceptance device, not the compiler.
- Every release candidate must pass real Godot runtime tests before it reaches the user.
- Final ZIPs are clean-extracted and retested before release.
- Truck control is user-rated 5/5 and is regression-sensitive.
- Road crossing is user-rated 5/5 and is regression-sensitive.
- Vehicle steering uses the joystick as a screen-space heading command for the vehicle nose.
- Global physical-fragment and stud budgets are intentional mobile constraints.
- Latest physical-phone feel ratings: barn destruction **4/5**, storm-probe build **5/5**, overall LEGO-game feel **4/5**.

## Branch ownership

Repository: lybyerc-lab/BrickStorm

- main is neutral/shared territory.
- openai/brickstorm is the OpenAI/ChatGPT implementation line.
- openai/construction-library is the OpenAI construction-library feature line.
- Other implementations, including Claude, use their own branches.
- Do not modify, merge, rewrite, or cherry-pick another implementation's branch without explicit user instruction.

## Release discipline

Before a user-facing release candidate:

1. run source/static validation;
2. run the pinned real Godot 4.7.2 engine gate;
3. exercise relevant gameplay systems and scene lifecycle;
4. run touch/input regression tests when applicable;
5. package the source;
6. extract the exact final ZIP into a clean directory;
7. rerun required source and engine tests against that copy;
8. publish only after those gates pass.

Avoid public version churn for internal failed attempts.

## Decision rule

When choosing between two implementations, prefer the one that better answers:

Would this feel at home in a classic LEGO game adaptation of Twister?
