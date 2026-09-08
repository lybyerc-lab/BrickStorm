# Attribution and Asset Provenance

Every third-party asset in this repository, where it came from, and under what
licence. Nothing ships here without an entry.

## Standing rule

**No asset extracted from a commercial game may ever enter this repository** —
no models, textures, audio, logos, code, or level data from the LEGO games, from
*Twister*, or from anything else. Not as reference, not "temporarily", not in a
branch. Everything here is either original work or carries an explicit
permissive licence recorded below.

This is the one rule that, broken once, makes the whole project unshippable.

## Audio

**Source:** [`lavenderdotpet/CC0-Public-Domain-Sounds`](https://github.com/lavenderdotpet/CC0-Public-Domain-Sounds)
**Licence:** CC0 1.0 Universal (public domain dedication) — no attribution
required, commercial use permitted, modification permitted.

Attribution is given here anyway, because knowing where a file came from is
worth more than the licence requires.

### Kenney (`kenney.nl`) — CC0 1.0

Originally published by Kenney as free CC0 game-asset packs.

| File(s) | Kenney pack | Used for |
|---|---|---|
| `impactWood_light_000`, `impactWood_medium_000`, `impactWood_heavy_000` | Impact Sounds | player SMASH on scenery |
| `impactPlate_heavy_000`, `impactMining_000` | Impact Sounds | heavy structural collapse |
| `impactMetal_heavy_000`, `impactPunch_heavy_000` | Impact Sounds | vehicle ramming |
| `impactGlass_light_000` | Impact Sounds | windows and glass |
| `impactSoft_heavy_000`, `impactBell_heavy_000` | Impact Sounds | minifig tumble |
| `click1` | UI Audio | stud pickup |
| `pepSound1`, `powerUp1`, `highUp`, `lowDown` | Digital Audio | pickups, jump, deploy, tumble |
| `jingles_STEEL00`, `jingles_HIT00` | Music Jingles | build-complete and objective stings |

### Loop bed — CC0 1.0

| File | Used for |
|---|---|
| `noise_01` | tornado roar bed, filtered and driven by proximity |
| `ambient_01` | wind bed |
| `machine_01` | vehicle engine loop, pitched by speed |
| `rolling` | debris rumble |

## Known gap

**No cow.** The source collection's animal folders contain growls and generic
creature voices, nothing bovine. Rather than pass a growl off as a moo, the cow
gag currently plays only its on-screen `MOO!` popup. A genuine CC0 cattle
recording is on the backlog.

Recorded because substituting the nearest-sounding file and calling it done is
exactly the kind of small dishonesty that accumulates into an asset library
nobody trusts.

## Verification

`--selftest` asserts every declared sound file exists, loads as a real audio
stream, and reports a non-zero length. It exits non-zero otherwise, so a missing
or corrupt asset fails the build rather than silently playing nothing.

**What that cannot check:** whether a sound is *the right sound*. These files
were chosen by name and category from a text listing — they have not been
listened to by their selector. A human ear is the final authority on whether
`noise_01` reads as a tornado, exactly as the physical device is the final
authority on touch. See `Docs/NO_DRIFT_POLICY.md`.
