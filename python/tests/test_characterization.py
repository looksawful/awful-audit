from __future__ import annotations

import os
import tempfile
import unittest
from pathlib import Path

from awful_scripts.audits import ReportBuilder, index, run


class AuditCharacterizationTests(unittest.TestCase):
    def make_project(self, root: Path) -> None:
        (root / "src").mkdir()
        (root / "public").mkdir()
        (root / "dist").mkdir()
        (root / "node_modules" / "pkg").mkdir(parents=True)
        (root / "index.html").write_text(
            '<main class="hero"><img src="public/hero.webp"></main>', encoding="utf-8"
        )
        (root / "src" / "app.ts").write_text(
            'document.querySelector(".hero")?.classList.add("ready")', encoding="utf-8"
        )
        (root / "src" / "style.css").write_text(
            '.hero{background:url("../public/hero.webp")}', encoding="utf-8"
        )
        (root / "public" / "hero.webp").write_bytes(b"asset")
        (root / "dist" / "bundle.css").write_text(".hero{}", encoding="utf-8")
        (root / "node_modules" / "pkg" / "ignored.js").write_text("ignored", encoding="utf-8")

    def test_all_modes_build_reports(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            self.make_project(root)
            expected_headings = {
                "full": "FULL PROJECT AUDIT",
                "assets": "ASSET AUDIT",
                "css": "CSS AUDIT",
                "html": "HTML AUDIT",
                "js": "JS AUDIT",
                "cssdist": "CSS DIST AUDIT",
                "dist": "DIST AUDIT",
                "all": "AWFUL AUDIT",
            }
            for mode, heading in expected_headings.items():
                with self.subTest(mode=mode):
                    result = run(mode, root)
                    self.assertEqual(result.mode, mode)
                    self.assertTrue(result.text.startswith(heading))

    def test_source_index_skips_canonical_node_modules_and_root_dist(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            self.make_project(root)
            paths = [path.relative_to(root).as_posix() for path in index(root).files]
            self.assertNotIn("node_modules/pkg/ignored.js", paths)
            self.assertNotIn("dist/bundle.css", paths)
            self.assertIn("src/app.ts", paths)

    def test_source_index_skips_mixed_case_generated_directories(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            self.make_project(root)
            (root / "NODE_MODULES" / "pkg").mkdir(parents=True)
            (root / "NODE_MODULES" / "pkg" / "ignored-upper.js").write_text("ignored", encoding="utf-8")
            (root / "src" / "Dist").mkdir()
            (root / "src" / "Dist" / "generated.js").write_text("generated", encoding="utf-8")
            paths = [path.relative_to(root).as_posix() for path in index(root).files]
            self.assertNotIn("NODE_MODULES/pkg/ignored-upper.js", paths)
            self.assertNotIn("src/Dist/generated.js", paths)

    def test_cssdist_includes_source_and_root_dist_css(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            self.make_project(root)
            text = run("cssdist", root).text
            self.assertIn("FILE: src/style.css", text)
            self.assertIn("FILE: dist/bundle.css", text)

    def test_dist_mode_owns_root_dist_only(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            self.make_project(root)
            text = run("dist", root).text
            self.assertIn("dist/bundle.css", text)
            self.assertNotIn("src/style.css", text)

    def test_report_builder_marks_truncation(self) -> None:
        report = ReportBuilder(limit_chars=32)
        report.line("x" * 128)
        self.assertIn("[REPORT TRUNCATED:", report.text())
        self.assertTrue(report.truncated)

    def test_file_limit_environment_uses_default_for_invalid_value(self) -> None:
        old = os.environ.get("AWFUL_AUDIT_MAX_FILE_KB")
        try:
            os.environ["AWFUL_AUDIT_MAX_FILE_KB"] = "not-an-int"
            from awful_scripts.audits import max_file_bytes

            self.assertEqual(max_file_bytes(), 512 * 1024)
        finally:
            if old is None:
                os.environ.pop("AWFUL_AUDIT_MAX_FILE_KB", None)
            else:
                os.environ["AWFUL_AUDIT_MAX_FILE_KB"] = old


if __name__ == "__main__":
    unittest.main()
