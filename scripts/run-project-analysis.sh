#!/usr/bin/env bash
# Runs report 50101 "BGB Project Hierarchy Analysis" for BGB-P-TOP in the container (OData BGBWebDemo_RunProjectAnalysis)
# and saves the xlsx. Requires the demo tree (scripts/setup-project-demo.sh) and the test app.
# Usage: scripts/run-project-analysis.sh [output.xlsx]
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
need curl; need python3
OUT="${1:-$REPO_ROOT/output/verify/project-hierarchy-analysis-$(date +%Y%m%d-%H%M%S).xlsx}"
mkdir -p "$(dirname "$OUT")"
ODATA="${ODATA_URL:-http://localhost:7048/BC/ODataV4}"
API="${API_URL:-http://localhost:7052/BC/api}"
COMPANY=$(curl -sf -u "$BC_AUTH" "$API/v2.0/companies" | python3 -c 'import sys,json,urllib.parse;print(urllib.parse.quote(json.load(sys.stdin)["value"][0]["name"]))')
curl -s -u "$BC_AUTH" -X POST -H 'Content-Type: application/json' -d '{}' "$ODATA/BGBWebDemo_RunProjectAnalysis?company=$COMPANY" \
  | python3 -c 'import sys,json,base64;d=json.load(sys.stdin);v=d.get("value");sys.exit("error: "+json.dumps(d)[:500]) if v is None else open(sys.argv[1],"wb").write(base64.b64decode(v))' "$OUT" \
  || die "report run failed"
ok "saved $OUT"
