#!/usr/bin/env bash
# Uninstall + unpublish our extensions (publisher Flemming Bakkensen) from the container.
# Usage: scripts/unpublish.sh ["Display Name" ...]   (default: all apps by our publisher, tests first)
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
API="${API_URL:-http://localhost:7052/BC/api}"
cid=$(curl -sf -u "$BC_AUTH" "$API/v2.0/companies" | python3 -c 'import sys,json;print(json.load(sys.stdin)["value"][0]["id"])')
EXT="$API/microsoft/automation/v2.0/companies($cid)/extensions"
list=$(curl -sf -u "$BC_AUTH" "$EXT?\$filter=publisher%20eq%20'Flemming%20Bakkensen'" | python3 -c '
import sys,json
v=json.load(sys.stdin)["value"]; names=sys.argv[1:]
v=[e for e in v if not names or e["displayName"] in names]
v.sort(key=lambda e: 0 if "Test" in e["displayName"] else 1)   # dependents first
for e in v: print(e["packageId"]+"\t"+e["displayName"])' "$@")
[ -n "$list" ] || { ok "nothing to unpublish"; exit 0; }
while IFS=$'\t' read -r pkg name; do
  for act in uninstall unpublish; do
    code=$(curl -s -o /dev/null -w '%{http_code}' -u "$BC_AUTH" -X POST -H 'Content-Type: application/json' "$EXT($pkg)/Microsoft.NAV.$act")
    [[ "$code" =~ ^20 ]] || log "$act $name: HTTP $code (may already be uninstalled)"
    sleep 2
  done
  ok "unpublished $name"
done <<< "$list"
