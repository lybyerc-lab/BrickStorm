# BrickStorm 0.3.6 Source Candidate

## Exact candidate identity

- Foundation: `0.3.6`
- Base: verified sealed `0.3.5`
- Base ZIP SHA-256: `457bc04a797ca90b2572da85c6cc834c112ffc968500cfa662f9a58af4f0ec0a`
- Candidate ZIP SHA-256: `5b4ca7e16f838158b4bf7963bf50b95e0cc2b227a9a802cd05c960aa0d989e6c`
- Source manifest entries: `314`
- Local implementation tip: `300bdd2` plus deterministic validation/package outputs

## Verification completed

The candidate source package was generated deterministically, extracted into a fresh directory, and checked again from that extraction.

- source manifest: `314/314` entries verified;
- deep audit: PASS;
- behavior contracts: `59/59` PASS;
- route QA: PASS;
- static validation: PASS;
- strict-parser negative tests: `10/10` PASS.

## Verification still required

- Godot 4.7.2 runtime/import gate;
- engine smoke/core/lifecycle/content/feel/currency/opening/soak/touch tests;
- physical Android acceptance and performance profiling.

The execution workspace that produced this candidate did not have Godot 4.7.2 installed and could not download it because outbound DNS was unavailable. Therefore this candidate is source-cleared but not release-cleared.

## 0.3.6 architecture applied

This candidate introduces the clean-room architecture layer identified during the Lost Temple archaeology:

- semantic `AudioEvent` resources under existing original BrickStorm sounds;
- `ActionAnimationProfile` semantic action events while preserving the accepted motor defaults;
- ordered reusable `BuildRecipe` / `BuildRecipeStep` data preserving the accepted build rhythm;
- typed `InteractionGraph` conditions/runtime with Story and Free Play policy gates;
- independent `SectionBudget` dimensions for render, texture/material, gameplay, physics/debris, studs, particles, audio, and camera requests;
- `StaticRenderClusterPolicy` implementing the rule: author modularly, cluster compatible inert scenery, keep LEGO-active identity separate.

The proven 0.3.5 opening remains the comparison baseline. The new `InteractionGraph` is intentionally not allowed to replace the working generator/cage chain until a new chain proves the abstraction in play.

## Repository note

This OpenAI branch is also the clean-room research record. The exact candidate ZIP remains the authoritative byte-complete 0.3.6 source artifact until every binary asset and generated-source file is confirmed present in the GitHub tree. Do not infer release clearance from the presence of these architecture files alone.
