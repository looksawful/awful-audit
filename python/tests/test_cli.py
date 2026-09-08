from __future__ import annotations

import contextlib
import io
import subprocess
import sys
import tempfile
import textwrap
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

    def test_missing_root_fails_without_report_or_output_file(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            missing = Path(td) / "does-not-exist"
            output = Path(td) / "missing-root.txt"
            stdout = io.StringIO()
            stderr = io.StringIO()
            with contextlib.redirect_stdout(stdout), contextlib.redirect_stderr(stderr):
                code = main(
                    [
                        "full",
                        "--root",
                        str(missing),
                        "--output",
                        str(output),
                        "--no-clipboard",
                    ]
                )
            self.assertNotEqual(code, 0)
            self.assertIn("root", stderr.getvalue().lower())
            self.assertIn(str(missing), stderr.getvalue())
            self.assertNotIn("FULL PROJECT AUDIT", stdout.getvalue())
            self.assertFalse(output.exists())

    def test_file_root_fails_without_report_or_output_file(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            root_file = Path(td) / "not-a-directory.txt"
            root_file.write_text("not a project directory", encoding="utf-8")
            output = Path(td) / "file-root.txt"
            stdout = io.StringIO()
            stderr = io.StringIO()
            with contextlib.redirect_stdout(stdout), contextlib.redirect_stderr(stderr):
                code = main(
                    [
                        "full",
                        "--root",
                        str(root_file),
                        "--output",
                        str(output),
                        "--no-clipboard",
                    ]
                )
            self.assertNotEqual(code, 0)
            self.assertIn("root", stderr.getvalue().lower())
            self.assertIn(str(root_file), stderr.getvalue())
            self.assertNotIn("FULL PROJECT AUDIT", stdout.getvalue())
            self.assertFalse(output.exists())

    def test_cli_import_does_not_require_tkinter(self) -> None:
        script = textwrap.dedent(
            """
            import builtins

            real_import = builtins.__import__

            def blocked_import(name, *args, **kwargs):
                if name == "tkinter" or name.startswith("tkinter."):
                    raise ImportError("simulated tkinter unavailable")
                return real_import(name, *args, **kwargs)

            builtins.__import__ = blocked_import
            import awful_scripts.cli
            print("cli import ok")
            """
        )
        result = subprocess.run([sys.executable, "-c", script], text=True, capture_output=True, check=False)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("cli import ok", result.stdout)

    def test_gui_mode_reports_missing_tkinter_only_when_selected(self) -> None:
        script = textwrap.dedent(
            """
            import builtins

            real_import = builtins.__import__

            def blocked_import(name, *args, **kwargs):
                if name == "tkinter" or name.startswith("tkinter."):
                    raise ImportError("simulated tkinter unavailable")
                return real_import(name, *args, **kwargs)

            builtins.__import__ = blocked_import
            from awful_scripts.cli import main
            raise SystemExit(main(["gui", "--root", "."]))
            """
        )
        result = subprocess.run([sys.executable, "-c", script], text=True, capture_output=True, check=False)
        self.assertEqual(result.returncode, 2)
        self.assertIn("gui", result.stderr.lower())
        self.assertIn("tkinter", result.stderr.lower())
        self.assertNotIn("traceback", result.stderr.lower())


if __name__ == "__main__":
    unittest.main()
