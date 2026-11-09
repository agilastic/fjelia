# Sourced by the scripts whose builds are handed out (TestFlight, Android
# release, App Store screenshots). Prints a copy of a --dart-define file
# without the developer switches: FJELIA_ECG_CLINICAL (medical ECG reading
# outside FjeliaPro), FJELIA_PRO (Pro without a purchase), and
# FJELIA_DEVELOPER_MENU (Settings > System > Developer).
public_defines() {
  local base out
  # Portable between BSD and GNU mktemp; the define file must end in .json.
  base="$(mktemp "${TMPDIR:-/tmp}/fjelia-defines.XXXXXX")"
  out="$base.json"
  mv "$base" "$out"
  python3 -I -c 'import json, sys
d = json.load(open(sys.argv[1]))
for k in ("FJELIA_ECG_CLINICAL", "FJELIA_PRO", "FJELIA_DEVELOPER_MENU"):
    d.pop(k, None)
json.dump(d, open(sys.argv[2], "w"))' "$1" "$out"
  printf '%s\n' "$out"
}
