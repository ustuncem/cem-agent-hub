# cem-agent-hub

A centralized hub for AI agent skills and plugin bundles, following the [Agent Skills open standard](https://agentskills.io). Ships cross-platform `SKILL.md` files and Claude Code plugin marketplace metadata.

## What's here

- **`skills/`** — Cem's own skills, grouped by domain (`mobile/`, `engineering/`, `typescript/`, `react-native/`). Skills live under `skills/<domain>/<skill-name>/`. Also includes `placeholder-skill/` at the root as a scaffold to duplicate when authoring. **Cursor only scans one level deep**, so nested domain skills are not auto-discovered there yet — Claude Code and `npx skills add` scan recursively.
- **`vendor/`** — Third-party skills, vendored in full (not submodules). Each org gets its own `vendor/<org>/` folder, synced from upstream via `scripts/sync-vendor.sh`.
- **`plugins/`** — Curated bundles of own + vendor skills, packaged as installable Claude Code plugins. None exist yet — they'll be added once there are enough real skills to combine.

Vendored sources:

- [`mattpocock/skills`](https://github.com/mattpocock/skills) → `vendor/mattpocock/`
- [`software-mansion-labs/skills`](https://github.com/software-mansion-labs/skills) → `vendor/software-mansion-labs/`
- [`callstackincubator/agent-skills`](https://github.com/callstackincubator/agent-skills) → `vendor/callstackincubator/`
- [`vercel-labs/agent-skills`](https://github.com/vercel-labs/agent-skills) → `vendor/vercel-labs/`
- [`expo/skills`](https://github.com/expo/skills) → `vendor/expo/`

```
cem-agent-hub/
├── skills/                # Cem's own skills (by domain)
│   ├── placeholder-skill/
│   ├── mobile/
│   ├── engineering/
│   ├── typescript/
│   │   └── typescript-naming-interfaces/
│   └── react-native/
├── vendor/                # Vendored third-party skills
│   ├── mattpocock/
│   ├── software-mansion-labs/
│   ├── callstackincubator/
│   ├── vercel-labs/
│   ├── expo/
│   └── margelo/
├── plugins/                # Plugin bundles (empty for now)
├── .claude-plugin/         # Claude Code marketplace definition
├── .agents/plugins/        # Codex-compatible marketplace definition
├── .cursor/rules/          # Cursor import entrypoint
└── scripts/                # sync-vendor.sh, validate.sh
```

## Installation

### Plugin bundles (Claude Code)

Not available yet — no bundles have been created. Once bundles exist:

```
/plugin marketplace add <username>/cem-agent-hub
/plugin install <bundle-name>@<username>/cem-agent-hub
```

### Individual skills (cross-platform, via skills.sh)

```bash
npx skills add <username>/cem-agent-hub
npx skills add <username>/cem-agent-hub --skill placeholder-skill -a claude-code
```

### Manual

```bash
git clone https://github.com/<username>/cem-agent-hub.git
cp -r cem-agent-hub/skills/placeholder-skill ~/.claude/skills/
```

## Authoring a skill

Duplicate `skills/placeholder-skill/`, place it under the right domain folder (`skills/<domain>/<skill-name>/`), and update the `SKILL.md` frontmatter (`name` must match the new folder name) and body. See `CLAUDE.md` for the full authoring checklist.

## Vendor sync

```bash
bash scripts/sync-vendor.sh            # sync all configured vendor targets
bash scripts/sync-vendor.sh --force    # overwrite existing vendor copies
```

Targets are configured in `scripts/sync-vendor.sh`. Each upstream's skills directory is copied into `vendor/<org>/` (default `skills/`; Expo uses `plugins/expo/skills/`). See `vendor/README.md` for details.

## Validation

```bash
bash scripts/validate.sh
```

Validates every `SKILL.md` under `skills/` and `vendor/` against the agentskills.io spec (via `npx skills-ref validate` if available, otherwise a basic frontmatter check).

## Organizing skills into domains

Own skills are grouped under domain subfolders: `mobile/`, `engineering/`, `typescript/`, `react-native/`. Example: `skills/typescript/typescript-naming-interfaces/SKILL.md`. This works natively on Claude Code, Hermes, and `npx skills add` (recursive scan). **Cursor only scans one level deep**, so nested skills may need to be symlinked or copied flat for Cursor to discover them. Skill names must remain globally unique regardless of which folder they sit in, since the `name` field has no namespace.

## License

MIT — see [LICENSE](LICENSE).
