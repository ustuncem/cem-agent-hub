<!-- Generated from adapters/skill-discovery.md by scripts/sync-adapters.sh. Do not edit. -->

This repo is `cem-agent-hub`, a hub of Agent Skills following the [agentskills.io](https://agentskills.io) standard.

- Own skills live under `skills/<domain>/<skill-name>/SKILL.md` (domains: `mobile`, `engineering`, `typescript`, `react-native`). `skills/placeholder-skill/` is a scaffold, not a real skill.
- Vendored third-party skills live under `vendor/<org>/<skill-name>/SKILL.md`.
- Many hosts scan skill directories only one level deep. Nested domain skills in this checkout are not auto-discovered unless the host walks recursively, the skill is installed flat (for example via `npx skills add`), or this instruction is followed.
- Skills may be model-invoked (default) or user-invoked (`disable-model-invocation: true` in `SKILL.md`, mirrored as `policy.allow_implicit_invocation: false` in `agents/openai.yaml`).

When a task matches a skill's `description`, read that `SKILL.md` (and any `references/` files it points to) before acting. User-invoked skills are only for when the user explicitly names them.

Do not paste every skill body into context. Load only the skill that matches the task.
