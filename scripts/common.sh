# Shared settings for BCGrokBot scripts. Source, don't execute.
set -euo pipefail
export DOTNET_ROOT="${DOTNET_ROOT:-$HOME/.dotnet}"
export PATH="$DOTNET_ROOT:$HOME/.dotnet/tools:$PATH"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BC_LINUX_DIR="${BC_LINUX_DIR:-/workspace/MsDyn365Bc.On.Linux}"
ALRUNNER_DLL="${ALRUNNER_DLL:-/workspace/alrunner-bc29/al-runner.dll}"
export BC_VERSION="${BC_VERSION:-29.0.54011.56009}"
export BC_WEBCLIENT="${BC_WEBCLIENT:-1}"
BC_AUTH="${BC_AUTH:-BCRUNNER:Admin123!}"
DEV_URL="${DEV_URL:-http://localhost:7049/BC/dev}"
WEB_URL="${WEB_URL:-http://localhost:8080/}"
MAIN_APP_FILE="Flemming Bakkensen_BCGrokBot_1.0.0.0.app"
log()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
ok()   { printf '\033[1;32m OK\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31mERR\033[0m %s\n' "$*" >&2; exit 1; }
need() { command -v "$1" >/dev/null 2>&1 || die "missing command: $1"; }
SUDO=""; [ "$(id -u)" -ne 0 ] && SUDO="sudo"
dc() { (cd "$BC_LINUX_DIR" && $SUDO -E docker compose "$@"); }
ALCOPS_VERSION="${ALCOPS_VERSION:-1.3.1}"
ANALYZER_DIR="$REPO_ROOT/.analyzers"
RULESET="$REPO_ROOT/BCGrokBot.ruleset.json"
# Directory of the AL tool actually executing (net8.0 host), for Microsoft cops
al_tool_dir() {
  local d; d=$(ls -d "$HOME"/.dotnet/tools/.store/microsoft.dynamics.businesscentral.development.tools/*/microsoft.dynamics.businesscentral.development.tools/*/tools/net8.0/any 2>/dev/null | sort -V | tail -1)
  [ -n "$d" ] && [ -f "$d/Microsoft.Dynamics.Nav.CodeCop.dll" ] || die "AL tool analyzers not found under ~/.dotnet/tools/.store"
  echo "$d"
}
ensure_alcops() {
  [ -f "$ANALYZER_DIR/ALCops.Common.dll" ] && [ -f "$ANALYZER_DIR/.version-$ALCOPS_VERSION" ] && return 0
  log "Downloading ALCops.Analyzers $ALCOPS_VERSION (net8.0)"
  local tmp; tmp=$(mktemp -d)
  curl -sSfL -o "$tmp/p.nupkg" "https://api.nuget.org/v3-flatcontainer/alcops.analyzers/$ALCOPS_VERSION/alcops.analyzers.$ALCOPS_VERSION.nupkg"
  rm -rf "$ANALYZER_DIR"; mkdir -p "$ANALYZER_DIR"
  unzip -qjo "$tmp/p.nupkg" 'lib/net8.0/*.dll' -d "$ANALYZER_DIR"; rm -rf "$tmp"
  touch "$ANALYZER_DIR/.version-$ALCOPS_VERSION"
}
analyzer_args() {
  local d; d=$(al_tool_dir)
  # Analyzers.Common / ALCops.Common must be listed so dependent cops resolve on Linux
  printf '%s\n' "/analyzer:$d/Microsoft.Dynamics.Nav.Analyzers.Common.dll" \
    "/analyzer:$d/Microsoft.Dynamics.Nav.CodeCop.dll" "/analyzer:$d/Microsoft.Dynamics.Nav.UICop.dll" \
    "/analyzer:$d/Microsoft.Dynamics.Nav.PerTenantExtensionCop.dll" "/analyzer:$ANALYZER_DIR/ALCops.Common.dll"
  for c in ApplicationCop DocumentationCop FormattingCop LinterCop PlatformCop TestAutomationCop; do
    echo "/analyzer:$ANALYZER_DIR/ALCops.$c.dll"; done
  echo "/ruleset:$RULESET"
}
