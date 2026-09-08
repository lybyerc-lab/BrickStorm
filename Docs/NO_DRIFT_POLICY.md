# BRICKSTORM No-Drift Policy

`Docs/NORTH_STAR.md` says what this game is. This document says how it stays
that way.

Drift is not usually a bad decision. It is a hundred reasonable ones, each
defensible alone, that together produce a different game than the one anybody
agreed to build. It is prevented by making the target explicit, making the
invariants enforceable, and making the checks capable of failing.

---

## Production summary

1. **The tornado destroys the world; the player loots it.** The player is never
   promoted back to primary agent of destruction.
2. **Nothing that moves is ever destroyed.** Enforced in code, not remembered.
3. **There is no fail state, only a toll.** No lives, no game over, no progress loss.
4. **Risk must be legible.** If a position's value is not readable at a glance,
   the feature is unfinished.
5. **True brick construction.** If it cannot be built from parts, it is not in the
   game. The funnel is the one deliberate exception.
6. **The world stays bright; only the sky darkens.**
7. **Mobile is the design target, not a port target.** Two thumbs, no camera
   control, one context button.
8. **Landscape only.** Any harness or capture viewport is wider than it is tall.
9. **A build is not correct because it runs, and not correct because it compiles.**
10. **Graphics are gameplay.** Readability of a brick, a band, or a multiplier is a
    mechanic, not a polish task.
11. **The repository is the durable record.** Chat is working context. A decision
    that is not committed here did not happen.
12. **Code and the document describing it land in the same commit.** A document
    updated later is a document that was wrong in between.
13. **Anchors are the map.** High-risk logic carries a registered `[BS:...]` anchor
    (`Docs/CODE_ANCHORS.md`) so it can be found without reading everything.
14. **Invariants live next to the code they constrain**, in the anchor header, not
    only in a design document nobody opens while editing.
15. **The physical Android device is the final authority** for touch, heat,
    battery, audio, and readability. CI green is not acceptance.
16. **Changes to the North Star require explicit director approval** and never
    arrive as a side effect of implementation work.
17. **External suggestions are advisory.** Including suggestions from another
    implementation in this repository.
18. **Placeholder names stay flagged until replaced.** See North Star, Naming.

---

## Scope discipline

The failure mode this section exists to prevent is not new ideas. It is that
**every finding becomes work because there is nowhere else to put it.**

- A finding discovered while working on something else goes on the backlog **by
  default** — including anything found by the person already inside the file, and
  especially anything that looks like a quick fix while you are in there.
- "While we're here" is the phrase that ends projects. Filing it *is* doing
  something about it.
- Promotion off the backlog is a deliberate act, not a default.
- If it is not clear whether a finding is in scope for the current piece of work,
  it is not.

---

## What the checks can and cannot see

**This is the most important section in this document, and it is written from a
failure that has already happened on a sibling project.**

A verification that string-matches source code cannot see anything. It confirms
that text exists. It does not confirm that the text does what it says, that the
result is correct, or that the picture on screen is not visibly broken. Whole
classes of shipped defects — geometry in the wrong place, wrong materials,
objects buried in the ground — have passed such checks green.

So the checks in this repository are ranked, and it is stated plainly which are
load-bearing:

| Check | What it actually proves | Weight |
|---|---|---|
| GDScript parse / import | The code compiles | Weak |
| `tools/verify_anchors.gd` | The anchor registry and the code agree | Structural only |
| `--selftest` | The funnel really tore bricks, and destruction really produced studs and score. Exits non-zero if not. | **Load-bearing** |
| `--capture` screenshots | What the frame actually looked like | **Load-bearing** |
| Device play | Everything else | **Final authority** |

The anchor verifier is deliberately honest about its limits: it checks that every
anchor in the code is registered and every registered anchor exists in the code,
with matched start/end markers. **It cannot tell you the code under an anchor
still upholds the invariant written above it.** Only a behavioural test or a human
can do that.

Never add a check that can only pass. A check that cannot fail is worse than no
check, because it produces the feeling of coverage.

---

## Before claiming work is done

1. `godot --headless --path . --import` — clean, no parse errors.
2. `godot --headless --path . --script res://tools/verify_anchors.gd` — anchors agree.
3. `godot --headless --path . -- --selftest` — prints `SELFTEST OK`, exits zero.
4. For anything visual: `--capture`, and **look at the screenshots**.
5. CI green on the pushed commit — checked before the claim, not when asked.

Statuses mean exactly this, and nothing looser:

- **Committed** — source exists in Git.
- **Built** — CI produced the artifact.
- **Self-tested** — the behavioural gate passed on that commit.
- **Looked at** — a human or a capture confirmed the picture.
- **Device-accepted** — played on the target Android hardware.

"It builds" is not any of these.

---

## When a change is proposed

Answer, in order:

1. Which North Star pillar does this serve?
2. Which law could it violate, and what stops it?
3. Does it change something in "Settled decisions"? If yes, stop and ask.
4. Does it move the player toward being the destroyer? If yes, refuse.
5. Can it be operated with a thumb, in landscape?
6. What check would fail if this regressed — and can that check actually fail?

If question 6 has no answer, the change is not ready.
