# cem-agent-hub

A centralized hub for AI agent skills and plugin bundles, following the [Agent Skills open standard](https://agentskills.io). Ships cross-platform `SKILL.md` files, Claude Code / Codex plugin marketplace metadata, and thin instruction-tier adapters so agents working in this checkout can find skills.

## What's here

- **`skills/`** — Cem's own skills, grouped by domain (`mobile/`, `engineering/`, `typescript/`, `react-native/`). Skills live under `skills/<domain>/<skill-name>/`. Also includes `placeholder-skill/` at the root as a scaffold to duplicate when authoring. `npx skills add` discovers this tree; instruction-tier adapters cover nested discovery in this checkout.
- **`vendor/`** — Third-party skills, vendored in full (not submodules). Each org gets its own `vendor/<org>/` folder, synced from upstream via `scripts/sync-vendor.sh`.
- **`plugins/`** — Curated bundles of own + vendor skills, packaged as installable Claude Code plugins. None exist yet — they'll be added once there are enough real skills to combine.
- **`adapters/`** — Canonical instruction-tier discovery text. Generated copies live in `AGENTS.md` and host rule folders. See [Agent portability](docs/agent-portability.md).

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
│   └── react-native/
├── vendor/                # Vendored third-party skills
├── plugins/               # Plugin bundles (empty for now)
├── adapters/              # Canonical instruction-tier text (do not copy per skill)
├── docs/agent-portability.md
├── AGENTS.md              # Generated: Amp, Jules, Zed, Aider, …
├── .claude-plugin/        # Claude Code marketplace definition
├── .agents/plugins/       # Codex-compatible marketplace definition
├── .cursor/rules/         # Generated Cursor discovery rule
└── scripts/               # sync-vendor.sh, sync-adapters.sh, validate.sh
```

## Installation

This is a **skill hub**, not a single always-on ruleset. Canonical content stays in `SKILL.md`. Hosts that speak Agent Skills install those files; hosts that only read project instructions get a short generated pointer (see [Agent portability](docs/agent-portability.md)).

### Individual skills (70+ hosts, via skills.sh)

```bash
npx skills add <username>/cem-agent-hub
npx skills add <username>/cem-agent-hub --skill interfaces-vs-types -a cursor -a claude-code
npx skills add <username>/cem-agent-hub -a '*'
npx skills add <username>/cem-agent-hub --full-depth    # include vendor/ skills
```

`--agent` names and install paths: [vercel-labs/skills](https://github.com/vercel-labs/skills#supported-agents) (Claude Code, Codex, Cursor, Copilot, Gemini CLI, OpenCode, Windsurf, Cline, Grok, Devin, Pi, Hermes, Qoder, OpenClaw, Antigravity, Amp, Zed, Junie, and others).

### Plugin bundles (Claude Code / Codex)

Not available yet — no bundles have been created. Once bundles exist:

```
/plugin marketplace add <username>/cem-agent-hub
/plugin install <bundle-name>@<username>/cem-agent-hub
```

Codex: `codex plugin marketplace add <username>/cem-agent-hub` then install the same bundle from `.agents/plugins/marketplace.json`.

### This checkout (instruction-tier)

Clone the repo. `AGENTS.md` and the generated files under `.cursor/rules/`, `.windsurf/rules/`, `.clinerules/`, `.github/copilot-instructions.md`, `.kiro/steering/`, `.qoder/rules/`, and `.junie/guidelines.md` tell the agent where skills live. Do not copy skill bodies into those files.

```bash
bash scripts/sync-adapters.sh    # regenerate after editing adapters/skill-discovery.md
```

### Manual (single skill)

```bash
git clone https://github.com/<username>/cem-agent-hub.git
cp -r cem-agent-hub/skills/placeholder-skill ~/.claude/skills/
```

## Authoring a skill

Duplicate `skills/placeholder-skill/`, place it under the right domain folder (`skills/<domain>/<skill-name>/`), and update the `SKILL.md` frontmatter (`name` must match the new folder name) and body. See `CLAUDE.md` for the full authoring checklist. Do not add per-host copies of the skill; instruction-tier adapters are generated from `adapters/skill-discovery.md`.

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

Checks that generated instruction-tier adapters match `adapters/skill-discovery.md`, then validates every `SKILL.md` under `skills/` and `vendor/` against the agentskills.io spec (via `npx skills-ref validate` if available, otherwise a basic frontmatter check).

## Organizing skills into domains

Own skills are grouped under domain subfolders: `mobile/`, `engineering/`, `typescript/`, `react-native/`. Example: `skills/typescript/interfaces-vs-types/SKILL.md`. `npx skills add` walks `skills/` up to three levels, so nested own skills install correctly. Cursor's built-in scan of this checkout is still one level deep — the generated `.cursor/rules/` file tells the agent to read nested `SKILL.md` files instead of flattening the tree. Skill names must remain globally unique regardless of which folder they sit in, since the `name` field has no namespace.

## License

MIT — see [LICENSE](LICENSE).
