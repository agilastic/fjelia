#!/usr/bin/env bash
# All-pages walk on the iPhone 11 (FJELIA_IOS_DEVICEI11 in scripts/local.env).
set -euo pipefail
[ -f "$(dirname "$0")/local.env" ] && . "$(dirname "$0")/local.env"
[ -n "${FJELIA_IOS_DEVICEI11:-}" ] || { echo "Set FJELIA_IOS_DEVICEI11 in scripts/local.env." >&2; exit 2; }
out="$(cd "$(dirname "$0")/.." && pwd)/build/test-pages/iphone11"
rm -rf "$out"
exec "$(dirname "$0")/test-pages.sh" ios --device "$FJELIA_IOS_DEVICEI11" --out "$out" "$@"
