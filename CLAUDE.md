# CLAUDE.md

This file gives Claude Code project-level context for `cem-agent-hub`.

## What this repo is

`cem-agent-hub` is a monorepo hub for AI agent skills and plugin bundles, following the [Agent Skills open standard](https://agentskills.io). Canonical content is `SKILL.md`. Skill-capable hosts install via `npx skills add`; Claude Code / Codex can also add this repo as a plugin marketplace for curated bundles:

```
/plugin marketplace add <username>/cem-agent-hub
```

## Structure

```
cem-agent-hub/
├── skills/              Cem's own skills (by domain)
│   ├── placeholder-skill/
│   ├── mobile/
│   ├── engineering/
│   ├── typescript/
│   └── react-native/
├── vendor/              Vendored copies of third-party skill repos
├── plugins/             Plugin bundles combining own + vendor skills
├── adapters/            Canonical instruction-tier discovery text
├── docs/agent-portability.md
├── AGENTS.md            Generated discovery instructions
├── .claude-plugin/      Claude Code marketplace definition
├── .agents/plugins/     Codex-compatible marketplace definition
├── .cursor/rules/       Generated Cursor discovery rule
└── scripts/             sync-vendor.sh, sync-adapters.sh, validate.sh
```

Three layers, built up in order:

1. **Own skills** (`skills/`) — grouped by domain (`mobile/`, `engineering/`, `typescript/`, `react-native/`). Skills live at `skills/<domain>/<skill-name>/`. `skills/placeholder-skill/` remains the scaffold to duplicate when authoring.
2. **Vendor skills** (`vendor/`) — third-party skills vendored in full (not submodules). Each upstream maps to `vendor/<org>/` via `scripts/sync-vendor.sh`. See `vendor/README.md` for the current list.
3. **Plugin bundles** (`plugins/`) — curated combinations of own + vendor skills packaged as installable Claude Code plugins. None exist yet; they get created once there are enough real skills to combine.
4. **Instruction-tier adapters** — generated from `adapters/skill-discovery.md` into `AGENTS.md` and host rule files. See `docs/agent-portability.md`. Do not duplicate skill bodies into those files.

Consumers on skill-capable hosts install with `npx skills add` (70+ agents). Claude Code / Codex marketplaces stay for curated bundles only.

## Working with skills

Every skill is a directory containing at minimum a `SKILL.md` with YAML frontmatter (`name`, `description`) plus a Markdown body of instructions. Recommended: `agents/openai.yaml` for Codex. Optional: `scripts/`, `references/`, `assets/`.

Key rules:

- `name` must match the **immediate parent directory name**, be lowercase letters/numbers/hyphens only, max 64 chars, no leading/trailing/consecutive hyphens.
- `description` describes what the skill does AND when to use it — this is what agents scan at startup to decide activation. Max 1024 chars. For user-invoked skills it is a short human summary instead.
- Skill names must stay globally unique across the whole repo, even across domain-grouping subfolders (the `name` field has no namespace).
- Keep the SKILL.md body under ~5000 tokens; move overflow into `references/`.
- Domain folders are `mobile/`, `engineering/`, `typescript/`, and `react-native/`. Place each skill under the matching domain: `skills/<domain>/<skill-name>/`.
- Ship `agents/openai.yaml` with at least `interface.display_name` and `interface.short_description`.

### Invocation (model vs user)

Every skill chooses how it is reached. Keep Claude Code and Codex aligned:

| Mode              | Claude Code (`SKILL.md`)         | Codex (`agents/openai.yaml`)                | `description`                          |
| ----------------- | -------------------------------- | ------------------------------------------- | -------------------------------------- |
| **Model-invoked** | omit `disable-model-invocation`  | omit `policy` (implicit invocation allowed) | model-facing; include trigger branches |
| **User-invoked**  | `disable-model-invocation: true` | `policy.allow_implicit_invocation: false`   | short human summary; no trigger list   |

Pick model-invocation when the agent (or another skill) must reach it on its own. Pick user-invocation when it should only run when someone types its name.

Minimal Codex metadata for every skill:

```yaml
interface:
  display_name: "Human Title"
  short_description: "One-line summary"
```

## Authoring a new skill

1. Duplicate `skills/placeholder-skill/` into the right domain folder and rename it (`skills/<domain>/<skill-name>/`).
2. Update the `name` field in `SKILL.md` to match the new folder name exactly.
3. Choose model- vs user-invoked and set `disable-model-invocation` / `agents/openai.yaml` accordingly.
4. Write a `description` that matches the invocation mode (triggers for model-invoked; short summary for user-invoked).
5. Replace the body with real instructions: overview → when to use → numbered steps → examples.
6. Run `bash scripts/validate.sh` before committing.
7. Do not add per-host copies of the new skill. If discovery text changes, edit `adapters/skill-discovery.md` and run `bash scripts/sync-adapters.sh`.

## Vendor sync

`scripts/sync-vendor.sh` clones upstream skill repos (shallow) and copies their skills directory into `vendor/<org>/` (default `skills/`; Expo uses `plugins/expo/skills/`), recording the synced commit SHA in `vendor/VERSIONS.txt`. Run with `--force` to re-sync unconditionally. Add new targets as additional entries in that script, each with its own `vendor/<org>/` subfolder. Never hand-edit vendor content directly.

## Plugin bundles

Once real skills exist, create a `plugin.json` per bundle under `plugins/<bundle-name>/`, listing relative paths to the own/vendor skills it includes, and add a matching entry to `.claude-plugin/marketplace.json` (and mirror it in `.agents/plugins/marketplace.json`) with `strict: false`. Plugin/bundle names must be kebab-case.

## Validation

Before committing changes to skills or vendor content:

```bash
bash scripts/validate.sh
```

This first checks that generated instruction-tier adapters match `adapters/skill-discovery.md`, then runs `npx skills-ref validate` if available, otherwise a basic frontmatter check (SKILL.md exists, has `name`/`description`, name matches directory, formats are within spec).
