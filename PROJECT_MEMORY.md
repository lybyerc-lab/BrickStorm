# BrickStorm Project Memory

This file is durable project memory for the OpenAI/ChatGPT implementation. Read it before changing gameplay, architecture, art direction, controls, levels, or content.

## Identity

- The game concept is LEGO: Twister.
- **LEGO: Twister is the North Star.**
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

## Construction, destruction, and builds

The world should look built to be touched and smashed in a traditional LEGO game. The shared construction library supports studs, plates, bricks, tiles, slopes, arches, posts, round parts, wheels, structural modules, intact states, build animation, authored break clusters, and rebuild states.

Large hero structures should break in readable authored stages while staying inside mobile fragment and stud budgets.

The storm-probe construction sequence is user-rated **5/5** and is regression-sensitive. Preserve its readable staged snap/build rhythm as the reference for important rebuildables.

A successful build animation is not the end of a buildable. Whenever it fits the level, the completed object should become a usable machine, tool target, traversal change, puzzle state, secret route, or later-level dependency. Building should change what the player can do.

## Tools

Contextual tools are part of the classic brick-game language, not an inventory simulator.

- Prefer ACTION-based contextual use on mobile instead of multiplying permanent buttons.
- **A tool must be recognizable before pickup.** Use a readable silhouette, contrasting stand/marker, and in-world name when necessary.
- **A carried tool must remain visibly communicated after pickup.** The actor/toolbelt should make ownership obvious.
- Support multiple contextual tools and character abilities over time. The wrench and pry bar are the first examples, not a complete tool system.
- Good future families include digging, cutting, levering, repair, scanning/science, and role-specific abilities.

## Currency

Physical collectible studs have fixed values and matching visual identities:

- **Silver = 10**
- **Gold = 100**
- **Blue = 1,000**
- **Purple = 10,000**

Do not create arbitrary physical stud values/colors that weaken immediate reward recognition. Direct mission bonuses may still add aggregate totals without spawning a physical stud for every point.

## Character and environment feel

**Roblox-like on-foot movement or generic block-sandbox environment language is a regression.** Do not normalize it as an acceptable placeholder direction.

On-foot character goals:

- immediate start response;
- decisive release/braking;
- quick whole-body pivots instead of strafing/gliding;
- limited air steering;
- short toy-weight jumps and readable landings;
- rigid hinge-like limb animation driven by actual travel;
- brick-toy silhouette and reactions rather than rectangular humanoid proportions.

Environment goals:

- use the classic brick-adventure contrast: a stylized real-world Oklahoma backdrop can be non-brick while characters, vehicles, tools, smashables, rebuildables, and secrets are the conspicuous brick gameplay layer;
- terrain may be smooth/mobile-safe, but visual dressing should break up large bright rectangles;
- use shaped dirt/field edges, crops, roadside clutter, horizon forms, brick-built props, storm atmosphere, and authored composition;
- preserve the accepted continuous collision surface under the farm road.

Authored-level rhythm goal:

- favor short chains such as smash → studs → tool/ability → build → consequence → secret/story beat instead of wide empty objective fields;
- use short camera reveals, reactive companion/NPC behavior, compact HUD feedback, and original sound to punctuate consequences;
- the 0.3.5 opening generator/sensor-cage chain is the first reference slice for this pacing language.

## Approved technical decisions and physical-phone ratings

- Engine: Godot 4.7.2 stable.
- Platform priority: Android/mobile first, landscape.
- The phone is an acceptance device, not the compiler.
- Every release candidate must pass real Godot runtime tests before it reaches the user.
- Final ZIPs are clean-extracted and retested before release.
- Truck control is user-rated **5/5** and regression-sensitive.
- Road crossing is user-rated **5/5** and regression-sensitive.
- Storm-probe build is user-rated **5/5** and regression-sensitive.
- Latest barn destruction rating: **4/5**.
- 0.3.3 tool-loop rating: **3/5**, specifically because the tool was difficult to recognize before pickup and carry-state was not obvious enough.
- 0.3.3 built-item usefulness rating: **4/5**, with the explicit request for more tools and more useful built objects.
- 0.3.3 overall LEGO feel: **4/5**, with movement and environment still called out as too Roblox-like.
- Vehicle steering uses the joystick as a screen-space heading command for the vehicle nose.
- Global physical-fragment and stud budgets are intentional mobile constraints.

## Branch ownership

Repository: `lybyerc-lab/BrickStorm`

- `main` is neutral/shared territory.
- `openai/brickstorm` is the OpenAI/ChatGPT implementation line.
- `openai/construction-library` is the OpenAI construction-library feature line.
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
8. verify packaged manifest hashes remain unchanged after testing;
9. publish only after those gates pass.

Avoid public version churn for internal failed attempts.

## Decision rule

When choosing between two implementations, prefer the one that better answers:

> **Would this feel at home in a classic LEGO game adaptation of Twister?**
