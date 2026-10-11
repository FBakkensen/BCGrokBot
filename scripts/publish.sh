#!/usr/bin/env bash
# Build and publish the main app to the container (forcesync).
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
"$(dirname "${BASH_SOURCE[0]}")/build.sh"
cd "$REPO_ROOT"
log "Publishing app/output/app.app to $DEV_URL"
resp=$(mktemp)
code=$(curl -s -o "$resp" -w '%{http_code}' -u "$BC_AUTH" -X POST -F file=@app/output/app.app \
  "$DEV_URL/apps?SchemaUpdateMode=forcesync")
if [ "$code" != 200 ]; then cat "$resp"; echo; rm -f "$resp"; die "publish failed (HTTP $code)"; fi
rm -f "$resp"; ok "published (HTTP 200)"
