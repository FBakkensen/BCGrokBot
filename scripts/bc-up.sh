#!/usr/bin/env bash
# Start dockerd (if needed) and the BC container; auto-recover a broken test toolkit.
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
need docker; need curl
[ -d "$BC_LINUX_DIR" ] || die "missing $BC_LINUX_DIR (git clone https://github.com/StefanMaron/MsDyn365Bc.On.Linux)"
if ! $SUDO docker info >/dev/null 2>&1; then
  log "Starting dockerd"
  $SUDO sh -c 'nohup dockerd >/tmp/dockerd.log 2>&1 &'
  for _ in $(seq 60); do $SUDO docker info >/dev/null 2>&1 && break; sleep 1; done
  $SUDO docker info >/dev/null 2>&1 || die "dockerd did not start (see /tmp/dockerd.log)"
fi
ok "docker running"

toolkit_ok() { # TestRunner API reachable on any company
  local cid
  for base in http://localhost:7048/BC http://localhost:7052/BC; do
    cid=$(curl -s --max-time 10 -u "$BC_AUTH" "$base/api/v2.0/companies" \
      | python3 -c 'import sys,json;print(json.load(sys.stdin)["value"][0]["id"])' 2>/dev/null) || continue
    [ "$(curl -s -o /dev/null -w '%{http_code}' --max-time 10 -u "$BC_AUTH" \
      "$base/api/custom/automation/v1.0/companies($cid)/codeunitRunRequests")" = 200 ] && return 0
  done
  return 1
}
up() { log "docker compose up (BC $BC_VERSION, webclient=$BC_WEBCLIENT)"; dc up -d --wait || die "container did not become healthy (dc logs bc)"; }

up
log "Checking test toolkit"
healthy=0
for _ in $(seq 12); do toolkit_ok && { healthy=1; break; }; sleep 5; done
if [ $healthy -eq 0 ] || dc logs bc 2>&1 | grep -q 'incompatible with the current compiler'; then
  log "Test toolkit broken - recovering with down -v + up (database is reset)"
  dc down -v; up
  for _ in $(seq 24); do toolkit_ok && { healthy=1; break; }; sleep 5; done
  toolkit_ok || die "toolkit still unavailable after reset"
  log "NOTE: database was reset - run scripts/publish.sh to republish apps"
fi
ok "test toolkit available"
if [ "$BC_WEBCLIENT" = 1 ]; then
  for _ in $(seq 30); do curl -sfL -o /dev/null "$WEB_URL" && break; sleep 2; done
  curl -sfL "$WEB_URL" | grep -q 'Business Central' || die "web client not reachable at $WEB_URL"
  ok "web client: $WEB_URL (login ${BC_AUTH%%:*} / ${BC_AUTH#*:})"
fi
