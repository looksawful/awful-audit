from __future__ import annotations

import contextlib
import io
import tempfile
import unittest
from pathlib import Path

from awful_scripts.cli import main, parser


class CliCharacterizationTests(unittest.TestCase):
    def test_parser_exposes_canonical_mode_and_no_clipboard(self) -> None:
        args = parser().parse_args(["html", "--root", ".", "--no-clipboard"])
        self.assertEqual(args.mode, "html")
        self.assertTrue(args.no_clipboard)

    def test_output_file_mode_writes_report_and_returns_zero(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            (root / "index.html").write_text("<main>cli fixture</main>", encoding="utf-8")
            output = root / "reports" / "html.txt"
            stdout = io.StringIO()
            with contextlib.redirect_stdout(stdout):
                code = main(
                    [
                        "html",
                        "--root",
                        str(root),
                        "--output",
                        str(output),
                        "--no-clipboard",
                    ]
                )
            self.assertEqual(code, 0)
            self.assertTrue(output.is_file())
            self.assertIn("HTML AUDIT", output.read_text(encoding="utf-8"))
            self.assertIn("clipboard: disabled", stdout.getvalue())

    def test_print_flag_keeps_report_on_stdout_with_output_file(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            (root / "index.html").write_text("<main>printed fixture</main>", encoding="utf-8")
            output = root / "report.txt"
            stdout = io.StringIO()
            with contextlib.redirect_stdout(stdout):
                code = main(
                    [
                        "html",
                        "--root",
                        str(root),
                        "--output",
                        str(output),
                        "--no-clipboard",
                        "--print",
                    ]
                )
            self.assertEqual(code, 0)
            self.assertIn("HTML AUDIT", stdout.getvalue())
            self.assertTrue(output.is_file())


if __name__ == "__main__":
    unittest.main()
