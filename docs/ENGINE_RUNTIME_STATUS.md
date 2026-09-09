# Godot Engine Runtime Status

## Status: 0.3.6 ENGINE GATE PENDING

- Current source candidate: **0.3.6**
- Target engine: **Godot 4.7.2 stable official**
- Android version code: **18**
- Current workspace limitation: external engine download blocked by outbound DNS
- Clean-extracted 0.3.6 source gate: **PASS**

## Known-good runtime baseline

**0.3.5 ENGINE GATE PASSED**

- Tested engine: **Godot 4.7.2 stable official**
- Reported build: `4.7.2.stable.official.ed1daf0bf`
- Linux editor archive SHA-256: `cadd3204e728a35d3f13adb7fd0d7902636b79f6b95c40c265eb73b6c35329e4`
- Graphical touch renderer: GL Compatibility through Mesa llvmpipe under Xvfb

`tools/run_engine_tests.sh` remains the engine-side release authority. For 0.3.6 it must repeat resource import, foundation smoke, core contracts, all-resource lifecycle, content gameplay, character feel, stud currency, authored opening, 600-frame soak, and touch dispatch at 1280 x 720, 1920 x 1080, and 2400 x 1080.

The core contract test now also exercises semantic `AudioEvent` lookup, `ActionAnimationProfile` defaults, ordered `BuildRecipe` timing, one-shot `InteractionGraph` output, `SectionBudget` sanity, and `StaticRenderClusterPolicy` collision separation.

No 0.3.6 engine PASS, APK PASS, or physical-phone PASS should be recorded until those gates actually run. The 5/5 truck heading model, 5/5 road crossing, and 5/5 storm-probe construction rhythm remain regression floors throughout that validation.
