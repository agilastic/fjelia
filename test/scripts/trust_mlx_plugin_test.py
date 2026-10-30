import importlib.util
import json
from pathlib import Path
import tempfile
import unittest


spec = importlib.util.spec_from_file_location(
    "trust_mlx_plugin",
    Path(__file__).resolve().parents[2] / "scripts/trust-mlx-plugin.py",
)
trust = importlib.util.module_from_spec(spec)
spec.loader.exec_module(trust)


class TrustMlxPluginTests(unittest.TestCase):
    def test_enables_only_pinned_plugin_and_preserves_other_entries(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "security/plugins.json"
            other = {"packageIdentity": "other", "targetName": "Tool", "custom": 1}
            old = dict(trust.PLUGIN, fingerprint="old-revision")
            path.parent.mkdir()
            path.write_text(json.dumps([other, old]))
            self.assertTrue(trust.enable_plugin(path))
            self.assertEqual(json.loads(path.read_text()), [other, trust.PLUGIN])
            before = path.read_bytes()
            self.assertFalse(trust.enable_plugin(path))
            self.assertEqual(path.read_bytes(), before)

    def test_creates_trust_file_on_first_use(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "security/plugins.json"
            self.assertTrue(trust.enable_plugin(path))
            self.assertEqual(json.loads(path.read_text()), [trust.PLUGIN])

    def test_malformed_existing_file_is_never_replaced(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "plugins.json"
            for content in ['{"unexpected":"format"}', '["invalid entry"]', "broken"]:
                path.write_text(content)
                with self.assertRaises(ValueError):
                    trust.enable_plugin(path)
                self.assertEqual(path.read_text(), content)

    def test_changed_revision_or_origin_requires_review(self):
        source = trust.ROOT / "ios/Runner.xcworkspace/xcshareddata/swiftpm/Package.resolved"
        trust.verify_pin(source)
        for field, value in [("revision", "changed"), ("location", "https://example.com/mlx-swift")]:
            with tempfile.TemporaryDirectory() as directory:
                data = json.loads(source.read_text())
                pin = next(p for p in data["pins"] if p["identity"] == "mlx-swift")
                (pin if field == "location" else pin["state"])[field] = value
                path = Path(directory) / "Package.resolved"
                path.write_text(json.dumps(data))
                with self.assertRaises(ValueError):
                    trust.verify_pin(path)


if __name__ == "__main__":
    unittest.main()
