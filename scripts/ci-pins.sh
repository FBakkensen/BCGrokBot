# Read toolchain pins from .github/workflows/ci.yml. Source, don't execute.
# That workflow file is the single source; cloud-agent install must not copy them.

ci_pins_file() {
  if [ -n "${CI_PINS_FILE:-}" ]; then
    printf '%s\n' "$CI_PINS_FILE"
    return
  fi
  local here
  here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  printf '%s\n' "$here/../.github/workflows/ci.yml"
}

# Print one env-block value (ALRUNNER_SHA, ALRUNNER_REPO, ALRUNNER_BC_VERSION, AL_TOOL_VERSION).
ci_pin() {
  local key="$1" file val
  file="$(ci_pins_file)"
  val="$(sed -n "s/^  ${key}:[[:space:]]*//p" "$file" | head -1 | tr -d "\"'" | tr -d '\r')"
  if [ -z "$val" ]; then
    printf 'missing CI pin %s in %s\n' "$key" "$file" >&2
    return 1
  fi
  printf '%s\n' "$val"
}

# setup-dotnet channels in ci.yml ("8.0.x" -> "8.0"), one per line.
ci_dotnet_channels() {
  local file
  file="$(ci_pins_file)"
  awk '
    /dotnet-version:/ { p = 1; next }
    p && /^[[:space:]]+[0-9]+\.[0-9]+\.x[[:space:]]*$/ {
      v = $1
      sub(/\.x$/, "", v)
      print v
      next
    }
    p && /^[^[:space:]#]/ { exit }
  ' "$file"
}
