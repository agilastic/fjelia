import os
from pathlib import Path
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[2]


class MetalToolchainTests(unittest.TestCase):
    def run_preflight(self, ready=False, download_fails=False, activation_fails=False):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            state = root / "ready"
            calls = root / "calls"
            if ready:
                state.touch()
            tools = {
                "xcrun": '''#!/bin/sh
echo "xcrun $*" >> "$FJELIA_TEST_METAL_CALLS"
test -f "$FJELIA_TEST_METAL_STATE"
''',
                "xcodebuild": '''#!/bin/sh
echo "xcodebuild $*" >> "$FJELIA_TEST_METAL_CALLS"
if test "$FJELIA_TEST_DOWNLOAD_FAILS" = 1; then exit 7; fi
if test "$FJELIA_TEST_ACTIVATION_FAILS" != 1; then
  /usr/bin/touch "$FJELIA_TEST_METAL_STATE"
fi
''',
            }
            for name, content in tools.items():
                path = root / name
                path.write_text(content)
                path.chmod(0o755)
            env = dict(os.environ)
            env.update({
                "PATH": f"{root}:/usr/bin:/bin",
                "FJELIA_TEST_METAL_STATE": str(state),
                "FJELIA_TEST_METAL_CALLS": str(calls),
                "FJELIA_TEST_DOWNLOAD_FAILS": "1" if download_fails else "0",
                "FJELIA_TEST_ACTIVATION_FAILS": "1" if activation_fails else "0",
            })
            result = subprocess.run(
                ["/bin/bash", str(ROOT / "scripts/ensure-metal-toolchain.sh")],
                env=env, text=True, capture_output=True, timeout=10,
            )
            return result, calls.read_text().splitlines()

    def test_working_compiler_never_downloads(self):
        result, calls = self.run_preflight(ready=True)
        self.assertEqual(result.returncode, 0)
        self.assertEqual(calls, ["xcrun metal --version"])

    def test_missing_compiler_is_installed_then_verified(self):
        result, calls = self.run_preflight()
        self.assertEqual(result.returncode, 0)
        self.assertEqual(calls, [
            "xcrun metal --version",
            "xcodebuild -downloadComponent MetalToolchain",
            "xcrun metal --version",
        ])

    def test_download_failure_stops_the_build(self):
        result, calls = self.run_preflight(download_fails=True)
        self.assertEqual(result.returncode, 7)
        self.assertEqual(len(calls), 2)

    def test_successful_download_with_unusable_compiler_still_fails(self):
        result, calls = self.run_preflight(activation_fails=True)
        self.assertEqual(result.returncode, 1)
        self.assertIn("still unavailable", result.stderr)
        self.assertEqual(len(calls), 3)


if __name__ == "__main__":
    unittest.main()
