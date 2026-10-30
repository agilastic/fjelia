#!/usr/bin/env bash
# MLX needs a usable compiler, even when Xcode can reuse cached build products.
set -euo pipefail

if xcrun metal --version >/dev/null 2>&1; then
  exit 0
fi

echo "Metal Toolchain is unavailable; installing/enabling it for the active Xcode..."
xcodebuild -downloadComponent MetalToolchain

# A successful download alone does not prove the compiler can be executed.
if ! xcrun metal --version; then
  echo "Metal Toolchain is still unavailable. Check Xcode > Settings > Components before retrying." >&2
  exit 1
fi

echo "Metal Toolchain is ready. If Xcode was already open, restart it once to refresh its component status."
