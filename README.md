# BrickStorm

Shared development repository for the BrickStorm project.

> **Creative identity:** the game is **LEGO: Twister**. `BrickStorm` is the development codename.

## Read Before Coding

Any contributor or agent working on the OpenAI implementation should read these first:

1. [`PROJECT_MEMORY.md`](PROJECT_MEMORY.md) — durable project decisions, approved controls, current direction, and release discipline.
2. [`docs/NORTH_STAR.md`](docs/NORTH_STAR.md) — the creative and gameplay target for LEGO: Twister.
3. [`docs/NO_DRIFT_POLICY.md`](docs/NO_DRIFT_POLICY.md) — rules that prevent the project from becoming a generic brick game, generic storm simulator, or unrelated tech demo.

A technically impressive change that violates these documents is not considered an improvement.

## Branch Ownership

- `openai/brickstorm`: OpenAI/ChatGPT implementation line.
- `openai/construction-library`: OpenAI construction-library feature work.
- Other implementations should use their own branch namespaces and should not commit directly to `openai/*` branches.

`main` is intentionally kept neutral so independent implementations can coexist without overwriting one another.

## Branch Rule

OpenAI work must not modify, merge, rewrite, or cherry-pick another implementation's branches unless the user explicitly requests comparison or integration.