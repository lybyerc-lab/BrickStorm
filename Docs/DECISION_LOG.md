# Decision Log

Append-only. Newest first. A decision that is not written here did not happen.

Entries record what changed, who decided, why, and **what it supersedes** — so a
future reader can tell a deliberate reversal from drift.

---

## 2026-09-08 — Audio from CC0 sources, and TT Games research applied

**Decided by:** director ("work on the audio also, but let's not invent what we
can find available open source"; "gather any info or source information from the
telltale games")
**Supersedes:** nothing. Fills the gap named as the top priority in the previous
session summary.

### Naming

The director said Telltale; the LEGO games are TT Games / Traveller's Tales.
Telltale made *The Walking Dead* and never made a LEGO game. Researched TT Games
and flagged the distinction rather than guessing.
See `Docs/TT_GAMES_REFERENCE.md`.

### Audio: found, not invented

All 21 sounds are CC0 1.0, sourced from `lavenderdotpet/CC0-Public-Domain-Sounds`
(largely Kenney's CC0 packs), with full provenance in `ATTRIBUTION.md`. Nothing
synthesised, nothing from a commercial game.

The network egress proxy blocks opengameart, kenney.nl, freesound, archive.org
and every general web host; only `raw.githubusercontent.com` with an explicit
file path was reachable, so the search was for CC0 audio mirrored into a public
GitHub repository.

`scripts/audio.gd` names events by what happened rather than by file, so a sound
can be swapped without touching a caller. The funnel's roar is the primary risk
signal - readable with the screen ignored, which matters because the whole game
is about proximity and the player's eyes are busy looting. Stud pickups climb a
pitch ladder through a streak and reset after a pause, which is a TT Games
signature and the reward loop's whole voice.

**No cow.** The source collection's animal folders hold growls, nothing bovine.
Rather than pass a growl off as a moo, the cow gag keeps only its on-screen
popup and the gap is recorded in `ATTRIBUTION.md`.

### A check that could not fail

The audio assertion was written to load every declared stream and check its
length. Removing a source `.ogg` and re-running it still passed.

`load()` resolves out of `.godot/imported/`, so a deleted source file still
"loads" from a stale import cache. The assertion was testing the cache, not the
shipped asset - precisely the failure mode `Docs/NO_DRIFT_POLICY.md` warns about,
committed by the person who wrote that warning.

Fixed to check `FileAccess.file_exists` on the source path as well as the loaded
stream, and re-verified by hiding a file and confirming a non-zero exit.

### Two TT Games findings, implemented

Both were sourced, both were wrong in our build:

1. **A crossed threshold is never taken back.** In LEGO Star Wars, True Jedi
   cannot be lost however low your studs fall afterwards. Our tumble takes 20%
   of the player's studs and could therefore have dropped them back below a
   TRUE CHASER threshold they had already earned. Now latched
   (`[BS:ECONOMY:THRESHOLD_LOCK]`). This is the load-bearing rule behind the
   whole risk economy: the currency is soft, the achievement is hard, and that
   is what keeps players willing to take risks.
2. **Respawn grants temporary invincibility.** We had none, so a player caught
   in the red band could be tumbled repeatedly with no way out - the exact
   punishment the no-fail design exists to prevent. Now a three-second flickering
   grace period after every tumble.

Both are asserted in `--selftest`, each able to fail independently.

### Verification

Import clean, ANCHORS OK 51/51, SELFTEST OK - 21 sounds present and non-empty,
drove 13.6m, ram tore 128 bricks, smash tore 30, funnel tore 272 - captures
re-taken and inspected.

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
