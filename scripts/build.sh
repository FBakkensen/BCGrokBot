#!/usr/bin/env bash
# Compile main app and test app. Fetches symbols if missing.
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
need al
cd "$REPO_ROOT"
if ! ls app/.alpackages/System.app test/.alpackages/System.app >/dev/null 2>&1 \
   || ! ls test/.alpackages/*Library\ Assert* >/dev/null 2>&1; then
  log "Symbols missing - downloading"; ./get-symbols.sh
fi
ensure_alcops
mapfile -t ANALYZERS < <(analyzer_args)
STRICT="${STRICT:-1}"  # 1 = warnings/analyzer failures fail the build
compile() { # project out
  log "Compiling $1"
  local outlog; outlog=$(mktemp)
  if ! al compile /project:"$1" /packagecachepath:"$1/.alpackages" /out:"$2" "${ANALYZERS[@]}" >"$outlog" 2>&1 \
     || grep -qE ': error [A-Z]+[0-9]+' "$outlog"; then
    cat "$outlog"; rm -f "$outlog"; die "compile failed: $1"; fi
  if grep -qE 'warning [A-Z]+[0-9]+|Exception' "$outlog"; then
    grep -E 'warning [A-Z]+[0-9]+|Exception:' "$outlog"
    [ "$STRICT" = 1 ] && { rm -f "$outlog"; die "warnings in $1 (STRICT=0 to allow)"; }
  fi
  rm -f "$outlog"
  [ -f "$2" ] || die "no output produced: $2"; ok "$2"
}
mkdir -p app/output test/output
compile app app/output/app.app
cp -f app/output/app.app "test/.alpackages/$MAIN_APP_FILE"
compile test test/output/test.app
