# BrickStorm Construction Library

> **Creative identity:** the game is **LEGO: Twister**. `BrickStorm` is only the development codename.

This branch develops the reusable brick-construction grammar for the OpenAI/ChatGPT implementation.

## Read Before Coding

Read these before adding primitives, modules, assemblies, destruction states, or build systems:

1. [`PROJECT_MEMORY.md`](PROJECT_MEMORY.md) — durable project memory and approved decisions.
2. [`docs/NORTH_STAR.md`](docs/NORTH_STAR.md) — LEGO: Twister creative target.
3. [`docs/NO_DRIFT_POLICY.md`](docs/NO_DRIFT_POLICY.md) — hard guardrails against generic brick-library or generic storm-game drift.

A technically elegant construction feature that does not help author LEGO: Twister content is not automatically useful.

## Branch Ownership

- `openai/brickstorm`: OpenAI/ChatGPT implementation line.
- `openai/construction-library`: this OpenAI feature branch.
- Other implementations, including Claude, stay on their own branch namespaces.

Do not modify, merge, rewrite, or cherry-pick another implementation's branch without explicit user instruction.