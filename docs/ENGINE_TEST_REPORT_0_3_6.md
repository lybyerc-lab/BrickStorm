# Engine Test Report 0.3.6

**Result: PASS**

Engine: Godot `4.7.2.stable.official.ed1daf0bf`

User-supplied Linux editor archive SHA-256: `cadd3204e728a35d3f13adb7fd0d7902636b79f6b95c40c265eb73b6c35329e4`

Final candidate ZIP SHA-256: `2cf2e966d254101e0c53de684967dfeef3cc8621720060df2ddb327273fe555c`

## Exact-package gate

The final deterministic 0.3.6 ZIP was extracted into a fresh directory. Its 315-entry manifest verified exactly, source validation passed, and the extracted project passed the complete real-engine gate:

- resource import;
- foundation smoke test;
- core contract engine test;
- all-resource load and scene lifecycle test;
- content gameplay systems test;
- character LEGO-feel test;
- stud-currency identity test;
- authored opening-slice test;
- 600-frame main-scene soak;
- graphical touch input at 1280 x 720;
- graphical touch input at 1920 x 1080;
- graphical touch input at 2400 x 1080.

No engine parser/runtime error markers were emitted by those gates.

## 0.3.6-specific runtime coverage

The core contract engine test exercises semantic `AudioEvent` lookup, `ActionAnimationProfile` defaults, ordered `BuildRecipe` timing, one-shot `InteractionGraph` output, `SectionBudget` sanity, and `StaticRenderClusterPolicy` collision separation. Existing engine tests continue to protect the authored opening, visible carried tools, character feel, canonical stud identity, truck/cow screen-heading behavior, road crossing, build/destruction systems, and touch lifecycle safety.

## Remaining gate

Physical Android acceptance remains required for subjective thumb feel, frame pacing, heat, sound balance, safe areas, target-device GPU behavior, and overall LEGO-game feel.
