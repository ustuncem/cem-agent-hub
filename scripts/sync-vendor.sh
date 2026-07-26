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

# Each target: "<upstream-repo> <vendor-subfolder> [skills-subdir]"
# skills-subdir defaults to "skills" when omitted.
# Add new vendor repos here as additional lines.
TARGETS=(
  "mattpocock/skills mattpocock"
  "software-mansion-labs/skills software-mansion-labs"
  "callstackincubator/agent-skills callstackincubator"
  "vercel-labs/agent-skills vercel-labs"
  "expo/skills expo plugins/expo/skills"
)

sync_target() {
  local upstream="$1"
  local subfolder="$2"
  local skills_subdir="${3:-skills}"
  local dest="$VENDOR_DIR/$subfolder"
  local tmp_dir
  local src

  tmp_dir="$(mktemp -d)"
  trap 'rm -rf "$tmp_dir"' RETURN

  echo "==> Syncing $upstream into vendor/$subfolder/ (from $skills_subdir/)"

  git clone --depth 1 "https://github.com/$upstream.git" "$tmp_dir" >/dev/null 2>&1
  local sha
  sha="$(git -C "$tmp_dir" rev-parse HEAD)"

  src="$tmp_dir/$skills_subdir"
  if [ ! -d "$src" ]; then
    echo "    ERROR: $upstream has no $skills_subdir/ directory at HEAD, skipping." >&2
    return 1
  fi

  if [ -d "$dest" ] && [ "$FORCE" -ne 1 ]; then
    local existing_sha
    existing_sha="$(grep -m1 "^$upstream " "$VERSIONS_FILE" 2>/dev/null | awk '{print $2}' || true)"
    if [ "$existing_sha" = "$sha" ]; then
      echo "    Already up to date at $sha, skipping (use --force to re-sync anyway)."
      return 0
    fi
  fi

  rm -rf "$dest"
  mkdir -p "$dest"
  cp -R "$src/." "$dest/"

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
