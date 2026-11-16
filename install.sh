#!/usr/bin/env bash
# Copies AGENTS.md and agents/*.md into ~/.claude.
# If a destination already exists, asks before replacing it.
# Also merges the permission rules in settings.json into ~/.claude/settings.json
# (requires python3), leaving every other setting untouched.
#
# Usage: ./install.sh [-y|--yes]
#   -y, --yes   Answer yes to every question (for non-interactive runs).
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="${HOME}/.claude"
ASSUME_YES=false

case "${1-}" in
  "") ;;
  -y|--yes) ASSUME_YES=true ;;
  *) echo "Usage: $0 [-y|--yes]" >&2; exit 2 ;;
esac

# confirm <question>: succeeds if the user answers yes (or --yes was given).
confirm() {
  local answer=""
  if [[ "$ASSUME_YES" == true ]]; then
    echo "$1 [y/N] y (--yes)"
    return 0
  fi
  read -r -p "$1 [y/N] " answer || true
  [[ "$answer" =~ ^[Yy]$ ]]
}

install_file() {
  local src="$1" dest="$2"
  if [[ -e "$dest" || -L "$dest" ]]; then
    if [[ ! -L "$dest" ]] && cmp -s "$src" "$dest"; then
      echo "Up to date ${dest}"
      return
    fi
    if ! confirm "${dest} already exists. Replace it?"; then
      echo "Skipped ${dest}"
      return
    fi
    rm -f "$dest"
  fi
  cp "$src" "$dest"
  echo "Copied ${dest}"
}

# permissions_py <check|apply> <src> <dest>
# check: prints the rules in <src> that are missing from <dest>.
# apply: appends those rules to <dest>, creating it if needed.
permissions_py() {
  python3 - "$@" <<'PY'
import json, os, sys

mode, src, dest = sys.argv[1:4]
with open(src) as f:
    wanted = json.load(f)["permissions"]
settings = {}
if os.path.exists(dest):
    with open(dest) as f:
        settings = json.load(f)
perms = settings.setdefault("permissions", {})
missing = [(kind, rule) for kind, rules in wanted.items()
           for rule in rules if rule not in perms.get(kind, [])]

if mode == "check":
    for kind, rule in missing:
        print(f"  {kind}: {rule}")
else:
    for kind, rule in missing:
        perms.setdefault(kind, []).append(rule)
    output = json.dumps(settings, indent=2, ensure_ascii=False) + "\n"
    with open(dest, "w") as f:
        f.write(output)
PY
}

merge_permissions() {
  local src="${REPO}/settings.json" dest="${TARGET}/settings.json" missing
  if ! command -v python3 >/dev/null; then
    echo "python3 not found: skipped permissions in ${dest}"
    return
  fi
  missing="$(permissions_py check "$src" "$dest")"
  if [[ -z "$missing" ]]; then
    echo "Up to date ${dest} (permissions)"
    return
  fi
  echo "These permission rules will be added to ${dest}:"
  echo "$missing"
  if ! confirm "Add them?"; then
    echo "Skipped permissions in ${dest}"
    return
  fi
  permissions_py apply "$src" "$dest"
  echo "Merged permissions into ${dest}"
}

echo "This installer only works with Claude Code: it copies files into ${TARGET}."
if ! confirm "Continue?"; then
  echo "Aborted. Nothing was installed."
  exit 1
fi

mkdir -p "${TARGET}/agents"

install_file "${REPO}/AGENTS.md" "${TARGET}/AGENTS.md"
for f in "${REPO}"/agents/*.md; do
  install_file "$f" "${TARGET}/agents/$(basename "$f")"
done
merge_permissions

echo "Done."
