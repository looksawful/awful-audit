from __future__ import annotations

import os
import re
import subprocess
from dataclasses import dataclass
from pathlib import Path

SKIP_DIRS = {".git", "node_modules", "dist", "build", ".next", ".vite", "coverage", "tmp", "temp", ".vercel", ".wrangler"}
CODE_EXTS = {".html", ".css", ".js", ".mjs", ".cjs", ".jsx", ".ts", ".tsx", ".json", ".md"}
JS_EXTS = {".js", ".mjs", ".cjs", ".jsx", ".ts", ".tsx"}
ASSET_EXTS = {".png", ".jpg", ".jpeg", ".webp", ".gif", ".svg", ".avif", ".mp4", ".webm", ".mov", ".m4v", ".mp3", ".wav", ".ogg", ".glb", ".gltf", ".hdr", ".ico", ".woff", ".woff2", ".ttf", ".otf", ".pdf", ".wasm"}


@dataclass(frozen=True)
class AuditResult:
    mode: str
    text: str


def rel(root: Path, path: Path) -> str:
    return path.relative_to(root).as_posix()


def text(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8")
    except UnicodeDecodeError:
        return path.read_text(encoding="utf-8", errors="replace")
    except Exception as exc:
        return f"READ ERROR: {exc}"


def files(root: Path, include_dist: bool = False) -> list[Path]:
    out: list[Path] = []
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = [d for d in dirnames if d not in SKIP_DIRS or (include_dist and d == "dist")]
        for name in filenames:
            out.append(Path(dirpath) / name)
    return sorted(out)


def git(root: Path) -> str:
    lines = []
    for cmd in (["git", "branch", "--show-current"], ["git", "status", "--short"], ["git", "log", "-1", "--oneline"]):
        try:
            lines.append(subprocess.run(cmd, cwd=root, text=True, capture_output=True, check=False).stdout.strip())
        except Exception as exc:
            lines.append(f"GIT ERROR: {exc}")
    return "\n".join(x for x in lines if x)


def audit_full(root: Path) -> AuditResult:
    root = root.resolve()
    all_files = files(root)
    code = [p for p in all_files if p.suffix.lower() in CODE_EXTS]
    lines = ["FULL PROJECT AUDIT", f"ROOT: {root}", "", "GIT", git(root), "", "CODE"]
    for p in code:
        lines += ["", f"FILE: {rel(root, p)}", f"SIZE: {p.stat().st_size} bytes", text(p)]
    lines += ["", "INVENTORY", f"TOTAL FILES: {len(all_files)}"]
    lines += [f"{rel(root, p)} | {p.suffix} | {round(p.stat().st_size / 1024, 2)} KB" for p in all_files]
    return AuditResult("full", "\n".join(lines))


def audit_html(root: Path) -> AuditResult:
    root = root.resolve()
    selected = [p for p in files(root) if p.suffix.lower() == ".html"]
    lines = ["HTML AUDIT", f"ROOT: {root}"]
    for p in selected:
        lines += ["", f"FILE: {rel(root, p)}", text(p)]
    return AuditResult("html", "\n".join(lines))


def audit_js(root: Path) -> AuditResult:
    root = root.resolve()
    selected = [p for p in files(root) if p.suffix.lower() in JS_EXTS]
    lines = ["JS AUDIT", f"ROOT: {root}"]
    for p in selected:
        lines += ["", f"FILE: {rel(root, p)}", text(p)]
    return AuditResult("js", "\n".join(lines))


def audit_css(root: Path) -> AuditResult:
    root = root.resolve()
    all_files = files(root)
    selected = [p for p in all_files if p.suffix.lower() == ".css"]
    lines = ["CSS AUDIT", f"ROOT: {root}"]
    for p in selected:
        lines += ["", f"FILE: {rel(root, p)}", text(p)]
    lines += ["", "CLASS MENTIONS"]
    rx = re.compile(r"(class(Name)?\s*=|classList\.|querySelector(All)?\(|getElementsByClassName\(|\.[_a-zA-Z-][_a-zA-Z0-9-]*)", re.I)
    for p in [x for x in all_files if x.suffix.lower() in CODE_EXTS]:
        for i, line in enumerate(text(p).splitlines(), 1):
            if rx.search(line):
                lines.append(f"{rel(root, p)}:{i} | {line.strip()}")
    return AuditResult("css", "\n".join(lines))


def audit_assets(root: Path) -> AuditResult:
    root = root.resolve()
    all_files = files(root)
    assets = [p for p in all_files if p.suffix.lower() in ASSET_EXTS]
    code = [p for p in all_files if p.suffix.lower() in CODE_EXTS]
    rx = re.compile(r"[A-Za-z0-9_./\\:@%+\-]+?\.(png|jpe?g|webp|gif|svg|avif|mp4|webm|mov|m4v|mp3|wav|ogg|glb|gltf|hdr|ico|woff2?|ttf|otf|pdf|wasm)([?#][^\"'\s)]*)?", re.I)
    lines = ["ASSET AUDIT", f"ROOT: {root}", f"ASSETS: {len(assets)}"]
    lines += [f"{rel(root, p)} | {p.suffix.lower()} | {round(p.stat().st_size / 1024, 2)} KB" for p in assets]
    lines += ["", "REFERENCES"]
    for p in code:
        for i, line in enumerate(text(p).splitlines(), 1):
            for match in rx.finditer(line):
                lines.append(f"{rel(root, p)}:{i} | {match.group(0)} | {line.strip()}")
    return AuditResult("assets", "\n".join(lines))


def audit_cssdist(root: Path) -> AuditResult:
    root = root.resolve()
    selected = [p for p in files(root, include_dist=True) if p.suffix.lower() == ".css"]
    lines = ["CSS DIST AUDIT", f"ROOT: {root}"]
    for p in selected:
        lines += ["", f"FILE: {rel(root, p)}", text(p)]
    return AuditResult("cssdist", "\n".join(lines))


def audit_dist(root: Path) -> AuditResult:
    root = root.resolve()
    dist = root / "dist"
    if not dist.exists():
        return AuditResult("dist", f"DIST AUDIT\nROOT: {root}\nDIST NOT FOUND")
    selected = sorted(p for p in dist.rglob("*") if p.is_file())
    total = sum(p.stat().st_size for p in selected)
    lines = ["DIST AUDIT", f"ROOT: {root}", f"FILES: {len(selected)}", f"TOTAL SIZE: {round(total / 1024 / 1024, 2)} MB"]
    lines += [f"{rel(root, p)} | {p.suffix} | {round(p.stat().st_size / 1024, 2)} KB" for p in sorted(selected, key=lambda x: x.stat().st_size, reverse=True)]
    return AuditResult("dist", "\n".join(lines))


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
    if mode == "all":
        parts = [run(key, root).text for key in ("full", "assets", "css", "html", "js", "cssdist", "dist")]
        return AuditResult("all", "\n\n".join(parts))
    return MODES[mode](root)
