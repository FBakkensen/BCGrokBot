#!/usr/bin/env bash
# Stop the BC containers, keeping data (volumes and containers preserved).
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
log "Stopping BC containers (data preserved)"
dc stop; ok "stopped - start again with scripts/bc-up.sh"
