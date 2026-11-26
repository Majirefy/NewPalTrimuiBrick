#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PORT_DIR="$ROOT/ports/newpal"
OUT="$ROOT/newpal.zip"

if [ ! -d "$PORT_DIR/newpal" ]; then
    echo "Missing port framework directory: $PORT_DIR/newpal" >&2
    exit 1
fi

# Keep the metadata embedded in the zip in sync with the repository copy.
cp -f "$PORT_DIR/port.json" "$PORT_DIR/newpal/newpal.port.json"

rm -f "$OUT"
(
    cd "$PORT_DIR"
    zip -q -r "$OUT" NewPal.sh newpal
)

echo "Built: $OUT"
