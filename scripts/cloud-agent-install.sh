#!/usr/bin/env bash
# Idempotent Cursor Cloud Agent bootstrap. Mirrors .github/workflows/ci.yml:
# .NET 8 + 10 SDKs, AL compiler 18.0.x, BC 29 W1 symbols, ALCops, al-runner from source.
# Does not start Docker or the BC Linux container (optional; RAM-heavy).
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

export DOTNET_ROOT="${DOTNET_ROOT:-$HOME/.dotnet}"
export PATH="$DOTNET_ROOT:$HOME/.dotnet/tools:$PATH"
export DOTNET_CLI_TELEMETRY_OPTOUT=1

# Pins match ci.yml. Override via env when bumping.
AL_TOOL_VERSION="${AL_TOOL_VERSION:-18.0.43.1464}"
ALRUNNER_REPO="${ALRUNNER_REPO:-StefanMaron/BusinessCentral.AL.Runner}"
ALRUNNER_SHA="${ALRUNNER_SHA:-9c2e53a512e1096aa72ce0321f4d711f92f77f96}"
ALRUNNER_BC_VERSION="${ALRUNNER_BC_VERSION:-29.0.54011.56009}"
ALRUNNER_DLL="${ALRUNNER_DLL:-$REPO_ROOT/alrunner-bc29/al-runner.dll}"

log() { printf '==> %s\n' "$*"; }

have() { command -v "$1" >/dev/null 2>&1; }

link_on_path() { # src dest — login shells may not load ~/.bashrc
  local src="$1" dest="$2"
  [ -x "$src" ] || return 0
  if [ -e "$dest" ] && [ "$(readlink -f "$dest" 2>/dev/null || true)" = "$(readlink -f "$src")" ]; then
    return 0
  fi
  if [ -w "$(dirname "$dest")" ]; then
    ln -sfn "$src" "$dest"
  elif have sudo; then
    sudo ln -sfn "$src" "$dest"
  fi
}

if ! have unzip || ! have curl; then
  log "Installing unzip/curl"
  sudo DEBIAN_FRONTEND=noninteractive apt-get update -qq
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq unzip curl
fi

if ! have dotnet || ! dotnet --list-sdks 2>/dev/null | grep -q '^8\.0' \
   || ! dotnet --list-sdks 2>/dev/null | grep -q '^10\.0'; then
  log "Installing .NET 8 and 10 SDKs into $DOTNET_ROOT"
  curl -fsSL https://dot.net/v1/dotnet-install.sh -o /tmp/dotnet-install.sh
  bash /tmp/dotnet-install.sh --channel 8.0 --install-dir "$DOTNET_ROOT"
  bash /tmp/dotnet-install.sh --channel 10.0 --install-dir "$DOTNET_ROOT"
fi
link_on_path "$DOTNET_ROOT/dotnet" /usr/local/bin/dotnet

if ! have al || ! al --version 2>/dev/null | grep -q "$AL_TOOL_VERSION"; then
  log "Installing AL compiler $AL_TOOL_VERSION"
  if dotnet tool list -g | grep -qi 'microsoft.dynamics.businesscentral.development.tools'; then
    dotnet tool update -g Microsoft.Dynamics.BusinessCentral.Development.Tools --version "$AL_TOOL_VERSION"
  else
    dotnet tool install -g Microsoft.Dynamics.BusinessCentral.Development.Tools --version "$AL_TOOL_VERSION"
  fi
fi
link_on_path "$HOME/.dotnet/tools/al" /usr/local/bin/al

if [ ! -f app/.alpackages/System.app ] || [ ! -f test/.alpackages/System.app ] \
   || ! ls test/.alpackages/*Library\ Assert* >/dev/null 2>&1; then
  log "Downloading BC 29 W1 symbols"
  ./get-symbols.sh
fi

# shellcheck source=common.sh
source "$REPO_ROOT/scripts/common.sh"
ensure_alcops

if [ ! -f "$ALRUNNER_DLL" ]; then
  log "Building al-runner $ALRUNNER_SHA for BC $ALRUNNER_BC_VERSION"
  src=$(mktemp -d)
  git init -q "$src"
  git -C "$src" fetch -q --depth 1 "https://github.com/$ALRUNNER_REPO" "$ALRUNNER_SHA"
  git -C "$src" checkout -q FETCH_HEAD
  mkdir -p "$(dirname "$ALRUNNER_DLL")"
  dotnet build "$src/AlRunner/" -c Release -p:_BCVersion="$ALRUNNER_BC_VERSION" \
    -p:AllowBcArtifactDownload=true -o "$(dirname "$ALRUNNER_DLL")"
  rm -rf "$src"
fi

ok "cloud-agent install ready (al $(al --version 2>/dev/null | head -1); al-runner $( [ -f "$ALRUNNER_DLL" ] && echo present || echo missing ))"
