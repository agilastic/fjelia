# Sourced by the Fjelia CE scripts. use_public_service builds against the
# public stub (packages/fjelia_service) instead of the private
# ../fjelia-service: it takes fjelia_service out of the local
# pubspec_overrides.yaml (the vendored overrides stay) and puts the file and
# pubspec.lock back, with the private package resolved again, on exit.
use_public_service() {
  local backup
  backup="$(mktemp -d "${TMPDIR:-/tmp}/fjelia-ce.XXXXXX")"
  cp pubspec.lock "$backup/pubspec.lock"
  if [ -f pubspec_overrides.yaml ]; then
    cp pubspec_overrides.yaml "$backup/pubspec_overrides.yaml"
    python3 -I - pubspec_overrides.yaml <<'PY'
import re, sys
path = sys.argv[1]
text = open(path).read()
# Drop the fjelia_service entry and its indented lines.
text = re.sub(r"^  fjelia_service:\n(?:    .*\n)*", "", text, flags=re.M)
open(path, "w").write(text)
PY
  fi
  PUBLIC_SERVICE_BACKUP="$backup"
  trap restore_private_service EXIT
  flutter pub get >/dev/null
}

restore_private_service() {
  local backup="${PUBLIC_SERVICE_BACKUP:-}"
  [ -n "$backup" ] || return 0
  [ -f "$backup/pubspec_overrides.yaml" ] && cp "$backup/pubspec_overrides.yaml" pubspec_overrides.yaml
  cp "$backup/pubspec.lock" pubspec.lock
  rm -rf "$backup"
  PUBLIC_SERVICE_BACKUP=""
  flutter pub get >/dev/null || echo "Run flutter pub get to switch back to the private service." >&2
}
