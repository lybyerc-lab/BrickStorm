# BrickStorm Level Building Construction Strategy

## Purpose

This document defines the building-art grammar to use as BrickStorm moves from isolated prototype encounters into authored levels such as farms, county roads, Wakita, motels, drive-in locations, and storm-damaged town blocks.

The core visual rule is:

**Permanent world shell, LEGO attachment layer.**

BrickStorm buildings should look like believable stylized Oklahoma architecture first, with clearly readable LEGO-built elements layered onto the structure where the player, tools, destruction, and tornado systems can act on them.

This supports the early brick-adventure visual language without turning every wall in the world into permanently simulated bricks.

---

## 1. Permanent shell

The main structural wall mass of an ordinary building should usually be authored as non-LEGO world geometry.

Typical shell content:

- foundations and slab mass;
- exterior wall planes and primary wall thickness;
- brick, plaster, siding, concrete, masonry, or painted-wall surfaces;
- large structural columns or major framing that is not intended to detach;
- interior wall mass where the player can enter;
- unreachable rear/side structure and background architecture.

The shell may use stylized materials and simplified geometry, but it should not visually read as a giant pile of LEGO bricks.

The shell remains inexpensive static environment geometry whenever possible and may participate in StaticRenderCluster generation when it has no independent gameplay state.

### Destruction rule

Ordinary tornado damage should not require the permanent wall shell to explode into hundreds of pieces.

The shell may receive:

- cracks;
- dust;
- decals or damage-state material changes;
- exposed attachment sockets;
- limited authored hero fractures;
- optional replacement damaged-shell meshes for major story beats.

Whole-wall destruction is reserved for authored hero events where it earns its physics and presentation budget.

---

## 2. LEGO attachment layer

The following building elements should normally be brick-built and independently authored:

- roofs and roof sections;
- windows and window frames;
- doors and door frames;
- shutters;
- signs and awnings;
- gutters/downspouts where visible and useful;
- vents and roof equipment;
- porch rails and selected porch pieces;
- decorative trim that benefits from LEGO readability;
- interactable fixtures;
- story/puzzle devices;
- Free Play reveals;
- selected chimney caps or roof-mounted details;
- hero destruction pieces.

This LEGO layer is where BrickStorm concentrates interaction, readable smashability, repair/build logic, studs, and tornado response.

A player looking at a building should be able to read which parts belong to the ordinary world and which parts belong to the LEGO gameplay language without needing an outline shader or icon over every object.

---

## 3. Roofs are authored destruction systems

Roofs should not be one giant rigid LEGO object and should not begin as hundreds of live bricks.

Author them in staged assemblies, for example:

`RoofIntact -> RoofHalfLeft / RoofHalfRight -> RoofPanelClusters -> selected loose LEGO pieces -> pooled debris`

Recommended roof structure:

- one or a few cheap intact presentation assemblies;
- spatially meaningful tear-off sections;
- authored edge/fracture sockets;
- selected loose shingles/plates/tiles where readable;
- pooled small debris for the final visual burst.

Tornado forces can promote roof clusters from static/presentation state into dynamic state according to the section fragment budget.

This should make a roof peel, lift, twist, and break apart progressively rather than simply vanish or detonate.

---

## 4. Windows and doors

Windows and doors should be LEGO-first gameplay modules fitted into non-LEGO wall openings.

### Windows

A window module may contain:

- brick-built frame;
- translucent LEGO-style pane;
- optional shutters;
- detach/fracture socket;
- optional stud/drop response;
- alternate damaged/open state.

Avoid realistic glass-shard simulation. The destruction language should remain toy-like and readable.

### Doors

A door module should provide:

- real authored hinge pivot;
- frame/socket alignment;
- normal open/close behavior when required;
- tornado-detach/fracture state where appropriate;
- tool, story, or Free Play interaction hooks where needed.

A door can therefore swing normally during ordinary play, then become a detachable LEGO object during a storm event without changing the permanent wall shell.

---

## 5. Building classes

### Background building

Purpose: visual world population.

- permanent shell dominates;
- LEGO roof/windows/doors may be visually simplified;
- little or no independent gameplay state;
- may use static clustering aggressively;
- tornado response may be presentation-only or limited to one authored attachment cluster.

### Gameplay building

Purpose: exploration, studs, tools, builds, secrets, or ordinary destruction.

- permanent wall shell;
- fully readable LEGO roof/windows/doors and interaction layer;
- selected independent attachment pieces;
- simple enterable or collision-aware shell where necessary;
- modest tornado/destruction budget.

### Hero building

Purpose: Wakita impact, drive-in destruction, major farmhouse/barn story beat, or other cinematic storm event.

- permanent shell may have authored damaged replacement states;
- roof broken into meaningful staged assemblies;
- windows/doors/signage independently destructible;
- selected wall fracture zones allowed;
- dedicated camera/audio/destruction timing;
- larger but still bounded fragment budget;
- tornado system can promote multiple LEGO attachment clusters during the event.

Even hero buildings should not make every visible brick a live rigid body.

---

## 6. Authoring sockets

A hybrid building should use explicit attachment sockets rather than hand-written positional offsets.

Useful anchors include:

- `roof_mount_*`
- `window_socket_*`
- `door_socket_*`
- `sign_socket_*`
- `awning_socket_*`
- `fracture_socket_*`
- `tornado_lift_socket_*`
- `build_socket_*`
- `tool_contact_*`

The permanent shell owns the architectural opening/location. The LEGO module owns its own pivot, interaction state, and destruction behavior.

This lets common windows, doors, roof pieces, and trim modules be reused across multiple buildings while keeping alignment deterministic.

---

## 7. Tornado damage progression

Preferred storm progression for an ordinary gameplay building:

1. wind/audio/particles establish pressure;
2. loose LEGO trim begins reacting;
3. shutters/signs/small roof details detach;
4. windows and doors can blow out or tear free;
5. one or more roof assemblies peel/lift;
6. hero roof clusters transition to bounded physics pieces;
7. the permanent wall shell remains as the recognizable damaged building;
8. debris settles, sleeps, or recycles according to the fragment budget.

For a major story destruction event, authored wall-shell damage states or limited structural fracture may be layered on top of this sequence.

This creates escalation while preserving both readability and phone performance.

---

## 8. Relationship to StaticRenderCluster

The permanent shell and noninteractive architectural dressing are good candidates for section-local static clustering.

Do not cluster away:

- LEGO roofs scheduled to detach;
- windows/doors with independent state;
- signs and awnings that can break;
- tool/build targets;
- secrets;
- hero destruction pieces;
- tornado-liftable attachments;
- camera-owned story pieces.

This is the intended bridge between the building grammar and the existing rule:

**author modularly, batch inert scenery, keep LEGO-active identity alive.**

---

## 9. First production target

Before mass-producing Wakita, build one representative hybrid structure and validate the complete pipeline.

Recommended first test building:

**small Oklahoma farmhouse / roadside service building**

It should include:

- permanent non-LEGO wall shell;
- LEGO roof;
- LEGO windows;
- LEGO front/back doors;
- one detachable sign/porch/utility detail;
- one ordinary smashable nearby;
- one tornado roof tear-off sequence;
- one window/door blowout response;
- one damaged-but-recognizable final state.

Test it in the existing 0.3.7 road/farm environment before scaling the grammar across Wakita.

Phone profiling should capture visible geometry, material families, active LEGO attachments, dynamic fragments, particles, and frame-time impact during the storm transition.

---

## 10. Character locomotion note before level production

The next character polish pass should preserve the accepted motor but change presentation toward a waist-led classic brick-adventure gait.

The hips/pelvis should visually lead horizontal motion, creating the impression that the character is being pulled from the waist. The shoulders then sway and counter-rotate more visibly above that motion rather than remaining square to the travel direction.

Desired presentation hierarchy:

`movement/root -> pelvis/waist lead -> torso follow/counter-rotation -> shoulder sway -> arms -> head settle`

The result should remain mechanically hinged and toy-like, not rubbery. Shoulder sway should be more visible than in 0.3.7, especially at run speed, while planted feet and the decisive stop/reversal response remain regression floors.

This character adjustment is important, but level-production work should now prioritize the hybrid building system above.