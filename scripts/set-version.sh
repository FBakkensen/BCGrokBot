#!/usr/bin/env bash
# Set app/app.json "version" (main app only), e.g. by CI before a deploy build.
# Usage: scripts/set-version.sh <build> [revision]   -> <major>.<minor>.<build>.<revision>
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
[ $# -ge 1 ] || die "usage: set-version.sh <build> [revision]"
python3 - "$REPO_ROOT/app/app.json" "$1" "${2:-0}" <<'PY'
import json, re, sys
path, build, rev = sys.argv[1], int(sys.argv[2]), int(sys.argv[3])
text = open(path, encoding="utf-8-sig").read()
major, minor = json.loads(text)["version"].split(".")[:2]
new = f"{major}.{minor}.{build}.{rev}"
# edit in place to keep the file's formatting
text = re.sub(r'("version"\s*:\s*")[^"]*(")', lambda m: m.group(1) + new + m.group(2), text, count=1)
open(path, "w", encoding="utf-8").write(text)
print(new)
PY
