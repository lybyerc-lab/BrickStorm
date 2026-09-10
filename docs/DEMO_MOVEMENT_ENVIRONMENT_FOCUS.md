# Demo-Focused Movement and Environment Study

## Purpose

This note narrows BrickStorm clean-room archaeology to the two areas that now matter most before large-scale level production:

1. classic brick-adventure character movement/presentation;
2. environment architecture, especially the boundary between ordinary static world geometry and LEGO-active gameplay/destruction pieces.

The user-supplied 2008 demo is the primary reference source for this phase. BrickStorm must extract behavior, ratios, system separation, authoring patterns, and aggregate structural evidence only. Do not copy or reconstruct proprietary meshes, textures, animation curves, level layouts, scripts, audio, or other protected content.

---

## 1. Movement evidence already verified from the demo

The reference does not appear to achieve character feel through radically different locomotion physics per human character.

Across sampled human configurations, the dominant locomotion values cluster tightly around a common motor. Useful clean-room relationships include:

- run/walk ratio around 2.3:1;
- very fast acceleration to run speed;
- compact toy-weight jump arc;
- limited airborne duration;
- common turn/collision scale;
- character identity expressed more strongly through abilities, items, action presentation, and contextual animations than through different base motors.

The action/ability sidecars are much richer than the motor configs. Prior aggregate parsing found hundreds of explicit action declarations with metadata for:

- action identity;
- playback rate/FPS policy;
- cycle/loop behavior;
- blend behavior;
- head-turn enable/lock;
- frame/event markers;
- footstep markers;
- item stow/restore;
- tool draw/use/put-away;
- repair/dig/pickup/bash contact timing;
- movement-speed modifiers during specific actions.

### Current BrickStorm interpretation

Keep one authoritative movement motor. The remaining LEGO-character gap should be attacked in the presentation hierarchy, not by making the controller slippery or adding a second locomotion system.

The current target remains:

`root travel -> waist/pelvis lead -> torso follow/counter-rotation -> shoulder sway -> arm lag -> head settle`

The user specifically identified two reference-game qualities to pursue:

- more visible shoulder sway during travel;
- the impression that the character is being pulled forward from the waist.

Those observations are consistent with the demo evidence that locomotion mechanics are shared while authored action presentation carries much of the visible character identity.

### Next movement archaeology questions

Prioritize these before another major character rewrite:

1. Separate ordinary walk/run presentation metadata from tool-carry walk/run variants.
2. Measure how often locomotion/action families lock or release head turning.
3. Identify start, stop, pivot/reversal, landing, smash, pickup, repair, and carry action families and their event-marker structure.
4. Determine which timing relationships are stable across human roles and which are action-specific.
5. Distinguish motor-driven translation from authored traversal/path presentation where the data allows a clean inference.
6. Use authored traversal splines as evidence for when special movement should leave the free locomotion motor entirely.

Do not copy animation curves or keyframes. The output should be independent timing relationships and presentation rules that can be tuned by eye in BrickStorm.

---

## 2. Environment architecture evidence already verified

The six measured playable reference sections show a strong separation between visible world population and gameplay-active object population.

Verified aggregate scene evidence includes:

- 2,976 compact model/bounds entries across the six sections;
- 301 static display groups;
- 53 vertex buffers;
- 4,303 validated rendered mesh-part descriptors;
- 661,283 non-degenerate historical reference triangles across those parts;
- thousands of visible/render records versus far smaller authored interactable populations.

The important relationship is architectural, not the historical triangle total:

**many authored/placed pieces feed much coarser static render structures, while gameplay-significant objects remain separately addressable.**

The reference also separates other environment responsibilities into distinct sidecars/systems:

- collision/terrain proxy geometry;
- moving/platform-linked collision;
- special/gameplay objects;
- interaction-state interfaces;
- interaction graphs;
- destructible profiles and lightweight placed destructible instances;
- navigation/path data;
- camera-only resources;
- section-local SFX bindings;
- section-specific render/gameplay/spectacle budgets.

### Collision evidence

Collision complexity is independently authored and varies by section intent. The chase-like reference section F uses only 870 sampled collision faces, far below several neighboring exploration sections, despite retaining substantial visible geometry.

This supports a strict BrickStorm rule:

**render geometry is not collision geometry.**

### Destruction evidence

The demo separates reusable destruction definitions from placed destructible instances. Some sections use a small local profile library to drive many placed instances, with additional shared/global templates also implied.

This supports:

`DestructibleProfile -> lightweight instance -> optional StormResponseProfile`

rather than attaching one generic rigid-body explosion to everything.

### Spectacle evidence

Reference section F simultaneously reduces:

- interaction breadth;
- collision complexity;
- navigation breadth;
- NPC/AI population;
- pickup density;
- optional puzzle systems;

while retaining visible scene geometry, destruction, camera pressure, and forward motion.

For BrickStorm, a tornado spectacle should therefore become more controlled underneath as it looks more chaotic on screen.

---

## 3. Relationship to the BrickStorm building rule

The user's preferred BrickStorm visual grammar is:

**permanent world shell + LEGO attachment layer**

with ordinary wall mass generally non-LEGO, while roofs, windows, doors, signs, trim, selected porch/utility pieces, interactables, and hero destruction pieces may be LEGO-built and independently stateful.

The demo does **not** prove a literal historical rule that walls were non-LEGO while roofs/windows/doors were LEGO. Do not claim that.

What the demo strongly supports is the underlying system separation needed to make the BrickStorm rule work:

- static world geometry can be coarse and cheap at runtime;
- collision can be separate from rendering;
- special/gameplay objects can retain independent identity;
- destructible behavior can be profile-driven;
- hero objects can transition from intact presentation to bounded dynamic pieces;
- static scenery can remain visually rich while gameplay/physics populations stay controlled.

So the hybrid building strategy is an independent LEGO: Twister art decision that fits the reference architecture unusually well.

---

## 4. Environment questions to mine next from the demo

Before mass-producing Wakita buildings, prioritize evidence for:

1. how static display groups partition spatially and by material;
2. how special objects are associated with bounds, transforms, LOD, and collision IDs;
3. which ordinary architecture-adjacent object families remain independently addressable in section sidecars;
4. how doors, moving panels, bridges, gates, hatches, planks, platforms, and other detachable/moving environment pieces are represented relative to static world geometry;
5. how destructible profiles bind to special objects and what instance data remains lightweight;
6. how camera sockets and interaction graphs refer to environment objects without embedding render geometry;
7. how section budgets shift when a set piece becomes destruction-heavy;
8. how common environment themes/materials are shared across neighboring sections.

The goal is not to reconstruct Lost Temple. The goal is to derive a clean BrickStorm building/level authoring contract that can scale across farms, county roads, Wakita, motels, drive-in structures, utilities, and the F5 finale.

---

## 5. Implementation hold points

Until this focused pass produces stronger evidence:

- do not replace the accepted BrickStorm on-foot motor;
- do not make the character smoother by introducing glide or unrestricted limb deformation;
- do not mass-produce final Wakita building assets;
- do not build giant monolithic environment meshes;
- do not make every LEGO attachment a permanently active rigid body;
- do not turn historical PC triangle counts into modern Android production caps.

Allowed now:

- tune waist-led presentation and shoulder sway on top of the accepted motor;
- prototype one hybrid building shell/attachment system;
- continue static-cluster and SectionBudget tooling;
- derive reusable environment sockets, collision proxies, destruction profiles, and attachment contracts from clean-room observations;
- use the sealed 0.3.7 package as the regression baseline while this evidence pass continues.

---

## 6. Decision rule

For the next development cycle, ask:

> What does the demo tell us about how classic brick-adventure games separate movement mechanics from character presentation, and permanent scenery from LEGO-active world state?

If a new dig does not materially sharpen one of those two answers, it is lower priority for now.
