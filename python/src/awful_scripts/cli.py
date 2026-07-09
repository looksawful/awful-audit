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
    p.add_argument("--print", action="store_true", help="print the full report even when --output is used")
    return p


def choose() -> str:
    print("awful-audit")
    print("all full assets css html js cssdist dist gui")
    value = input("mode: ").strip().lower()
    return value or "all"


def main(argv: list[str] | None = None) -> int:
    args = parser().parse_args(argv)
    mode = args.mode or choose()
    root = Path(args.root).resolve()
    if mode == "gui":
        gui_main(root)
        return 0

    result = run(mode, root)
    output_path = Path(args.output).resolve() if args.output else None
    copied = False

    if output_path:
        output_path.parent.mkdir(parents=True, exist_ok=True)
        output_path.write_text(result.text, encoding="utf-8")

    if not args.no_clipboard:
        if output_path:
            copied = copy(f"awful-audit report saved: {output_path}")
        else:
            copied = copy(result.text)

    if output_path and not args.print:
        print(f"output: {output_path}")
        print(f"chars: {len(result.text)}")
        if args.no_clipboard:
            print("clipboard: disabled")
        else:
            print("clipboard: output path copied" if copied else "clipboard: failed")
    else:
        print(result.text)
        if args.no_clipboard:
            print("clipboard: disabled")
        else:
            print("clipboard: full report copied" if copied else "clipboard: failed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
