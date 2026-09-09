# Foundation Hardening Review 0.3.6

## Status

- **SOURCE GATE: PASS** with `tools/run_validation.sh` completing all checks, including 59/59 behavior contracts.
- **CLEAN-EXTRACTED SOURCE GATE: PASS** with the final source ZIP manifest verified 315/315 and the full source validation suite rerun from a fresh extraction.
- **ENGINE GATE: PASS** with Godot `4.7.2.stable.official.ed1daf0bf`, including resource import, all engine contract scenes, a 600-frame soak, and graphical touch dispatch at 1280 x 720, 1920 x 1080, and 2400 x 1080 from the exact final ZIP after fresh extraction.
- **PHYSICAL ANDROID GATE: PENDING**.

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

Section limits are now explicitly separated into static clusters/visible clusters, material families/texture residency, active interactables/NPCs/vehicles, dynamic bodies/tornado fragments/studs, particles, audio voices, and camera requests.

### `StaticRenderClusterPolicy`

The source records the archaeology-derived rule: **author modularly, ship compatible inert scenery in spatially sensible runtime batches, preserve collision separately, and never cluster away LEGO-active identity.** No automatic mesh baker is enabled in 0.3.6. That implementation waits for the representative phone stress scene.

## Regression result

The automated Godot gate preserves the measurable 0.3.5 floors, including truck nose-heading semantics, road crossing, opening build progression, touch lifecycle safety, visible carried tools, character feel, and canonical stud identity. Subjective phone feel remains a physical-device judgment.

## Known deferred work

- Physical Android acceptance.
- Representative Wakita/tornado stress scene and measured cluster/material/texture/physics budgets.
- First production InteractionGraph chain.
- Actual static cluster baker/import step after profiling proves the right granularity.
