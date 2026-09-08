# No-Drift Policy

This branch must not turn LEGO: Twister into a generic brick library or generic storm game.

## Canonical Identity

- The target game is **LEGO: Twister**.
- BrickStorm is only the development codename.
- Classic early Traveller's Tales LEGO games are conceptual design precedent.
- Original code and lawful assets/placeholders only. Do not copy proprietary source, ripped assets, movie footage, music, dialogue dumps, or protected production material.

## Mandatory Pre-Change Questions

Before implementing a substantial feature, answer the relevant questions:

1. What *Twister*-specific fantasy, location, vehicle, story beat, or storm behavior does this strengthen?
2. Where are the classic LEGO-game verbs: smash, collect, build, interact, drive, discover, replay?
3. Does the tornado meaningfully affect or transform this system when appropriate?
4. Does this improve replay through secrets, abilities, collectibles, alternate paths, or Free Play-style logic?
5. Will it remain readable and responsive on a phone?
6. Does it preserve approved controls and mobile performance budgets?

If these answers are weak, redesign before implementation.

## Drift Forbidden Without Explicit User Approval

Do not silently steer toward:

- generic tornado simulator
- realism-first fluid simulation
- generic brick sandbox
- survival/crafting
- stat-heavy RPG
- combat-first action game
- open-world checklist design that replaces authored movie levels
- sterile brick CAD showcase
- infrastructure-heavy tech demo with thin playable content
- procedural generation that erases recognizable Twister sequences

## Construction-Library Guardrails

Prioritize elements and modules that directly serve near-term LEGO: Twister content:

- Oklahoma homes and clapboard walls
- barns, sheds, farms, fences, tractors, troughs, mailboxes
- Wakita storefronts and civic structures
- drive-in structures
- utility poles, transformers, road signs, water towers
- chase vehicles, trailers, storm gear, Dorothy-style equipment
- tornado-damaged versions and detachable hero-destruction chunks
- rebuildable gameplay assemblies

The library should support states such as:

- intact
- damaged
- destructible
- fragment/chunk generation
- rebuild animation
- rebuilt result

Do not spend major development time on obscure brick primitives with no foreseeable Twister use.

## Approved-System Lock

Protected until the user explicitly requests a change:

- Truck control: **5/5** user rating.
- Road crossing: **5/5** user rating.
- Vehicle joystick points the desired **screen-space heading of the vehicle nose**.

Any vehicle-system refactor must regression-test these behaviors.

## Content Bias

Once infrastructure is stable, bias work toward visible playable value:

- story spaces
- smashables
- buildables
- secrets
- collectibles
- puzzles
- characters
- vehicles
- slapstick gags
- tornado set pieces

Internal abstraction is justified when it makes those things faster or safer to produce.

## Branch Discipline

- OpenAI work stays under `openai/*`.
- Do not write to Claude or other implementations' branches.
- Do not merge/cherry-pick another implementation without explicit user instruction.
- Comparisons should be read-only until the user selects what to integrate.

## Release Gate

A candidate must pass both technical and creative gates:

1. check `PROJECT_MEMORY.md`;
2. check `docs/NORTH_STAR.md`;
3. check this policy;
4. run the real Godot 4.7.2 engine gate;
5. regression-test approved controls;
6. package, clean-extract, and retest the exact release artifact.

A technically green build can still fail the no-drift gate.

When in doubt, **LEGO: Twister wins the tie.**