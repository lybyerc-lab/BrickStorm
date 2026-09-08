# BrickStorm Project Memory

This file is the durable project memory for the OpenAI/ChatGPT implementation. Read it before changing gameplay, architecture, art direction, controls, level structure, or content.

## Identity

- **The game concept is LEGO: Twister.**
- **BrickStorm is only the development codename.**
- The project should feel like an early Traveller's Tales LEGO game built around the story, locations, vehicles, storm chasing, destruction, comedy, and spectacle of the original *Twister* film.
- A feature that makes the project more generic but less recognizably LEGO: Twister is a regression, even if it is technically impressive.

## Primary Creative Reference

Use the classic LEGO-game language associated with early Traveller's Tales titles such as LEGO Star Wars, LEGO Indiana Jones, and LEGO Pirates of the Caribbean as conceptual design precedent:

- readable third-person action
- slapstick visual comedy
- smash almost everything
- collectible studs bursting from scenery
- rebuild broken pieces into useful or ridiculous contraptions
- character-specific abilities
- vehicles with arcade handling
- authored story levels
- hub exploration
- secrets, collectibles, and replay
- Free Play-style reasons to revisit completed levels
- exaggerated physical comedy rather than realism-first simulation

Use those ideas and patterns as inspiration. Do not copy proprietary source code, ripped assets, movie footage, dialogue dumps, music, logos, or other protected production content.

## Twister-Specific North Star

The tornado is not background weather. It is the level's moving villain and world-rearrangement system.

The game should repeatedly turn recognizable Twister situations into LEGO gameplay:

- Wakita as the principal hub and recovery space
- the storm-chaser convoy
- Dorothy-style probe equipment and deployment
- storm pursuit and vehicle sequences
- farms, roads, roadside structures, utility infrastructure, barns, and small-town Oklahoma
- drive-in destruction
- storm aftermath and rebuilding
- escalating tornado encounters
- the F5 finale
- cows treated with the seriousness appropriate to airborne livestock, which is none

Movie moments come first. Mechanics should serve those moments rather than replacing them with arbitrary missions.

## Construction and Destruction Language

The world should look and behave as though it was built to be smashed in a traditional LEGO game.

Construction-library priorities include:

- studs, plates, bricks, tiles, slopes, arches, posts, round elements, wheels, and structural modules
- Oklahoma clapboard walls and farm structures
- barn walls, roofs, gables, sheds, fences, signs, mailboxes, troughs, tractors, utility poles, water towers, storefronts, drive-in structures, weather equipment, and vehicle assemblies
- reusable assemblies that can support intact, build, destruction, and rebuild states
- authored hero destruction for large structures plus budgeted procedural fragments and studs
- readable silhouettes and exaggerated break behavior over sterile CAD accuracy

The construction library exists to make LEGO: Twister easier to author. It is not an end in itself.

## Current Technical Baseline

- Engine: **Godot 4.7.2**
- Platform priority: **Android/mobile first**, landscape
- Real Godot engine testing is required before release candidates are handed to the user.
- Final packaged ZIPs are clean-extracted and retested, not merely tested in the working directory.
- Mobile performance budgets for physical fragments and studs are intentional and should not be discarded casually.

### Approved control decisions

These are currently user-accepted and should be treated as regression-sensitive:

- Character movement was improved after early testing and is currently acceptable.
- **Truck control: 5/5 user rating.**
- **Road crossing: 5/5 user rating.**
- Vehicle steering model: the joystick direction is a **screen-space heading command for the vehicle's nose**. Pull the stick where the player wants the front of the truck to point. The vehicle turns toward that direction and then moves into it.
- Do not silently revert to camera-relative gas/brake steering, tank controls, or local-forward-only steering.
- Cow riding/charging is part of the evolving playable sandbox and should use the same readable heading language where appropriate.

## Current Gameplay Direction

The project has moved beyond a foundation-only prototype. The desired trajectory is now **more game**:

- more smashables
- denser but mobile-safe destruction effects
- more buildables with gameplay consequences
- more authored environmental set pieces
- more secrets and collectible rewards
- more character and vehicle variety
- more story levels
- more tornado-driven environmental rearrangement
- more classic LEGO-game comedy and replay value

Do not spend multiple releases polishing isolated technical systems while the playable content remains thin.

## Branch Ownership

Repository: `lybyerc-lab/BrickStorm`

- `main` is neutral/shared territory.
- `openai/brickstorm` is the OpenAI/ChatGPT implementation line.
- `openai/construction-library` is the OpenAI construction-library feature line.
- Claude or other implementations must use their own branches.
- Do not modify, merge, rewrite, or cherry-pick another implementation's branch unless the user explicitly asks for comparison or integration.

## Release Discipline

The phone is an acceptance device, not the compiler.

Before a release candidate is handed to the user:

1. run source/static gates;
2. run the real Godot 4.7.2 engine gate;
3. load and exercise relevant scenes and systems;
4. run touch/input regression tests where applicable;
5. package the project;
6. extract the exact final ZIP to a clean directory;
7. rerun the required validation and Godot tests against that packaged copy;
8. only then publish the candidate.

Avoid version-number churn for every internal attempt. Work internally until a candidate deserves a user-facing version.

## Decision Rule

When choosing between two implementations, prefer the one that better answers:

> **Would this feel at home in a classic LEGO game adaptation of Twister?**

If the answer is no, reconsider the feature before adding it.