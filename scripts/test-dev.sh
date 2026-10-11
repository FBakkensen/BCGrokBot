#!/usr/bin/env bash
# Fast in-process tests with al-runner (no container).
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
need dotnet
[ -f "$ALRUNNER_DLL" ] || die "al-runner not found at $ALRUNNER_DLL (build it from BusinessCentral.AL.Runner main)"
cd "$REPO_ROOT"
log "Running al-runner (BC 29.0) on ./app ./test"
dotnet "$ALRUNNER_DLL" --bc-version 29.0 ./app ./test "$@"
