#!/usr/bin/env bash
# Non-browser verification harness for bc-app. Evidence -> output/verify/<run-id>/
# Usage: scripts/verify.sh doctor|unit|integration|installed|all
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
RUN_ID="${RUN_ID:-$(date +%Y%m%d-%H%M%S)}"
EVID="$REPO_ROOT/output/verify/$RUN_ID"
API="${API_URL:-http://localhost:7052/BC/api}"
mkdir -p "$EVID"
company_id() { curl -sf -u "$BC_AUTH" "$API/v2.0/companies" | python3 -c 'import sys,json;print(json.load(sys.stdin)["value"][0]["id"])'; }

doctor() {
  log "doctor -> $EVID/doctor.txt"
  {
    echo "time: $(date -Is)"
    $SUDO docker info >/dev/null 2>&1 && echo "docker: up" || { echo "docker: DOWN"; return 1; }
    echo "containers: $(dc ps --format '{{.Name}}={{.Health}}' 2>/dev/null | paste -sd' ')"
    dc ps --format '{{.Health}}' bc 2>/dev/null | grep -qx healthy || { echo "bc: NOT healthy"; return 1; }
    echo "bc version: $(curl -sf -u "$BC_AUTH" "$API/v2.0/companies" | python3 -c 'import sys,json;print(json.load(sys.stdin)["value"][0]["systemVersion"])')"
    local cid; cid=$(company_id)
    echo "test runner api: $(curl -s -o /dev/null -w '%{http_code}' -u "$BC_AUTH" "$API/custom/automation/v1.0/companies($cid)/codeunitRunRequests")"
    echo "web client: $(curl -s -o /dev/null -w '%{http_code}' -L "$WEB_URL")"
    echo "dev endpoint: $(curl -s -o /dev/null -w '%{http_code}' "$DEV_URL/metadata")"
  } | tee "$EVID/doctor.txt"
  grep -q 'test runner api: 200' "$EVID/doctor.txt" && grep -q 'web client: 200' "$EVID/doctor.txt" \
    || die "doctor failed - run scripts/bc-up.sh"
  ok "instance healthy"
}
unit() {
  log "unit (al-runner) -> $EVID/unit.txt"
  "$REPO_ROOT/scripts/test-dev.sh" 2>&1 | tee "$EVID/unit.txt" | grep -E '^(Tests:|Result:)'
  [ "${PIPESTATUS[0]}" = 0 ] || die "unit tests failed"
  ok "unit tests passed"
}
integration() {
  log "integration (container) -> $EVID/integration.txt, $EVID/junit.xml"
  "$REPO_ROOT/scripts/test-integration.sh" > "$EVID/integration.txt" 2>&1 || { tail -20 "$EVID/integration.txt"; die "integration failed"; }
  cp "$REPO_ROOT/output/junit.xml" "$EVID/junit.xml"
  grep -E "total, .* passed" "$EVID/integration.txt" | tail -1
  ok "integration tests passed"
}
installed() {
  log "installed extensions -> $EVID/extensions.json"
  local cid; cid=$(company_id)
  curl -sf -u "$BC_AUTH" "$API/microsoft/automation/v2.0/companies($cid)/extensions?\$filter=publisher%20eq%20'Flemming%20Bakkensen'" \
    | python3 -c 'import sys,json;v=json.load(sys.stdin)["value"];json.dump(v,open(sys.argv[1],"w"),indent=1);[print("  %s %s.%s installed=%s" % (e["displayName"], e["versionMajor"], e["versionMinor"], e["isInstalled"])) for e in v]' "$EVID/extensions.json"
  python3 -c 'import json,sys;v=json.load(open(sys.argv[1]));sys.exit(0 if any(e["displayName"]=="My BC App" and e["isInstalled"] for e in v) else 1)' "$EVID/extensions.json" \
    || die "My BC App is not installed - run scripts/publish.sh"
  ok "My BC App installed"
}
case "${1:-all}" in
  doctor) doctor ;; unit) unit ;; integration) doctor; integration ;; installed) installed ;;
  all) doctor; unit; integration; installed ;;
  *) die "usage: $0 doctor|unit|integration|installed|all" ;;
esac
log "evidence: $EVID"
