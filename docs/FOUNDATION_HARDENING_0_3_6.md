# Foundation Hardening Review 0.3.6

## Status

- **SOURCE GATE: PASS** with `tools/run_validation.sh` completing all checks, including 59/59 behavior contracts.
- **CLEAN-EXTRACTED SOURCE GATE: PASS** with the generated source ZIP manifest verified entry-for-entry and the full source validation suite rerun from a fresh extraction.
- **ENGINE GATE: PENDING** until the complete Godot 4.7.2 runner executes on this exact source candidate.
- **PHYSICAL ANDROID GATE: PENDING** after engine clearance.

## Goal

0.3.6 applies the useful clean-room findings without converting the project into a clone or destabilizing known-good gameplay. Protected means regression floor, not museum glass.

## Added foundation systems

### `AudioEvent`

Existing original BrickStorm sounds remain the payload. Gameplay-facing methods still call `AudioDirector.play_stud`, `play_smash`, `play_build_snap`, `play_build_complete`, `play_tool_pickup`, `play_tool_use`, and `play_secret`, but those methods now resolve semantic event data with room for variants, pitch/gain ranges, concurrency, cooldown, and future spatial policy.

### `ActionAnimationProfile`

The accepted motor is unchanged. Start, pivot, landing holds, stride cadence, pose-return response, and semantic footstep/landing/pivot/tool/smash markers now belong to a presentation profile. Defaults match the 0.3.5 values.

### `BuildRecipe`

`BuildableObject` now translates its existing ordered element data into a reusable `BuildRecipe`. The default recipe preserves the 0.3.5 `0.035` order cadence, move duration, rotation ratio, snap schedule, shake, and camera focus values. Future authored builds can override the recipe without rewriting the base interaction code.

### `InteractionGraph`

A typed semantic runtime supports ALL/ANY/NONE conditions, one-shot/repeatable outputs, and Story/Free Play policy gates. It is not yet driving the proven generator/cage opening. The first production use should be a new authored chain with A/B play comparison before any migration of the reference slice.

### `SectionBudget`

Section limits are now explicitly separated into:

- static cluster count and visible cluster count;
- material families and texture residency;
- active interactables, NPCs, and vehicles;
- dynamic bodies, tornado fragments, and active studs;
- particles, audio voices, and camera requests.

### `StaticRenderClusterPolicy`

The source now records the rule inferred from the scene archaeology: **author modularly, ship compatible inert scenery in spatially sensible runtime batches, preserve collision separately, and never cluster away LEGO-active identity.** No automatic mesh baker is enabled in 0.3.6. That implementation waits for the representative phone stress scene.

## Regression policy

The following 0.3.5 results remain comparison floors:

- truck control: 5/5;
- road crossing: 5/5;
- storm-probe build rhythm: 5/5;
- latest barn destruction: 4/5;
- authored opening generator/cage chain: reference slice.

New architecture must preserve or clearly improve the actual play result. If an abstraction makes the game less tactile, less readable, or less fun, the abstraction loses.

## Engine gate additions

`core_contract_engine_test.gd` now checks:

- semantic build AudioEvent exists and keeps the original initial variant;
- ActionAnimationProfile retains accepted timing defaults;
- BuildRecipe creates explicit ordered steps and preserves build cadence;
- InteractionGraph emits the expected semantic output once;
- SectionBudget defaults are internally sane;
- StaticRenderClusterPolicy keeps collision separate.

## Known deferred work

- Godot 4.7.2 execution of this exact candidate.
- Physical Android acceptance.
- Representative Wakita/tornado stress scene and measured cluster/material/texture/physics budgets.
- First production InteractionGraph chain.
- Actual static cluster baker/import step after profiling proves the right granularity.
