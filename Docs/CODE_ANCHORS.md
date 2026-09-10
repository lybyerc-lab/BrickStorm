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
- `[BS:ECONOMY:THRESHOLD_LOCK]` — `scripts/main.gd` — a crossed threshold is never taken back
- `[BS:ECONOMY:SENSOR_BALLS]` — `scripts/main.gd` — the collectible layer and its payout
- `[BS:ECONOMY:STUD_VALUE]` — `scripts/stud_field.gd` — value decided at collection
- `[BS:ECONOMY:STUD_RECYCLING]` — `scripts/stud_field.gd` — cap behaviour

### Player

- `[BS:PLAYER:SMASH]` — `scripts/main.gd` — player-driven destruction; ungated, always available
- `[BS:PLAYER:JUMP]` — `scripts/player.gd` — the jump
- `[BS:PLAYER:CHARACTERS]` — `scripts/player.gd` — ability gates per character
- `[BS:PLAYER:WALK_CYCLE]` — `scripts/player.gd` — the stiff-legged minifig waddle
- `[BS:PLAYER:MOVEMENT]` — `scripts/player.gd` — movement under wind
- `[BS:PLAYER:BRACE]` — `scripts/player.gd` — brace and lift immunity
- `[BS:PLAYER:TUMBLE]` — `scripts/player.gd` — the carried-and-dropped state

### UI

- `[BS:UI:HUD]` — `scripts/hud.gd` — readouts and layout
- `[BS:UI:MULTIPLIER]` — `scripts/hud.gd` — the dominant HUD element
- `[BS:UI:ACTION_BUTTONS]` — `scripts/hud.gd` — the three buttons; only BUILD is contextual
- `[BS:UI:SWAP]` — `scripts/hud.gd` — character portraits
- `[BS:UI:TOUCH_STICK]` — `scripts/virtual_stick.gd` — floating virtual stick

### Vehicles

- `[BS:VEHICLE:OCCUPANCY]` — `scripts/vehicle.gd` — boarding and alighting
- `[BS:VEHICLE:DRIVE]` — `scripts/vehicle.gd` — arcade handling; the stick is a heading
- `[BS:VEHICLE:RAM]` — `scripts/vehicle.gd` — driving through scenery destroys it

### Audio

- `[BS:AUDIO:BANK]` — `scripts/audio.gd` — the event vocabulary; events name what happened, not the file
- `[BS:AUDIO:MIX]` — `scripts/audio.gd` — bus layout and the master limiter
- `[BS:AUDIO:MIXER]` — `scripts/audio.gd` — stream cache and the fixed 3D voice pool
- `[BS:AUDIO:FLAT]` — `scripts/audio.gd` — voice priority, and why the player's own feedback is not positional
- `[BS:AUDIO:STUD_LADDER]` — `scripts/audio.gd` — rising pitch through a stud streak
- `[BS:AUDIO:STORM_ROAR]` — `scripts/main.gd` — the funnel's roar as the primary risk signal
- `[BS:AUDIO:ENGINE]` — `scripts/vehicle.gd` — engine loop pitched by road speed

### Content (hand-authored)

- `[BS:CONTENT:HOG_LOT]` — `scripts/set_piece.gd` — the authored farmyard; three collectibles, three verbs
- `[BS:CONTENT:BUILD_STEPS]` — `scripts/set_piece.gd` — the staircase the build assembles
- `[BS:CONTENT:SET_PIECE]` — `scripts/main.gd` — placement and wiring of the authored piece
- `[BS:CONTENT:ABILITY_GATE]` — `scripts/structure.gd` — heavy scenery only Bill can shift

### Comedy

- `[BS:COMEDY:VOCABULARY]` — `scripts/comedy.gd` — the onomatopoeia word banks
- `[BS:COMEDY:POPUPS]` — `scripts/comedy.gd` — floating comic-book words
- `[BS:COMEDY:GAGS]` — `scripts/main.gd` — flying livestock and the outhouse

### Camera

- `[BS:CAMERA:DIRECTOR]` — `scripts/main.gd` — auto-framing; not a player control

### World

- `[BS:RENDER:FACE]` — `shaders/face.gdshader` — the face wrap computed from position, and why it is not authored on the mesh
- `[BS:RENDER:BASEPLATE]` — `shaders/baseplate.gdshader` — the ground is a baseplate, and why its studs are shaded rather than modelled
- `[BS:BUILD:TORSO]` — `scripts/brick_lib.gd` — one tapered torso part, and why its print is ink-line artwork
- `[BS:RENDER:TORSO]` — `shaders/torso.gdshader` — printing the front face, selected by the local normal
- `[BS:BUILD:FACE]` — `scripts/brick_lib.gd` — the face is printed, not modelled, and why brows carry it
- `[BS:BUILD:CHAMFER]` — `scripts/brick_lib.gd` — the chamfered brick, and why a bare BoxMesh read as generic blocks
- `[BS:RENDER:WIND]` — `shaders/brick_common.gdshaderinc` — the vertex wind, and why its storm must be the same storm the physics uses
- `[BS:RENDER:PLASTIC]` — `scripts/brick_lib.gd` — the one definition of what plastic looks like, and why the fresnel term is bricks-only
- `[BS:WORLD:ENVIRONMENT]` — `scripts/main.gd` — sky, light, fog
- `[BS:WORLD:GROUND]` — `scripts/main.gd` — ground plane and crop squares
- `[BS:WORLD:AREA_STATE]` — `scripts/main.gd` — the sub-area's intensity state, and the ambience bed that follows it
- `[BS:WORLD:NEAR_CACHE]` — `scripts/main.gd` — cached short list of nearby structures for the per-frame hot loops
- `[BS:WORLD:STREAM]` — `scripts/main.gd` — corridor blocks spawn ahead of the storm and are reclaimed behind
- `[BS:WORLD:LAYOUT]` — `scripts/main.gd` — where the town stands
- `[BS:WORLD:CRITTERS]` — `scripts/main.gd` — cows; protected actors

### Objective

- `[BS:OBJECTIVE:PHASES]` — `scripts/main.gd` — loot, build, carry, deploy, won
- `[BS:OBJECTIVE:CONTEXT_ACTION]` — `scripts/main.gd` — what the context button means here
- `[BS:OBJECTIVE:DOROTHY]` — `scripts/main.gd` — the build spot and the pod

### QA

- `[BS:QA:SELFTEST]` — `scripts/main.gd` — the load-bearing behavioural gate
- `[BS:QA:PLAYTHROUGH]` — `scripts/main.gd` — records a full round as a timestamped event log
- `[BS:QA:CAPTURE]` — `scripts/main.gd` — screenshot capture
- `[BS:QA:AUTOPILOT]` — `scripts/main.gd` — the demo driver used for captures

---

## Adding an anchor

1. Add it to the correct section above, with its file and a one-line purpose.
2. Wrap the code with the start/end markers and fill in Purpose and Invariants.
3. Run `godot --headless --path . --script res://tools/verify_anchors.gd`.
4. Land the registry entry and the code in the **same commit**.
