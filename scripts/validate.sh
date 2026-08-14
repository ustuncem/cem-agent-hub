#!/usr/bin/env bash
# Validate SKILL.md files against the agentskills.io spec.
#
# Default: own skills under skills/ only. Vendor copies are skipped
# because they are not authored here and many use extra frontmatter
# that skills-ref rejects. Pass --all after a vendor sync.
#
# Prefers a single `skills-ref` process (via npx if needed) for own
# skills; falls back to a basic frontmatter check. Vendor is always
# the basic check.
#
# Usage:
#   bash scripts/validate.sh                 skills/ only
#   bash scripts/validate.sh --all           skills/ + vendor/
#   bash scripts/validate.sh --vendor        vendor/ only
#   bash scripts/validate.sh PATH [PATH...]  specific skill dirs, SKILL.md files, or trees

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

usage() {
  cat <<'EOF'
Usage: bash scripts/validate.sh [options] [PATH...]

Validate SKILL.md files against the agentskills.io spec.

  (no args)    Own skills under skills/ only
  --all        Also validate vendor/ (basic frontmatter check)
  --vendor     Validate vendor/ only
  PATH...      Specific skill directories, SKILL.md files, or trees

  -h, --help   Show this help
EOF
}

INCLUDE_SKILLS=1
INCLUDE_VENDOR=0
PATHS=()

while [ "$#" -gt 0 ]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    --all)
      INCLUDE_SKILLS=1
      INCLUDE_VENDOR=1
      ;;
    --vendor)
      INCLUDE_SKILLS=0
      INCLUDE_VENDOR=1
      ;;
    --)
      shift
      PATHS+=("$@")
      break
      ;;
    -*)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
    *)
      PATHS+=("$1")
      ;;
  esac
  shift
done

echo "==> Checking instruction-tier adapters"
if ! bash "$REPO_ROOT/scripts/sync-adapters.sh" --check; then
  exit 1
fi
echo ""

FAILED=0
CHECKED=0

# Collect skill directories (relative to REPO_ROOT), skipping nested
# SKILL.md files under references/ — those are docs, not skill packages.
find_skill_mds() {
  find "$1" -type f -name SKILL.md ! -path '*/references/*' -print0 2>/dev/null
}

add_skill_md() {
  local skill_md="$1"
  local dest="$2"
  local skill_dir rel
  skill_dir="$(cd "$(dirname "$skill_md")" && pwd)"
  rel="${skill_dir#"$REPO_ROOT"/}"
  if grep -qxF "$rel" "$dest" 2>/dev/null; then
    return
  fi
  printf '%s\n' "$rel" >> "$dest"
}

# Resolve a user path to SKILL.md files.
collect_from_path() {
  local target="$1"
  local dest="$2"

  if [ -f "$target" ]; then
    if [ "$(basename "$target")" != "SKILL.md" ]; then
      echo "FAIL  not a SKILL.md file: $target" >&2
      FAILED=$((FAILED + 1))
      return 1
    fi
    add_skill_md "$target" "$dest"
    return 0
  fi

  if [ ! -d "$target" ]; then
    echo "FAIL  path not found: $target" >&2
    FAILED=$((FAILED + 1))
    return 1
  fi

  if [ -f "$target/SKILL.md" ]; then
    add_skill_md "$target/SKILL.md" "$dest"
    return 0
  fi

  local skill_md
  while IFS= read -r -d '' skill_md; do
    add_skill_md "$skill_md" "$dest"
  done < <(find_skill_mds "$target")
}

check_skill() {
  local skill_dir="$1"
  local match_dirname="${2:-1}"
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

  local name description
  name="$(printf '%s\n' "$frontmatter" | grep -m1 '^name:' | sed 's/^name:[[:space:]]*//; s/^["'\'']//; s/["'\'']$//; s/[[:space:]]*$//')"
  description="$(printf '%s\n' "$frontmatter" | grep -m1 '^description:' | sed 's/^description:[[:space:]]*//; s/[[:space:]]*$//')"

  # Vendor copies often use block scalars (`description:`) and namespaced
  # names that do not match the directory. Smoke-test keys only.
  if [ "$match_dirname" -eq 0 ]; then
    if ! printf '%s\n' "$frontmatter" | grep -q '^name:'; then
      echo "FAIL  $skill_md: missing 'name' field"
      FAILED=$((FAILED + 1))
      return
    fi
    if ! printf '%s\n' "$frontmatter" | grep -q '^description:'; then
      echo "FAIL  $skill_md: missing 'description' field"
      FAILED=$((FAILED + 1))
      return
    fi
    echo "PASS  $skill_dir"
    return
  fi

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

run_basic_checks() {
  local list_file="$1"
  local match_dirname="${2:-1}"
  local skill_dir
  [ -s "$list_file" ] || return 0
  while IFS= read -r skill_dir; do
    [ -n "$skill_dir" ] || continue
    check_skill "$skill_dir" "$match_dirname"
  done < "$list_file"
}

resolve_skills_ref_pkg() {
  local bin pkg
  if command -v skills-ref >/dev/null 2>&1; then
    bin="$(command -v skills-ref)"
  elif command -v npx >/dev/null 2>&1; then
    bin="$(npx --yes -p skills-ref -- sh -c 'command -v skills-ref' 2>/dev/null)" || return 1
  else
    return 1
  fi
  pkg="$(cd "$(dirname "$bin")/../skills-ref" && pwd)"
  [ -f "$pkg/dist/index.js" ] || return 1
  printf '%s\n' "$pkg"
}

run_skills_ref_batch() {
  local pkg="$1"
  local list_file="$2"
  local output line checked_n failed_n

  [ -s "$list_file" ] || return 0

  output="$(
    node --input-type=module - "$pkg" "$list_file" <<'EOF'
import { readFileSync } from "node:fs";
import { join } from "node:path";
import { pathToFileURL } from "node:url";

const pkg = process.argv[2];
const listFile = process.argv[3];
const { validate } = await import(pathToFileURL(join(pkg, "dist/index.js")).href);
const dirs = readFileSync(listFile, "utf8").split("\n").filter(Boolean);
let failed = 0;
for (const dir of dirs) {
  const errors = await validate(dir);
  if (errors.length > 0) {
    console.log(`FAIL  ${dir}`);
    for (const error of errors) {
      console.log(`  - ${error}`);
    }
    failed++;
  } else {
    console.log(`PASS  ${dir}`);
  }
}
console.log(`SKILLS_REF_STATS ${dirs.length} ${failed}`);
process.exit(0);
EOF
  )"

  checked_n=""
  failed_n=""
  while IFS= read -r line; do
    case "$line" in
      SKILLS_REF_STATS\ *)
        checked_n="${line#SKILLS_REF_STATS }"
        failed_n="${checked_n#* }"
        checked_n="${checked_n%% *}"
        ;;
      *)
        printf '%s\n' "$line"
        ;;
    esac
  done <<< "$output"

  if [ -z "$checked_n" ]; then
    echo "==> skills-ref batch failed, falling back to basic frontmatter checks" >&2
    run_basic_checks "$list_file"
    return 0
  fi

  CHECKED=$((CHECKED + checked_n))
  FAILED=$((FAILED + failed_n))
  return 0
}

OWN_LIST="$(mktemp)"
VENDOR_LIST="$(mktemp)"
trap 'rm -f "$OWN_LIST" "$VENDOR_LIST"' EXIT

if [ "${#PATHS[@]}" -gt 0 ]; then
  for target in "${PATHS[@]}"; do
    dest="$OWN_LIST"
    case "$target" in
      vendor|vendor/*|*/vendor|*/vendor/*)
        dest="$VENDOR_LIST"
        ;;
    esac
    # Absolute / relative paths under vendor/
    abs="$target"
    if [ -e "$target" ]; then
      if [ -d "$target" ]; then
        abs="$(cd "$target" && pwd)"
      else
        abs="$(cd "$(dirname "$target")" && pwd)/$(basename "$target")"
      fi
      case "$abs" in
        "$REPO_ROOT"/vendor|"$REPO_ROOT"/vendor/*)
          dest="$VENDOR_LIST"
          ;;
      esac
    fi
    collect_from_path "$target" "$dest" || true
  done
else
  if [ "$INCLUDE_SKILLS" -eq 1 ]; then
    while IFS= read -r -d '' skill_md; do
      add_skill_md "$skill_md" "$OWN_LIST"
    done < <(find_skill_mds skills)
  fi
  if [ "$INCLUDE_VENDOR" -eq 1 ]; then
    while IFS= read -r -d '' skill_md; do
      add_skill_md "$skill_md" "$VENDOR_LIST"
    done < <(find_skill_mds vendor)
  fi
fi

OWN_COUNT=0
VENDOR_COUNT=0
[ -s "$OWN_LIST" ] && OWN_COUNT="$(grep -c . "$OWN_LIST")"
[ -s "$VENDOR_LIST" ] && VENDOR_COUNT="$(grep -c . "$VENDOR_LIST")"

if [ "$OWN_COUNT" -eq 0 ] && [ "$VENDOR_COUNT" -eq 0 ]; then
  if [ "$FAILED" -gt 0 ]; then
    echo ""
    echo "Checked 0 skill(s), $FAILED failure(s)."
    exit 1
  fi
  echo "No SKILL.md files to validate."
  exit 0
fi

if [ "${#PATHS[@]}" -eq 0 ] && [ "$INCLUDE_VENDOR" -eq 0 ]; then
  echo "==> Validating $OWN_COUNT skill(s) under skills/ (vendor/ skipped; pass --all to include)"
elif [ "$OWN_COUNT" -gt 0 ] && [ "$VENDOR_COUNT" -gt 0 ]; then
  echo "==> Validating $OWN_COUNT own skill(s) and $VENDOR_COUNT vendor skill(s)"
elif [ "$VENDOR_COUNT" -gt 0 ]; then
  echo "==> Validating $VENDOR_COUNT vendor skill(s)"
else
  echo "==> Validating $OWN_COUNT skill(s)"
fi

if [ "$OWN_COUNT" -gt 0 ]; then
  SKILLS_REF_PKG=""
  if SKILLS_REF_PKG="$(resolve_skills_ref_pkg)"; then
    echo "==> Using skills-ref (one process)"
    run_skills_ref_batch "$SKILLS_REF_PKG" "$OWN_LIST"
  else
    echo "==> skills-ref not available, running basic frontmatter checks"
    run_basic_checks "$OWN_LIST"
  fi
fi

if [ "$VENDOR_COUNT" -gt 0 ]; then
  echo "==> Vendor frontmatter checks (skills-ref skipped; copies are upstream)"
  run_basic_checks "$VENDOR_LIST" 0
fi

echo ""
echo "Checked $CHECKED skill(s), $FAILED failure(s)."

if [ "$FAILED" -gt 0 ]; then
  exit 1
fi
