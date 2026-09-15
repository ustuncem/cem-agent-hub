#!/usr/bin/env bash
# Sync vendored third-party skill repos into vendor/.
#
# Pulls each target repo IN FULL (shallow clone), copies its skills
# directory into the corresponding vendor/<org>/ folder, and records the
# synced commit SHA in vendor/VERSIONS.txt.
#
# Usage:
#   scripts/sync-vendor.sh            sync all targets, skip ones already up to date
#   scripts/sync-vendor.sh --force    overwrite existing vendor copies unconditionally

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VENDOR_DIR="$REPO_ROOT/vendor"
VERSIONS_FILE="$VENDOR_DIR/VERSIONS.txt"

FORCE=0
for arg in "$@"; do
  case "$arg" in
    --force) FORCE=1 ;;
    *)
      echo "Unknown argument: $arg" >&2
      echo "Usage: $0 [--force]" >&2
      exit 1
      ;;
  esac
done

# Each target: "<upstream-repo> <vendor-subfolder> [skills-subdir] [layout] [skill-name]"
# skills-subdir defaults to "skills" (path inside the cloned repo to copy or read).
# layout defaults to "copy" (replace vendor subfolder with skills-subdir contents).
#   merge — copy skills-subdir into an existing vendor subfolder (no rm -rf)
#   merge-skill — copy one skill directory (skills-subdir) into vendor/<subfolder>/<basename>/
#   plugin-skills — flatten plugins/*/skills/* into vendor subfolder (skills-subdir ignored)
#   root-skill — copy repo-root SKILL.md into vendor/<subfolder>/<skill-name>/
# skill-name is required for root-skill.
# Add new vendor repos here as additional lines.
TARGETS=(
  "mattpocock/skills mattpocock"
  "software-mansion-labs/skills software-mansion-labs"
  "callstackincubator/agent-skills callstackincubator"
  "callstackincubator/agent-skills callstackincubator .claude/skills/validate-skills merge-skill"
  "callstackincubator/react-native-harness callstackincubator skills merge"
  "vercel-labs/agent-skills vercel-labs"
  "expo/skills expo plugins/expo/skills"
  "expo/skills expo plugins/expo-experiments/skills/expo-migrate-module merge-skill"
  "expo/skills expo .claude/skills/expo-skill-eval merge-skill"
  "margelo/react-native-skills margelo"
  "DietrichGebert/ponytail dietrichgebert"
  "JuliusBrussee/caveman juliusbrussee"
  "ayghri/i-have-adhd ayghri"
  "humanlayer/skills humanlayer plugins plugin-skills"
  "estevg/skills estevg plugins plugin-skills"
  "tovimx/maestro-mobile-testing-skill tovimx . root-skill maestro-mobile-testing"
)

sync_target() {
  local upstream="$1"
  local subfolder="$2"
  local skills_subdir="${3:-skills}"
  local layout="${4:-copy}"
  local root_skill_name="${5:-}"
  local dest="$VENDOR_DIR/$subfolder"
  local tmp_dir
  local src

  tmp_dir="$(mktemp -d)"
  trap 'rm -rf "$tmp_dir"' RETURN

  echo "==> Syncing $upstream into vendor/$subfolder/ (from $skills_subdir/, layout: $layout)"

  git clone --depth 1 "https://github.com/$upstream.git" "$tmp_dir" >/dev/null 2>&1
  local sha
  sha="$(git -C "$tmp_dir" rev-parse HEAD)"

  case "$layout" in
    copy|merge|merge-skill)
      src="$tmp_dir/$skills_subdir"
      if [ ! -d "$src" ]; then
        echo "    ERROR: $upstream has no $skills_subdir/ directory at HEAD, skipping." >&2
        return 1
      fi
      ;;
    plugin-skills)
      src="$tmp_dir/plugins"
      if [ ! -d "$src" ]; then
        echo "    ERROR: $upstream has no plugins/ directory at HEAD, skipping." >&2
        return 1
      fi
      ;;
    root-skill)
      if [ -z "$root_skill_name" ]; then
        echo "    ERROR: root-skill layout requires a skill directory name." >&2
        return 1
      fi
      if [ ! -f "$tmp_dir/SKILL.md" ]; then
        echo "    ERROR: $upstream has no SKILL.md at repo root, skipping." >&2
        return 1
      fi
      ;;
    *)
      echo "    ERROR: unknown layout '$layout' for $upstream" >&2
      return 1
      ;;
  esac

  if [ -d "$dest" ] && [ "$FORCE" -ne 1 ]; then
    local existing_sha
    existing_sha="$(grep -m1 "^$upstream " "$VERSIONS_FILE" 2>/dev/null | awk '{print $2}' || true)"
    if [ "$existing_sha" = "$sha" ]; then
      echo "    Already up to date at $sha, skipping (use --force to re-sync anyway)."
      return 0
    fi
  fi

  if [ "$layout" = "merge" ]; then
    mkdir -p "$dest"
    cp -R "$src/." "$dest/"
  elif [ "$layout" = "merge-skill" ]; then
    local skill_name
    skill_name="$(basename "$skills_subdir")"
    mkdir -p "$dest"
    rm -rf "$dest/$skill_name"
    cp -R "$src" "$dest/$skill_name"
  elif [ "$layout" = "copy" ]; then
    rm -rf "$dest"
    mkdir -p "$dest"
    cp -R "$src/." "$dest/"
  elif [ "$layout" = "plugin-skills" ]; then
    rm -rf "$dest"
    mkdir -p "$dest"
    local plugin_skill_dir skill_name
    for plugin_skill_dir in "$src"/*/skills/*/; do
      [ -d "$plugin_skill_dir" ] || continue
      skill_name="$(basename "$plugin_skill_dir")"
      cp -R "$plugin_skill_dir" "$dest/$skill_name"
    done
  elif [ "$layout" = "root-skill" ]; then
    mkdir -p "$dest"
    rm -rf "$dest/$root_skill_name"
    mkdir -p "$dest/$root_skill_name"
    cp "$tmp_dir/SKILL.md" "$dest/$root_skill_name/"
  fi

  update_versions_file "$upstream" "$sha"
  echo "    Synced $upstream @ $sha"
}

update_versions_file() {
  local upstream="$1"
  local sha="$2"
  touch "$VERSIONS_FILE"

  local tmp_file
  tmp_file="$(mktemp)"
  grep -v "^$upstream " "$VERSIONS_FILE" > "$tmp_file" 2>/dev/null || true
  echo "$upstream $sha $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$tmp_file"
  sort "$tmp_file" -o "$tmp_file"
  mv "$tmp_file" "$VERSIONS_FILE"
}

for target in "${TARGETS[@]}"; do
  # shellcheck disable=SC2086
  sync_target $target
done

echo "Done."
