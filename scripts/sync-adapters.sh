#!/usr/bin/env bash
# Generate instruction-tier host adapters from adapters/skill-discovery.md.
#
# Usage:
#   bash scripts/sync-adapters.sh          # write generated files
#   bash scripts/sync-adapters.sh --check  # fail if generated files are stale

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE="$REPO_ROOT/adapters/skill-discovery.md"
CHECK=0

if [ "${1:-}" = "--check" ]; then
  CHECK=1
fi

if [ ! -f "$SOURCE" ]; then
  echo "FAIL  missing $SOURCE" >&2
  exit 1
fi

BODY="$(cat "$SOURCE")"
MARKER="<!-- Generated from adapters/skill-discovery.md by scripts/sync-adapters.sh. Do not edit. -->"

write_or_check() {
  local dest="$1"
  local contents="$2"
  local tmp
  tmp="$(mktemp)"
  printf '%s' "$contents" > "$tmp"
  # Ensure trailing newline
  if [ "$(tail -c1 "$tmp" | wc -l)" -eq 0 ]; then
    printf '\n' >> "$tmp"
  fi

  if [ "$CHECK" -eq 1 ]; then
    if [ ! -f "$dest" ]; then
      echo "FAIL  missing generated adapter: $dest (run bash scripts/sync-adapters.sh)"
      rm -f "$tmp"
      return 1
    fi
    if ! cmp -s "$tmp" "$dest"; then
      echo "FAIL  stale adapter: $dest (run bash scripts/sync-adapters.sh)"
      rm -f "$tmp"
      return 1
    fi
    echo "PASS  $dest"
    rm -f "$tmp"
    return 0
  fi

  mkdir -p "$(dirname "$dest")"
  mv "$tmp" "$dest"
  echo "WROTE $dest"
}

FAILED=0

emit() {
  local dest="$1"
  local contents="$2"
  if ! write_or_check "$dest" "$contents"; then
    FAILED=$((FAILED + 1))
  fi
}

# AGENTS.md — Amp, Jules, Zed, Aider, Codex-in-VS-Code, CodeWhale, generic
emit "$REPO_ROOT/AGENTS.md" "$MARKER

$BODY"

# Cursor
emit "$REPO_ROOT/.cursor/rules/cem-agent-hub.mdc" "---
description: Load Agent Skills from this repo's skills/ and vendor/ directories
alwaysApply: true
---

$MARKER

$BODY"

# Windsurf
emit "$REPO_ROOT/.windsurf/rules/cem-agent-hub.md" "---
trigger: always_on
---

$MARKER

$BODY"

# Cline
emit "$REPO_ROOT/.clinerules/cem-agent-hub.md" "$MARKER

$BODY"

# GitHub Copilot Chat (editor extension)
emit "$REPO_ROOT/.github/copilot-instructions.md" "$MARKER

$BODY"

# Kiro
emit "$REPO_ROOT/.kiro/steering/cem-agent-hub.md" "$MARKER

$BODY"

# Qoder
emit "$REPO_ROOT/.qoder/rules/cem-agent-hub.md" "$MARKER

$BODY"

# JetBrains Junie (legacy guidelines path)
emit "$REPO_ROOT/.junie/guidelines.md" "$MARKER

$BODY"

if [ "$FAILED" -gt 0 ]; then
  echo ""
  echo "Adapter check failed ($FAILED file(s)). Run: bash scripts/sync-adapters.sh"
  exit 1
fi

if [ "$CHECK" -eq 1 ]; then
  echo "Adapter copies are up to date."
fi
