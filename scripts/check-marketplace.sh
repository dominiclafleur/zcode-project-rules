#!/usr/bin/env sh
# Runs the upstream zcode-plugins checks against this directory without copying
# or editing the upstream scripts.
#
#   1. node test/test.mjs                      (plugin self-test)
#   2. validate.py on this standalone layout   (marketplace.json + external_plugins/)
#   3. build_dist.py on this layout            (dist/ is removed afterwards)
#   4. drop-in: validate.py on a scratch copy of zcode-plugins with this plugin
#      and marketplace-entry.json merged in    (scratch copy is removed afterwards)
#   5. whitespace check (the CONTRIBUTING.md `git diff --check` equivalent)
#
# Usage: sh scripts/check-marketplace.sh [path/to/zcode-plugins]
# Default upstream path: ../zcode-plugins next to this directory.
set -eu

ROOT=$(cd "$(dirname "$0")/.." && pwd)
UPSTREAM=$(cd "${1:-$ROOT/../zcode-plugins}" && pwd)
SCRIPTS="$UPSTREAM/scripts"
PLUGIN="$ROOT/external_plugins/project-rules"
SCRATCH="$ROOT/.dropin-check"

[ -f "$SCRIPTS/validate.py" ] || { echo "validate.py not found under $SCRIPTS" >&2; exit 2; }

# validate.py and build_dist.py derive ROOT from their own __file__. Executing
# the unmodified source with __file__ pointed at <root>/scripts/ retargets them.
run_upstream() {
  python3 -I - "$SCRIPTS" "$1" "$2" <<'PY'
import sys
scripts, root, name = sys.argv[1:4]
sys.path.insert(0, scripts)
path = scripts + "/" + name
code = compile(open(path, encoding="utf-8").read(), path, "exec")
exec(code, {"__name__": "__main__", "__file__": root + "/scripts/" + name})
PY
}

cleanup() { rm -rf "$SCRATCH" "$ROOT/dist"; }
trap cleanup EXIT

echo "== 1. plugin self-test"
node "$PLUGIN/test/test.mjs" | tail -n 1

echo "== 2. validate.py (standalone layout)"
run_upstream "$ROOT" validate.py

echo "== 3. build_dist.py (standalone layout)"
run_upstream "$ROOT" build_dist.py

echo "== 4. validate.py (drop-in into zcode-plugins)"
rm -rf "$SCRATCH"
mkdir -p "$SCRATCH"
for item in marketplace.json plugins external_plugins assets; do
  [ -e "$UPSTREAM/$item" ] && cp -R "$UPSTREAM/$item" "$SCRATCH/$item"
done
rm -rf "$SCRATCH/external_plugins/project-rules"
cp -R "$PLUGIN" "$SCRATCH/external_plugins/project-rules"
python3 -I - "$SCRATCH/marketplace.json" "$ROOT/marketplace-entry.json" <<'PY'
import json, sys
market_path, entry_path = sys.argv[1:3]
market = json.load(open(market_path, encoding="utf-8"))
entry = json.load(open(entry_path, encoding="utf-8"))
market["plugins"] = [p for p in market["plugins"] if p.get("name") != entry["name"]] + [entry]
with open(market_path, "w", encoding="utf-8") as fh:
    json.dump(market, fh, ensure_ascii=False, indent=2)
    fh.write("\n")
PY
run_upstream "$SCRATCH" validate.py

echo "== 5. whitespace"
if grep -rnI --exclude-dir=.dropin-check --exclude-dir=dist '[[:blank:]]$' "$ROOT"; then
  echo "trailing whitespace found" >&2
  exit 1
fi
echo "OK: no trailing whitespace"
