# Godot Engine Runtime Status

## Status: 0.3.6 ENGINE GATE PASSED

- Current candidate: **0.3.6**
- Target/tested engine: **Godot 4.7.2 stable official**
- Reported build: `4.7.2.stable.official.ed1daf0bf`
- User-supplied Linux editor archive SHA-256: `cadd3204e728a35d3f13adb7fd0d7902636b79f6b95c40c265eb73b6c35329e4`
- Android version code: **18**
- Final candidate ZIP SHA-256: `2cf2e966d254101e0c53de684967dfeef3cc8621720060df2ddb327273fe555c`
- Final source manifest: **315/315 PASS**
- Clean-extracted source gate: **PASS**
- Clean-extracted real-Godot engine gate: **PASS**

## Engine gate coverage

The exact final ZIP was extracted into a fresh directory and passed:

- resource import;
- foundation smoke;
- core contracts;
- all-resource load and scene lifecycle;
- content gameplay systems;
- character LEGO-feel;
- stud-currency identity;
- authored opening slice;
- 600-frame main-scene soak;
- graphical touch dispatch at 1280 x 720;
- graphical touch dispatch at 1920 x 1080;
- graphical touch dispatch at 2400 x 1080.

The 0.3.6 core contract additionally exercises semantic `AudioEvent` lookup, `ActionAnimationProfile` defaults, ordered `BuildRecipe` timing, one-shot `InteractionGraph` output, `SectionBudget` sanity, and `StaticRenderClusterPolicy` collision separation.

## Remaining gate

APK export and physical-phone acceptance remain pending. The 5/5 truck heading model, 5/5 road crossing, and 5/5 storm-probe construction rhythm remain regression floors throughout target-device validation.
