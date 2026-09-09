# Lost Temple Clean-Room Archaeology

## Purpose and boundary

This document records aggregate technical observations from static analysis of a user-supplied 2008 LEGO adventure-game demo. It exists to inform independent BrickStorm engineering.

Nothing in this document is intended to reproduce proprietary game content. Do not import or redistribute extracted meshes, textures, animation curves, scripts, audio, music, cutscenes, level geometry, puzzle solutions, or other copyrighted assets. Only system architecture, aggregate counts, timing relationships, state-machine patterns, and clean-room implementation lessons are retained.

`docs/CLASSIC_TT_CLEANROOM_REFERENCE.md` contains the higher-level BrickStorm translation. This file is the evidence ledger behind that reference.

---

## 1. Archive and level partitioning

The Lost Temple scene archive resolves to 14 named scene bundles:

- one master scene bundle;
- six gameplay section bundles: A, B, D, E, F, G;
- three small camera companion bundles for D, E, G;
- one intro scene;
- three outro variants.

The separate game-data archive contains 5,145 files overall and 160 Lost Temple sidecar/config resources. The Lost Temple sidecars span terrain, collision, route/path, interaction, camera, AI, effects, animation, and text/config families.

The important architectural conclusion is that a chapter is not treated as one monolithic world. It is authored as a sequence of compact streamed sections with independent scene content and independent behavioral sidecars.

### BrickStorm implication

Use:

`Story / Film -> Chapter -> Streamed Section`

A chapter manifest should own route order and mode policy. A section manifest should own local world content, camera data, behavior, interactables, performance budgets, and transition points.

---

## 2. Measured gameplay-section complexity

Approximate decoded scene profiles:

| Section | Scene size | Materials | Textures | Texture payload | Vertex buffers | Vertex payload | Index payload | Model entries | Static display groups | Special objects | Splines |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| A | 33.78 MiB | 158 | 61 nonzero | 27.32 MiB | 14 | 5.50 MiB | 0.43 MiB | 598 | 46 | 191 | 11 |
| B | 30.75 MiB | 105 | 52 nonzero | 27.06 MiB | 9 | 3.17 MiB | 0.25 MiB | 347 | 29 | 56 | 15 |
| D | 31.54 MiB | 216 | 42 nonzero | 22.66 MiB | 10 | 7.68 MiB | 0.51 MiB | 945 | 88 | 227 | 37 |
| E | 20.38 MiB | 141 | 29 | 14.26 MiB | 7 | 5.36 MiB | 0.35 MiB | 505 | 54 | 76 | 10 |
| F | 22.71 MiB | 150 | 39 | 15.43 MiB | 5 | 6.55 MiB | 0.42 MiB | 316 | 73 | 50 | 6 |
| G | 22.65 MiB | 81 | 56 nonzero | 19.46 MiB | 8 | 2.75 MiB | 0.25 MiB | 265 | 11 | 28 | 8 |

### Key observations

1. Texture payload dominates many section files.
2. Geometry is packed into a relatively small number of large vertex/index streams rather than thousands of independent render assets.
3. Section complexity varies dramatically according to the authored beat.
4. Interaction density, special-object density, and camera/path density are independent axes. A section can be geometry-heavy but interaction-light, or vice versa.

### BrickStorm implication

Mobile budgeting must include texture memory and render-state complexity, not just physics fragments. Section budgets should explicitly cap:

- resident texture memory;
- unique materials;
- active render groups;
- physical fragments;
- active studs;
- interactive objects;
- NPCs;
- vehicles;
- storm debris;
- important audio voices;
- camera requests.

---

## 3. Camera content is deliberately separable

Three sections use tiny dedicated camera companion bundles:

| Camera bundle | Approx. size | Splines | Materials | Textures | Models | Special objects |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| D camera | 10.1 KiB | 30 | 0 | 0 | 0 | 0 |
| E camera | 9.7 KiB | 15 | 0 | 0 | 0 | 0 |
| G camera | 7.8 KiB | 8 | 0 | 0 | 0 | 0 |

These bundles are almost pure authored camera/path metadata.

Camera profile text includes parameters for blend time, position seek, target/look ratios, offsets, pullback or target distance, rail offsets, and shake.

Overlap between gameplay and camera splines varies by section. Some camera sockets are shared with gameplay scene metadata, while transition/door routes remain gameplay-only.

### BrickStorm implication

Keep presentation authoring lightweight and independent from heavyweight world scenes.

Recommended resources:

- `CameraSocketProfile`
- `CameraRailProfile`
- `CameraBeat`

A camera beat should reference anchors/splines and presentation settings, not duplicate scene geometry.

---

## 4. Section F is a useful chase/set-piece profile

Section F differs strongly from the ordinary exploration sections.

Measured/configured traits:

- far clip approximately 35 versus roughly 800 in the neighboring ordinary sections;
- only six scene splines;
- one obstacle instance;
- 24 serialized destructible/blow-up instances;
- 37 placed pickups;
- no buildables;
- no local FlowBox interaction graph;
- one small AI script with three states;
- one camera profile emphasizing rail offset and shake;
- companion behavior increases run speed modestly and routes toward a named endpoint;
- placed pickups are much farther apart in authoring order than in ordinary exploration sections.

This is a textbook example of **spending complexity where the beat needs it**. Optional puzzle density is stripped away while destruction, route readability, camera pressure, and forward motion remain.

### BrickStorm implication

Tornado chase sections should have a deliberate spectacle mode:

- shorten effective horizon complexity;
- reduce unrelated NPCs and optional interactables;
- suspend low-value background logic;
- preserve only highly readable pickups and route cues;
- prioritize destruction, debris, vehicle/character motion, camera, and storm audio;
- use authored route splines and companion anchors where appropriate;
- increase pickup spacing as traversal speed increases.

This should be an explicit `SectionBudget` / `SpectacleBudgetProfile`, not accidental optimization after performance problems appear.

---

## 5. Serialized interaction-object density

Representative gameplay sections contain the following serialized interactable families.

### Section A

- 43 obstacles
- 2 buildables
- 66 destructibles
- 5 dig targets
- 98 pickups
- 3 grapple points
- 1 mini-cut
- 2 zip/swing paths
- 4 turrets
- 2 plugs

### Section B

- 10 obstacles
- 2 buildables
- 21 destructibles
- 99 pickups
- 2 grapple points
- 2 levers
- 1 mini-cut

### Section D

- 70 obstacles
- 1 buildable
- 21 destructibles
- 85 pickups
- 3 grapple points
- 23 ledges
- 2 technical-role devices
- 4 mini-cuts
- 2 zip/swing paths
- 1 whip-role interaction
- 12 turrets
- 2 plugs

### Section E

- 107 obstacles
- 2 destructibles
- 103 pickups
- 4 grapple points
- 3 ledges
- 1 lever
- 2 security-role doors
- 4 mini-cuts
- 1 zip/swing path
- 1 puzzle

### Section F

- 1 obstacle
- 24 destructibles
- 37 pickups

### Section G

- 9 obstacles
- 1 buildable
- 40 destructibles
- 1 dig target
- 110 pickups
- 1 mini-cut
- 2 plugs

Some human-readable section budget/config comments differ slightly from serialized instance counts. The serialized runtime data should therefore be considered the stronger authority when validating content budgets.

### BrickStorm implication

Build tooling that derives/validates section counts from the actual packed scene/resources. Do not trust hand-maintained budget comments alone.

A release gate should compare authored/declared limits with serialized scene counts and warn when they drift.

---

## 6. Interaction graphs are separate from interactable definitions

Five gameplay sections contain explicit text interaction graphs.

Aggregate graph observations:

- 414 FlowBox nodes;
- 58 collapse/grouping nodes;
- 288 FlowBoxes reference typed interactables;
- 373 FlowBox child edges;
- 68 typed condition nodes;
- condition families include `Any`, `All`, and `Loop`;
- common graph flags include start-hidden, finished-hidden, finished-deactivated, reverse, output-only, and mode gating.

Common action families include:

- activate interactable;
- set interactable visibility;
- set generic visibility;
- enable a camera/socket;
- play/stop a short cut;
- trigger an effect;
- play an obstacle action;
- activate a character;
- update a counter;
- transition to another level/section.

Typed FlowBoxes reference obstacles, destructibles, timers, turrets, dig targets, grapples, buildables, puzzles, pickups, levers, push blocks, plugs, technical-role devices, messages, and other small interaction classes.

### BrickStorm implication

The correct abstraction is not one bespoke script per puzzle. Use:

- `InteractionNode`
- `ConditionNode`
- `InteractionEdge`
- `InteractionGraph`

Scene objects expose stable semantic state queries. The graph owns authored consequence routing.

This is ideal for LEGO: Twister chains such as:

`smash blockage -> recover part -> repair probe -> camera reveal -> storm pressure rises -> route opens`

---

## 7. Buildables are explicit ordered recipes

Serialized buildables contain ordered sub-parts rather than merely a complete/incomplete toggle.

Observed nontrivial recipe lengths include:

- 8 pieces;
- 12 pieces;
- 14 pieces;
- 15 pieces;
- 30 pieces.

Completed builds frequently feed another interaction state or world consequence.

### BrickStorm implication

Generalize the successful storm-probe sequence into `BuildRecipe`:

- ordered build steps;
- per-step snap marker;
- optional part animation;
- build-loop feedback;
- completion feedback;
- completion output into `InteractionGraph`.

Recipe length should scale with the narrative importance of the build. A tiny roadside repair may be 4-8 steps; a hero Dorothy/probe assembly can be significantly longer while still remaining readable on mobile.

---

## 8. Pickup economy is mixed, not trail-only

Placed gameplay-section pickups:

| Section | Silver | Gold | Blue | Minikits | Placed stud face value |
| --- | ---: | ---: | ---: | ---: | ---: |
| A | 40 | 43 | 13 | 2 | 17,700 |
| B | 48 | 42 | 7 | 2 | 11,680 |
| D | 41 | 34 | 8 | 2 | 11,810 |
| E | 46 | 43 | 13 | 1 | 17,760 |
| F | 12 | 21 | 3 | 1 | 5,220 |
| G | 42 | 63 | 3 | 2 | 9,720 |

Totals across the six gameplay sections:

- 229 silver;
- 246 gold;
- 47 blue;
- 10 minikit-style collectibles;
- no placed purple studs in these section pickup lists.

The chapter Story stud target is higher than the value of placed studs alone. Therefore destructibles, enemies, builds, and other gameplay must contribute meaningfully to the stud economy.

Authoring-order spacing also expands dramatically in the chase-like F section compared with ordinary exploration sections, consistent with faster traversal requiring wider, cleaner pickup cues.

### BrickStorm implication

Do not make stud economy depend primarily on pre-placed trails.

Use multiple sources:

- authored route guidance;
- smashing/destruction;
- successful builds/repairs;
- enemy/hazard interactions;
- secrets;
- storm-risk rewards;
- vehicle/object stunts.

Preserve BrickStorm's fixed values:

- silver 10;
- gold 100;
- blue 1,000;
- purple 10,000.

Spacing should be authored against expected movement speed, especially in vehicle/tornado pursuit sections.

---

## 9. AI is mostly small finite-state machines plus shared references

Across the Lost Temple AI sidecars:

- 18 scripts;
- 82 explicit states;
- 7 shared/reference-script uses.

Common high-level actions include:

- set controller;
- activate;
- go to locator;
- follow player;
- set state;
- add script processor;
- avoid or ignore another character;
- kill/despawn.

Common conditions include:

- taken over / player controlled;
- Free Play state;
- identity checks;
- reachability;
- obstacle state;
- trigger-area membership;
- locator range;
- opponent availability;
- spawn state;
- offscreen timer.

Level-local scripts frequently delegate generic behavior to a shared reference and only add the section-specific overlay.

### BrickStorm implication

Use reusable behavior modules and thin section overlays.

Recommended companion modes:

- FOLLOW_PLAYER
- HELP_INTERACTION
- HELP_BUILD
- ENTER_VEHICLE
- EXIT_VEHICLE
- DANGER_REACT
- STORY_POSITION

Section scripts should mostly select targets, locators, triggers, and exceptions rather than reimplementing navigation/follow/combat behavior.

---

## 10. Movement appears shared; action presentation carries identity

Multiple human character configurations use closely clustered core locomotion values. The stronger differences appear in abilities, carried items, animation actions, and contextual behavior.

Shared ability definitions contain hundreds of explicit action records with event-frame metadata. Common action metadata includes:

- action identity;
- playback rate;
- frame/event markers;
- cycle/loop control;
- head-turn lock;
- item stow/restore rules;
- movement-speed modifiers;
- blend behavior;
- footstep markers.

Repair, digging, pickup, bash, and tool lifecycle actions all expose explicit timing markers.

### BrickStorm implication

Do not fragment the protected player motor into one controller per character.

Use one authoritative locomotion core plus `ActionAnimationProfile` resources with semantic event markers. The event markers can trigger:

- footsteps;
- impact sounds;
- tool contact;
- item attach/detach;
- build snaps;
- dust/brick particles;
- camera impulses;
- gameplay contact windows.

---

## 11. Tools are capability-driven items with a full lifecycle

The reference item-type data separates an item's visual/carry setup from semantic capabilities.

Common item configuration concepts include:

- held socket/locator;
- stow socket/locator;
- offsets, rotation, and scale;
- capability tags;
- pickup visibility/glow;
- take-out and put-away actions;
- idle, walk, run, bash, throw, or use actions;
- semantic pickup/use/put-away audio events.

Representative capability families include repair/mechanic, dig, crank, torch/fire, bash/combo, carry/throw, paddle, and plug/device interaction.

### BrickStorm implication

Create a `ToolDefinition` resource with:

- visible model;
- carry/stow sockets;
- capability tags;
- contextual ACTION bindings;
- action-animation profiles;
- semantic audio events;
- optional durability/use policy;
- readability rules while available, carried, and usable.

This directly addresses the 0.3.3 weakness where the tool was mechanically functional but not sufficiently readable before pickup or during carry.

---

## 12. Destruction data is authored, not generic rubble-only

Serialized destructible records reference special objects plus effect/particle families and stud-related values. Scene special objects also carry bounds, LOD information, and two wind-response fields.

The Lost Temple sample leaves its per-object wind fields at zero, so this level does not prove active wind simulation. It does prove that environmental-response properties belong naturally at the object/profile level rather than only in one global weather controller.

### BrickStorm implication

Use:

`DestructibleProfile + StormResponseProfile`

Possible storm-response fields:

- wind susceptibility;
- shear susceptibility;
- lift threshold;
- detach threshold;
- tumble class;
- debris budget class;
- anchored/breakaway state;
- storm-only failure animation;
- safe reassembly/rebuild policy.

Hero structures should use authored staged destruction. Generic scenery should remain pooled and budget-aware.

---

## 13. Music transitions are authored state changes

Music data contains quiet/action state identities plus legal transition markers within tracks.

Action-oriented states frequently offer more closely spaced transition opportunities than calm states. Some intense states provide legal transition points only a few seconds apart.

### BrickStorm implication

`MusicStateDirector` should request states, then execute the transition at an authored legal marker unless an emergency override is needed.

For LEGO: Twister, storm pressure can both select state and influence transition urgency:

- CALM
- WATCH
- BUILDING_STORM
- CHASE
- TORNADO_CRISIS
- AFTERMATH

---

## 14. Free Play is a route/policy overlay

The chapter configuration explicitly distinguishes Story and Free Play route destinations and target values. Interaction-graph flags also contain mode-dependent behavior.

### BrickStorm implication

Do not fork whole scenes for Free Play.

The same section should accept a mode policy that changes:

- character/role access;
- alternate interaction nodes;
- collectible routes;
- secret entrances;
- optional tool/build solutions;
- section transitions;
- reward targets.

---

## 15. Proposed BrickStorm architecture additions from this pass

### Immediate

1. `ActionAnimationProfile`
2. `ToolDefinition`
3. `AudioEvent`
4. `InteractionGraph`
5. `BuildRecipe`

### Presentation

6. `CameraSocketProfile`
7. `CameraRailProfile`
8. `CameraBeat`
9. `MusicStateDirector`

### World / tornado

10. `DestructibleProfile`
11. `StormResponseProfile`
12. `SectionBudget`
13. `SpectacleBudgetProfile`

### Content authoring

14. `ChapterManifest`
15. `SectionManifest`
16. shared `NPCBehaviorProfile` + section overlay
17. `TraversalPath`
18. Story/Free Play `ModePolicy`

### Tooling / regression protection

19. serialized section-budget validator
20. texture-memory validator
21. interaction-graph validation
22. build-recipe validation
23. action-event marker validation

---

## 16. Most important lesson for LEGO: Twister

The strongest pattern in this study is not a specific mechanic. It is **selective authored complexity**.

The reference game uses reusable systems, but it does not ask every system to run at maximum density in every section. A puzzle-heavy exploration section, a traversal section, and a fast chase section carry different content mixes and different visual budgets.

For BrickStorm, that means the tornado should be allowed to reallocate the game budget dynamically and by authored section:

- quiet farm: exploration, tools, builds, secrets, NPC texture;
- convoy: vehicles, route cues, debris, roadside destruction;
- drive-in: large staged destruction, crowd reactions, spectacle camera;
- Wakita: dense interactables, rescue/build chains, environmental storytelling;
- F5 finale: sharply reduced unrelated complexity, maximal storm/debris/destruction/audio budget.

That is the path to something that feels chaotic without actually being uncontrolled.
