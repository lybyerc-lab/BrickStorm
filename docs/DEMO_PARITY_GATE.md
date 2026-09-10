# Demo Parity Gate

## Purpose

Every meaningful LEGO: Twister / BrickStorm development pass must answer two questions before it can be called an improvement:

1. How does the current visual presentation compare with the user-supplied 2008 classic brick-adventure demo?
2. How does the current gameplay feel compare with that demo?

The demo is the 5/5 measurement stick. A pass does not earn visual or gameplay parity merely because it improves on the previous BrickStorm build or passes automated engine tests.

This is a clean-room comparison. Measure relationships, proportions, timing, density, system separation, feedback, readability, and player feel. Do not copy proprietary meshes, textures, animation curves, audio, layouts, scripts, or other protected production content.

## Mandatory Visual Comparison

Score each 0-5 against the demo reference:

- minifigure silhouette and proportions at actual gameplay-camera distance;
- locomotion presentation: waist lead, shoulder sway, rigid hinge limbs, pivot/start/stop/land readability;
- LEGO-active architectural fit: windows, doors, roofs, signs, awnings, hinges, sockets, seams, and snap alignment;
- environment composition and visual density;
- LEGO-active versus permanent-world readability;
- material/plastic response, lighting, shadowing, and surface richness;
- camera framing and authored emphasis;
- destruction readability before, during, and after failure.

For every visual pass ask: **If this frame were inserted into footage from the reference game, what would immediately give BrickStorm away?**

Any obvious answer is a prioritized craftsmanship defect, not cosmetic backlog.

## Mandatory Gameplay Comparison

Score each 0-5 against the demo reference:

- movement response and toy weight;
- smash / collect / build rhythm;
- contextual actions and tool handling;
- interaction consequence chains;
- vehicle readability and responsiveness;
- destruction and hazard play;
- animation/audio/stud/camera feedback density;
- companion/character-role behavior where applicable;
- Story/Free Play replay hooks and alternate solutions;
- level pacing, authored route clarity, and interactions per minute.

For every gameplay pass ask: **If someone played thirty seconds without seeing the title, what would make it feel unlike the reference brick-adventure game?**

## Evidence Required Per Pass

A meaningful pass report must include:

- visual parity score /5;
- gameplay parity score /5;
- strongest improvement relative to the previous pass;
- biggest remaining visual giveaway;
- biggest remaining gameplay giveaway;
- protected regressions checked;
- screenshots or gameplay-camera captures where visual work changed;
- engine/contract results where behavior changed;
- explicit verdict: ACCEPT, ACCEPT AS FOUNDATION ONLY, or REWORK BEFORE EXPANSION.

Do not use an automated PASS marker as evidence of visual parity.

## Geometry Fit Gate

Attachment sockets existing is necessary but not sufficient.

Production hybrid buildings must validate fit relationships, including:

- window center and opening center alignment;
- intentional frame overlap around wall openings;
- door bottom/threshold alignment;
- hinge plane alignment where applicable;
- roof eave alignment to the intended wall/gable line;
- left/right roof ridge convergence;
- no visible floating, unintended penetration, or asymmetric gaps;
- detached state reveals a believable opening rather than hidden geometry mistakes.

Future automated tests should validate geometric tolerances in addition to socket identity, and gameplay-camera captures remain the final visual authority.

## Character Silhouette Gate

A character is not visually accepted because the animation hierarchy is technically correct.

At gameplay distance the figure must immediately read as a classic minifigure-style toy through silhouette and proportion before clothing color or facial detail is considered. Required comparison points include head-to-torso ratio, torso taper, hip block, leg length/width/spacing, shoulder span, rigid bent-arm silhouette, hand mass, foot mass, neck/head seating, and accessory scale.

Movement polish cannot hide an incorrect base silhouette.

## Current 0.4.0 Classification

Foundation 0.4.0 remains a technically sealed checkpoint and a useful production architecture milestone.

It is **not** demo-parity accepted visually. The current character silhouette still reads too much like a custom block figure, and building attachment fit is not yet precise enough at windows, doors, and roofs.

Its gameplay architecture is closer to the reference than its visual presentation, but the full reference feel still requires denser semantic feedback, richer character/action presentation, more contextual role gameplay, stronger replay hooks, and more interactions per minute.

The next production pass should fix character silhouette and building fit before expanding Wakita acreage.
