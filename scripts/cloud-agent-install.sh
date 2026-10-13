#!/usr/bin/env bash
# Idempotent Cloud Agent Build install. Pins come from .github/workflows/ci.yml
# (scripts/ci-pins.sh). Heavy outputs live under ~/.cache/bcgrokbot and
# /usr/share/dotnet so a later git checkout does not throw them away.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
# shellcheck disable=SC1091
source "$ROOT/scripts/common.sh"

ALRUNNER_REPO="$(ci_pin ALRUNNER_REPO)"
ALRUNNER_SHA="$(ci_pin ALRUNNER_SHA)"
ALRUNNER_BC_VERSION="$(ci_pin ALRUNNER_BC_VERSION)"
AL_TOOL_VERSION="$(ci_pin AL_TOOL_VERSION)"
CACHE="$BCGROKBOT_CACHE"
mkdir -p "$CACHE"

step_start=$SECONDS
step() { printf '\033[1;34m==>\033[0m %s\n' "$*"; step_start=$SECONDS; }
step_ok() { printf '\033[1;32m OK\033[0m %s (%ss)\n' "$1" "$((SECONDS - step_start))"; }

step "OS packages"
sudo DEBIAN_FRONTEND=noninteractive apt-get update -qq
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
  -o Dpkg::Options::=--force-confdef \
  -o Dpkg::Options::=--force-confold \
  ca-certificates curl git unzip python3 xz-utils \
  docker.io docker-compose-v2 iptables
step_ok "packages"

step "iptables-legacy (compose bridges)"
# The VM ships iptables-legacy FORWARD policy DROP that only accepts docker0.
# Docker's nft backend never updates that table, so user-defined compose
# networks cannot forward or egress. Point the iptables binary at legacy
# before dockerd programs rules.
sudo update-alternatives --set iptables /usr/sbin/iptables-legacy
sudo update-alternatives --set ip6tables /usr/sbin/ip6tables-legacy
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json >/dev/null << 'EOF'
{
  "storage-driver": "overlayfs",
  "iptables": true,
  "ip6tables": false,
  "firewall-backend": "iptables"
}
EOF
if ! id -nG ubuntu | tr ' ' '\n' | grep -qx docker; then
  sudo usermod -aG docker ubuntu
fi
step_ok "docker config"

step ".NET SDKs"
channels="$(ci_dotnet_channels)"
[ -n "$channels" ] || die "no dotnet-version channels in ci.yml"
# common.sh chose DOTNET_ROOT before these SDKs existed. Pin it now.
export DOTNET_ROOT=/usr/share/dotnet
export PATH="$DOTNET_ROOT:$HOME/.dotnet/tools:$PATH"
curl -fsSL https://dot.net/v1/dotnet-install.sh -o /tmp/dotnet-install.sh
while read -r channel; do
  [ -n "$channel" ] || continue
  if [ -x /usr/share/dotnet/dotnet ] && /usr/share/dotnet/dotnet --list-sdks 2>/dev/null | grep -q "^${channel}"; then
    continue
  fi
  sudo bash /tmp/dotnet-install.sh --channel "$channel" --install-dir /usr/share/dotnet
done <<< "$channels"
sudo ln -sfn /usr/share/dotnet/dotnet /usr/local/bin/dotnet
step_ok "dotnet $(dotnet --list-sdks | tr '\n' ' ')"

step "AL compiler $AL_TOOL_VERSION"
export PATH="$DOTNET_ROOT:$HOME/.dotnet/tools:$PATH"
if ! dotnet tool list -g | awk 'NR>1 {print $1, $2}' | grep -qx "microsoft.dynamics.businesscentral.development.tools ${AL_TOOL_VERSION}"; then
  if dotnet tool list -g | awk 'NR>1 {print $1}' | grep -qx microsoft.dynamics.businesscentral.development.tools; then
    dotnet tool update -g Microsoft.Dynamics.BusinessCentral.Development.Tools --version "$AL_TOOL_VERSION"
  else
    dotnet tool install -g Microsoft.Dynamics.BusinessCentral.Development.Tools --version "$AL_TOOL_VERSION"
  fi
fi
sudo ln -sfn "$HOME/.dotnet/tools/al" /usr/local/bin/al
sudo tee /etc/profile.d/bcgrokbot.sh >/dev/null << 'EOF'
export DOTNET_ROOT="${DOTNET_ROOT:-/usr/share/dotnet}"
export PATH="$DOTNET_ROOT:${HOME}/.dotnet/tools:${PATH}"
EOF
step_ok "al $($HOME/.dotnet/tools/al --version)"

step "al-runner $ALRUNNER_SHA"
out="$CACHE/al-runner"
stamp="$out/.built-sha"
if [ ! -f "$out/al-runner.dll" ] || [ "$(cat "$stamp" 2>/dev/null || true)" != "$ALRUNNER_SHA" ]; then
  src="$CACHE/alrunner-src"
  rm -rf "$src"
  git init -q "$src"
  git -C "$src" fetch -q --depth 1 "https://github.com/${ALRUNNER_REPO}" "$ALRUNNER_SHA"
  git -C "$src" checkout -q FETCH_HEAD
  dotnet build "$src/AlRunner/" -c Release \
    -p:_BCVersion="$ALRUNNER_BC_VERSION" \
    -p:AllowBcArtifactDownload=true \
    -o "$out"
  printf '%s\n' "$ALRUNNER_SHA" > "$stamp"
fi
step_ok "$out/al-runner.dll"

step "BC Linux clone and artifacts"
bc_dir="$CACHE/MsDyn365Bc.On.Linux"
if [ ! -d "$bc_dir/.git" ]; then
  git clone -q --depth 1 https://github.com/StefanMaron/MsDyn365Bc.On.Linux "$bc_dir"
fi
art="$CACHE/bc-artifacts"
# Same request the container stamps: args|sandbox|<version>|w1
bash "$bc_dir/scripts/download-artifacts.sh" sandbox "$BC_VERSION" w1 "$art"
export BC_ARTIFACTS_DIR="$art"
step_ok "artifacts $art"

step "Docker images"
if ! sudo docker info >/dev/null 2>&1; then
  sudo sh -c 'nohup dockerd >/tmp/dockerd.log 2>&1 &'
  for _ in $(seq 60); do
    sudo docker info >/dev/null 2>&1 && break
    sleep 1
  done
  sudo docker info >/dev/null 2>&1 || die "dockerd did not start (see /tmp/dockerd.log)"
fi
# Tags come from the upstream compose file, not a second pin.
(cd "$bc_dir" && sudo -E docker compose pull)
step_ok "compose pull"

step "Warm build and dev tests"
# Fills app/.alpackages, .analyzers, and the al-runner BC artifact cache
# (~/.cache/al-runner) so the next agent's build.sh / test-dev.sh hit disk.
scripts/build.sh
scripts/test-dev.sh
step_ok "build + test-dev"

ok "cloud-agent install complete (al-runner $ALRUNNER_SHA)"
