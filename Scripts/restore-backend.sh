#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="$ROOT/OriginalApp/KayakTime.app"
CHUNKS="$ROOT/BackendChunks"
OUT="$APP/KayakTime"
mkdir -p "$APP"
cat "$CHUNKS"/KayakTime.part* > "$OUT"
EXPECTED="$(awk '{print $1}' "$CHUNKS/KayakTime.sha256")"
ACTUAL="$(shasum -a 256 "$OUT" | awk '{print $1}')"
if [ "$EXPECTED" != "$ACTUAL" ]; then
  echo "ERROR: restored backend executable checksum mismatch" >&2
  exit 1
fi
chmod +x "$OUT"
echo "Backend executable restored and checksum verified."
