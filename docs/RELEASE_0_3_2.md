# BrickStorm Foundation 0.3.2 Release Record

## North Star

The game is **LEGO: Twister**. `BrickStorm` is the development codename.

## Feel-first goal

0.3.2 responds directly to the physical-device 0.3.1 ratings:

- Barn destruction: 3/5
- Probe build: 3/5
- LEGO-game feel: 3/5

The release deliberately prioritizes visible payoff rather than adding more foundation abstraction.

## Player-visible changes

- Barn hero destruction is cause-aware. Direct impact punches through the front first while tornado damage peels the roof and walls with visible anticipation.
- Studs spill during collapse stages instead of appearing only after the entire structure is gone.
- Storm-probe components are visible in scattered form before the player builds them.
- Probe assembly runs in readable construction phases and finishes as an active spinning sensor rig.
- Persistent placed stud trails improve first-minute navigation and collectible rhythm.
- Smashable scarecrows add lightweight farm gags and destruction targets.
- The original procedural player visual has a more readable brick-toy silhouette without changing accepted movement physics.

## Protected behavior

- Truck control remains the accepted screen-heading model rated 5/5 by the user.
- Road crossing remains the accepted continuous-collider solution rated 5/5 by the user.
- Mobile destruction budgets remain capped.

## Verification

Source gates:

- 59 tagged GDScripts
- 33 scenes
- 43/43 behavior contracts
- 51 deep-audit grouped checks
- static validation PASS
- route QA PASS
- strict-parser negative fixtures 10/10 PASS

Exact clean-package Godot 4.7.2 gate:

- resource import PASS
- foundation smoke PASS
- core contracts PASS
- all resources and scene lifecycle PASS
- content gameplay systems PASS
- main scene 600-frame soak PASS
- touch input 1280x720 PASS
- touch input 1920x1080 PASS
- touch input 2400x1080 PASS

Payload integrity after validation and Godot execution:

- SOURCE_MANIFEST entries checked: 231
- unchanged hashes: 231/231 PASS
- ZIP integrity: PASS
- SHA-256: `e45af121f4d3d5a5c7c422e56ec937a5145fcba479dbe033bccae8a4c7ddddb3`

## Repository note

`openai/brickstorm` remains a curated workstream mirror rather than a complete byte-for-byte copy of the sealed archive. The verified release ZIP and its manifest remain the authoritative complete 0.3.2 snapshot until repository migration is completed and verified.
