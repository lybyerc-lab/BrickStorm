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

BrickStorm Foundation **0.4.5** is the current byte-authoritative, clean-extracted, Godot-tested OpenAI baseline.

Sealed archive: `brickstorm_foundation_v0_4_5.zip`

SHA-256: `47fe560d9bb95548c9698ab6d16abe0f4defc7f71eb6b0ab267b3c41e9a9172d`

Exact-package verification includes:

- source manifest: **424/424** entries unchanged after all clean-extracted testing;
- source/static release gate;
- deep audit: **99 GDScripts / 51 scenes / 46 global class_name symbols**;
- **78/78** behavior contracts;
- strict-parser negative tests: **10/10**;
- tornado route QA: PASS;
- real Godot `4.7.2.stable.official.ed1daf0bf` import/runtime/core/lifecycle/content gates;
- character LEGO-feel and hybrid-building gates;
- phone QA lab and runtime telemetry gate;
- canonical stud identity;
- authored opening slice;
- preserved county-road chase;
- Wakita first-block vertical slice;
- 600-frame main-scene soak;
- graphical touch at 1280x720, 1920x1080, and 2400x1080.

During the exact-package aggregate run, the 1920x1080 Xvfb wrapper failed to retain its temporary marker log. The 1920x1080 and 2400x1080 stages were rerun independently against the same exact extraction; both Godot processes exited 0, printed `BRICKSTORM TOUCH INPUT ENGINE TEST: PASS`, and emitted no engine error markers.

The sealed ZIP stored in the LEGO: Twister Library is the byte authority. The GitHub branch remains a curated implementation/history mirror unless a full-repository mirror is separately verified.

## 0.4.5 phone-playtest response

The incoming physical-phone authority is **0.4.4 = 3.9/5 overall**. The user's notes were:

- cars moved faster than nearby studs could comfortably be collected;
- the minifig run felt a little slow;
- the environment felt too linear;
- the long playing field should follow the demo's stronger level progression: compact spaces stacked beside one another with some elevation.

0.4.5 answers those notes without changing the protected 5/5 truck handling.

### Movement and currency

- On-foot minifig travel is faster while preserving the accepted little-run/swagger presentation.
- Studs use stronger vehicle-aware attraction and catch-up so the truck can retain its accepted speed without outrunning reward feedback.

### Demo-informed exploration topology

The exploration rule is now:

**adjacent compact play spaces + lateral movement + readable elevation + through-flow**.

The opening farm now uses:

- the county road as the low navigation datum;
- a raised equipment-yard room on the east side;
- a raised barn-yard room on the west side;
- separate entrance and exit ramps through both raised rooms;
- story collectibles and reward arcs that move laterally and vertically through those spaces;
- elevation-safe sensor-kit bobbing and authored placement.

This replaces the earlier idea of simply placing optional flat detours beside one long road. Raised rooms are meant to be traversed through, not merely entered and backtracked from.

The high-speed tornado pursuit is intentionally different. Demo archaeology shows the chase-like reference section reduces navigation, interaction, and collision breadth while retaining forward motion, destruction, camera pressure, and pickups. Therefore:

**exploration sections may stack and branch; spectacle chase sections may deliberately tighten into readable corridors.**

## Demo parity status

The user-supplied 2008 classic brick-adventure demo remains the **5/5 measurement stick**. Automated PASS results prove stability, not subjective parity.

Incoming completed Android score: **0.4.4 = 3.9/5 overall**.

0.4.5 working estimates pending physical-phone replay:

- visual parity: approximately **3.9/5**;
- gameplay parity: approximately **3.7/5**;
- verdict: **ACCEPT AS FOUNDATION ONLY pending device replay**.

Do not convert these estimates into user scores.

Strongest 0.4.5 improvement: the opening exploration space now progresses across adjacent raised rooms rather than reading as one long flat strip.

Biggest remaining visual giveaway: authored asset/material/lighting richness and later long-axis compositions, especially the current Wakita presentation, remain below the shipped reference.

Biggest remaining gameplay giveaway: contextual character roles, companion behavior, semantic feedback density, alternate solutions, secrets, and Story/Free Play depth remain below the reference.

## Protected wins / regression floors

- Truck heading control: **5/5**
- Road crossing: **5/5**
- Storm-probe build rhythm: **5/5**
- Generator/sensor-cage opening: protected reference slice
- County-road / production InteractionGraph chase: protected
- hopping buildable identification: protected
- torso/shoulder swagger and little-run presentation: protected
- roadside/farmhouse prop nesting: protected
- Wakita objective/checkpoint/camera/tornado-route ownership: protected
- phone QA harness and runtime telemetry: protected
- canonical stud denomination identity and mobile destruction budgets: protected

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

A candidate is not sealed until source validation passes, real Godot 4.7.2 tests pass, the exact ZIP is clean-extracted and retested, and source-manifest hashes remain unchanged after testing. Physical Android remains authoritative for rendering, audio, performance, thermals, thumb feel, movement speed, stud pacing, level progression, and overall classic-LEGO impression.