# North Star: LEGO: Twister

## One-Sentence Vision

Build the game that feels like the original *Twister* was adapted during the classic early Traveller's Tales LEGO era: recognizable movie beats, slapstick comedy, chunky construction, constant smashing and rebuilding, collectible-driven exploration, arcade vehicles, secrets, and a tornado that physically rearranges the level around the player.

## Craftsmanship Bar

The target reaction is:

> **"Wait... they made a LEGO: Twister game?"**

BrickStorm should not settle for reading as a competent fan prototype or a generic game inspired by classic LEGO titles. The goal is enough consistency, specificity, polish, and authored detail that a player could briefly believe they had discovered a forgotten licensed Traveller's Tales-era adaptation.

That standard applies to the whole experience, not screenshots alone:

- character silhouettes and animation must immediately read as classic LEGO-game characters;
- locomotion must carry the waist-led, shoulder-driven toy rhythm expected from the reference era;
- environments must look intentionally authored rather than assembled from convenient primitives;
- LEGO-active objects must be visually distinct, useful, and integrated into the world rather than scattered on top of it;
- camera, audio, studs, builds, destruction, reactions, UI, and transitions must all reinforce the same game language;
- recognizable *Twister* locations and moments must be specific enough that the game could not be mistaken for a generic tornado adventure;
- mobile constraints may change implementation cost, but should not be visible as unfinished presentation;
- placeholders are acceptable during development only when they are clearly temporary and do not become the quality target.

A feature is not finished merely because it works. It is finished when its behavior, presentation, feedback, and surrounding composition belong convincingly to the same imagined LEGO: Twister release.

## The Six Pillars

### 1. Twister First

Every major level, mechanic, vehicle, buildable, and spectacle should feel connected to *Twister*.

Preferred source material includes:

- Wakita
- the storm-chaser convoy
- storm-probe equipment
- farm roads and Oklahoma countryside
- barns and utility infrastructure
- rival chasers
- the drive-in sequence
- damaged-town recovery
- escalating tornado encounters
- the F5 finale
- airborne cows

Generic storm content is acceptable only when it strengthens one of these experiences.

### 2. Classic LEGO-Game Grammar

The player should instinctively understand the world through familiar LEGO-game verbs:

- smash
- collect
- build
- interact
- switch ability/character
- drive
- discover
- replay

The game should reward curiosity with studs, gags, secrets, alternate routes, destructible set pieces, unlocks, and Free Play-style opportunities.

### 3. The Tornado Is the Villain

The tornado is not a weather shader or distant timer.

It should:

- move through authored routes
- pull and fling props
- damage or peel structures in phases
- expose hidden paths
- block old paths
- transform traversal
- create rescue moments
- interact with vehicles and characters
- produce escalating spectacle
- occasionally turn livestock into aviation

Storm behavior may be cheat-heavy under the hood. The player experience matters more than fluid-simulation purity.

### 4. Destruction and Rebuilding Are the World Language

The environment should read as constructed from pieces worth touching.

Large hero objects should break in satisfying authored stages. Smaller objects can use shared destruction systems, pooled fragments, particle chips, and studs.

Rebuildables should preferably change gameplay, such as:

- opening a route
- creating a ramp
- repairing storm equipment
- activating machinery
- building a bridge
- creating a launcher
- rebuilding a town object into something hilariously unnecessary

### 5. Slapstick Adventure, Not Grim Disaster

The tone is adventurous, affectionate, and physical.

Tension can rise as storms intensify, but comedy should keep punching holes in the seriousness through animation, props, character reactions, environmental gags, and absurd rebuild results.

Characters should survive disaster with classic LEGO-game elasticity.

### 6. Mobile Immediacy

The game is Android/mobile-first.

That means:

- readable camera framing
- short-to-medium mission chunks
- responsive touch controls
- low-friction interaction
- strong silhouettes
- effects that remain legible on a phone
- performance budgets that protect frame rate

Complexity belongs behind the curtain. The player's thumbs should not need an engineering degree.

## Visual North Star

The desired visual impression is not generic block art and not photoreal Oklahoma with studs glued on.

It should feel like a classic LEGO-game world:

- recognizable LEGO-scale construction logic
- chunky proportions
- bright readable plastics against stormy skies
- physical studs and layered plates where they matter
- simplified but recognizable architecture
- authored break seams
- small visual jokes embedded in scenery
- storm damage that reveals the construction underneath

The construction library should prioritize 1990s Oklahoma vocabulary: clapboard homes, barns, roadside signs, utility poles, farm equipment, storm gear, small-town storefronts, drive-in structures, trucks, trailers, water towers, fences, and improvised scientific equipment.

## Level Structure North Star

A strong story level generally mixes several of these beats:

1. recognizable movie setup;
2. exploration and smashing;
3. small build puzzle;
4. character ability interaction;
5. vehicle or chase segment;
6. tornado escalation;
7. transformed environment;
8. comic payoff or set-piece destruction;
9. collectible/replay hooks that become richer in Free Play.

## Hub North Star

Wakita should eventually function as the primary hub:

- convoy staging
- character selection/unlocks
- vehicles
- replaying story chapters
- collectibles
- rebuilt-town progression
- small environmental gags
- visual signs of campaign progress

As the story advances, Wakita should become more complete, stranger, and more obviously rebuilt by LEGO logic.

## Character Ability Direction

Character differences should create replay value rather than merely stat differences.

Examples:

- Jo: storm equipment, climbing, storm clues
- Bill: vehicle repair, intuitive storm interactions
- Dusty: heavy equipment, sound-system antics, large-object interactions
- Melissa: civilian interactions, rescue/medical/psychology-flavored puzzles, comedic reactions
- Rabbit: navigation and shortcuts
- Beltzer: mechanical systems
- Jonas/rival-tech roles: high-tech panels and corporate equipment

Exact implementation may evolve, but the principle is fixed: abilities should unlock alternate routes and Free Play opportunities.

## Vehicle Direction

Vehicles should be fun before they are realistic.

Important families include:

- chase trucks
- convoy vehicles
- Dusty's bus
- rival black fleet
- tractors and farm vehicles
- emergency vehicles
- ridiculous secret unlocks
- Dorothy as an intentionally absurd possible 100% reward

Current approved vehicle control uses the joystick as a screen-space heading command for the vehicle nose.

## The Test

Before accepting a major feature, ask:

> Does this make the player feel more like they are playing a classic LEGO adaptation of *Twister*?

If it could be dropped unchanged into a generic brick sandbox, generic survival game, or generic tornado simulator, it probably needs another design pass.