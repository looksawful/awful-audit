from __future__ import annotations

import contextlib
import io
import os
import tempfile
import unittest
from pathlib import Path
from unittest import mock

from awful_scripts.cli import main


class ClipboardPolicyTests(unittest.TestCase):
    def make_large_project(self, root: Path) -> None:
        for index in range(3):
            (root / f"large-{index}.md").write_text("x" * 400_000, encoding="utf-8")

    def test_oversized_full_report_skips_text_clipboard(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            self.make_large_project(root)
            old_limit = os.environ.get("AWFUL_AUDIT_MAX_CLIPBOARD_MB")
            try:
                os.environ["AWFUL_AUDIT_MAX_CLIPBOARD_MB"] = "1"
                stdout = io.StringIO()
                with mock.patch("awful_scripts.cli.copy") as copy_mock, contextlib.redirect_stdout(stdout):
                    code = main(["full", "--root", str(root)])
            finally:
                if old_limit is None:
                    os.environ.pop("AWFUL_AUDIT_MAX_CLIPBOARD_MB", None)
                else:
                    os.environ["AWFUL_AUDIT_MAX_CLIPBOARD_MB"] = old_limit

            self.assertEqual(code, 0)
            self.assertEqual(copy_mock.call_count, 0)
            self.assertIn("clipboard: skipped (report too large)", stdout.getvalue())

    def test_output_path_mode_copies_path_even_when_report_is_large(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            self.make_large_project(root)
            output = root / "reports" / "full.txt"
            old_limit = os.environ.get("AWFUL_AUDIT_MAX_CLIPBOARD_MB")
            try:
                os.environ["AWFUL_AUDIT_MAX_CLIPBOARD_MB"] = "1"
                stdout = io.StringIO()
                with mock.patch("awful_scripts.cli.copy", return_value=True) as copy_mock, contextlib.redirect_stdout(stdout):
                    code = main(["full", "--root", str(root), "--output", str(output)])
            finally:
                if old_limit is None:
                    os.environ.pop("AWFUL_AUDIT_MAX_CLIPBOARD_MB", None)
                else:
                    os.environ["AWFUL_AUDIT_MAX_CLIPBOARD_MB"] = old_limit

            self.assertEqual(code, 0)
            self.assertTrue(output.is_file())
            copy_mock.assert_called_once_with(f"awful-audit report saved: {output.resolve()}")
            self.assertIn("clipboard: output path copied", stdout.getvalue())


if __name__ == "__main__":
    unittest.main()
