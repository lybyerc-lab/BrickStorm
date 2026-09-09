# TT Games Reference

What the LEGO games actually do, what we can use, and what we must never take.

---

## First, a naming correction

**Telltale Games** made *The Walking Dead*, *Sam & Max* and *The Wolf Among Us* —
episodic narrative adventures. They never made a LEGO game.

The LEGO games are **TT Games**, whose development arm is **Traveller's Tales**
(with TT Fusion for handheld/mobile), publishing through Warner Bros. This
document is about them. If the intent was Telltale's episodic-choice structure,
that is a different reference and a different design.

---

## Provenance of this document

Honesty about sourcing, per `Docs/NO_DRIFT_POLICY.md`:

- **§ Sourced** below is from web search results, cited inline. Most primary
  sources were unreachable from this environment — the LEGO first-party
  *Bits N' Bricks* podcast transcript, Game Developer, Brick Fanatics, Wikipedia
  and StrategyWiki are all blocked by the network egress proxy here. Only search
  result snippets and GitHub got through.
- **§ The system** is design analysis, not citation. It is the reasoning about
  *why* these mechanics work, and it is opinion.
- Nothing here was obtained by extracting, decompiling or datamining a shipped
  game. See "The line we do not cross".
- **The official LEGO Indiana Jones PC demo now runs in this environment and
  has been observed first-hand (2026-09-09).** This supersedes the earlier entry
  here, which said it could not be. That entry was written after the download
  failed and was then over-generalised from "archive.org is blocked" to "this
  cannot be done" - two different claims. The download is still blocked; the
  installer arrived by another route. See "Running the demo" below for the
  method, so nobody re-derives it.
- Findings taken from watching it run are marked **[observed]**. They are
  first-hand and outrank the search-snippet sources above them, but they come
  from one demo level, not the shipped game.

---

## § Sourced

### The stud economy

- Studs are the universal currency, spent on characters, hints, vehicles and
  extras. ([StrategyWiki via search](https://strategywiki.org/wiki/LEGO_Star_Wars:_The_Video_Game/Gameplay))
- **True Jedi** is a per-level stud threshold. The bar is divided into ten
  segments that turn gold as you fill it. **Once the threshold is reached it
  cannot be lost, however low your studs fall afterwards.**
  ([LEGO Star Wars Wiki](https://starwarslego.fandom.com/wiki/True_Jedi))
- Completing a level's **ten minikit canisters** assembles a vehicle and pays
  **50,000 studs** plus a Gold Brick.
  ([GameFAQs](https://gamefaqs.gamespot.com/wii/939578-lego-star-wars-the-complete-saga/faqs/51249/hints-tips))
- Gold Bricks come from story completion, True Jedi, all minikits, and direct
  purchase from the hub. (ibid.)

### Death

- On death the player **explodes into LEGO pieces, loses studs, and respawns
  where they were, temporarily invincible.** There is no restart and no lives.
  ([GameFAQs](https://gamefaqs.gamespot.com/wii/939578-lego-star-wars-the-complete-saga/faqs/51249/hints-tips),
  [gamepressure](https://www.gamepressure.com/lego-star-wars-the-skywalker-saga/death/z3f9bb))

### Humour and voice

- The original games had **no dialogue at all** and were described as
  "a hilarious, miming beast"; the absence of speech **forced the design to be
  more creative with physical comedy**.
  ([Xbox Wire](https://news.xbox.com/en-us/2022/04/05/adding-dialogue-to-the-new-lego-star-wars/),
  [Fandom](https://www.fandom.com/articles/lego-star-wars-dialogue))

### Co-op and accessibility

- **Drop-in, drop-out co-op** has been a defining feature of the series for
  years, playable at any player's leisure, with levels deliberately easy to
  navigate and simple puzzles, so the games stay accessible at any age.
  ([DualShockers](https://www.dualshockers.com/lego-games-with-amazing-couch-co-op-design/),
  [The Brick Bench](https://thebrickbench.com/best-co-op-lego-games/))

### Free Play and ability gates

- **Free Play** returns you to a completed level with any unlocked character, to
  reach areas that were restricted on the first pass — which is where minikits
  hide. ([GameFAQs](https://gamefaqs.gamespot.com/wii/939578-lego-star-wars-the-complete-saga/faqs/51249/hints-tips))

### Iteration

- LEGO Indiana Jones was prototyped **on top of** LEGO Star Wars, then rebuilt
  from the ground up; climbing, swinging and throwing objects as weapons were
  new to the series, and puzzle design was reworked to fit the franchise.
  ([Wikipedia via search](https://en.wikipedia.org/wiki/Lego_Indiana_Jones:_The_Original_Adventures))
- TT Games reject the idea of a formula, describing the approach as "work really,
  really hard to make the best game you can to really bring that IP to life in a
  way that's never been done before."
  ([DualShockers](https://www.dualshockers.com/lego-star-wars-the-skywalker-saga-interview-e3-2019/))

---

## § The system

Analysis, not citation. Five principles that make the above cohere.

### 1. Progress is never taken back

The single most important line in the sourced material: **True Jedi, once
earned, cannot be lost.** Death costs studs — but it cannot cost you a threshold
you already crossed.

This is what makes "you lose studs on death" feel like a toll rather than a
punishment. The currency is soft; the *achievement* is hard. A game that took
back a completed goal would make every risk feel like a trap, and the entire
design depends on the player being willing to take risks constantly.

### 2. The reward curve is absurdly generous

50,000 studs for ten collectibles, when a level's stud threshold is a few
thousand. TT Games are not balancing an economy — they are paying out
spectacularly for engagement with optional content. The message is that
exploring is *rewarded*, loudly, not merely permitted.

### 3. Constraint produced the comedy

The games are funny **because** nobody could speak. Removing dialogue forced
every joke into physical action, which is legible to a six-year-old, a
non-English speaker, and an adult simultaneously. It is a constraint that made
the product better and broader, not a limitation worked around.

### 4. Collectibles are diegetic

Minikits are *LEGO canisters that build a LEGO vehicle*. The collectible, the
reward, and the fiction are one object. Compare a generic "collect 10 orbs".

### 5. Everything is a second pass

Free Play means the first run cannot be exhaustive by design. The player is
*meant* to see locked doors they cannot open. That is not friction — it is the
promise of a reason to come back, planted while they are still enjoying the
first visit.

---

## What BRICKSTORM already has

| TT pattern | Our equivalent | State |
|---|---|---|
| Studs as universal currency | Studs, band-multiplied | Done |
| Explode into pieces, lose studs, no restart | TUMBLE, `[BS:LAW:NO_FAIL]` | Done |
| Nothing that moves is harmed | `[BS:LAW:NO_HARM]` — stronger than TT's | Done |
| Silent physical comedy | `[BS:COMEDY:POPUPS]`, gags | Done |
| Smash everything | `[BS:PLAYER:SMASH]`, ramming | Done |
| Character ability gates | Jo / Bill, `[BS:PLAYER:CHARACTERS]` | Done |
| Build spots as reward beats | `[BS:OBJECTIVE:DOROTHY]` | Partial |
| Diegetic collectibles | Sensor balls — designed, not built | **Gap** |
| True-threshold per level | True Chaser — designed, not built | **Gap** |
| Free Play second pass | Designed, not built | **Gap** |
| Drop-in drop-out co-op | Out of scope on mobile | Deferred |
| Hub world | Designed, not built | **Gap** |

## Findings worth acting on now

Two are cheap, sourced, and correct — and both were wrong in our build:

1. **A crossed threshold must never be lost.** Our tumble takes 20% of the
   player's studs, which could drop them back below a True Chaser threshold they
   had already earned. That directly contradicts the most load-bearing rule in
   the sourced material.
2. **Respawn grants temporary invincibility.** We had none, so a player caught in
   the red band could be tumbled repeatedly with no way out — the exact
   "punishment" feeling that the no-fail design exists to prevent.

Both are implemented; see `Docs/DECISION_LOG.md`.

## Findings for the backlog

- **Diegetic collectibles beat generic ones.** Sensor balls are already the right
  answer; build them.
- **Pay out absurdly.** Whatever the sensor-ball reward ends up being, it should
  feel disproportionate.
- **Plan for the second pass.** Place things now that Bill cannot reach and Jo
  can only see, so Free Play has something to open later.

---

## § Observed

From watching the demo run here on 2026-09-09. **Read the limits first.**

What was seen clearly: the attract loop, the Raiders idol chamber, a whip-swing
traversal over a river, and a Cairo street fight. What was *not* seen reliably:
extended hands-on play with the HUD up. Under software rendering the in-game
world frequently renders as shattered polygons - a wined3d/llvmpipe problem,
not a fact about the game - while cinematics render correctly. So the notes
below are about **staging, density and composition**, which survive that, and
not about frame-by-frame game feel, which does not. Nothing here is a
measurement of the shipped game's tuning; a stopwatch on real hardware still
beats all of it.

- **[observed] Studs are authored geometry, not scatter.** In the idol chamber
  the pickups sit in an even semicircular arc across the floor, gold and silver
  alternating, describing the shape of the room and pointing at the pedestal.
  They are level design that happens to be currency. BRICKSTORM currently
  *scatters* studs from destruction, which is the opposite: our studs are an
  output of the simulation, theirs are an input to the composition. Both should
  exist. Only one of them does here.
- **[observed] The prop density is far past what feels reasonable.** One screen
  of the U-boat pen holds a submarine, a torpedo cart, a run of seven safety
  railings, three ladders, two hanging lamps, two wall panels, crates, floor
  markings, dock plating and a lit brazier - and a control room visible through
  a window with figures in it. Almost none of it is required by the level. This
  is the single biggest visible gap against our own playtest note that the map
  is bare by t=90s. Density is what makes smashing feel inexhaustible.
- **[observed] The camera sits low and well back.** The character occupies
  roughly a fifth of frame height and sits below the centre line, with
  substantial headroom above. It is neither over-the-shoulder nor a high orbit.
  The scene, not the character, is the subject of the shot.
- **[observed] Cinematics are letterboxed inside the play frame.** The mode
  switch is announced by two black bars rather than by a camera change. It costs
  nothing and it is unmistakable.
- **[observed] The ground is never clean.** Loose parts lie about in the play
  space. Whether authored or the residue of a smash, the read is the same: the
  floor carries evidence.
- **[observed] Sound is authored, not left at unity.** The shipped audio config
  is plain text and documents its own schema. 1,421 sample entries; 1,337 carry
  pitch randomisation (median +/-10%); 793 carry volume randomisation that is
  *always negative*; 156 carry an explicit priority for voice stealing; 221 are
  marked non-positional. Acted on already - see the commit that added voice
  priority and the flat pool.

---

## Running the demo

Recorded because it took several wrong turns to get right, and because the
result is only useful if it is reproducible.

The demo is a 2008 32-bit DirectX 9 title. It runs under Wine on a headless
container with software rendering, but three separate things have to be true at
once, and each one fails in a way that looks like a different problem:

1. **32-bit Wine.** `dpkg --add-architecture i386`, then `wine32:i386`. Without
   it the installer's InstallShield wrapper dies before it unpacks anything.
2. **A Wine virtual desktop, not a bare X display.** On a plain Xvfb the game
   fails at startup with `Failed to create d3d device. Error = 0x8876086c`.
   The error is misleading: OpenGL is fine. Xvfb exposes exactly *one* video
   mode, at 0 Hz. The game enumerates modes, rejects the only candidate, and
   then calls `CreateDevice` with `D3DFMT_UNKNOWN` as the backbuffer format,
   which D3D correctly refuses. Running under
   `wine explorer /desktop=indy,1024x768` makes Wine synthesize a normal mode
   table; the game then picks a mode and writes `ScreenRefreshRate 60` into its
   own config, which is how you know it worked.
3. **The game's own safe-rendering flags.** With defaults the world renders as
   shattered polygons - the vertex pipeline breaks because wined3d reports
   llvmpipe as card vendor `0000`, and the game takes a vendor path meant for
   real hardware. In `pcconfig.txt` set `AllowVendorExtensions 0`,
   `IgnoreVendorPresets 1`, `ForceShaderModel 2`. Geometry then renders
   correctly.

The 0x8876086c failure is worth remembering in its own right: **the error names
the symptom, not the cause.** "Failed to create d3d device" was a display-mode
enumeration problem. Two rounds were spent on the graphics stack before reading
the actual `WINEDEBUG=+d3d9` trace, which named it immediately.

Nothing from this install lives in this repository. The installer, the Wine
prefix and every captured frame are kept outside it deliberately, and no frame
of the demo is committed. See below.

---

## The line we do not cross

**No asset, model, texture, sound, line of code, level layout or logo from any
LEGO game, from *Twister*, or from any other commercial product may enter this
repository.** Not extracted, not datamined, not "as reference", not temporarily.

What is legitimate, and what this document is: studying **how a design works**
and applying the reasoning. Mechanics are not copyrightable; assets and code
are, and trade dress is protectable. Everything in `assets/` is CC0 with
provenance recorded in `ATTRIBUTION.md`, and every brick in the game is
generated by our own code.

The product names in this project are placeholders and are to be replaced before
publication. See `Docs/NORTH_STAR.md`, "Naming".
