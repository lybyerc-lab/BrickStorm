# Foundation Hardening Review 0.3.4

**Internal foundation gate: PASS**

0.3.4 deliberately changes rejected on-foot feel while preserving the user-approved truck heading model, road collision, storm-probe build rhythm, destruction budgets, and generic build/tool architecture.

## Audited foundation

- 68 tagged first-party GDScript files plus 10 tagged validation/release tools;
- 39 authored scene/resource files in the current vertical slice;
- 51 static behavior contracts;
- canonical stud value/color ownership in `StudCurrency`;
- real-engine character-feel regression coverage;
- real-engine stud-currency regression coverage;
- two contextual tool identities and two tool-use loops;
- visible pre-pickup and carried-tool communication;
- visual-only anti-block-sandbox environment dressing over the frozen continuous ground collider;
- centralized input, groups, missions, counters, tools, utilities, and stable content IDs;
- versioned save data and hard mobile destruction budgets unchanged.

## Regression boundary changes

On-foot movement is no longer protected merely because it was previously acceptable. Physical feedback explicitly rejected its Roblox-like presentation, so 0.3.4 establishes a new contract: hard start, hard stop, fast pivot, quick facing, bounded air steering, and rigid toy-like locomotion animation.

Truck steering and road crossing remain frozen at their user-rated 5/5 behavior. The on-foot rework does not modify `InputRouter` vehicle-facing semantics or the continuous road collider.

## Tool boundary

Tools remain actor-owned and contextual. World objects communicate requirements through prompts and actor method boundaries. A pickup must communicate identity before collection, and acquired tools remain visibly represented on the actor/toolbelt. The wrench and pry bar share this system.

## Environment boundary

The anti-Roblox visual pass changes only visual dressing and lighting. The ground continues to use one continuous collision body, the road remains a collision-free visual skin, and crop/field/horizon dressing adds no vehicle-catching collision seams.

## Known deferred work

- Physical-phone acceptance of the new on-foot controller and avatar animation.
- More environment construction density and authored roadside clutter.
- More contextual tool families and character-role ownership for Free Play.
- Better animation blending for smash/build/tool use and storm reactions.
- Production audio, richer materials, and more authored landmark silhouettes.
- Long-form save/checkpoint policy for acquired tools and powered puzzle state.

## Release rule

Static validation is not runtime verification. A release still requires the pinned Godot 4.7.2 engine gate, exact ZIP packaging, clean extraction, repeat validation and Godot testing against that exact payload, and post-test manifest verification.
