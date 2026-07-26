# CLAUDE.md

This file gives Claude Code project-level context for `cem-agent-hub`.

## What this repo is

`cem-agent-hub` is a monorepo hub for AI agent skills and plugin bundles, following the [Agent Skills open standard](https://agentskills.io). It ships cross-platform `SKILL.md` files plus Claude Code plugin marketplace metadata, and can be added directly as a plugin marketplace:

```
/plugin marketplace add <username>/cem-agent-hub
```

## Structure

```
cem-agent-hub/
├── skills/              Cem's own skills (agentskills.io format)
├── vendor/              Vendored copies of third-party skill repos
├── plugins/             Plugin bundles combining own + vendor skills
├── .claude-plugin/      Claude Code marketplace definition
├── .agents/plugins/     Codex-compatible marketplace definition
├── .cursor/rules/       Cursor rule that points at skills/
└── scripts/             sync-vendor.sh, validate.sh
```

Three layers, built up in order:

1. **Own skills** (`skills/`) — currently just `skills/placeholder-skill/`, a scaffold to duplicate when authoring a real skill. Not a functioning skill itself.
2. **Vendor skills** (`vendor/`) — third-party skills vendored in full (not submodules). Each upstream maps to `vendor/<org>/` via `scripts/sync-vendor.sh`. See `vendor/README.md` for the current list.
3. **Plugin bundles** (`plugins/`) — curated combinations of own + vendor skills packaged as installable Claude Code plugins. None exist yet; they get created once there are enough real skills to combine.

## Working with skills

Every skill is a directory containing at minimum a `SKILL.md` with YAML frontmatter (`name`, `description`) plus a Markdown body of instructions. Optional subdirectories: `scripts/`, `references/`, `assets/`.

Key rules:

- `name` must match the **immediate parent directory name**, be lowercase letters/numbers/hyphens only, max 64 chars, no leading/trailing/consecutive hyphens.
- `description` describes what the skill does AND when to use it — this is what agents scan at startup to decide activation. Max 1024 chars.
- Skill names must stay globally unique across the whole repo, even across domain-grouping subfolders (the `name` field has no namespace).
- Keep the SKILL.md body under ~5000 tokens; move overflow into `references/`.
- Do not create domain-grouping folders (`backend/`, `mobile/`, `shared/`) until there are enough skills to justify it.

## Authoring a new skill

1. Duplicate `skills/placeholder-skill/` and rename the folder.
2. Update the `name` field in `SKILL.md` to match the new folder name exactly.
3. Write a specific `description` covering what the skill does and when to use it.
4. Replace the body with real instructions: overview → when to use → numbered steps → examples.
5. Run `bash scripts/validate.sh` before committing.

## Vendor sync

`scripts/sync-vendor.sh` clones upstream skill repos (shallow) and copies their skills directory into `vendor/<org>/` (default `skills/`; Expo uses `plugins/expo/skills/`), recording the synced commit SHA in `vendor/VERSIONS.txt`. Run with `--force` to re-sync unconditionally. Add new targets as additional entries in that script, each with its own `vendor/<org>/` subfolder. Never hand-edit vendor content directly.

## Plugin bundles

Once real skills exist, create a `plugin.json` per bundle under `plugins/<bundle-name>/`, listing relative paths to the own/vendor skills it includes, and add a matching entry to `.claude-plugin/marketplace.json` (and mirror it in `.agents/plugins/marketplace.json`) with `strict: false`. Plugin/bundle names must be kebab-case.

## Validation

Before committing changes to skills or vendor content:

```bash
bash scripts/validate.sh
```

This runs `npx skills-ref validate` if available, otherwise falls back to a basic frontmatter check (SKILL.md exists, has `name`/`description`, name matches directory, formats are within spec).
