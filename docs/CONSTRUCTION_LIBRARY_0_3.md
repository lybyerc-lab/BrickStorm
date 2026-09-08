# Construction Library 0.3

## Purpose

The construction library is a reusable authoring grammar for LEGO: Twister content. It is not a generic CAD project and it does not own story logic.

## Core data

### BrickDimensions

Defines the canonical game-scale stud pitch, plate height, brick height, stud size, visual gaps, bevel defaults, grid snapping, and stack math.

### BrickPalette

Defines reusable molded-plastic, transparent, rubber, and metal material colors/roughness so authored sets remain visually coherent without copied textures or branded assets.

### BrickElementSpec

One tagged element carries:

- element kind;
- stud dimensions and plate height;
- color/material values;
- target position and rotation;
- studs/underside/detail flags;
- mass;
- semantic role;
- break cluster;
- build order;
- free-form tags.

The same spec can therefore participate in intact rendering, build animation, destruction grouping, and later rebuild/state tooling.

### BrickBuilder

Procedurally renders the current element kinds using Godot primitives. Supported families include bricks, plates, tiles, slopes, inverted slopes, round/cone parts, wheels, beams, technic-like beams, arches, bars, and panels. Studs and hero underside tubes use the shared dimensions.

## Live integrations

- Chase truck visual body.
- Weather scanner.
- Storm siren.
- Cow ramp.
- Wind vane.
- Storm probe deployment assembly.
- Multiple farm prop families use the same construction dimensions/palette direction.

## Build semantics

`BuildableObject.add_build_element()` accepts a `BrickElementSpec`. Build timing comes from the authored `build_order`, not list position. The old raw-box method remains available for migration rather than forcing a risky all-at-once rewrite.

## Destruction semantics

`BrickElementSpec.break_cluster` and the base `DestructibleStructure` staged-release contract provide the path from intact authored structures to readable hero destruction while keeping physical debris bounded.

## Next modules

Prioritize modules with immediate LEGO: Twister value:

- Oklahoma clapboard wall/window/door sets;
- barn gables and roof modules;
- Wakita storefront facade kits;
- utility poles, transformers, wires, and roadside infrastructure;
- drive-in screen framing;
- water tower legs/tank modules;
- chase-vehicle equipment racks;
- Dorothy-style storm science equipment;
- damaged/rebuild states for the same assemblies.
