# No-Drift Policy

This policy prevents BrickStorm from slowly turning into a different game while individual features are added.

## Canonical Identity

The target game is **LEGO: Twister**.

BrickStorm is a development codename, not a separate creative direction.

The design language is a classic early Traveller's Tales-style LEGO adaptation of the original *Twister* movie, built with original code and lawful assets/placeholders.

## Mandatory Pre-Change Check

Before implementing a substantial gameplay, level, art, UI, vehicle, storm, or construction-library feature, answer these questions:

1. **Twister specificity:** What part of the *Twister* fantasy, setting, movie structure, storm chasing, or character role does this strengthen?
2. **LEGO-game grammar:** Where are the smash, collect, build, interact, drive, discover, replay, or slapstick opportunities?
3. **Tornado relationship:** Does the storm affect this system, reveal it, threaten it, rearrange it, or create spectacle around it where appropriate?
4. **Replay value:** Can character abilities, secrets, collectibles, alternate routes, or Free Play make this more interesting later?
5. **Mobile readability:** Will the mechanic remain clear and responsive on a phone?
6. **Approved-system preservation:** Does this preserve accepted controls, performance budgets, save contracts, and other proven foundations?

If a substantial feature cannot answer at least the relevant questions above, stop and redesign it before implementation.

## Drift That Is Not Allowed Without Explicit User Approval

Do not silently steer the project toward:

- a generic tornado simulator
- realism-first fluid simulation at the expense of authored gameplay
- a generic brick sandbox
- a survival/crafting game
- an equipment-management simulator
- a stat-heavy RPG
- a weapon/combat-first action game
- an open-world checklist game that replaces authored movie levels
- a sterile LEGO-like CAD showcase with little gameplay
- a tech demo whose systems grow while playable content stays thin
- procedural generation that erases recognizable Twister locations and sequences
- cinematic imitation with little player interaction

A useful technical system is not automatically a useful LEGO: Twister feature.

## Conceptual Reference Policy

Classic LEGO games are strong design precedent. It is acceptable to study and emulate their **conceptual patterns**, including:

- readable smashable scenery
- studs and collectible feedback
- build animations and rebuild puzzles
- slapstick cutscene pacing
- character ability gating
- hub-and-story-level structure
- Free Play replay loops
- arcade vehicles
- secret areas and completion rewards

Do not copy or distribute proprietary game source, extracted/ripped assets, trademarked presentation packages, movie footage, music, dialogue transcripts, actor likeness assets, or other protected production material.

The goal is to make an original implementation of the familiar game language.

## Construction-Library No-Drift Rules

Every meaningful addition to the brick-construction library should support at least one actual game-content need.

Priority categories are:

- 1990s Oklahoma buildings
- barns, sheds, fences, farms, tractors, troughs, mailboxes, and roadside props
- Wakita storefronts and civic structures
- drive-in structures
- utility poles, wires, transformers, signs, and water towers
- storm-chasing vehicles and trailers
- Dorothy-style scientific equipment
- tornado-damaged variants and detachable structural chunks
- rebuildable gameplay assemblies

Avoid spending large amounts of time on obscure brick primitives that have no near-term use in a Twister level.

The library must support gameplay states, not merely appearance:

- intact
- damaged
- destructible
- fragment/chunk generation
- rebuild animation
- rebuilt result

## Approved Control Lock

The following user-accepted behavior is protected until the user requests a change:

- Truck control rating: **5/5**.
- Road crossing rating: **5/5**.
- Vehicle joystick direction commands the desired **screen-space heading of the vehicle nose**.

Changes to vehicle architecture must include regression tests proving these behaviors still work.

Do not 'improve' accepted controls by silently replacing their control philosophy.

## Content-to-Systems Balance

After a foundation is stable, development should bias toward visible playable value.

Prefer work that produces:

- new story beats
- new level spaces
- smashables
- buildables
- puzzles
- secrets
- characters
- vehicles
- gags
- tornado set pieces
- collectible/replay hooks

over endless internal abstraction.

Infrastructure work is justified when it makes those things easier, safer, or faster to build.

## Release No-Drift Gate

Before a release candidate:

1. compare major changes against `PROJECT_MEMORY.md`;
2. compare the experience against `docs/NORTH_STAR.md`;
3. confirm this policy has not been violated;
4. run the real Godot engine gate;
5. regression-test previously approved controls;
6. clean-extract and retest the exact package to be released.

A technically green build may still fail the no-drift gate.

## Branch Discipline

- `openai/brickstorm` belongs to the OpenAI/ChatGPT implementation.
- OpenAI feature branches should remain under the `openai/` namespace.
- Do not write to Claude or other agents' branches.
- Do not merge another implementation into the OpenAI line without explicit user instruction.
- Comparisons between implementations should be read-only until the user chooses what to integrate.

## Escalation Rule

If a requested or proposed feature conflicts with the North Star, do not quietly reinterpret the project.

Surface the conflict clearly and ask the user whether the North Star itself should change.

Until the user explicitly changes it, **LEGO: Twister wins the tie.**