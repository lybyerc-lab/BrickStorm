# Foundation Hardening Review 0.3.1

## Verdict

**Internal foundation gate: PASS** after source validation and the real Godot 4.7.2 engine suite complete successfully.

This does not claim campaign completion or physical Android performance acceptance. It means the reusable foundation is structured well enough to support aggressive LEGO: Twister content growth without knowingly carrying the largest prototype shortcuts forward.

## Audited foundation

- 57 first-party GDScript files plus tagged validation/release tools;
- 32 authored scenes/resources in the current vertical slice;
- project/autoload composition and startup ordering;
- generic mission/session ownership;
- centralized input, scene-group, mission, and counter identifiers;
- accepted player/truck/cow control boundaries;
- active actor and vehicle lifecycle;
- versioned/sanitized save handling;
- destruction ownership and mobile budgets;
- authored hero-break lifecycle;
- construction-library dependency direction;
- buildable animation semantics;
- tornado registration/force contracts;
- safe-area UI composition;
- scene/resource closure and teardown;
- Android export assumptions;
- release/test tooling;
- project doctrine and branch ownership.

## Generic mission state

`GameManager` owns generic mission session state, not story-specific objectives. Content registers stable counter IDs through `GameConstants`. Sensor kits are one counter ID, not a global special case. Future Wakita rescues, Dorothy assembly, convoy tasks, drive-in objectives, F5 deployment, secrets, and Free Play goals must remain content data.

## Code labels and ownership

Every first-party GDScript and validation/release tool carries `@brickstorm.*` metadata for subsystem, role, scope, risk, contracts, North-Star relationship, and owning branch. `tools/code_map.py` generates `docs/CODE_MAP.md`; release validation fails if the map is stale or a code file loses its label.

This is intentionally not line-by-line commentary. Tags identify ownership and regression blast radius while local comments explain non-obvious invariants.

## Construction dependency boundary

The construction library provides reusable dimensions, palette roles, element specs, rendering, build order, and destruction semantics. Twister-specific content composes those primitives. The construction layer must not become a second game or pull story-specific mission logic into the foundation.

## Authored destruction boundary

`DestructibleStructure` records compact fragment blueprints. Ordinary props can still break in one bounded release. Hero structures may return an authored cluster sequence. Each stage reserves through `DestructionManager`; it does not create a parallel unbounded physics path. Rewards finalize after all stages complete.

The barn proves the pattern with five ordered clusters and a real Godot regression test.

## Save sanitation

Save JSON is treated as untrusted input. Defaults load first, compatible fields merge, unknown fields are discarded, numeric values clamp, IDs normalize, and effects quality falls back to a known profile. The next schema version must add an explicit migration rather than silently changing existing key meaning.

## Doctrine as build contract

`PROJECT_MEMORY.md`, `docs/NORTH_STAR.md`, and `docs/NO_DRIFT_POLICY.md` are required package files. Validation fails if they disappear or lose their identity markers. This prevents a source ZIP, cold-start agent, or future branch handoff from forgetting that the target is LEGO: Twister and that BrickStorm is only the codename.

## Known deferred work

- Physical Android profiling for the denser construction visuals and hero destruction.
- Batching/instancing work if intact studded scenery becomes GPU or draw-call heavy.
- More hero-structure templates and tornado-triggered authored destruction beats.
- Production audio, character animation, cutscene sequencing, hub progression, Free Play, and campaign structure.
- Full source mirroring to the OpenAI GitHub branch after the candidate is proven; the current repo branch is not yet a byte-for-byte mirror of the full game tree.

## Release rule

Static validation is never described as runtime verification. A user-facing candidate requires the pinned real Godot gate, packaging, clean extraction, and rerunning the required gates against the exact packaged copy.
