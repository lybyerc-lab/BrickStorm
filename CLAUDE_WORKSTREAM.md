# Claude BrickStorm Workstream

This branch is owned by the Claude implementation of BrickStorm.

## Branch policy

Mirrors the convention established on `main` and in `OPENAI_WORKSTREAM.md`:

- Active branch: `claude/lego-twister-mobile-game-3a8ypy`
- Do not commit OpenAI or other independent implementations to this branch.
- Do not merge this branch into `main` without explicit project-owner approval.
- `main` stays neutral so the independent versions can coexist.

This branch has not been merged anywhere and does not touch `openai/*`.

## Engine gate

Godot **4.7.2**, matching the OpenAI workstream so both implementations share a
baseline. The project was authored against 4.6 and verified to import and pass
`--selftest` unchanged on 4.7.2.

Renderer is `gl_compatibility` for both mobile and web: it is the fastest path on
low-end Android and the only one that works in a browser without cross-origin
isolation headers.

## Verification standard

Nothing here is described as working on the strength of it compiling.

- `godot --headless --path . -- --selftest` drives the funnel onto the barn and
  steps real physics frames, then asserts that bricks were actually torn and that
  destruction produced studs and score. It exits non-zero if not.
- `--capture` runs an autopilot and writes real screenshots; everything in
  `Docs/shots/` is a capture from a run, not concept art.
- CI runs the self-test as a gate before it will export anything.

## Current state

A playable vertical slice — see `README.md` for what is in it and what is not.
The full campaign design is `Docs/GAME_CONCEPT.md`.

## Asset policy

All geometry is original procedural code. No extracted commercial models,
textures, logos, code, or level assets. Product and character names are
placeholders for an unlicensed design exercise and are to be replaced before any
publication.
