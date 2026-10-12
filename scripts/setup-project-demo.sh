#!/usr/bin/env bash
# Web verification demo for the project hierarchy feature (dev container only).
# Recreates projects BGB-P-TOP <- BGB-P-C1 (cust B), BGB-P-C2 (sell-to S, bill-to A) <- BGB-P-G1 (A, foreign currency),
# BGB-P-G2 (B), each with one billable resource line; deletes open demo invoices first.
# Requires: container up, main + test app published (scripts/test-integration.sh).
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
need curl; need python3
ODATA="${ODATA_URL:-http://localhost:7048/BC/ODataV4}"
API="${API_URL:-http://localhost:7052/BC/api}"
COMPANY=$(curl -sf -u "$BC_AUTH" "$API/v2.0/companies" | python3 -c 'import sys,json,urllib.parse;print(urllib.parse.quote(json.load(sys.stdin)["value"][0]["name"]))')
log "Running project hierarchy demo setup (OData BGBWebDemo_SetupProjectHierarchyDemo)"
out=$(curl -s -w '\n%{http_code}' -u "$BC_AUTH" -X POST -H 'Content-Type: application/json' -d '{}' \
  "$ODATA/BGBWebDemo_SetupProjectHierarchyDemo?company=$COMPANY")
code=${out##*$'\n'}; body=${out%$'\n'*}
[ "$code" = "200" ] || die "project demo setup failed (HTTP $code): $body"
ok "$(printf '%s' "$body" | python3 -c 'import sys,json;print(json.load(sys.stdin)["value"])')"
echo "Web client: ${WEB_URL}?page=89  (Projects; admin ${BC_AUTH%%:*})"
