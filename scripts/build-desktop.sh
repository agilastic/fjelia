#!/usr/bin/env bash
# Build Fjelia desktop for this machine from the sibling fjelia-desktop
# checkout; arguments go to its scripts/build.sh (e.g. --profile).
set -euo pipefail
desktop="$(cd "$(dirname "$0")/../.." && pwd)/fjelia-desktop"
case "${1:-}" in
  -h|--help)
    cat <<'EOT'
Usage: scripts/build-desktop.sh [--profile]
Builds Fjelia desktop for this machine (macOS universal app, Linux or Windows)
with ../fjelia-desktop/scripts/build.sh and prints the path of the result.
Needs fjelia-desktop and fjelia-core checked out next to this repository.
EOT
    exit 0 ;;
esac
[ -x "$desktop/scripts/build.sh" ] || {
  echo "fjelia-desktop not found next to this repository: $desktop" >&2
  exit 1
}
exec "$desktop/scripts/build.sh" "$@"
