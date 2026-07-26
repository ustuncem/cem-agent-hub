# Vendor Skills

This directory holds **vendored copies** of third-party Agent Skills. These are not submodules — each subfolder is a full copy of an upstream repo's `skills/` directory, synced in via `scripts/sync-vendor.sh`.

## Why vendor instead of submodule?

- Skills need to be scannable and installable directly from this repo (e.g. via `npx skills add` or Claude Code plugin bundles) without requiring consumers to initialize submodules.
- Vendored copies can be pinned and diffed like any other tracked file.

## Currently synced

| Directory                | Upstream repo                                                                           |
| ------------------------ | --------------------------------------------------------------------------------------- |
| `mattpocock/`            | [`mattpocock/skills`](https://github.com/mattpocock/skills)                             |
| `software-mansion-labs/` | [`software-mansion-labs/skills`](https://github.com/software-mansion-labs/skills)       |
| `callstackincubator/`    | [`callstackincubator/agent-skills`](https://github.com/callstackincubator/agent-skills) |
| `vercel-labs/`           | [`vercel-labs/agent-skills`](https://github.com/vercel-labs/agent-skills)               |
| `expo/`                  | [`expo/skills`](https://github.com/expo/skills)                                         |
| `margelo/`               | [`margelo/react-native-skills`](https://github.com/margelo/react-native-skills)         |

Each entry is a full copy of that repo's skills directory (`skills/`, or `plugins/expo/skills/` for Expo). Commit SHAs are recorded in `vendor/VERSIONS.txt`.

## Updating

```bash
bash scripts/sync-vendor.sh
bash scripts/sync-vendor.sh --force   # overwrite existing vendor copies
```

## Adding a new vendor repo

Add a new target to `scripts/sync-vendor.sh` with its own subfolder under `vendor/`. Do not add new vendor repos without updating the sync script — vendor content should always be reproducible from it.

## Do not hand-edit

Files under vendor subfolders (other than this README and `VERSIONS.txt`) are managed by the sync script. Hand edits will be overwritten on the next sync.
