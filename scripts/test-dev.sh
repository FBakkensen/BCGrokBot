#!/usr/bin/env bash
# Fast in-process tests with al-runner (no container).
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
need dotnet
[ -f "$ALRUNNER_DLL" ] || die "al-runner not found at $ALRUNNER_DLL (build it from BusinessCentral.AL.Runner main)"
cd "$REPO_ROOT"
# Container-only test codeunits (need real permission enforcement / CRONUS data); run by test-integration.sh.
CONTAINER_ONLY_CODEUNITS=(50152)
EXCLUDES=()
for c in "${CONTAINER_ONLY_CODEUNITS[@]}"; do EXCLUDES+=(--exclude-test "Codeunit$c"); done
log "Running al-runner (BC 29.0) on ./app ./test (excluding container-only: ${CONTAINER_ONLY_CODEUNITS[*]})"
dotnet "$ALRUNNER_DLL" --bc-version 29.0 "${EXCLUDES[@]}" ./app ./test "$@"
