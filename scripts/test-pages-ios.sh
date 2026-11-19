#!/usr/bin/env bash
# All-pages walk on the main iPhone (FJELIA_IOS_DEVICE in scripts/local.env).
set -euo pipefail
[ -f "$(dirname "$0")/local.env" ] && . "$(dirname "$0")/local.env"
[ -n "${FJELIA_IOS_DEVICE:-}" ] || { echo "Set FJELIA_IOS_DEVICE in scripts/local.env." >&2; exit 2; }
out="$(cd "$(dirname "$0")/.." && pwd)/build/test-pages/iphone"
rm -rf "$out"
exec "$(dirname "$0")/test-pages.sh" ios --device "$FJELIA_IOS_DEVICE" --out "$out" "$@"
