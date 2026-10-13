#!/usr/bin/env bash
# Dev container only. Ensures projects BGB-V-TOP and its four subprojects exist, then two archive runs
# with resource usage posted on BGB-V-TOP between them. Idempotent: a second run leaves two runs in place.
# Requires: container up, main + test app published (scripts/test-integration.sh).
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
need curl; need python3
ODATA="${ODATA_URL:-http://localhost:7048/BC/ODataV4}"
API="${API_URL:-http://localhost:7052/BC/api}"
COMPANY=$(curl -sf -u "$BC_AUTH" "$API/v2.0/companies" | python3 -c 'import sys,json,urllib.parse;print(urllib.parse.quote(json.load(sys.stdin)["value"][0]["name"]))')
log "Running project version demo setup (OData BGBWebDemo_SetupProjectVersionDemo)"
out=$(curl -s -w '\n%{http_code}' -u "$BC_AUTH" -X POST -H 'Content-Type: application/json' -d '{}' \
  "$ODATA/BGBWebDemo_SetupProjectVersionDemo?company=$COMPANY")
code=${out##*$'\n'}; body=${out%$'\n'*}
[ "$code" = "200" ] || die "project version demo setup failed (HTTP $code): $body"
ok "$(printf '%s' "$body" | python3 -c 'import sys,json;print(json.load(sys.stdin)["value"])')"
echo "Web client: ${WEB_URL}?page=88&filter=%27No.%27%20IS%20%27BGB-V-TOP%27  (admin ${BC_AUTH%%:*})"
echo "Actions: Archive Hierarchy, Project Version Compare, Project Version Trend."
