# Classic TT Clean-Room Reference for BrickStorm

## Purpose

This document records implementation lessons derived from static clean-room study of a user-supplied 2008 LEGO adventure-game demo. It exists to improve **LEGO: Twister** without importing proprietary game assets, source code, scripts, animation data, audio, level geometry, or other copyrighted content.

The usable output is architectural: system boundaries, state-machine patterns, feedback layering, approximate aggregate timing/behavior observations, and design principles that can be reimplemented independently in Godot.

BrickStorm remains governed by `PROJECT_MEMORY.md`, `docs/NORTH_STAR.md`, and `docs/NO_DRIFT_POLICY.md`. If a lesson below conflicts with LEGO: Twister's creative target, the North Star wins.

## Executive finding

Classic brick-adventure feel does **not** appear to come from one special movement constant. The reference layers many small authored systems around a relatively consistent common character motor:

- animation-event footsteps and contacts;
- material-specific sound families;
- randomized audio variants with pitch/gain variation;
- separate stud drop, land, and pickup events;
- explicit tool draw/use/put-away states;
- small camera cuts, reveals, shake, and socket presets;
- data-authored build sequences;
- state-driven interaction graphs;
- compact reusable NPC behavior state machines;
- music states with authored legal transition points;
- section-specific streaming and subsystem budgets;
- Story/Free Play route and condition differences.

The cumulative texture is the target. BrickStorm should therefore favor many inexpensive, semantically connected feedback layers over one oversized simulation system.

---

## 1. Character motor: common mechanics, layered presentation

Across the sampled human character configurations, core movement values are unusually consistent. The dominant reference values cluster around:

- walk speed: about `0.6` reference units;
- run speed: about `1.4`;
- acceleration: about `10`;
- jump impulse: about `1.9`;
- airborne gravity: about `-5`;
- turn rate: about `1`;
- common collision radius/height: about `0.1 / 0.42`.

These are **reference ratios, not BrickStorm constants to copy**. The useful relationships are:

- run/walk ratio around 2.3:1;
- very short time to reach run speed;
- compact toy-weight jump arc;
- limited airborne duration;
- differences between characters are expressed more through abilities, animation, items, and context than radically different locomotion motors.

### BrickStorm translation

Keep one authoritative on-foot motor and improve feel through an `ActionAnimationProfile` layer that can own:

- animation/pose identity;
- frame/event markers for footsteps, landings, tool contacts, build snaps, smash impacts;
- movement multipliers when an action needs them;
- blend in/out rules;
- head-turn enable/lock;
- visible carried-item state;
- item stow/restore rules;
- loop/cycle behavior.

This supports the existing project goal of immediate start response, planted reversal, whole-body pivots, limited air steering, and hinge-like toy animation without fragmenting movement logic across every character.

---

## 2. Interaction graph: authored consequences instead of giant scripts

The sampled level data separates **typed interactables** from a separate authored graph that connects their states and consequences.

Aggregate observations from five gameplay-section graphs:

- 414 flow groups;
- 288 typed interactable nodes;
- 68 condition nodes;
- 373 child edges;
- common conditions include `Any`, `All`, and `Loop`;
- common flags cover start-hidden, finish-hidden, finish-deactivated, reverse, output-only, and Story/Free Play gating;
- cyclic graphs are used for repeatable traps and hazard behavior.

Interactable families expose small, explicit state/query contracts rather than arbitrary monolithic per-object logic. Observed families include obstacles, buildables, destructibles, dig targets, pickups, grapples, ledges, levers, timers, doors, plugs, puzzles, mini-cuts, turrets, messages, push blocks, portals, and role-specific devices.

### BrickStorm translation

Create a reusable `InteractionGraph` system composed of data resources:

- `InteractionNode`
- `ConditionNode`
- `InteractionEdge`
- `InteractionGraph`

Recommended condition operators:

- ALL
- ANY
- NONE
- LOOP / repeat gate

Recommended edge/node flags:

- start hidden
- start inactive
- finish hidden
- finish inactive
- reverse
- output only
- Story-only
- Free-Play-only

Interactables should expose stable semantic queries such as `is_built`, `is_destroyed`, `is_active`, `is_open`, `is_collected`, `is_occupied`, and `is_complete` instead of graph code knowing concrete scene internals.

For LEGO: Twister this lets authored chains read naturally:

`smash debris -> collect parts -> repair probe -> camera reveal -> storm pressure rises -> route opens`

without baking the entire sequence into one level script.

---

## 3. Builds: explicit recipes with world consequences

Reference buildables use explicit ordered part lists. Sampled important builds span roughly 6 to 30 ordered pieces rather than simply toggling an object from invisible to complete.

Graph analysis also shows that completed builds commonly feed another gameplay node: an obstacle changes, something becomes destructible, traversal changes, a tool target appears, or a later condition becomes true.

### BrickStorm translation

Promote the successful storm-probe rhythm into a general `BuildRecipe` resource:

- `steps[]`: ordered visual/build pieces;
- snap timing per step or timing profile;
- optional camera emphasis events;
- build-loop audio event;
- snap audio event;
- completion event;
- consequence output into `InteractionGraph`.

A build that only plays an animation and awards studs should be considered incomplete unless the story beat specifically calls for that simplicity.

---

## 4. Audio: semantic events, variation, and material response

The reference audio configuration is strongly data-driven.

Aggregate observations from approximately 992 active sample declarations:

- about 122 randomized variant groups;
- about 302 group-member references;
- average randomized group size about 3.5;
- more than 900 declarations include pitch randomization;
- more than 600 include volume variation;
- more than 100 loops;
- explicit priorities are common;
- explicit near/far falloff records exist;
- footsteps, tools, studs, destruction, vehicles, and ambience are all represented by dedicated semantic families.

Particularly relevant layering:

- footsteps vary by material and by sample;
- tools have pickup/draw/use/put-away phases;
- repair tools can loop while working and trigger context-specific contact sounds;
- studs distinguish drop, ground contact, and pickup;
- brick destruction distinguishes small/medium impacts, individual/multiple debris, collapse, and build/form sounds.

### BrickStorm translation

Use an `AudioEvent` resource instead of direct clip references in gameplay code.

Suggested fields:

- semantic event ID;
- variants[];
- pitch random range;
- gain random range;
- priority;
- loop;
- ducking behavior;
- spatial near/far range;
- concurrency limit;
- material override table;
- cooldown / anti-spam rule.

First BrickStorm event families to harden:

- footsteps by dirt/grass/wood/metal/brick/wet surface;
- jump takeoff and landing by surface;
- brick small/medium/large impacts;
- brick scatter and settle;
- stud drop, bounce/land, pickup by tier;
- wrench/pry-bar/tool draw, use, loop, put-away;
- vehicle body, tire, suspension, collision;
- storm wind layers and debris impacts.

The goal is high event density with low per-event cost.

---

## 5. Music: state machine plus legal transition markers

The reference music configuration separates quiet/action/no-music states and provides authored transition markers rather than blindly crossfading at arbitrary times.

Aggregate observation:

- quiet-state legal transitions tend to be farther apart;
- action-state transition points are more frequent;
- sampled action cues can offer legal transitions within only a few seconds during intense sequences.

### BrickStorm translation

Create a `MusicStateDirector` with states such as:

1. CALM
2. WATCH
3. BUILDING_STORM
4. CHASE
5. TORNADO_CRISIS
6. AFTERMATH

Each cue should provide optional authored transition markers. A requested intensity change waits for the next acceptable marker unless an emergency transition policy overrides it.

For tornado gameplay, marker density can increase with intensity so the score becomes more responsive as danger rises without sounding chopped apart.

---

## 6. Cameras: reusable sockets, short authored emphasis

Level data contains named camera presets/sockets with parameters for blending, positional seek, offsets, pullback/target distance, and sometimes shake. Camera-only resource bundles also exist separately from the larger gameplay scene bundles.

### BrickStorm translation

Add a `CameraSocketProfile` resource and short-lived camera requests:

- world anchor / target anchor;
- blend time;
- positional seek rate;
- look ratio;
- pullback / distance;
- vertical and forward offsets;
- shake profile;
- maximum hold time;
- return policy.

Use these for:

- generator comes alive;
- probe completes;
- bridge/route opens;
- tornado reveals itself;
- barn wall peels away;
- convoy vehicle crashes through a set piece;
- Free Play secret is exposed.

These should punctuate gameplay rather than steal control for long stretches.

---

## 7. Level architecture: authored streamed sections with explicit budgets

The reference game divides a chapter into multiple short streamed sections rather than treating the entire adventure as one giant world.

Section configuration owns values such as:

- music identity;
- local subsystem capacities;
- character/far clipping distances;
- transition splines/doors;
- camera presets;
- cutscene routing;
- Story/Free Play exits;
- optional projectiles, water, hazards, or other local systems.

A particularly intense hazard section dramatically shortens its far clip and uses a much smaller interaction set than neighboring exploration sections. This is an important mobile lesson: **reduce unrelated scene complexity when spectacle must spike**.

### BrickStorm translation

Use a hierarchy similar to:

`Film / Story -> Chapter -> Streamed Section`

Suggested resources:

- `ChapterManifest`
- `SectionManifest`
- `SectionBudget`

A section budget can define caps for:

- physical fragments;
- active studs;
- smashables;
- buildables;
- contextual tools;
- NPCs;
- vehicles;
- tornado debris;
- particle emitters;
- important audio voices;
- camera requests.

For large tornado encounters, deliberately tighten horizon complexity, NPC count, and unrelated interactables so physics/destruction/audio have room to surge.

---

## 8. Companion and enemy AI: small reusable FSMs

Reference behavior scripts are mostly explicit finite-state machines with named Conditions and Actions. Level-local scripts combine named locators/path regions with reusable behaviors. Shared character scripts provide reusable following, fighting, trigger-help, and carry-help modes.

This suggests a deliberately thin high-level companion controller rather than a giant all-knowing AI.

### BrickStorm translation

Use reusable behavior modules driven by a small blackboard/query vocabulary.

Example companion high-level modes:

- FOLLOW_PLAYER
- HELP_INTERACTION
- HELP_BUILD
- ENTER_VEHICLE
- EXIT_VEHICLE
- DANGER_REACT
- STORY_POSITION

Example queries:

- player_near
- target_reachable
- interaction_waiting_for_partner
- tornado_pressure_above
- safe_anchor_available
- vehicle_has_seat
- story_gate_active

Named authored anchors and routes should do much of the spatial storytelling work.

---

## 9. Traversal: authored paths paired with action presentation

Reference sidecars separate traversal/action splines from behavior logic and pair paths with explicit action/animation identities.

### BrickStorm translation

Use authored `TraversalPath` resources for special movement instead of asking the free movement motor to solve everything:

- ladders;
- ledge shimmies;
- squeeze-throughs;
- zip lines;
- carrying/placing equipment;
- tornado-safe handholds;
- probe deployment lanes;
- scripted vehicle entry/exit approaches.

This keeps toy animation readable and avoids slippery sandbox-style locomotion.

---

## 10. Destruction: profile-driven feedback

Reference destructible data ties an object to material/debris identity, particles, audio family, and authored interaction consequences.

### BrickStorm translation

Create a `DestructibleProfile` with:

- material family;
- durability / staged break thresholds;
- authored break clusters;
- debris palette;
- physical-fragment budget class;
- particle event family;
- audio event family;
- stud/drop table;
- tornado susceptibility;
- optional rebuild target;
- InteractionGraph outputs.

Large hero structures should remain authored staged events. Small scenery can use pooled generic fragments.

---

## 11. Story and Free Play are data, not duplicated levels

The reference graphs and section manifests contain explicit mode gating and alternate exits/routes. Character rosters and collectible dependencies are separated from the physical scene.

### BrickStorm translation

Treat Story and Free Play as policies over the same authored section:

- allowed character roles;
- alternate interaction nodes;
- secret routes;
- collectible gates;
- optional build/tool solutions;
- alternate section transitions.

Do not fork entire scenes merely to create Free Play.

---

## 12. Proposed BrickStorm implementation order

### P0: Feel multipliers

1. `AudioEvent` semantic audio layer.
2. `ActionAnimationProfile` and animation event markers.
3. `InteractionGraph` with typed states and ALL/ANY/LOOP conditions.
4. `BuildRecipe.steps[]` generalized from the protected storm-probe build rhythm.

These four systems directly attack the remaining gap between a competent prototype and authored classic brick-adventure texture.

### P1: Authored presentation

5. `CameraSocketProfile` / temporary camera request system.
6. `MusicStateDirector` with transition markers.
7. `DestructibleProfile` and pooled fragment classes.

### P2: Level scalability

8. `ChapterManifest` / `SectionManifest`.
9. Explicit `SectionBudget` caps.
10. Story/Free Play policy gates.

### P3: Character/world depth

11. Reusable companion/NPC FSM modules.
12. Authored traversal paths.
13. Expanded contextual role/tool families.

---

## 13. Direct adaptation to LEGO: Twister

The reference architecture becomes especially useful because tornado intensity can drive multiple existing semantic systems at once rather than being a separate weather minigame.

A single `StormPressure` state can influence:

- music-state request and transition urgency;
- ambient-wind AudioEvents;
- debris/destructible susceptibility;
- camera shake availability;
- NPC danger reactions;
- section fragment budgets;
- vehicle handling assists/pressure;
- authored InteractionGraph gates;
- horizon visibility and fog;
- Story consequences and Free Play opportunities.

The tornado therefore remains the moving villain and world-rearrangement system while the surrounding game still speaks classic brick-adventure grammar.

---

## 14. What must not be copied

Do not add extracted or reconstructed reference-game content to BrickStorm, including:

- meshes, textures, animation curves, skeletons, level geometry;
- audio samples or music;
- original scripts or binary resources;
- cutscene timing/content;
- proprietary character data;
- exact level layouts or puzzle solutions;
- decompiled/reconstructed source code.

Use independent Godot implementations based only on the behavioral and architectural observations in this document.

## Decision test

For each implementation derived from this research, ask both:

1. Does it improve authored classic brick-adventure feel?
2. Does it make **LEGO: Twister** more recognizable, tactile, funny, and replayable?

If the answer to the second question is no, the research has become a distraction rather than a guide.
