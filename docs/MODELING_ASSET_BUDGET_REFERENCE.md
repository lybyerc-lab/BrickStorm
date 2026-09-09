# BrickStorm Modeling and Asset-Budget Reference

## Purpose

This document turns clean-room observations from a user-supplied 2008 brick-adventure demo into independent modeling, import, and runtime guidance for **LEGO: Twister / BrickStorm**.

It does **not** contain or authorize use of extracted reference-game meshes, textures, geometry, collision, materials, scripts, animation, or other proprietary assets. Numeric observations below are aggregate structural measurements used only to understand architectural relationships. BrickStorm assets remain independently authored.

The most important result is not a historical polygon target. It is this separation:

**render budget != active gameplay budget != physics budget**

BrickStorm should budget those three systems independently and deliberately.

---

## 1. Verified section payload anatomy

Six playable reference sections were decomposed and their resource blobs accounted for into authored metadata, compressed texture payloads, vertex buffers, and 16-bit index data.

| Section | Total bytes | Metadata | Texture payload | Vertex buffers | Index buffer |
| --- | ---: | ---: | ---: | ---: | ---: |
| A | 35,421,896 | 1.57% | 80.87% | 16.29% | 1.27% |
| B | 32,241,872 | 0.88% | 87.99% | 10.32% | 0.81% |
| D | 33,068,740 | 2.18% | 71.86% | 24.34% | 1.62% |
| E | 21,364,806 | 1.97% | 69.98% | 26.31% | 1.74% |
| F | 23,814,220 | 1.36% | 67.95% | 28.85% | 1.85% |
| G | 23,750,264 | 0.83% | 85.93% | 12.14% | 1.10% |

Each section's metadata/resource boundaries and texture span cross-check exactly against the scene container's own pointers and declared resource sizes.

### Clean-room lesson

Historical section size is dominated by texture storage, while authored metadata remains very small. Geometry cost also varies dramatically between neighboring sections.

Do **not** create one generic `section_complexity` number. BrickStorm `SectionBudget` should track at least:

- visible/render geometry;
- texture residency;
- material/draw complexity;
- active interactables;
- dynamic physics bodies;
- tornado debris/fragments;
- NPCs and vehicles;
- particles;
- audio voices.

A section can be visually rich while gameplay simulation remains intentionally sparse.

---

## 2. The spectacle-section result

One sampled high-intensity section is especially informative.

Its gameplay-side configuration contains only about one major obstacle and a relatively small active interaction set, yet its scene payload still contains roughly 6.55 MiB of vertex data and a substantial texture payload.

### BrickStorm translation

During a tornado set piece, reduce **active simulation complexity** before reducing all visible world detail.

A convoy chase, drive-in impact, Wakita strike, or F5 corridor may therefore keep substantial authored environment geometry while deliberately lowering:

- unrelated smashable logic;
- NPC decision-making;
- concurrent build/tool interactions;
- independent physics bodies;
- background collectible simulation;
- nonessential particles.

The saved CPU/physics budget can then be spent on the tornado, hero destruction, vehicle response, debris, audio, and camera work.

This is a stronger rule than simply lowering polygon count whenever the storm becomes intense.

---

## 3. Texture structure and reuse

Across the six playable sections, 278 valid compressed texture instances were measured. Their historical formats are not targets for BrickStorm, but their usage pattern is useful:

- opaque-oriented compressed textures strongly dominate;
- alpha-capable textures are a minority;
- mipmapped textures are common;
- large textures are used selectively rather than universally;
- many textures recur across more than one section.

Content hashing found:

- 278 texture instances;
- 189 unique texture payloads;
- 89 duplicate instances;
- 56 texture hashes shared between sections;
- about 20.9% of the measured texture bytes were duplicate content across those section packages.

### BrickStorm translation

Prefer a deterministic shared asset library plus section-local dependency manifests.

Do not duplicate the same prairie, road, brick, utility, trim, vehicle-detail, or common-prop texture merely because it appears in another section.

Storage deduplication does **not** mean keeping every shared texture resident in memory. Section loading should still request only the resources needed by the current and prefetched sections.

### Starting mobile import tiers

These are BrickStorm starting points, not historical reference values:

- tiny/common gameplay prop: 256 to 512 maximum dimension where practical;
- modular environment family: 512 to 1024;
- hero prop/build/vehicle: 1024 by default;
- 2048: exception requiring visible benefit and phone profiling.

Use atlases or shared material families where they actually reduce state/material churn without creating huge always-resident sheets.

---

## 4. Material reuse is more important than material count

The six playable sections contain 851 material records in aggregate.

Of those:

- 696 reference a texture;
- 155 are untextured;
- the textured materials collectively use only 174 distinct texture-slot identities when counted per section.

That is roughly four textured material variants for each distinct texture slot.

### Clean-room lesson

Visual variety can come from **material parameter variation over shared texture families**, rather than unique texture sets for every surface.

### BrickStorm translation

Favor shared Godot material/resource families with controlled parameters such as:

- LEGO plastic color;
- roughness/specular response;
- tint;
- dirt/wear scalar where appropriate;
- emissive state for powered devices;
- damage state where shader variation is cheaper than a new texture set.

Do not create a separate image set for every LEGO color or every trivial prop variation.

For brick-built objects, color/material identity should be data whenever possible.

---

## 5. Bounds and render population are not gameplay-object counts

The six playable scene containers include 2,976 compact bounds records in aggregate:

- A: 598
- B: 347
- D: 945
- E: 505
- F: 316
- G: 265

These numbers are much larger than the known gameplay-interactable counts in the matching sections.

A bounds record should **not** be interpreted as one unique prop, but the disparity is architecturally useful.

### BrickStorm translation

Keep these categories separate:

1. **Render population**: visible meshes, modules, dressing, backdrop.
2. **Gameplay population**: smashables, builds, tools, secrets, pickups, triggers.
3. **Physics population**: currently simulated rigid bodies, fragments, vehicles, debris.

A telephone pole can exist visually without running interaction logic. A distant building can have no collision. A hero barn can render as a small number of intact assemblies until its destruction state promotes selected pieces into physics.

This separation is central to making Oklahoma feel populated without asking a phone to simulate the entire county.

---

## 6. Vertex storage favors tailored layouts

The sampled scene data does not appear to force every vertex to carry every possible attribute.

A recurring primary rigid-world layout is structurally verified at 28 bytes per vertex:

- 12 bytes of float position;
- two compact 4-byte attribute groups;
- 8 bytes of float UV data.

Other buffers use different record widths, indicating multiple tailored vertex layouts rather than one universal maximal format.

The exact semantics of every packed field are not required for BrickStorm and should not be copied.

### BrickStorm translation

Author only the vertex channels an asset actually needs:

- no tangents if the asset does not use normal mapping;
- no vertex colors unless they serve a real purpose;
- no UV2 unless the lighting/import path needs it;
- no skinning data on static environment or rigid build/destruction chunks;
- keep character/animated hero geometry on a separate cost path from ordinary rigid props.

Godot decides final GPU storage details, but Blender authoring and import choices determine whether unnecessary channels exist in the first place.

---

## 7. Do not derive modern mobile triangle caps from a 2008 PC game

The scene data contains explicit vertex and 16-bit index buffers, but exact draw boundaries and strip/list semantics have not yet been fully reconstructed for every level resource.

Raw index-buffer measurements are therefore **not** reliable exact triangle counts and must not be turned into fake precision.

More importantly, even perfect historical triangle counts would not establish the correct performance ceiling for BrickStorm on modern Android hardware.

### Correct validation path

1. Build representative independent BrickStorm assets using the rules in this document.
2. Assemble a representative Wakita block with environment modules, props, characters, vehicle, studs, and interactables.
3. Add a representative tornado hero event with the expected fragment/debris/particle/audio spike.
4. Run it on the user's acceptance phone.
5. Profile frame time, draw calls, material switches, texture residency, physics bodies, particles, and audio voices.
6. Lock actual per-tier budgets from that measurement.
7. Re-run the stress scene whenever the rendering or destruction architecture materially changes.

The phone benchmark sets the cap. Archaeology tells us how to organize the content so the cap is useful.

---

## 8. BrickStorm modeling classes

Every independently authored model should declare one primary asset class.

### `BACKDROP`

Use for distant Oklahoma scenery and horizon dressing.

- static;
- no runtime physics;
- collision absent unless absolutely needed;
- minimal vertex channels;
- aggressively shared materials/textures;
- LOD/impostor policy allowed.

### `MODULAR_WORLD`

Use for road sections, building shells, fences, utilities, terrain modules, storefront shells, farm architecture.

- reusable;
- static by default;
- simple authored collision where player contact is possible;
- shared material families;
- pieces sized for section reuse and culling.

### `GAMEPLAY_PROP`

Use for readable smashables, movable props, puzzle/tool targets, pickups, and interaction scenery.

- strong phone-scale silhouette;
- simple collision;
- one dominant gameplay-material identity where possible;
- explicit interaction anchor/socket if needed;
- promotes to physics only when its behavior requires it.

### `BUILD_COMPONENT`

Use for ordered pieces of a `BuildRecipe`.

- clean local origin;
- known final transform;
- readable assembly role;
- optional build-snap socket;
- no continuous rigid-body simulation merely because the part moves during the build animation.

### `DESTRUCTIBLE_HERO`

Use for barns, signs, hero walls, drive-in structures, utility structures, large story smashables.

Author as:

- intact presentation assembly;
- staged break clusters;
- a limited set of meaningful loose pieces;
- pooled generic debris/fragments;
- optional reusable/rebuild target.

The intact object should remain cheap until damage requires the expensive state.

### `VEHICLE_HERO`

Use for chaser vehicles and story vehicles.

- rigid body shell separated from cosmetic detail where useful;
- wheel/steering/contact anchors;
- bounded material-slot count;
- damage clusters authored separately from driving physics;
- tornado-force and collision response sockets/regions when required.

### `TOOL`

Use for wrench, pry bar, dig/cut/repair/scan/science tools.

- intentionally readable on a phone screen;
- clean grip/carry transform;
- explicit contact point;
- draw/use/stow presentation supported;
- silhouette may be slightly exaggerated when fidelity conflicts with readability.

### `CHARACTER`

Use for minifigure characters.

- dedicated rigged/animated cost path;
- shared base rig and common movement presentation where possible;
- role identity expressed through items, abilities, animation profiles, and contextual interactions rather than unnecessary skeleton variants.

---

## 9. Standard authored sockets and pivots

Models that interact with builds, tools, vehicles, destruction, carrying, or tornado forces should use predictable authored anchors instead of one-off script offsets.

Recommended names:

- `grab_socket`
- `hinge_socket`
- `fracture_socket`
- `carry_socket`
- `build_socket`
- `vehicle_mount`
- `tool_contact`

Additional domain-specific anchors are allowed, but these should cover common behaviors.

### Pivot rules

- doors/signs/panels: pivot at the physical hinge or attachment line;
- telephone poles: meaningful base/fracture origin;
- roof panels: attachment-edge pivot where staged peel-away is intended;
- build parts: local origin chosen for readable snap-in motion;
- tools: grip and contact positions authored separately;
- vehicle wheels: pivots centered and aligned for steering/spin;
- destructible clusters: local origin should support the intended break impulse.

Do not repair bad asset origins later with piles of per-instance magic offsets.

---

## 10. Gameplay material identity

Rendering material and gameplay material are related but should not be the same concept.

Recommended gameplay-material tags include only the families BrickStorm actually needs, for example:

- `LEGO_PLASTIC`
- `WOOD`
- `METAL`
- `GLASS`
- `ASPHALT`
- `DIRT`
- `GRASS`
- `FABRIC`

A gameplay-material tag can drive:

- footsteps;
- impacts;
- smash/break audio;
- debris family;
- particle response;
- tire/contact audio;
- tool-contact feedback;
- tornado susceptibility modifiers.

This prevents every gameplay script from reverse-engineering behavior from shader/material names.

---

## 11. Build modeling contract

Buildables should be modeled as ordered meaningful components, not merely a complete model that fades in.

Each `BuildRecipe` component should provide:

- stable part identifier;
- final transform;
- optional incoming/source transform policy;
- snap pivot/socket;
- collision policy before/during/after build;
- optional material/audio event override.

The completed build should then emit a semantic consequence into `InteractionGraph`.

Examples in BrickStorm include probe assemblies, generators, antennas, barricades, Dorothy racks, sensor equipment, and Free Play devices.

Preserve the successful storm-probe rhythm while generalizing the data model.

---

## 12. Destruction modeling contract

Do not simulate every LEGO element continuously.

For a hero structure, author logical break clusters such as:

`intact shell -> major panel/roof/wall clusters -> selected loose bricks -> pooled debris`

A barn, for example, may contain an intact core plus roof halves, wall clusters, doors, hero loose props, and a small brick-fragment palette.

`DestructibleProfile` determines when each cluster transitions and what fragment budget class it may consume.

### Tornado rule

The tornado may promote additional authored clusters into dynamic state, but promotion is budgeted. Off-camera or low-value debris should settle, sleep, recycle, or use cheaper visual treatment rather than remaining live rigid bodies indefinitely.

---

## 13. Modeling/import checklist

Before an asset is accepted:

- correct primary asset class assigned;
- readable silhouette at intended phone camera distance;
- transform/origin sane;
- required sockets/pivots present;
- unused vertex channels removed;
- texture size appropriate to asset tier;
- shared material/texture family used where practical;
- gameplay material tag assigned if relevant;
- collision authored separately and kept simple;
- build parts have final transforms;
- destructibles have authored break clusters rather than implicit per-brick simulation;
- no proprietary reference-game geometry, textures, materials, or reconstructed assets present.

---

## 14. Next empirical gate

The next useful number is **not** another historical archive metric. It is BrickStorm's own phone stress-test result.

Before mass-producing Wakita, convoy vehicles, Dorothy equipment, barns, and destruction props, create a representative stress scene and establish measured tiers for:

- visible triangles/vertices;
- draw calls/material switches;
- texture residency;
- active rigid bodies;
- sleeping/recycled debris;
- particles;
- active studs;
- NPCs;
- audio voices;
- frame-time headroom during a tornado spike.

Those measured limits become `SectionBudget` defaults and modeling-tier acceptance gates.

---

## Bottom line

The clean-room reference strongly supports a BrickStorm pipeline built around:

- modular reusable world art;
- shared texture/material families;
- small authored metadata;
- tailored rigid versus animated vertex needs;
- separate render, gameplay, and physics populations;
- ordered build components;
- staged destruction clusters;
- semantic sockets and gameplay-material tags;
- section-specific budgets;
- phone-derived final performance caps.

That architecture gives us room for the visual richness of Oklahoma and the explosive LEGO destruction of Twister without turning every visible brick, fence post, and roof shingle into a permanently simulated object.
