#!/usr/bin/env bash
# Verify that the mesh forward-path case survived backports preprocessing.
set -euo pipefail

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <prepared-backports-directory>" >&2
    exit 2
fi

backports_dir=$1
config="$backports_dir/.config"
source="$backports_dir/net/mac80211/iface.c"
object="$backports_dir/net/mac80211/iface.o"

for path in "$config" "$source" "$object"; do
    if [ ! -f "$path" ]; then
        echo "Missing mesh forward-path build input: $path" >&2
        exit 1
    fi
done

if ! grep -qx 'CPTCFG_MAC80211_MESH=y' "$config"; then
    echo "Backports mesh support is disabled in $config" >&2
    exit 1
fi

for symbol in mesh_path_lookup mpp_path_lookup; do
    if ! readelf --wide --symbols "$object" | awk -v symbol="$symbol" \
        '$7 == "UND" && $8 == symbol { found = 1 } END { exit !found }'; then
        echo "Mesh forward-path code was not compiled: $symbol absent from $object" >&2
        exit 1
    fi
done

echo "Mesh forward-path build check passed: active route and portal lookups compiled"
