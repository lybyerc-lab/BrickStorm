# OpenAI BrickStorm Workstream

This branch is owned by the ChatGPT/OpenAI implementation of BrickStorm.

## Branch policy

- Active branch: `openai/brickstorm`
- Do not commit Claude or other independent implementations to this branch.
- Do not merge this branch into `main` without explicit project-owner approval.
- Treat `main` as a neutral coordination point while independent versions coexist.

## Current baseline

The gameplay baseline is BrickStorm 0.3.0, the phone-tested build that includes truck heading controls, flat road crossing, rideable/chargeable cow gameplay, denser farm destruction, and four buildables.

## Current development focus

The next major system is the reusable construction library for the traditional interlocking-brick action-adventure visual language. The library is original procedural geometry and does not include extracted commercial models, textures, logos, code, or level assets.

## Release discipline

Changes are expected to pass the Godot 4.7.2 engine gate before being treated as a release candidate.
