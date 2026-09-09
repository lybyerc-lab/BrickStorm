# Lost Temple Clean-Room Deep Pass 2

## Scope

This document extends `LOST_TEMPLE_CLEANROOM_ARCHAEOLOGY.md` with additional clean-room measurements focused on asset reuse, collision/navigation complexity, semantic interaction interfaces, destructible-profile reuse, and section-local audio bindings.

No proprietary assets or scripts are included. The purpose is to derive independent BrickStorm architecture and authoring rules.

---

## 1. Cross-section texture reuse is measurable

Across the six decoded gameplay scene bundles A/B/D/E/F/G:

- 279 non-empty embedded texture payload instances were observed;
- only 191 payloads are byte-unique;
- total texture payload represented by all six sections: 132,318,648 bytes;
- byte-unique texture payload: 104,451,280 bytes;
- exact cross-section duplication: 27,867,368 bytes, approximately 26.6 MiB;
- therefore about 21% of the sampled texture bytes are exact duplicates between sections.

Pairwise exact-payload overlap is strongly clustered:

| Pair | Shared texture payloads | Approx. shared bytes |
| --- | ---: | ---: |
| A / B | 24 | 6.75 MiB |
| A / G | 22 | 5.57 MiB |
| B / G | 24 | 8.63 MiB |
| D / E | 16 | 6.96 MiB |
| B / D | 8 | 2.71 MiB |
| B / E | 7 | 1.46 MiB |
| A / D | 7 | 0.08 MiB |
| A / E | 6 | 0.46 MiB |
| F / any one section | 2-4 | at most about 0.71 MiB |

This suggests at least two thematic reuse neighborhoods in the sampled chapter, while the focused chase/set-piece section F is largely self-contained.

### BrickStorm translation

Do not package common Oklahoma/farm/vehicle/storm materials independently into every streamed section.

Use something like:

- `EnvironmentThemePack`
- `SectionAssetPack`
- `HeroSetPiecePack`

A section manifest references shared theme resources plus its genuinely local resources. Godot resource paths should remain stable so shared textures/materials are loaded once and reused rather than duplicated as section-private assets.

Candidate shared packs for LEGO: Twister include:

- Oklahoma ground/road/grass/wood/metal common set;
- common LEGO brick material palette;
- common vehicle surfaces;
- common storm/debris material set;
- Wakita-specific pack;
- drive-in-specific pack;
- tornado-chase-specific pack.

---

## 2. Collision complexity tracks authored section intent

The terrain/collision sidecar is spatially partitioned into terrain groups and mesh blocks. It also supports infinite-wall boundaries and platform-linked terrain groups.

Measured collision profiles:

| Section | Terrain groups | Platform-linked groups | Infinite-wall groups | Wall points | Mesh blocks | Collision faces |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| A | 139 | 77 | 5 | 148 | 260 | 2,303 |
| B | 85 | 20 | 2 | 154 | 280 | 2,911 |
| D | 210 | 127 | 3 | 142 | 417 | 3,448 |
| E | 102 | 28 | 1 | 7 | 435 | 4,773 |
| F | 44 | 28 | 1 | 122 | 95 | 870 |
| G | 52 | 15 | 7 | 118 | 187 | 2,456 |

The chase-like F section again stands out: only 870 terrain collision faces, dramatically below the other gameplay sections.

The public LIJ1-compatible terrain loader also shows that platform terrain can be linked back to rendered special objects through stable scene IDs. This is a useful separation of collision/physical support from visual scene content.

### BrickStorm translation

Treat collision as an authored proxy layer, not a duplicate of visual geometry.

Recommended split:

- intact visual assembly;
- simple intact collision proxy;
- stable assembly/object ID;
- optional moving/platform collision binding;
- destruction state transition;
- pooled dynamic debris after breakaway.

For tornado destruction this allows a barn wall, sign, roof section, or utility object to remain cheap while intact and only become expensive when the authored storm state actually releases it.

---

## 3. AI navigation is also section-budgeted

Each sampled gameplay section contains a primary navigation/path graph plus optional triggers, locators, locator sets, and placed AI creatures.

Measured high-level navigation data:

| Section | Path points | Path connections | Special-object-bound path points | World triggers | AI locators | Locator sets | Placed AI creatures |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| A | 63 | 65 | 3 | 0 | 1 | 1 | 0 |
| B | 78 | 75 | 0 | 1 | 6 | 1 | 3 |
| D | 132 | 138 | 9 | 4 | 8 | 2 | 2 |
| E | 41 | 39 | 3 | 0 | 0 | 0 | 0 |
| F | 36 | 35 | 0 | 0 | 1 | 0 | 0 |
| G | 30 | 31 | 0 | 2 | 9 | 2 | 0 |

F again has the profile of a stripped-down pursuit corridor: 36 path points, 35 explicit connections, no local triggers, one locator, and no placed AI creatures.

### BrickStorm translation

Do not run a universal maximum-complexity navigation layer in every scene.

A `SectionBudget` should also control:

- active navigation regions;
- NPC path graph complexity;
- active story locators;
- helper/companion targets;
- crowd systems;
- tornado-safe navigation anchors.

For high-speed storm pursuit, use a compact authored route plus only the locators needed for rescue/chase/story beats.

---

## 4. Interactables expose a stable semantic state interface

A separate generated interaction-interface sidecar enumerates interactable instances and the semantic states each type exposes. This sits between binary object configuration and the higher-level interaction graph.

Aggregate sampled state interfaces include:

| Interactable family | Interface instances | Exposed semantic states |
| --- | ---: | --- |
| obstacle | 240 | end, not-at-start, proximity, at-start, playing-forward, destroyed, active-frame window |
| destructible | 174 | blown-up, punched, plugging, picked-up |
| ledge | 26 | can-use, occupied |
| door | 23 | active |
| turret-like device | 16 | destroyed, fired, shot-count condition |
| grapple | 12 | active, occupied, two-character occupied |
| timer | 12 | ping |
| short cinematic beat | 11 | played, playing |
| pickup exposed to graph | 9 | collected |
| AI processor | 9 | processing |
| buildable | 6 | finished |
| dig interaction | 6 | end, not-at-start, at-start |
| plug/device connection | 6 | plugged, plug-ID states, not-plugged |
| zip/swing traversal | 5 | active, in-use |
| lever | 3 | down plus role/result variants |
| special authored action | 3 | end, not-at-start |
| role-specific technical device | 2 | active, special-button state, handle state |
| security door | 2 | opened |
| puzzle | 1 | solved |

The important point is not the individual names. It is the architectural layer: each interactable type publishes a small semantic query contract that the graph can consume without knowing its binary implementation.

### BrickStorm translation

Add an explicit `InteractionStateAdapter` / semantic-state contract layer.

Examples:

- `is_built`
- `is_destroyed`
- `is_active`
- `is_open`
- `is_collected`
- `is_occupied`
- `is_complete`
- `is_powered`
- `is_repaired`
- `storm_state`

`InteractionGraph` should depend on these semantic states, never on concrete scene-node internals.

This improves testability and makes authored LEGO chains easy to remix for Story and Free Play.

---

## 5. Destruction uses reusable profiles plus cheap instances

The serialized destructible system separates a small profile library from placed destructible instances.

| Section | Local destruction profiles | Placed destructible instances |
| --- | ---: | ---: |
| A | 25 | 66 |
| B | 3 | 21 |
| D | 13 | 21 |
| E | 16 | 2 |
| F | 8 | 24 |
| G | 9 | 40 |

A profile can be reused by many scene objects. Several sections also contain placed instances whose template is not defined in the local profile list, indicating reuse of shared/global destruction templates in addition to section-local profiles.

The profile records carry independent references for material/debris/effect families, multiple particle/effect hooks, decal/emitter/swap/shadow-style presentation fields, and a numeric reward parameter. Placed instances then reference a profile/template and add lightweight placement/state data.

This is significantly more deliberate than attaching a generic rigid-body explosion script to every smashable.

### BrickStorm translation

Use three layers:

1. `DestructibleProfile`
2. lightweight `DestructibleInstance`
3. optional `StormResponseProfile`

A `DestructibleProfile` should own reusable feedback and break behavior:

- material family;
- break pattern/class;
- staged thresholds;
- debris palette;
- particle/audio families;
- stud/reward table;
- optional decal/dust/swap behavior;
- fragment budget class.

The scene instance should mostly own transform, stable ID, current state, and profile reference.

This architecture is directly compatible with pooled physics fragments and the mobile-first rule that assemblies remain intact until they actually need to break.

---

## 6. Section-local SFX binds world events to global semantic audio

Small per-section SFX sidecars contain names of local scene/animation events and references that resolve directly to identifiers in the global audio configuration.

The sidecars do not need to embed the audio clips themselves. They provide authored binding between a local event and a global semantic sound family plus local parameters.

The sampled sections bind events for categories such as:

- bridge/set-piece motion;
- water interaction;
- doors and mechanical latches;
- projectile/trap motion;
- tool/object drops;
- rolling/impacting large objects;
- landing and collision events.

### BrickStorm translation

Separate:

- `AudioEvent` definition, global/reusable;
- `SceneAudioBinding`, section-local;
- animation/action event marker, local trigger.

Example:

`barn_roof_panel detach marker -> SceneAudioBinding -> wood_large_break AudioEvent`

The scene should not know or care which particular sample variation gets played.

---

## 7. F is now a multi-system chase signature, not a single clue

Section F differs from ordinary exploration sections simultaneously across many independent systems:

- far clip dramatically reduced;
- no local high-level interaction graph;
- no buildables;
- only one obstacle;
- only 37 placed pickups;
- pickup spacing substantially widened;
- only six scene splines;
- one rail/shake-oriented camera profile;
- compact companion behavior biased toward running to the endpoint;
- only 44 terrain groups and 870 terrain collision faces;
- 36 AI path points / 35 explicit path connections;
- no AI triggers;
- no placed AI creatures;
- eight local destruction profiles driving 24 placed destructibles.

This is strong cross-system evidence for an intentionally narrowed set-piece budget rather than a coincidental low-content room.

### BrickStorm translation

Create `SpectacleBudgetProfile` as a first-class section policy.

For tornado pursuit/F5 sequences it can deliberately trade:

- world horizon complexity;
- optional interactions;
- idle NPC logic;
- navigation breadth;
- dense pickup trails;

for:

- debris;
- staged destruction;
- vehicle/character motion;
- storm particles;
- important audio voices;
- camera pressure;
- readable route cues.

The result should look more chaotic while the underlying runtime becomes more controlled.

---

## 8. Updated clean-room architecture shortlist

The most strongly supported BrickStorm abstractions now are:

- `EnvironmentThemePack`
- `SectionAssetPack`
- `ChapterManifest`
- `SectionManifest`
- `SectionBudget`
- `SpectacleBudgetProfile`
- `InteractionGraph`
- `InteractionStateAdapter`
- `BuildRecipe`
- `ActionAnimationProfile`
- `ToolDefinition`
- `AudioEvent`
- `SceneAudioBinding`
- `CameraSocketProfile`
- `CameraRailProfile`
- `CameraBeat`
- `DestructibleProfile`
- `DestructibleInstance`
- `StormResponseProfile`
- `NPCBehaviorProfile`
- `TraversalPath`
- Story/Free Play `ModePolicy`

## 9. Practical lesson

The recurring architectural pattern is separation of **definition**, **instance**, **semantic state**, and **authored consequence**.

For BrickStorm that means a tornado does not need to understand every barn, sign, truck, probe, NPC, and collectible implementation. It can operate through stable semantic profiles and states:

`storm pressure -> response profile -> object state change -> interaction graph -> camera/audio/reward consequence`

That is both more LEGO-like and more controllable on a phone.
