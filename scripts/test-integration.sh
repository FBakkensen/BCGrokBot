#!/usr/bin/env bash
# Build, publish main app, then run the test app inside the BC container.
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
"$(dirname "${BASH_SOURCE[0]}")/publish.sh"
mkdir -p "$REPO_ROOT/output"
log "Running integration tests (codeunits 50150..50199)"
$SUDO "$BC_LINUX_DIR/scripts/run-tests.sh" --app "$REPO_ROOT/test/output/test.app" \
  --codeunit-range 50150..50199 --junit-output "$REPO_ROOT/output/junit.xml" "$@"
