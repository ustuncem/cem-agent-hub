# Agent portability

This hub is a **catalog of many skills**, not a single always-on ruleset. Host support is therefore different from products like [ponytail](https://github.com/DietrichGebert/ponytail), which copy the same compact rule text into every agent's config.

Canonical skill content is always `SKILL.md` (plus optional `references/`, `scripts/`, `assets/`, and Codex `agents/openai.yaml`). Host files are thin adapters. Never duplicate a skill body into `.cursor/rules/`, `AGENTS.md`, or similar.

## Two jobs

| Job                                   | What we ship                                                                                                                               | What we do not ship                                                        |
| ------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------ | -------------------------------------------------------------------------- |
| **Consume skills in another project** | Valid `SKILL.md` trees under `skills/` and `vendor/`. Install with `npx skills add`. Claude/Codex plugin marketplaces for curated bundles. | Per-host plugin hooks, slash commands, or always-on copies of every skill. |
| **Work inside this checkout**         | Generated instruction-tier files that tell the agent where skills live and to load only the matching one.                                  | Pasting all skill instructions into context.                               |

## Consume: skill-capable hosts

[npx skills add](https://github.com/vercel-labs/skills) already installs Agent Skills into **70+** hosts (Claude Code, Codex, Cursor, Copilot, Gemini CLI, OpenCode, Windsurf, Cline, Grok, Devin, Pi, Hermes, Qoder, OpenClaw, Antigravity, Amp, Zed, Junie, and many more). That is the plugin-tier path for this repo.

```bash
npx skills add <username>/cem-agent-hub
npx skills add <username>/cem-agent-hub --skill interfaces-vs-types -a cursor -a claude-code
npx skills add <username>/cem-agent-hub -a '*'          # every detected host
npx skills add <username>/cem-agent-hub --full-depth    # also discover vendor/ SKILL.md files
```

Default discovery walks `skills/` (and a few other well-known skill folders) up to three levels deep. Own skills under `skills/<domain>/<skill-name>/` are found. Vendored skills under `vendor/` are **not** in that walk — pass `--full-depth` (or install from the upstream listed in `vendor/README.md`).

Agent `--agent` names and install paths: [vercel-labs/skills § Supported Agents](https://github.com/vercel-labs/skills#supported-agents).

Do not add Gemini extensions, OpenCode plugins, Grok `plugin.json`, Hermes hooks, or Copilot CLI plugin manifests unless a host can point at the skill directories **without** injecting every skill on every turn. Those manifests are appropriate for a single always-on product (ponytail), not for a hub.

Claude Code and Codex marketplaces (`.claude-plugin/marketplace.json`, `.agents/plugins/marketplace.json`) stay reserved for **curated plugin bundles** under `plugins/`, not a dump of the whole catalog.

## Work here: instruction-tier hosts

These hosts do not install `SKILL.md` from this checkout automatically (or only scan one level deep). They get a short always-on pointer generated from [`adapters/skill-discovery.md`](../adapters/skill-discovery.md):

| Host                                                            | Generated file                     |
| --------------------------------------------------------------- | ---------------------------------- |
| Generic / Amp / Jules / Zed / Aider / CodeWhale / VS Code Codex | `AGENTS.md`                        |
| Cursor                                                          | `.cursor/rules/cem-agent-hub.mdc`  |
| Windsurf                                                        | `.windsurf/rules/cem-agent-hub.md` |
| Cline                                                           | `.clinerules/cem-agent-hub.md`     |
| GitHub Copilot Chat (editor)                                    | `.github/copilot-instructions.md`  |
| Kiro                                                            | `.kiro/steering/cem-agent-hub.md`  |
| Qoder                                                           | `.qoder/rules/cem-agent-hub.md`    |
| JetBrains Junie (legacy path)                                   | `.junie/guidelines.md`             |

Junie still needs Guidelines Path pointed at `AGENTS.md` in settings if it does not pick up `.junie/guidelines.md`.

Regenerate after editing the canonical file:

```bash
bash scripts/sync-adapters.sh
```

`bash scripts/validate.sh` runs `sync-adapters.sh --check` so copies cannot drift.

## Authoring rule

When adding a skill, update `SKILL.md` (and `agents/openai.yaml` for Codex). Do **not** add a new Windsurf/Cursor/Copilot copy of that skill. Instruction-tier files stay generic discovery text; skill-capable hosts load `SKILL.md` after install.
