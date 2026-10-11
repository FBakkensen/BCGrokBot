#!/usr/bin/env bash
# Create/update the read-only Microsoft BCApps reference checkout (W1, BC 29).
# Sparse + blobless + shallow: only Base App, W1 tests, System App, Business Foundation, rulesets.
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
need git
REF_DIR="${BCAPPS_REF_DIR:-/workspace/ref/BCApps}"
BRANCH="${BCAPPS_BRANCH:-releases/29.x}"
PATHS=('/src/Layers/W1/BaseApp/' '/src/Layers/W1/Tests/' '/src/System Application/' '/src/Business Foundation/' '/src/rulesets/' '/*.md')
if [ ! -d "$REF_DIR/.git" ]; then
  log "Cloning microsoft/BCApps $BRANCH (sparse) -> $REF_DIR"
  mkdir -p "$(dirname "$REF_DIR")"
  git clone -q --depth 1 --filter=blob:none --sparse -b "$BRANCH" https://github.com/microsoft/BCApps "$REF_DIR"
else
  log "Updating $REF_DIR ($BRANCH)"
  git -C "$REF_DIR" fetch -q --depth 1 origin "$BRANCH"
  git -C "$REF_DIR" reset -q --hard FETCH_HEAD   # read-only mirror: never edit files here
fi
git -C "$REF_DIR" sparse-checkout set --no-cone "${PATHS[@]}"
ok "BCApps $(git -C "$REF_DIR" log -1 --format='%h %cs') | BaseApp $(grep -m1 '"version"' "$REF_DIR/src/Layers/W1/BaseApp/app.json" | tr -dc '0-9.') | $(find "$REF_DIR/src" -type f | wc -l) files"
