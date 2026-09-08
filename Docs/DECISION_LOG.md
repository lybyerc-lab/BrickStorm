# Decision Log

Append-only. Newest first. A decision that is not written here did not happen.

Entries record what changed, who decided, why, and **what it supersedes** — so a
future reader can tell a deliberate reversal from drift.

---

## 2026-09-08 — Three action buttons, drivable vehicles, and comedy as a pillar

**Decided by:** director
**Supersedes:** North Star pillar 6 (single context button), the inversion
statement's treatment of player destruction, and `Docs/GAME_CONCEPT.md` §11
open question 1 (vehicles).

### The decision

1. **Vehicles are drivable.** Not scripted, not on-rails. You get in, you steer,
   you drive through a barn.
2. **Three action buttons: SMASH, BUILD, JUMP.** Replacing the single context
   button.
3. **Smashing everything, and the humour, are pillars** — the director's words:
   "the best part of the Lego games is smashing everything and the humor. we
   need to emulate those as much as possible."

### Why this was raised as a conflict first

The North Star, committed hours earlier, said the player "is never promoted back
to primary agent of destruction", that there is exactly one action button, and
that Bill's smash "must never grow into" a destruction model. The policy says
changes to the North Star require explicit director approval and never arrive as
a side effect of implementation. This is that approval, recorded rather than
silently applied.

### How the inversion survives

The inversion did not have to die to satisfy this.

- **Player smash** is ungated, always available, and pays at the player's
  current band — which, away from the funnel, is ×1.
- **Funnel debris** pays ×2 to ×5.

So the player smashes everything constantly, and the risk economy is untouched:
the multiplier is still the reason to go near the storm. What changed is that
destruction is no longer *only* the storm's job. What did not change is that the
storm is still where the money is.

The inversion statement in the North Star has been rewritten to say this
directly rather than being deleted.

### What was built

- `scripts/vehicle.gd` — arcade handling where the stick is a heading, not a
  wheel; ramming tears scenery with force scaled by speed; boarding syncs the
  driver's position so risk band, wind, magnet and camera all keep working
  unchanged, and driving into the red band pays exactly like walking into it.
- `scripts/comedy.gd` — floating comic-book onomatopoeia at the point of impact,
  plus the running gags: cows moo when the funnel throws them, and the outhouse
  has an occupant.
- Three buttons in `scripts/hud.gd`. SMASH and JUMP never change meaning; only
  BUILD is contextual (BUILD / GRAB / DEPLOY / DRIVE / EXIT).
- **BRACE became automatic** — release the stick in high wind and the player
  digs in. The button budget was spent on SMASH/BUILD/JUMP, and this removes a
  control rather than adding a fourth.

### Verification

The self-test was extended to cover the new systems rather than left to cover
only the old ones. It now asserts the truck moves under throttle, that ramming
tears bricks, that player smash tears bricks, and that JUMP leaves the ground —
each able to fail independently.

It did fail on first run: `JUMP did not leave the ground`. The cause was the
test, not the code — a lingering tumble from the preceding smash phase was
refusing the jump, making the assert order-dependent. Fixed by parking the
funnel and clearing the tumble before the jump phase. Recorded because "the gate
caught something and it turned out to be the gate's fault" is exactly the kind
of event that gets quietly deleted from history.

Measured on the commit that landed this: drove 13.6m, ram tore 128 bricks,
player smash tore 30, funnel tore 262, 2,308 studs banked.
