#!/usr/bin/env python3
"""Enable the reviewed MLX build plugin for Fjelia's exact pinned revision."""

import json
import os
from pathlib import Path
import sys
import tempfile


ROOT = Path(__file__).resolve().parents[1]
REVISION = "0bb916c67f4b9e5c682cbe02a42c701c93ab5021"
PLUGIN = {
    "fingerprint": REVISION,
    "packageIdentity": "mlx-swift",
    "targetName": "CudaBuild",
}


def verify_pin(resolved):
    pins = json.loads(resolved.read_text())["pins"]
    matches = [pin for pin in pins if pin["identity"] == "mlx-swift"]
    if len(matches) != 1 or (
        matches[0].get("location", "").removesuffix(".git")
        != "https://github.com/ml-explore/mlx-swift"
        or matches[0]["state"].get("revision") != REVISION
        or matches[0]["state"].get("version") != "0.31.6"
    ):
        raise ValueError("MLX pin changed; review CudaBuild before enabling it")


def enable_plugin(path):
    entries = json.loads(path.read_text()) if path.exists() else []
    if not isinstance(entries, list) or any(not isinstance(e, dict) for e in entries):
        raise ValueError(f"Unexpected plugin trust file format: {path}")
    if PLUGIN in entries:
        return False
    # Preserve other packages and plugins, including their additional fields.
    entries = [
        entry for entry in entries
        if (entry.get("packageIdentity"), entry.get("targetName"))
        != (PLUGIN["packageIdentity"], PLUGIN["targetName"])
    ]
    entries.append(PLUGIN)
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = None
    try:
        with tempfile.NamedTemporaryFile(
            mode="w", dir=path.parent, prefix=".fjelia-plugin-", delete=False
        ) as stream:
            temporary = Path(stream.name)
            json.dump(entries, stream, indent=2)
            stream.write("\n")
        os.replace(temporary, path)
    finally:
        if temporary is not None:
            temporary.unlink(missing_ok=True)
    return True


def main():
    if len(sys.argv) > 1:
        raise ValueError("Usage: python3 scripts/trust-mlx-plugin.py")
    resolved = ROOT / "ios/Runner.xcworkspace/xcshareddata/swiftpm/Package.resolved"
    verify_pin(resolved)
    path = Path.home() / "Library/org.swift.swiftpm/security/plugins.json"
    changed = enable_plugin(path)
    print(
        f"MLX CudaBuild {'enabled' if changed else 'already enabled'} "
        f"for 0.31.6 ({REVISION[:12]})."
    )


if __name__ == "__main__":
    try:
        main()
    except (OSError, ValueError, KeyError) as error:
        sys.exit(f"Cannot enable MLX plugin: {error}")
