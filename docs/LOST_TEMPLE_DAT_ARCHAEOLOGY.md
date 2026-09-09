# Lost Temple DAT Archaeology

## Scope and clean-room boundary

This note records structural observations from static analysis of a user-supplied 2008 LEGO adventure-game demo. It is intended only to guide independent BrickStorm architecture.

No extracted meshes, textures, audio, animation data, scripts, level geometry, or other proprietary game assets belong in this repository.

## Verified container chain

The supplied Windows demo installer was statically unpacked without execution:

`InstallShield setup.exe -> LEGOIndyDemo.msi -> embedded Data1.cab -> LZX folder 26 -> raiders.dat`

CAB folder 26 expands exactly to its declared uncompressed byte count and contains the relevant configuration/archive payloads including `audio.cfg`, `music.cfg`, and `raiders.dat`.

`raiders.dat` itself is an old-format Traveller's Tales DAT with a compact metadata table at the end of the file.

Observed archive metadata:

- archive payload size: 165,188,872 bytes
- metadata offset: 165,187,840
- metadata size: 1,032 bytes
- old DAT type marker: -2
- file count: 14
- name-node count: 28
- 32-bit path hashes present
- packed gameplay resources use LZ2K
- small root/camera sidecars are stored raw

The filename/hash reconstruction matches the old TT DAT path hashing logic used by public extraction tooling.

## Lost Temple resource partition

The demo chapter is divided into a root resource, six main gameplay sections, optional camera-only sidecars, an intro, and three alternate outros.

| Resource role | Stored bytes | Uncompressed bytes | Storage |
| --- | ---: | ---: | --- |
| Lost Temple root | 10,000 | 10,000 | raw NU20/GSC |
| Section A | 16,885,229 | 35,421,896 | LZ2K |
| Section B | 18,880,255 | 32,241,872 | LZ2K |
| Section D camera sidecar | 10,328 | 10,328 | raw NU20/GSC |
| Section D | 16,858,382 | 33,068,740 | LZ2K |
| Section E camera sidecar | 9,976 | 9,976 | raw NU20/GSC |
| Section E | 13,638,000 | 21,364,806 | LZ2K |
| Section F | 15,363,285 | 23,814,220 | LZ2K |
| Section G camera sidecar | 8,024 | 8,024 | raw NU20/GSC |
| Section G | 12,808,165 | 23,750,264 | LZ2K |
| Intro | 8,266,240 | 15,791,228 | LZ2K |
| Outro end | 27,733,968 | 46,728,094 | LZ2K |
| Outro lose | 17,421,862 | 31,627,234 | LZ2K |
| Outro win | 17,292,496 | 31,010,768 | LZ2K |

Combined:

- stored resource bytes: 165,186,210
- reconstructed uncompressed resource bytes: 294,857,450

The small remainder of the DAT is archive alignment/metadata.

## Important architectural observations

### 1. A chapter is a set of authored sections, not one giant scene

The chapter is physically partitioned into multiple substantial gameplay GSCs rather than a single monolithic level payload.

This supports BrickStorm's proposed hierarchy:

`Story -> Chapter -> Streamed Section`

A Twister chapter should therefore be allowed to move through compact authored spaces such as:

- approach road
- farm/probe site
- convoy segment
- drive-in
- Wakita block
- tornado-impact pocket
- finale corridor

while preserving continuity through shared chapter state.

### 2. Camera resources can be tiny, optional sidecars

Sections D, E, and G have separate camera-only GSC files around only 8-10 KB, while neighboring gameplay payloads are tens of megabytes.

The camera sidecars expose named socket-style anchors such as A/B/C/D/mid/camera sockets and start-camera markers.

Clean-room lesson: camera choreography does not need to live inside the heavy gameplay scene. BrickStorm can store compact `CameraSocketProfile` / camera-beat resources independently from world geometry and gameplay objects.

### 3. Section payloads contain strongly named authored object sets

The first decompressed blocks of the gameplay GSCs contain human-readable name tables before the heavy binary scene data.

Representative semantic families observed across sections include:

- bridge and rolling-bridge pieces
- push blocks
- raft/water-gate pieces
- spike traps
- pull/whip targets
- build components
- balls/planks/bridge pieces
- spear fields
- doors and transition sockets
- engine/cog/prop assemblies
- cutscene-only props

The value is not the specific objects. The value is that each streamed section begins with a compact, authored semantic object vocabulary tied to that section's encounter grammar.

For BrickStorm, a section manifest should similarly make its intended verbs obvious from its content roster.

### 4. Different sections have materially different content density

Approximate uncompressed gameplay-section sizes:

- A: 35.4 MB
- B: 32.2 MB
- D: 33.1 MB
- E: 21.4 MB
- F: 23.8 MB
- G: 23.8 MB

This is a roughly 1.65x spread between the lightest and heaviest sampled main sections.

Clean-room lesson: section complexity is deliberately variable. BrickStorm should not force every section to the same object/physics/audio budget. `SectionBudget` should be authored for the encounter.

### 5. Cinematic variants are separate authored payloads

The chapter contains an intro plus distinct end/lose/win outro resources.

Clean-room lesson: major story outcomes can share a gameplay section but branch into separate lightweight authored presentation payloads. For Twister this is useful for success/failure/secret outcomes without duplicating the playable world.

### 6. Repeated semantic assets across sections support reusable content families

Name tables show recurring vegetation/material/prop families alongside strongly section-specific encounter pieces.

Clean-room lesson: BrickStorm should separate reusable world vocabulary from section-local hero content:

- reusable prairie/road/farm prop families
- reusable brick smashable families
- reusable stud/audio/destruction profiles
- section-local hero builds, hazards, vehicles, and tornado consequences

This improves memory reuse and gives each section a recognizable mechanical identity.

## GSC container observations

Raw and decompressed samples begin with the `NU20` family marker and expose recurring high-level chunks/tags such as:

- `HEAD`
- `NTBL`
- `TREF`
- `TST0`
- `MS00`
- `SST0`
- `INID`
- `FDNS`
- `BNDS`
- `DISP`
- `VBIB`
- `SALI`
- `DYNO`
- `GSNH`
- `PNTR`
- `GMETA`

These tags indicate that a GSC is a bundled scene/resource container containing multiple typed subsystems rather than an undifferentiated geometry blob.

For BrickStorm, we should preserve that conceptual separation even though Godot's native resource model will look different.

Suggested independent equivalents:

- scene header / section manifest
- name/object table
- texture/material references
- bounds/culling information
- display/render resources
- vertex/index or mesh resources
- dynamic-object resources
- pointer/reference relocation handled naturally by Godot Resources
- metadata/debug provenance kept in development builds only

## BrickStorm sizing rule derived from the map

Do not copy the reference byte sizes directly. Use them as evidence for the *shape* of the architecture:

1. One chapter may contain several independently loadable gameplay sections.
2. Camera choreography should be separable and cheap.
3. Each section gets an authored semantic object roster.
4. Section complexity may vary substantially according to the encounter.
5. Reusable environment families should be shared across sections.
6. Hero destruction/build sequences remain section-local.
7. Major outcome cinematics/presentation can branch without duplicating gameplay scenes.

## Immediate implementation consequence

When BrickStorm moves beyond the farm opening, prefer:

`ChapterManifest`

containing ordered `SectionManifest` resources, where each section owns:

- entry/exit anchors
- camera-beat sidecar
- section budget
- semantic interactable roster
- build/destruction hero objects
- NPC/vehicle roster
- storm-pressure range
- music-state policy
- Story/Free Play gates
- prefetch references for the next section

The Lost Temple archive map strongly supports this direction and gives us confidence that authored sectional streaming is compatible with the classic brick-adventure feel we are targeting.
