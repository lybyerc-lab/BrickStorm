# BrickStorm: Storm Run

## Foundation 0.3.6 source candidate

BrickStorm is the development codename for an Android-first **LEGO: Twister** fan-game prototype built in Godot 4.7.2. Foundation 0.3.6 is an archaeology-to-architecture hardening pass: it layers reusable classic-brick-adventure systems underneath the proven Foundation 0.3.5 opening without replacing the user-approved truck, road, and storm-probe behavior.

Read `PROJECT_MEMORY.md`, `docs/NORTH_STAR.md`, and `docs/NO_DRIFT_POLICY.md` before substantial design or architecture changes.

### Protected 0.3.5 gameplay baseline

The first minute remains the same authored chain:

1. follow a denomination-colored stud trail;
2. smash nearby brick scenery for studs;
3. identify and collect the clearly labeled wrench;
4. assemble the scattered farm generator with the protected staged build rhythm;
5. use the visibly carried wrench on the completed generator;
6. watch a short camera reveal as the powered sensor cage opens;
7. collect the first storm-sensor kit;
8. continue into the wider farm with truck, cow, scanner, smash/build side progression, pry-bar secret, and storm-probe finale.

Truck control, road crossing, and storm-probe build rhythm remain regression floors, not museum pieces. Improvements are welcome only when they clearly preserve or beat the known-good play result.

### What 0.3.6 adds

- `AudioEvent`: semantic audio identity with sample variants, pitch/gain policy, concurrency, cooldown, and future spatial fields while retaining the existing original BrickStorm sounds and public playback calls.
- `ActionAnimationProfile`: data-owned start/pivot/land timing, stride cadence, and semantic footstep/landing/pivot/tool/smash event markers layered over the accepted on-foot motor.
- `BuildRecipe` + `BuildRecipeStep`: ordered component cadence, snap timing, and completion camera punctuation generalized from the existing build system while preserving its current defaults.
- `InteractionGraph`: typed ALL/ANY/NONE semantic conditions, one-shot/repeatable nodes, and Story/Free Play policy gates. It is foundation-only in this candidate and does not replace the proven opening chain yet.
- `SectionBudget`: separate static-render cluster, material/texture, gameplay-population, physics/debris, stud, particle, audio, and camera limits.
- `StaticRenderClusterPolicy`: codifies the modeling rule **author modularly, cluster compatible inert scenery, keep LEGO-active identity separate** without prematurely baking a specific renderer implementation.
- Core engine-test coverage prepared for all of the above so Godot 4.7.2 must exercise the new resource contracts before 0.3.6 can be release-cleared.

### Mobile controls

The left virtual joystick points the active actor toward the requested screen direction. On foot it commands a fast planted toy response. In the truck it points the hood. On the cow it points the cow's nose. ACTION interacts, JUMP jumps on foot, and SMASH attacks on foot or triggers the cow charge while mounted.

### Current verification status

**0.3.6 source gate:** PASS. Source inventory, code map, deep audit, route QA, strict-parser fixtures, project validation, and 59/59 behavior contracts pass. The generated source ZIP was also verified entry-for-entry and the same validation suite passed again from a fresh extraction.

**0.3.6 engine gate:** PENDING. This execution workspace cannot reach the external Godot download host, so the candidate has not yet earned the Godot 4.7.2 runtime, soak, graphical touch, or clean-extracted engine PASS markers.

**0.3.5 baseline:** ENGINE GATE PASSED with Godot 4.7.2 stable, including resource import, smoke, core contracts, all-resource lifecycle, content gameplay, character feel, stud currency, authored opening, 600-frame soak, and multi-resolution touch tests.

Physical Android testing remains the authority for thumb feel, target-device GPU behavior, frame pacing, safe areas, heat, battery use, sound balance, cluster/draw pressure, and subjective LEGO-game feel.

See `docs/FOUNDATION_HARDENING_0_3_6.md`, `docs/ENGINE_RUNTIME_STATUS.md`, `docs/FOUNDATION_ACCEPTANCE.md`, and `docs/MOBILE_TEST_CARD.md`.
