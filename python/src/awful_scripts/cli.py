from __future__ import annotations

import argparse
from pathlib import Path

from .audits import MODES, run
from .clipboard import copy
from .gui import main as gui_main


def parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(prog="awful-audit")
    p.add_argument("mode", nargs="?", choices=["all", *MODES.keys(), "gui"])
    p.add_argument("--root", default=".")
    p.add_argument("--output")
    p.add_argument("--no-clipboard", action="store_true")
    return p


def choose() -> str:
    print("awful-audit")
    print("all full assets css html js cssdist dist gui")
    value = input("mode: ").strip().lower()
    return value or "all"


def main(argv: list[str] | None = None) -> int:
    args = parser().parse_args(argv)
    mode = args.mode or choose()
    if mode == "gui":
        gui_main(Path(args.root))
        return 0
    result = run(mode, Path(args.root))
    if args.output:
        Path(args.output).write_text(result.text, encoding="utf-8")
    if not args.no_clipboard:
        copy(result.text)
    print(result.text)
    return 0
