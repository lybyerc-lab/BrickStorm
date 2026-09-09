# Foundation Hardening Review 0.3.7

## Status

- **SOURCE GATE: PASS** on the synchronized 0.3.7 tree.
- **ENGINE GATE: PASS** with official Godot 4.7.2 stable across import, contracts, road chase, soak, and three graphical touch resolutions.
- **CLEAN-EXTRACTED PACKAGE GATE: REQUIRED** before delivery of the sealed candidate.
- **PHYSICAL ANDROID GATE: PENDING** after packaged engine clearance.

## Goal

0.3.7 spends the new 0.3.6 architecture on visible game quality: **CHARACTER POLISH** plus a meaningful **ROAD CHASE** expansion. It is not another architecture-only release.

## Character polish

The accepted motor remains unchanged. The visual/presentation layer now uses:

- tapered molded torso instead of stacked rectangular humanoid blocks;
- separate pelvis and torso roots;
- low-sided rigid arm forms with a fixed molded elbow bend;
- compact C-grip hand silhouette;
- tighter head/cap/neck proportions;
- arm cadence slightly offset from the legs;
- pelvis/torso counter-rotation during the run;
- delayed head follow and reduced vertical bob;
- planted toy pivots and bounded land squash retained.

The target is less rigid **without** rubber-hose motion. Limbs remain mechanical hinges.

## Road chase

After the protected storm-probe build completes, the game now continues north beyond the original farm boundary.

New beats:

1. return to the chase truck;
2. follow fast steering studs down the extended road;
3. punch through a first cross-road debris gust;
4. stop at the disabled county gate;
5. build the roadside storm beacon;
6. use the existing wrench to repair/power the beacon;
7. the first production `InteractionGraph` evaluates `probe_deployed AND beacon_online`;
8. the graph opens the county barrier;
9. resume the chase through a hero utility-pole destruction beat and second debris gust;
10. reach the north ridge for the first-intercept payoff and Wakita-forward story hook.

## Regression policy

The following remain comparison floors:

- truck control: 5/5;
- road crossing: 5/5;
- storm-probe build rhythm: 5/5;
- generator/sensor-cage opening: reference slice;
- 0.3.6 architecture contracts: engine-cleared baseline.

The new north-road ground overlaps the original collision slab specifically to avoid creating a seam under the accepted truck.

## InteractionGraph proof

The generator/cage chain remains untouched. The road beacon/barrier is the first production proof of the generalized graph layer. Building the beacon alone is insufficient; wrench repair must set the second semantic state before the graph may emit the gate-open output.
