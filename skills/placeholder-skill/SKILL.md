---
name: placeholder-skill
description: >
  Placeholder skill scaffold for cem-agent-hub. Not yet a real skill —
  use this folder structure as the template when authoring new skills.
---

# Placeholder Skill

This is a scaffold, not a functioning skill. Duplicate this folder and rename it when creating a new skill.

## Structure

- `SKILL.md` (required) — metadata + instructions
- `agents/openai.yaml` (recommended) — Codex display name + invocation policy
- `scripts/` (optional) — executable code the agent can run
- `references/` (optional) — additional docs loaded on demand, keep one level deep
- `assets/` (optional) — templates, images, resources

Do not add Cursor/Windsurf/Copilot/Gemini copies of this skill. Host adapters are generated from `adapters/skill-discovery.md`; consumers install `SKILL.md` via `npx skills add`.

## Invocation

Pick one and keep Claude Code + Codex in sync:

**Model-invoked** (default) — agent can fire it from the description; other skills can reach it.

- Omit `disable-model-invocation` in `SKILL.md`.
- Write a model-facing `description` with trigger branches ("Use when…").
- In `agents/openai.yaml`, ship only `interface` (no `policy` block), matching this scaffold.

**User-invoked** — only the human typing the skill name can fire it.

- Set `disable-model-invocation: true` in `SKILL.md`.
- Keep `description` a short human summary (no trigger list).
- In `agents/openai.yaml`, add:

```yaml
policy:
  allow_implicit_invocation: false
```

Use model-invocation when the agent (or another skill) must reach it on its own. Use user-invocation when it should only run by hand.

## When to use

Not applicable — replace this section with real trigger conditions when authoring an actual skill.
