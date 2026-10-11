#!/usr/bin/env bash
# Downloads BC 29 (W1) symbols from the public MSSymbols feed into app/.alpackages and test/.alpackages
set -euo pipefail
B=https://dynamicssmb2.pkgs.visualstudio.com/571e802d-b44b-45fc-bd41-4cfddec73b44/_packaging/b656b10c-3de0-440c-900c-bc2e4e86d84c/nuget/v3/flat2
V=29.0.54011.55644
PKGS="microsoft.platform.symbols:29.0.55597 microsoft.application.symbols:$V microsoft.baseapplication.symbols.437dbf0e-84ff-417a-965d-ed2bb9650972:$V microsoft.businessfoundation.symbols.f3552374-a1f2-4356-848e-196002525837:$V microsoft.systemapplication.symbols.63ca2fa4-4f03-4f2b-a480-172fef340d3f:$V microsoft.libraryassert.symbols.dd0be2ea-f733-4d65-bb34-a28f4624fb14:$V microsoft.testrunner.symbols.23de40a6-dfe8-4f80-80db-d70f83ce8caf:$V"
tmp=$(mktemp -d); mkdir -p app/.alpackages test/.alpackages
for p in $PKGS; do id=${p%%:*}; ver=${p##*:}
  curl -sSfL -o "$tmp/$id.nupkg" "$B/$id/$ver/$id.$ver.nupkg"; unzip -qo "$tmp/$id.nupkg" '*.app' -d "$tmp/x"; done
cp "$tmp"/x/*.app app/.alpackages/; cp "$tmp"/x/*.app test/.alpackages/; rm -rf "$tmp"
