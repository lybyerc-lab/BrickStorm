# OpenAI BrickStorm Workstream

This branch is owned by the ChatGPT/OpenAI implementation of BrickStorm.

## Branch policy

- Active branch: `openai/brickstorm`
- Construction feature branch: `openai/construction-library`
- Do not commit Claude or other independent implementations to these branches.
- Do not merge this branch into `main` without explicit project-owner approval.
- Treat `main` as neutral coordination territory while independent implementations coexist.

## Creative identity

The game is **LEGO: Twister**. `BrickStorm` is only the development codename. Read `PROJECT_MEMORY.md`, `docs/NORTH_STAR.md`, `docs/NO_DRIFT_POLICY.md`, and `docs/DEMO_PARITY_GATE.md` before substantial design or implementation work.

## Current sealed baseline

BrickStorm Foundation **0.4.3** is the current byte-authoritative, clean-extracted, Godot-tested OpenAI baseline.

Sealed archive: `brickstorm_foundation_v0_4_3.zip`

SHA-256: `472b63990da14dc1abe7d64ecacf8f373040b35908c995060a9577a3793c1965`

Exact-package verification includes:

- source manifest: **402/402** entries unchanged before and after clean-extracted testing;
- source/static release gate;
- deep audit: **96 GDScripts / 49 scene-resource files**;
- **74/74** behavior contracts;
- strict-parser negative tests: **10/10**;
- real Godot `4.7.2.stable.official.ed1daf0bf` import/runtime/core/lifecycle/content gates;
- character LEGO-feel, minifigure silhouette, little-run, and torso-swagger gates;
- hybrid-building precision fit plus phone-visible roadside/farmhouse nesting coverage;
- canonical stud identity;
- authored opening slice;
- preserved county-road chase;
- Wakita first-block vertical slice;
- 600-frame main-scene soak;
- graphical touch at 1280x720, 1920x1080, and 2400x1080.

The aggregate graphical wrapper reached its environment wall-clock limit after 1280x720. The exact-package 1920x1080 and 2400x1080 stages were rerun directly with Xvfb managed separately; both Godot processes exited 0, printed the required touch PASS marker, and emitted no Godot error markers.

The sealed ZIP stored in the LEGO: Twister Library is the byte authority. The GitHub branch remains a curated implementation/history mirror unless a full-repository mirror is separately verified.

## Physical-phone baseline and demo parity

The user-supplied 2008 classic brick-adventure demo remains the **5/5 measurement stick**. Automated PASS results prove stability and protected behavior, not visual parity.

The most recent completed physical Android playtest is **0.4.2**:

- user played a full round;
- user said **“It’s fun.”**;
- user-rated overall result: **3.8/5**;
- remaining observed defects: torso needed more swagger like the shoulders, and some house props were still visibly off.

0.4.3 was built specifically from those observations. Do not overwrite the 0.4.2 phone score with an automated estimate.

Current 0.4.3 status pending Android replay:

- visual parity working estimate: approximately **3.8/5**;
- gameplay parity working estimate: approximately **3.4/5**;
- verdict: **ACCEPT AS FOUNDATION ONLY, pending physical-phone subjective review**.

Strongest 0.4.3 improvement: the torso now participates as a distinct delayed phase between pelvis lead and shoulder finish, and phone-visible legacy/background house paths are covered by the same fit discipline as Wakita.

Biggest remaining visual giveaway: authored mesh quality, materials, texture/surface richness, prop specificity, and environment dressing remain below the shipped reference.

Biggest remaining gameplay giveaway: contextual actions, companion/character-role behavior, semantic feedback density, alternate solutions, secrets, and Story/Free Play depth remain below the reference.

## 0.4.3 correction contracts

### Character presentation

Keep one authoritative on-foot motor. Current visible hierarchy:

`travel/root -> pelvis lead -> delayed torso yaw/roll/lateral follow -> broader later shoulder finish -> rigid arm lag -> head settle`

0.4.3 adds independent torso phase/follow behavior rather than asking the shoulders to carry all visible swagger. The narrower 0.4.2 shoulders and little minifigure run/hustle remain protected.

### Phone-visible building fit

Building grammar remains **permanent world shell + LEGO attachment layer**.

0.4.3 extends fit correction beyond the newer Wakita kit:

- legacy `HybridRoadsideHouse` windows/door now seat by visible shell-face depth;
- its roof mount, pitch, depth, and overhang derive from the receiving shell;
- its gable fill derives from the same roof run/pitch;
- `NaturalFarmhouseBackdrop`, which exposed the phone-visible defect, now derives paired roof halves and gable fill together;
- farmhouse windows and door use recess -> trim -> face layering instead of flat pasted rectangles.

These guarantees are represented by named release contracts, not just screenshot inspection.

## Protected wins / regression floors

- Truck heading control: **5/5**
- Road crossing: **5/5**
- Storm-probe build rhythm: **5/5**
- Generator/sensor-cage opening: protected reference slice
- County-road / production InteractionGraph chase: protected
- 0.4.2 hopping buildable identification: protected
- Wakita objective/checkpoint/camera/tornado-route ownership: protected
- Canonical stud denomination identity and mobile destruction budgets: protected

Protected means comparison floor, not museum glass. Improvements are welcome only when the play result clearly remains equal or better.

## Mandatory pass review

Every meaningful pass reports:

1. visual parity /5 versus the demo;
2. gameplay parity /5 versus the demo;
3. strongest improvement;
4. biggest remaining visual giveaway;
5. biggest remaining gameplay giveaway;
6. protected regressions checked;
7. explicit verdict: ACCEPT, ACCEPT AS FOUNDATION ONLY, or REWORK BEFORE EXPANSION.

## Release discipline

A candidate is not sealed until source validation passes, real Godot 4.7.2 tests pass, the exact ZIP is clean-extracted and retested, and source-manifest hashes remain unchanged after testing. Physical Android remains authoritative for rendering, audio, performance, thermals, thumb feel, torso swagger, prop nesting, and overall classic-LEGO impression.