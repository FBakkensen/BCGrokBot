#!/usr/bin/env bash
# Wipe BC database/volumes and start fresh.
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
log "Resetting BC (down -v) - all data is deleted"
dc down -v
"$(dirname "${BASH_SOURCE[0]}")/bc-up.sh"
