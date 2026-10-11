#!/usr/bin/env bash
# Pin microsoft/BCQuality at /workspace/ref/BCQuality, copy our custom rules into its
# custom/ layer, and rebuild the knowledge index (needs pwsh; skipped if missing).
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
need git
BCQ_DIR="${BCQUALITY_DIR:-/workspace/ref/BCQuality}"
BCQ_PIN="$(tr -d '[:space:]' < "$REPO_ROOT/quality/BCQUALITY_PIN")"
[ -d "$BCQ_DIR/.git" ] || { log "Cloning microsoft/BCQuality"; git clone -q https://github.com/microsoft/BCQuality "$BCQ_DIR"; }
if [ "$(git -C "$BCQ_DIR" rev-parse HEAD)" != "$BCQ_PIN" ]; then
  log "Checking out pinned BCQuality $BCQ_PIN"
  git -C "$BCQ_DIR" fetch -q origin
  git -C "$BCQ_DIR" checkout -q --detach "$BCQ_PIN"
fi
log "Syncing quality/bcquality-custom -> $BCQ_DIR/custom"
rm -rf "$BCQ_DIR/custom/knowledge" "$BCQ_DIR/custom/skills"
cp -r "$REPO_ROOT/quality/bcquality-custom/knowledge" "$REPO_ROOT/quality/bcquality-custom/skills" "$BCQ_DIR/custom/"
if command -v pwsh >/dev/null 2>&1; then
  pwsh -NoProfile -File "$BCQ_DIR/tools/Build-KnowledgeIndex.ps1" | tail -1
else
  log "pwsh not found - BCQuality falls back to folder discovery (install: dotnet tool install -g PowerShell)"
fi
ok "BCQuality $(git -C "$BCQ_DIR" rev-parse --short HEAD) ready"
