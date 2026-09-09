# BrickStorm Static Render Cluster Strategy

## Purpose

This note preserves a materially useful clean-room refinement discovered during parallel analysis of the user-supplied 2008 brick-adventure demo and translates it into an independent BrickStorm / LEGO: Twister runtime strategy.

No proprietary meshes, textures, geometry, scripts, or other reference-game assets belong in BrickStorm. The useful result is architectural.

## Executive rule

**Author modularly. Ship compatible static scenery in runtime clusters. Keep LEGO-active identity separate.**

BrickStorm should use a two-level scene model:

1. Small reusable authoring modules for flexible world construction.
2. Coarser runtime render clusters for ordinary noninteractive static scenery.

This bridges Blender-friendly modular construction with mobile-friendly draw/submission behavior.

---

## Reference observation

A parallel clean-room pass over the six measured playable sections reported:

- 2,976 model entries;
- 301 static display groups;
- 53 vertex buffers.

The important relationship is the order-of-magnitude reduction from authored/model entries to static display groups and the still smaller number of large geometry streams.

These counts should be re-checked against BrickStorm's local archaeology tooling before being treated as historical ground truth for tests or thresholds. The architectural pattern is nevertheless consistent with the already-verified GSC evidence: many authored pieces feed relatively few geometry streams/display structures, while gameplay-significant objects remain separately addressable.

## Clean-room inference

The source world appears compatible with a workflow where many small reusable source pieces are authored and placed independently, while ordinary static scenery is submitted in coarser render groups.

The right BrickStorm translation is **not** to model giant monolithic buildings or roads in Blender.

Instead:

- model small reusable pieces;
- assemble sections from those pieces;
- bake or cluster compatible static, noninteractive pieces at section build/import time;
- preserve logical source identity in editor/development metadata when useful;
- keep gameplay-significant pieces as independent runtime entities.

---

## `StaticRenderCluster`

BrickStorm should introduce a concept similar to `StaticRenderCluster` for section-local runtime scenery batching.

A cluster is a generated runtime presentation asset, not the primary authored source asset.

A candidate cluster may combine compatible instances when all of the following are true:

- static for the lifetime of the loaded section or cluster state;
- no independent gameplay state;
- no independent destruction state;
- no independent tornado-lift state;
- no tool/build/rebuild interaction;
- no independent camera beat or reveal ownership;
- no independent audio state that requires object identity;
- compatible material/render pipeline;
- spatially close enough that culling the cluster as one unit is reasonable.

Examples of good candidates:

- ordinary fence runs;
- wall and storefront shell modules;
- static road-edge pieces;
- noninteractive trim;
- background utility hardware;
- prairie dressing;
- static roof or facade details that never detach;
- noninteractive repeated set dressing.

---

## Never cluster away LEGO-active identity

The following remain individually addressable runtime objects unless a specific implementation proves otherwise:

- smashables;
- rebuildables;
- `BuildRecipe` components that need independent animation/state;
- vehicles;
- tools;
- pickups when independently collectible;
- tornado-liftable props;
- hero destruction clusters;
- Free Play reveals and gated secrets;
- puzzle/interactable devices;
- objects with independent camera beats;
- objects with independent semantic audio state;
- objects with story/InteractionGraph state;
- anything whose individual visibility or transform changes during gameplay.

Practical rule:

> **Model small, render static scenery in sensible batches, keep meaningful LEGO-active pieces individually alive.**

---

## Clustering is not the same as instancing

BrickStorm now has three complementary tools for repeated/static world art:

### 1. Modular authored scene

Best for level design and reuse.

Examples: road modules, storefront shells, fences, prairie props, utility poles.

### 2. Instancing / `MultiMesh`

Best for many copies of identical low-state geometry.

Examples: identical fence posts, vegetation clumps, repeated background debris, identical small trim pieces.

### 3. `StaticRenderCluster`

Best for spatially local, noninteractive scenery that may consist of different source modules but can be baked into a coarser runtime draw asset.

These strategies can coexist. A section build step may select among them based on material compatibility, spatial locality, reuse count, and gameplay identity.

---

## Spatial clustering rule

Do not merge an entire streamed section into one mega-mesh simply to minimize draw calls.

Clusters need spatial bounds small enough for useful culling.

Good clustering units will usually align with authored visibility/camera zones such as:

- one side of a road stretch;
- one storefront facade group;
- one farmyard pocket;
- one prairie dressing cell;
- one background building shell region.

The optimal cluster size is determined by phone profiling. Too small creates excessive submission overhead. Too large destroys culling efficiency and may keep unnecessary textures/geometry visible or resident.

---

## Material policy

Static clustering should prefer compatible shared material families rather than creating unique baked materials for every cluster.

Goals:

- reduce draw/material churn;
- preserve reuse of common BrickStorm material resources;
- avoid giant always-resident atlases;
- keep texture residency tied to current/prefetched section needs.

A cluster-generation step may partition neighboring source modules into separate clusters when material families or transparency/render states make combining them counterproductive.

---

## Collision policy

Render clustering does not require collision clustering.

Keep collision on the cheapest representation suitable for gameplay:

- no collision for unreachable backdrop;
- simple section-static collision for ordinary walkable world;
- separate simple collision primitives for gameplay props;
- independent dynamic collision for vehicles/destructibles only when active.

A baked render cluster should never force BrickStorm to use expensive render geometry as collision geometry.

---

## Destruction handoff

Hero destruction should use an intact-to-active handoff:

1. Intact presentation may include or coexist with cheap static rendering.
2. When the destruction event begins, the affected hero object/cluster region is hidden or swapped.
3. Authored break clusters and pooled fragments become active.
4. Settled/off-camera low-value debris sleeps, recycles, or collapses back to cheap presentation where appropriate.

Do not permanently simulate pieces merely because they may become destructible later.

---

## `SectionBudget` additions

In addition to existing geometry, texture, gameplay, and physics limits, `SectionBudget` should track or expose diagnostics for:

- authored static module count;
- generated static-cluster count;
- visible static-cluster count;
- cluster draw/surface count;
- material-family count;
- visible material-family count;
- texture residency estimate/measurement;
- independent LEGO-active object count;
- active dynamic physics bodies;
- debris/fragment pool usage;
- draw calls / render submissions where available;
- frame-time impact during the phone stress test.

These are not all hard caps initially. Some begin as profiler telemetry until representative scenes establish sensible thresholds.

---

## Suggested build/import pipeline

A future BrickStorm section-build tool can perform roughly this sequence:

1. Load the authored modular section.
2. Classify every object by asset/gameplay role.
3. Exclude all LEGO-active or independently stateful objects from static clustering.
4. Partition remaining static scenery by spatial cell/visibility region.
5. Partition again by compatible render/material state.
6. Select instancing for heavily repeated identical modules where useful.
7. Bake remaining compatible static modules into `StaticRenderCluster` resources.
8. Generate cluster bounds and development provenance back to source modules.
9. Preserve separate simple collision data.
10. Record resulting cluster/material/texture metrics into section diagnostics.
11. Validate the generated section against `SectionBudget` and the phone stress benchmark.

The source Blender/Godot scene remains modular and editable. Generated runtime clusters are disposable build artifacts that can be regenerated when source art changes.

---

## Application to LEGO: Twister

This strategy is especially useful for Twister because the world needs to look busy while only selected objects need to become physically or mechanically alive.

### Wakita

Static cluster candidates:

- ordinary storefront shells;
- curb/sidewalk/road dressing;
- noninteractive facade trim;
- distant roofs and building backs;
- ordinary fence/utility dressing.

Keep independent:

- hero signs;
- smashable storefront props;
- tornado-liftable objects;
- destructible walls/roof sections;
- Free Play secrets;
- vehicles;
- story devices and NPC interaction props.

### Farms and prairie

Static cluster candidates:

- ordinary fence runs;
- distant barns/sheds that are not gameplay objects;
- ground dressing;
- repeated field-edge scenery.

Keep independent:

- probe equipment;
- buildable generators/sensors;
- hero barns;
- utility poles scheduled to fail or lift;
- player-readable tools and smashables.

### Tornado spectacle

The storm can leave static clusters visually present while promoting only selected authored objects into expensive gameplay/physics states.

This reinforces the existing rule:

**visual richness, gameplay complexity, and physics complexity are separate budgets.**

---

## Phone benchmark questions

When the representative Wakita + tornado stress scene exists, test several clustering granularities and measure:

- total draw calls/submissions;
- visible cluster count;
- CPU render-thread time;
- GPU frame time;
- culling effectiveness;
- texture residency;
- memory overhead;
- cluster regeneration/build cost outside runtime;
- tornado spike headroom;
- any visual/state bugs caused by over-clustering.

Then set BrickStorm's actual cluster-size and count guidance from measured Godot/Android behavior rather than historical assumptions.

---

## Decision rule

Before clustering a source object, ask:

> Can this object lose its individual runtime identity without the player, gameplay systems, tornado, camera, audio, destruction, Story mode, or Free Play ever needing to know?

If yes, it is a static-cluster candidate.

If no, keep it independently alive.
