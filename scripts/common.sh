# Shared settings for BCGrokBot scripts. Source, don't execute.
set -euo pipefail
# shellcheck disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")/ci-pins.sh"
if [ -z "${DOTNET_ROOT:-}" ]; then
  if [ -x /usr/share/dotnet/dotnet ]; then
    DOTNET_ROOT=/usr/share/dotnet
  else
    DOTNET_ROOT="$HOME/.dotnet"
  fi
fi
export DOTNET_ROOT
export PATH="$DOTNET_ROOT:$HOME/.dotnet/tools:$PATH"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BCGROKBOT_CACHE="${BCGROKBOT_CACHE:-$HOME/.cache/bcgrokbot}"
# Prebuilt al-runner from scripts/cloud-agent-install.sh. CI sets ALRUNNER_DLL.
if [ -z "${ALRUNNER_DLL:-}" ]; then
  ALRUNNER_DLL=""
  for _alr in \
    "$BCGROKBOT_CACHE/al-runner/al-runner.dll" \
    /opt/bcgrokbot/al-runner/al-runner.dll \
    /workspace/alrunner-bc29/al-runner.dll
  do
    if [ -f "$_alr" ]; then ALRUNNER_DLL="$_alr"; break; fi
  done
  ALRUNNER_DLL="${ALRUNNER_DLL:-/workspace/alrunner-bc29/al-runner.dll}"
  unset _alr
fi
if [ -z "${BC_LINUX_DIR:-}" ]; then
  BC_LINUX_DIR=""
  for _bcd in \
    "$BCGROKBOT_CACHE/MsDyn365Bc.On.Linux" \
    /opt/bcgrokbot/MsDyn365Bc.On.Linux \
    /workspace/MsDyn365Bc.On.Linux
  do
    if [ -f "$_bcd/docker-compose.yml" ]; then BC_LINUX_DIR="$_bcd"; break; fi
  done
  BC_LINUX_DIR="${BC_LINUX_DIR:-/workspace/MsDyn365Bc.On.Linux}"
  unset _bcd
fi
if [ -z "${BC_ARTIFACTS_DIR:-}" ] && [ -f "$BCGROKBOT_CACHE/bc-artifacts/app/manifest.json" ]; then
  export BC_ARTIFACTS_DIR="$BCGROKBOT_CACHE/bc-artifacts"
fi
export BC_VERSION="${BC_VERSION:-$(ci_pin ALRUNNER_BC_VERSION)}"
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
dc() {
  local -a files=(-f "$BC_LINUX_DIR/docker-compose.yml")
  if [ "${BC_DOCKER_NETWORK:-}" = "host" ]; then
    files+=(-f "$REPO_ROOT/scripts/docker-compose.cloud-agent.yml")
  fi
  (cd "$BC_LINUX_DIR" && $SUDO -E docker compose "${files[@]}" "$@")
}
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
