#!/usr/bin/env bash
# Validate every SKILL.md under skills/ and vendor/ against the
# agentskills.io spec.
#
# Prefers `npx skills-ref validate` if available; falls back to a basic
# frontmatter check otherwise.

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

if command -v npx >/dev/null 2>&1 && npx --yes skills-ref --version >/dev/null 2>&1; then
  echo "==> Using skills-ref validate (per skill)"
  FAILED=0
  CHECKED=0
  while IFS= read -r -d '' skill_md; do
    skill_dir="$(dirname "$skill_md")"
    CHECKED=$((CHECKED + 1))
    if npx --yes skills-ref validate "$skill_dir"; then
      : # pass, skills-ref prints its own output
    else
      FAILED=$((FAILED + 1))
    fi
  done < <(find skills vendor -type f -name SKILL.md -print0 2>/dev/null)
  echo ""
  echo "Checked $CHECKED skill(s), $FAILED failure(s)."
  [ "$FAILED" -eq 0 ]
  exit $?
fi

echo "==> skills-ref not available, running basic frontmatter checks"

FAILED=0
CHECKED=0

check_skill() {
  local skill_dir="$1"
  local skill_md="$skill_dir/SKILL.md"
  local dir_name
  dir_name="$(basename "$skill_dir")"

  CHECKED=$((CHECKED + 1))

  if [ ! -f "$skill_md" ]; then
    echo "FAIL  $skill_dir: missing SKILL.md"
    FAILED=$((FAILED + 1))
    return
  fi

  if ! head -n1 "$skill_md" | grep -q '^---$'; then
    echo "FAIL  $skill_md: does not start with YAML frontmatter (---)"
    FAILED=$((FAILED + 1))
    return
  fi

  local frontmatter
  frontmatter="$(awk 'NR==1{next} /^---$/{exit} {print}' "$skill_md")"

  local name
  name="$(printf '%s\n' "$frontmatter" | grep -m1 '^name:' | sed 's/^name: *//' | tr -d '"' | tr -d "'" | xargs)"
  local description
  description="$(printf '%s\n' "$frontmatter" | grep -m1 '^description:' | sed 's/^description: *//')"

  if [ -z "$name" ]; then
    echo "FAIL  $skill_md: missing 'name' field"
    FAILED=$((FAILED + 1))
    return
  fi

  if [ "$name" != "$dir_name" ]; then
    echo "FAIL  $skill_md: name '$name' does not match parent directory '$dir_name'"
    FAILED=$((FAILED + 1))
    return
  fi

  if ! [[ "$name" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]]; then
    echo "FAIL  $skill_md: name '$name' must be lowercase letters, numbers, hyphens only, no leading/trailing/consecutive hyphens"
    FAILED=$((FAILED + 1))
    return
  fi

  if [ "${#name}" -gt 64 ]; then
    echo "FAIL  $skill_md: name '$name' exceeds 64 characters"
    FAILED=$((FAILED + 1))
    return
  fi

  if [ -z "$description" ]; then
    echo "FAIL  $skill_md: missing or empty 'description' field"
    FAILED=$((FAILED + 1))
    return
  fi

  if [ "${#description}" -gt 1024 ]; then
    echo "FAIL  $skill_md: description exceeds 1024 characters"
    FAILED=$((FAILED + 1))
    return
  fi

  echo "PASS  $skill_dir"
}

while IFS= read -r -d '' skill_md; do
  check_skill "$(dirname "$skill_md")"
done < <(find skills vendor -type f -name SKILL.md -print0 2>/dev/null)

echo ""
echo "Checked $CHECKED skill(s), $FAILED failure(s)."

if [ "$FAILED" -gt 0 ]; then
  exit 1
fi
