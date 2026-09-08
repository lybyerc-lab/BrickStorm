# Stable Code Anchors

Labels that make high-risk logic findable without reading the whole project, and
that carry each subsystem's invariants **next to the code they constrain**.

`tools/verify_anchors.gd` enforces that this registry and the source agree. It is
run by CI.

---

## Format

Start marker, in GDScript:

```gdscript
# ============================================================================
# [BS:ECONOMY:RISK_BANDS]
# Purpose: Concentric value bands around the funnel.
# Invariants:
# - Value rises monotonically toward the funnel.
# - These thresholds are the single source of truth for both the multiplier
#   and the rings drawn on the ground.
# ============================================================================
```

End marker:

```gdscript
# [BS:ECONOMY:RISK_BANDS:END]
```

Rules:

- Every anchor in the source must appear in this registry, and every anchor in
  this registry must appear in the source. Both directions are checked.
- Every start marker has exactly one matching `:END`.
- An anchor name is used once. Anchors do not nest.
- The `Purpose` line says what the block owns. The `Invariants` say what must
  remain true — these are the things a future change is most likely to break
  silently.

**What this cannot do:** the verifier confirms the registry and the markers
agree. It cannot confirm the code under an anchor still upholds the invariant
written above it. Only `--selftest`, a screenshot, or a human can do that. See
`Docs/NO_DRIFT_POLICY.md`, "What the checks can and cannot see."

---

## Approved anchors

### Laws

The two non-negotiables from `Docs/NORTH_STAR.md`, enforced in code.

- `[BS:LAW:NO_HARM]` — `scripts/brick_lib.gd` — debris collision layer; scenery physically cannot touch an actor
- `[BS:LAW:NO_FAIL]` — `scripts/player.gd` — tumble instead of death

### Construction

- `[BS:BUILD:PALETTE]` — `scripts/brick_lib.gd` — stud pitch, brick dimensions, classic colours
- `[BS:BUILD:BRICK]` — `scripts/brick_lib.gd` — the visual brick and its stud MultiMesh
- `[BS:BUILD:STUD]` — `scripts/brick_lib.gd` — the collectible stud silhouette
- `[BS:BUILD:MINIFIG]` — `scripts/brick_lib.gd` — minifig assembly
- `[BS:BUILD:TOWN]` — `scripts/prop_builder.gd` — the farm town prop set

### Destruction

- `[BS:DESTRUCTION:STRUCTURE]` — `scripts/structure.gd` — visuals until torn, bodies after
- `[BS:DESTRUCTION:TEAR]` — `scripts/structure.gd` — promotion of a brick to a rigid body
- `[BS:DESTRUCTION:DEBRIS_LIFECYCLE]` — `scripts/main.gd` — loose brick ages into studs

### Storm

- `[BS:STORM:FUNNEL_VISUAL]` — `scripts/tornado.gd` — segmented writhing funnel
- `[BS:STORM:SKIRT]` — `scripts/tornado.gd` — orbiting debris skirt at the base
- `[BS:STORM:PATH]` — `scripts/tornado.gd` — waypoint wander
- `[BS:STORM:WIND_FIELD]` — `scripts/tornado.gd` — wind sampled at a point
- `[BS:STORM:DEBRIS_VORTEX]` — `scripts/tornado.gd` — forces applied to loose debris

### Economy

- `[BS:ECONOMY:RISK_BANDS]` — `scripts/tornado.gd` — band thresholds and multipliers
- `[BS:ECONOMY:STUD_VALUE]` — `scripts/stud_field.gd` — value decided at collection
- `[BS:ECONOMY:STUD_RECYCLING]` — `scripts/stud_field.gd` — cap behaviour

### Player

- `[BS:PLAYER:CHARACTERS]` — `scripts/player.gd` — ability gates per character
- `[BS:PLAYER:MOVEMENT]` — `scripts/player.gd` — movement under wind
- `[BS:PLAYER:BRACE]` — `scripts/player.gd` — brace and lift immunity
- `[BS:PLAYER:TUMBLE]` — `scripts/player.gd` — the carried-and-dropped state

### UI

- `[BS:UI:HUD]` — `scripts/hud.gd` — readouts and layout
- `[BS:UI:MULTIPLIER]` — `scripts/hud.gd` — the dominant HUD element
- `[BS:UI:CONTEXT_BUTTON]` — `scripts/hud.gd` — the one button and its live label
- `[BS:UI:SWAP]` — `scripts/hud.gd` — character portraits
- `[BS:UI:TOUCH_STICK]` — `scripts/virtual_stick.gd` — floating virtual stick

### Camera

- `[BS:CAMERA:DIRECTOR]` — `scripts/main.gd` — auto-framing; not a player control

### World

- `[BS:WORLD:ENVIRONMENT]` — `scripts/main.gd` — sky, light, fog
- `[BS:WORLD:GROUND]` — `scripts/main.gd` — ground plane and crop squares
- `[BS:WORLD:LAYOUT]` — `scripts/main.gd` — where the town stands
- `[BS:WORLD:CRITTERS]` — `scripts/main.gd` — cows; protected actors

### Objective

- `[BS:OBJECTIVE:PHASES]` — `scripts/main.gd` — loot, build, carry, deploy, won
- `[BS:OBJECTIVE:CONTEXT_ACTION]` — `scripts/main.gd` — what the context button means here
- `[BS:OBJECTIVE:DOROTHY]` — `scripts/main.gd` — the build spot and the pod

### QA

- `[BS:QA:SELFTEST]` — `scripts/main.gd` — the load-bearing behavioural gate
- `[BS:QA:CAPTURE]` — `scripts/main.gd` — screenshot capture
- `[BS:QA:AUTOPILOT]` — `scripts/main.gd` — the demo driver used for captures

---

## Adding an anchor

1. Add it to the correct section above, with its file and a one-line purpose.
2. Wrap the code with the start/end markers and fill in Purpose and Invariants.
3. Run `godot --headless --path . --script res://tools/verify_anchors.gd`.
4. Land the registry entry and the code in the **same commit**.
