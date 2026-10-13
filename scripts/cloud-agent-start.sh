#!/usr/bin/env bash
# Per-boot: start dockerd. The BC container is not started here (it is large
# and only needed for integration tests; run scripts/bc-up.sh).
set -euo pipefail
if sudo docker info >/dev/null 2>&1; then
  exit 0
fi
sudo sh -c 'nohup dockerd >/tmp/dockerd.log 2>&1 &'
for _ in $(seq 60); do
  if sudo docker info >/dev/null 2>&1; then
    exit 0
  fi
  sleep 1
done
echo "dockerd did not start (see /tmp/dockerd.log)" >&2
exit 1
