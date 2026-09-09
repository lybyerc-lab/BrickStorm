# Engine Test Report 0.3.7

## Result: PASS

Foundation 0.3.7 passed the complete Godot-side release gate using the user-supplied official Linux editor.

## Engine identity

- Engine: Godot `4.7.2.stable.official.ed1daf0bf`
- Supplied editor archive SHA-256: `cadd3204e728a35d3f13adb7fd0d7902636b79f6b95c40c265eb73b6c35329e4`
- Rendering method: GL Compatibility
- Graphical test device under Xvfb: Mesa llvmpipe

## Passing stages

1. Resource import: PASS
2. Foundation smoke: PASS
3. Core contracts: PASS
4. All resources and scene lifecycle: PASS
5. Content gameplay systems: PASS
6. Character LEGO feel: PASS
7. Stud currency identity: PASS
8. Authored opening slice: PASS
9. 0.3.7 road chase: PASS
10. Main scene 600-frame soak: PASS
11. Touch input 1280 x 720: PASS
12. Touch input 1920 x 1080: PASS
13. Touch input 2400 x 1080: PASS

The host execution wrapper timed out when the entire shell runner was invoked as one long tool call, so the exact component commands from `tools/run_engine_tests.sh` were executed in smaller batches. Required PASS markers and engine-error scans were retained for every component. The test standard was not reduced.

## 0.3.7-specific proof

The road-chase engine test exercises the actual authored sequence:

`probe complete -> road beacon revealed -> ordered build -> wrench repair -> InteractionGraph output -> barrier opens -> chase resumes -> hero roadside destruction -> first intercept`

It explicitly verifies that completing the beacon build alone does **not** bypass the wrench requirement or open the gate.

The character-feel test verifies that the accepted player motor still starts, stops, reverses, pivots, jumps, and carries tools correctly while the visual hierarchy now separates pelvis and torso motion and retains independently articulated rigid legs.

## Package rule

This report clears the synchronized working tree. The deterministic 0.3.7 ZIP must be extracted into a fresh directory and repeat the source and engine gates before it becomes the delivery artifact.

Physical Android testing remains the authority for device-specific performance, safe areas, heat, battery behavior, audio mix, thumb feel, and subjective LEGO-character motion/readability.
