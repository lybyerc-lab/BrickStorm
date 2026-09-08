# BrickStorm Project Memory

This branch inherits the OpenAI/ChatGPT project's standing directive:

- **The game is LEGO: Twister.**
- **BrickStorm is only the development codename.**
- The target feel is a classic early Traveller's Tales LEGO adaptation of the original *Twister* film: authored story levels, slapstick comedy, smash-everything scenery, studs, rebuilding, character abilities, arcade vehicles, secrets, replay, hub progression, and a tornado that actively rearranges levels.

## Creative Memory

Movie moments come first. Mechanics should turn recognizable Twister situations into LEGO gameplay rather than replacing them with generic objectives.

Core content direction includes:

- Wakita hub and recovery progression
- storm-chaser convoy and chase vehicles
- Dorothy-style storm-probe equipment
- Oklahoma farms, roads, barns, utilities, storefronts, drive-in structures, and storm-damaged towns
- tornado pursuit and escalation
- drive-in destruction
- town aftermath and rebuilding
- F5 finale
- airborne-cow comedy

The tornado is the moving villain and world-rearrangement system, not merely background weather.

## Construction-Library Memory

This branch exists to make LEGO: Twister easier to author. It is not a generic brick-CAD project.

Prioritize reusable parts and assemblies that directly support the game:

- studs, plates, bricks, tiles, slopes, arches, posts, round parts, wheels
- clapboard homes and Oklahoma farm structures
- barns, sheds, fences, signs, mailboxes, troughs, tractors
- Wakita storefronts and civic structures
- utility poles, transformers, water towers, drive-in structures
- chase vehicles, trailers, storm equipment, Dorothy-style science gear
- intact, damaged, destructible, fragment, rebuild-animation, and rebuilt states

Prefer readable LEGO-game silhouettes and satisfying break behavior over sterile geometric accuracy.

## Technical Memory

- Engine: **Godot 4.7.2**
- Android/mobile first, landscape
- Real Godot engine testing is required before user-facing releases.
- Final packaged ZIPs must be clean-extracted and retested.
- Physical fragment/stud budgets exist to protect mobile performance.

### User-approved regression locks

- Character movement is currently acceptable after tuning.
- **Truck control: 5/5.**
- **Road crossing: 5/5.**
- Vehicle joystick direction is a **screen-space heading command for the vehicle nose**: pull where you want the front of the vehicle to point.
- Do not silently replace that control philosophy.
- Cow riding/charging belongs in the playable sandbox and should preserve the same readable heading language where appropriate.

## Development Direction

The project needs **more game**, not endless infrastructure:

- more smashables
- more destruction feedback within mobile budgets
- more meaningful buildables
- more puzzles, secrets, collectibles, characters, vehicles, and story beats
- more authored tornado spectacle
- more classic LEGO-game humor and replay value

Infrastructure is valuable when it accelerates visible playable content.

## Branch Ownership

- `main`: neutral/shared
- `openai/brickstorm`: OpenAI stable implementation line
- `openai/construction-library`: this OpenAI feature branch
- Claude and other implementations stay on their own branches

Do not modify, merge, rewrite, or cherry-pick another implementation's work unless the user explicitly requests comparison or integration.

## Decision Rule

Before accepting a meaningful change, ask:

> **Would this feel at home in a classic LEGO game adaptation of Twister?**

If not, redesign it before adding it.