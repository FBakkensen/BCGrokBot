#!/usr/bin/env bash
# Deploy an .app to a Business Central SaaS environment through the Automation API
# (service-to-service / OAuth client credentials). Used by the CD job; runnable locally.
#
# Required env:  BC_TENANT_ID BC_ENVIRONMENT BC_CLIENT_ID BC_CLIENT_SECRET
# Optional env:  BC_COMPANY_ID (default: first company)  SCHEMA_SYNC_MODE (Add|Force Sync, default Add)
#                POLL_SECONDS (10)  TIMEOUT_SECONDS (1800)  BC_API_HOST  BC_LOGIN_HOST
# Usage: scripts/deploy-saas.sh [--dry-run] [path/to/app.app]   (default app/output/app.app)
#   --dry-run  validates the .app and prints the plan; no network calls, no secrets needed.
set -euo pipefail
die() { printf '\033[1;31mERR\033[0m %s\n' "$*" >&2; exit 1; }
log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
ok()  { printf '\033[1;32m OK\033[0m %s\n' "$*"; }

DRY=0; [ "${1:-}" = "--dry-run" ] && { DRY=1; shift; }
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_FILE="${1:-$REPO_ROOT/app/output/app.app}"
[ -f "$APP_FILE" ] || die "app file not found: $APP_FILE (run scripts/build.sh)"
command -v curl >/dev/null && command -v python3 >/dev/null || die "need curl and python3"

# Read name/publisher/version from the package manifest (NAVX header is 40 bytes, then a zip)
read -r APP_NAME APP_PUBLISHER APP_VERSION < <(python3 - "$APP_FILE" <<'PY'
import io, re, sys, zipfile
data = open(sys.argv[1], "rb").read()
z = zipfile.ZipFile(io.BytesIO(data[40:] if data[:4] == b"NAVX" else data))
m = z.read("NavxManifest.xml").decode("utf-8-sig")
app = re.search(r"<App\s[^>]*>", m).group(0)
get = lambda k: re.search(k + r'="([^"]*)"', app).group(1)
print(get("Name").replace(" ", "\u00a0"), get("Publisher").replace(" ", "\u00a0"), get("Version"))
PY
)
APP_NAME="${APP_NAME//$'\u00a0'/ }"; APP_PUBLISHER="${APP_PUBLISHER//$'\u00a0'/ }"
SYNC="${SCHEMA_SYNC_MODE:-Add}"
case "$SYNC" in "Add"|"Force Sync") ;; *) die "SCHEMA_SYNC_MODE must be 'Add' or 'Force Sync'";; esac
log "App: $APP_NAME by $APP_PUBLISHER, version $APP_VERSION ($(stat -c %s "$APP_FILE") bytes)"
log "Target: tenant ${BC_TENANT_ID:-<unset>} environment ${BC_ENVIRONMENT:-<unset>}, schema sync '$SYNC'"
if [ "$DRY" = 1 ]; then ok "dry run: package valid, nothing deployed"; exit 0; fi

for v in BC_TENANT_ID BC_ENVIRONMENT BC_CLIENT_ID BC_CLIENT_SECRET; do [ -n "${!v:-}" ] || die "$v is not set"; done
LOGIN="${BC_LOGIN_HOST:-https://login.microsoftonline.com}"
APIHOST="${BC_API_HOST:-https://api.businesscentral.dynamics.com}"
BASE="$APIHOST/v2.0/$BC_TENANT_ID/$BC_ENVIRONMENT/api/microsoft/automation/v2.0"

log "Requesting token (client credentials)"
TOKEN=$(curl -sS --fail-with-body -X POST "$LOGIN/$BC_TENANT_ID/oauth2/v2.0/token" \
  --data-urlencode "grant_type=client_credentials" \
  --data-urlencode "client_id=$BC_CLIENT_ID" \
  --data-urlencode "client_secret=$BC_CLIENT_SECRET" \
  --data-urlencode "scope=$APIHOST/.default" \
  | python3 -c 'import sys,json;print(json.load(sys.stdin)["access_token"])') || die "token request failed"
[ -n "${GITHUB_ACTIONS:-}" ] && echo "::add-mask::$TOKEN"
AUTH=(-H "Authorization: Bearer $TOKEN")

# api <method> <url> [curl args...] -> body on stdout; dies on HTTP >= 400
api() {
  local method=$1 url=$2; shift 2
  local out code
  out=$(curl -sS -X "$method" "${AUTH[@]}" -w '\n%{http_code}' "$url" "$@") || die "$method $url: curl failed"
  code=${out##*$'\n'}; out=${out%$'\n'*}
  [ "$code" -lt 400 ] || die "$method $url -> HTTP $code: $out"
  printf '%s' "$out"
}
json() { python3 -c "import sys,json;d=json.load(sys.stdin);print($1)"; }

if [ -z "${BC_COMPANY_ID:-}" ]; then
  BC_COMPANY_ID=$(api GET "$BASE/companies" | json 'd["value"][0]["id"]') || die "no company found"
fi
C="$BASE/companies($BC_COMPANY_ID)"
ok "company $BC_COMPANY_ID"

log "Creating extensionUpload"
# The API keeps one upload record per company; reuse it if a previous upload left one behind
UPLOAD_ID=$(api GET "$C/extensionUpload" | json '(d["value"][0]["systemId"] if d["value"] else "")')
[ -n "$UPLOAD_ID" ] && api PATCH "$C/extensionUpload($UPLOAD_ID)" -H 'Content-Type: application/json' -H 'If-Match: *' \
  -d "{\"schedule\":\"Current Version\",\"schemaSyncMode\":\"$SYNC\"}" >/dev/null
[ -n "$UPLOAD_ID" ] || UPLOAD_ID=$(api POST "$C/extensionUpload" -H 'Content-Type: application/json' \
  -d "{\"schedule\":\"Current Version\",\"schemaSyncMode\":\"$SYNC\"}" | json 'd["systemId"]')
ok "extensionUpload $UPLOAD_ID"

log "Uploading extensionContent"
api PATCH "$C/extensionUpload($UPLOAD_ID)/extensionContent" -H 'Content-Type: application/octet-stream' \
  -H 'If-Match: *' --data-binary "@$APP_FILE" >/dev/null
log "Starting install (Microsoft.NAV.upload)"
api POST "$C/extensionUpload($UPLOAD_ID)/Microsoft.NAV.upload" -H 'Content-Length: 0' >/dev/null
STARTED=$(date -u +%Y-%m-%dT%H:%M:%SZ)

log "Polling extensionDeploymentStatus for $APP_NAME $APP_VERSION"
deadline=$(( $(date +%s) + ${TIMEOUT_SECONDS:-1800} ))
while :; do
  status=$(api GET "$C/extensionDeploymentStatus" | APP_NAME="$APP_NAME" APP_VERSION="$APP_VERSION" python3 -c '
import sys, json, os
rows = [r for r in json.load(sys.stdin)["value"]
        if r.get("name") == os.environ["APP_NAME"] and r.get("appVersion") == os.environ["APP_VERSION"]]
rows.sort(key=lambda r: r.get("startedOn", ""), reverse=True)
print(rows[0]["status"] if rows else "NotFound")')
  echo "    $(date -u +%H:%M:%S) $status"
  case "$status" in
    Completed) ok "deployed $APP_NAME $APP_VERSION to $BC_ENVIRONMENT"; exit 0;;
    Failed) die "deployment failed; see Extension Deployment Status in $BC_ENVIRONMENT (started $STARTED)";;
  esac
  [ "$(date +%s)" -lt "$deadline" ] || die "timed out waiting for deployment (last status: $status)"
  sleep "${POLL_SECONDS:-10}"
done
