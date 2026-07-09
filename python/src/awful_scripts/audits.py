from __future__ import annotations

import os
import re
import subprocess
from dataclasses import dataclass
from pathlib import Path

SKIP_DIRS = {
    ".git",
    "node_modules",
    "dist",
    "build",
    ".next",
    ".vite",
    "coverage",
    "tmp",
    "temp",
    ".vercel",
    ".wrangler",
    ".cache",
    ".turbo",
    ".parcel-cache",
    ".svelte-kit",
    ".nuxt",
    ".output",
    "out",
    "vendor",
}
CODE_EXTS = {".html", ".css", ".js", ".mjs", ".cjs", ".jsx", ".ts", ".tsx", ".json", ".md"}
JS_EXTS = {".js", ".mjs", ".cjs", ".jsx", ".ts", ".tsx"}
ASSET_EXTS = {
    ".png",
    ".jpg",
    ".jpeg",
    ".webp",
    ".gif",
    ".svg",
    ".avif",
    ".mp4",
    ".webm",
    ".mov",
    ".m4v",
    ".mp3",
    ".wav",
    ".ogg",
    ".glb",
    ".gltf",
    ".hdr",
    ".ico",
    ".woff",
    ".woff2",
    ".ttf",
    ".otf",
    ".pdf",
    ".wasm",
}


def env_int(name: str, default: int, minimum: int = 1) -> int:
    raw = os.environ.get(name, "").strip()
    try:
        value = int(raw)
    except ValueError:
        return default
    return value if value >= minimum else default


def max_file_bytes() -> int:
    return env_int("AWFUL_AUDIT_MAX_FILE_KB", 512, 16) * 1024


def max_report_chars() -> int:
    return env_int("AWFUL_AUDIT_MAX_REPORT_MB", 8, 1) * 1024 * 1024


def max_clipboard_chars() -> int:
    return env_int("AWFUL_AUDIT_MAX_CLIPBOARD_MB", 2, 1) * 1024 * 1024


@dataclass(frozen=True)
class AuditResult:
    mode: str
    text: str


@dataclass
class ProjectIndex:
    root: Path
    files: list[Path]
    files_with_root_dist: list[Path] | None = None
    dist_files: list[Path] | None = None


class ReportBuilder:
    def __init__(self, limit_chars: int | None = None) -> None:
        self.limit_chars = limit_chars or max_report_chars()
        self.parts: list[str] = []
        self.length = 0
        self.truncated = False

    def line(self, value: object = "") -> None:
        if self.truncated:
            return
        text = f"{value}\n"
        if self.length + len(text) > self.limit_chars:
            note = "\n[REPORT TRUNCATED: set AWFUL_AUDIT_MAX_REPORT_MB to a larger value if you need a bigger report]\n"
            self.parts.append(note)
            self.length += len(note)
            self.truncated = True
            return
        self.parts.append(text)
        self.length += len(text)

    def text(self) -> str:
        return "".join(self.parts).rstrip()


def rel(root: Path, path: Path) -> str:
    try:
        return path.relative_to(root).as_posix()
    except ValueError:
        return path.as_posix()


def stat_size(path: Path) -> int:
    try:
        return path.stat().st_size
    except OSError:
        return 0


def read_text_limited(path: Path, limit: int | None = None) -> str:
    limit = limit or max_file_bytes()
    try:
        size = path.stat().st_size
        if size <= limit:
            return path.read_text(encoding="utf-8", errors="replace")
        with path.open("rb") as fh:
            head = fh.read(limit)
        text = head.decode("utf-8", errors="replace")
        return f"{text}\n[TRUNCATED: file is {size} bytes, copied first {limit} bytes]"
    except Exception as exc:
        return f"READ ERROR: {exc}"


def max_scan_line_chars() -> int:
    return env_int("AWFUL_AUDIT_MAX_SCAN_LINE_CHARS", 20000, 1000)


def read_lines_limited(path: Path) -> list[str]:
    return read_text_limited(path).splitlines()


def scan_lines_limited(path: Path) -> list[str]:
    limit = max_scan_line_chars()
    out: list[str] = []
    for line in read_lines_limited(path):
        if len(line) > limit:
            out.append(f"{line[:limit]} [LINE TRUNCATED]")
        else:
            out.append(line)
    return out


def files(root: Path, include_root_dist: bool = False, only_root_dist: bool = False) -> list[Path]:
    root = root.resolve()
    if only_root_dist:
        root = root / "dist"
        if not root.exists():
            return []
        include_root_dist = True
    root_dist = (root / "dist").resolve() if not only_root_dist else root.resolve()
    out: list[Path] = []
    for dirpath, dirnames, filenames in os.walk(root):
        current = Path(dirpath)
        kept: list[str] = []
        for dirname in dirnames:
            child = current / dirname
            is_root_dist = dirname.lower() == "dist" and child.resolve() == root_dist
            if dirname in SKIP_DIRS and not (include_root_dist and is_root_dist):
                continue
            kept.append(dirname)
        dirnames[:] = kept
        for name in filenames:
            out.append(current / name)
    return sorted(out)


def index(root: Path) -> ProjectIndex:
    root = root.resolve()
    return ProjectIndex(root=root, files=files(root))


def files_with_root_dist(idx: ProjectIndex) -> list[Path]:
    if idx.files_with_root_dist is None:
        idx.files_with_root_dist = files(idx.root, include_root_dist=True)
    return idx.files_with_root_dist


def dist_files(idx: ProjectIndex) -> list[Path]:
    if idx.dist_files is None:
        idx.dist_files = files(idx.root, only_root_dist=True)
    return idx.dist_files


def git(root: Path) -> str:
    lines: list[str] = []
    commands = (["git", "branch", "--show-current"], ["git", "status", "--short"], ["git", "log", "-1", "--oneline"])
    for cmd in commands:
        try:
            result = subprocess.run(cmd, cwd=root, text=True, capture_output=True, check=False, timeout=5)
            text = (result.stdout or result.stderr).strip()
            if text:
                lines.append(text)
        except Exception as exc:
            lines.append(f"GIT ERROR: {exc}")
    return "\n".join(lines)


def add_file_block(report: ReportBuilder, root: Path, path: Path, with_size: bool = False) -> None:
    report.line()
    report.line(f"FILE: {rel(root, path)}")
    if with_size:
        report.line(f"SIZE: {stat_size(path)} bytes")
    report.line(read_text_limited(path))


def audit_full(idx: ProjectIndex, limit_chars: int | None = None) -> AuditResult:
    code = [p for p in idx.files if p.suffix.lower() in CODE_EXTS]
    report = ReportBuilder(limit_chars)
    report.line("FULL PROJECT AUDIT")
    report.line(f"ROOT: {idx.root}")
    report.line()
    report.line("GIT")
    report.line(git(idx.root))
    report.line()
    report.line("CODE")
    for path in code:
        if report.truncated:
            break
        add_file_block(report, idx.root, path, with_size=True)
    report.line()
    report.line("INVENTORY")
    report.line(f"TOTAL FILES: {len(idx.files)}")
    for path in idx.files:
        if report.truncated:
            break
        report.line(f"{rel(idx.root, path)} | {path.suffix} | {round(stat_size(path) / 1024, 2)} KB")
    return AuditResult("full", report.text())


def audit_html(idx: ProjectIndex, limit_chars: int | None = None) -> AuditResult:
    selected = [p for p in idx.files if p.suffix.lower() == ".html"]
    report = ReportBuilder(limit_chars)
    report.line("HTML AUDIT")
    report.line(f"ROOT: {idx.root}")
    for path in selected:
        if report.truncated:
            break
        add_file_block(report, idx.root, path)
    return AuditResult("html", report.text())


def audit_js(idx: ProjectIndex, limit_chars: int | None = None) -> AuditResult:
    selected = [p for p in idx.files if p.suffix.lower() in JS_EXTS]
    report = ReportBuilder(limit_chars)
    report.line("JS AUDIT")
    report.line(f"ROOT: {idx.root}")
    for path in selected:
        if report.truncated:
            break
        add_file_block(report, idx.root, path)
    return AuditResult("js", report.text())


def audit_css(idx: ProjectIndex, limit_chars: int | None = None) -> AuditResult:
    selected = [p for p in idx.files if p.suffix.lower() == ".css"]
    report = ReportBuilder(limit_chars)
    report.line("CSS AUDIT")
    report.line(f"ROOT: {idx.root}")
    for path in selected:
        if report.truncated:
            break
        add_file_block(report, idx.root, path)
    report.line()
    report.line("CLASS MENTIONS")
    rx = re.compile(r"(class(Name)?\s*=|classList\.|querySelector(All)?\(|getElementsByClassName\(|\.[_a-zA-Z-][_a-zA-Z0-9-]*)", re.I)
    for path in [p for p in idx.files if p.suffix.lower() in CODE_EXTS]:
        if report.truncated:
            break
        for i, line in enumerate(scan_lines_limited(path), 1):
            if report.truncated:
                break
            if rx.search(line):
                report.line(f"{rel(idx.root, path)}:{i} | {line.strip()}")
    return AuditResult("css", report.text())


def audit_assets(idx: ProjectIndex, limit_chars: int | None = None) -> AuditResult:
    assets = [p for p in idx.files if p.suffix.lower() in ASSET_EXTS]
    code = [p for p in idx.files if p.suffix.lower() in CODE_EXTS]
    rx = re.compile(r"(?<![\w./\\:@%+\-])[\w./\\:@%+\-]{1,260}\.(?:png|jpe?g|webp|gif|svg|avif|mp4|webm|mov|m4v|mp3|wav|ogg|glb|gltf|hdr|ico|woff2?|ttf|otf|pdf|wasm)(?:[?#][^\"'\s)]{0,200})?", re.I)
    report = ReportBuilder(limit_chars)
    report.line("ASSET AUDIT")
    report.line(f"ROOT: {idx.root}")
    report.line(f"ASSETS: {len(assets)}")
    for path in assets:
        if report.truncated:
            break
        report.line(f"{rel(idx.root, path)} | {path.suffix.lower()} | {round(stat_size(path) / 1024, 2)} KB")
    report.line()
    report.line("REFERENCES")
    for path in code:
        if report.truncated:
            break
        for i, line in enumerate(scan_lines_limited(path), 1):
            if report.truncated:
                break
            for match in rx.finditer(line):
                if report.truncated:
                    break
                report.line(f"{rel(idx.root, path)}:{i} | {match.group(0)} | {line.strip()}")
    return AuditResult("assets", report.text())


def audit_cssdist(idx: ProjectIndex, limit_chars: int | None = None) -> AuditResult:
    selected = [p for p in files_with_root_dist(idx) if p.suffix.lower() == ".css"]
    report = ReportBuilder(limit_chars)
    report.line("CSS DIST AUDIT")
    report.line(f"ROOT: {idx.root}")
    for path in selected:
        if report.truncated:
            break
        add_file_block(report, idx.root, path)
    return AuditResult("cssdist", report.text())


def audit_dist(idx: ProjectIndex, limit_chars: int | None = None) -> AuditResult:
    dist = idx.root / "dist"
    report = ReportBuilder(limit_chars)
    report.line("DIST AUDIT")
    report.line(f"ROOT: {idx.root}")
    if not dist.exists():
        report.line("DIST NOT FOUND")
        return AuditResult("dist", report.text())
    selected = dist_files(idx)
    total = sum(stat_size(path) for path in selected)
    report.line(f"FILES: {len(selected)}")
    report.line(f"TOTAL SIZE: {round(total / 1024 / 1024, 2)} MB")
    for path in sorted(selected, key=stat_size, reverse=True):
        if report.truncated:
            break
        report.line(f"{rel(idx.root, path)} | {path.suffix} | {round(stat_size(path) / 1024, 2)} KB")
    return AuditResult("dist", report.text())


MODES = {
    "full": audit_full,
    "assets": audit_assets,
    "css": audit_css,
    "html": audit_html,
    "js": audit_js,
    "cssdist": audit_cssdist,
    "dist": audit_dist,
}


def run(mode: str, root: Path) -> AuditResult:
    mode = mode.lower().strip()
    idx = index(root)
    if mode == "all":
        order = ("full", "assets", "css", "html", "js", "cssdist", "dist")
        total_limit = max_report_chars()
        section_limit = max(512 * 1024, total_limit // len(order))
        report = ReportBuilder(total_limit)
        report.line("AWFUL AUDIT")
        report.line(f"ROOT: {idx.root}")
        for key in order:
            if report.truncated:
                break
            report.line()
            report.line(f"=== {key.upper()} ===")
            report.line(MODES[key](idx, section_limit).text)
        return AuditResult("all", report.text())
    return MODES[mode](idx)
