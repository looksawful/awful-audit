---
name: awful-audit-python-cli
description: Work safely on the awful-audit Python CLI, packaging, clipboard adapter, GUI boundary, and Python characterization tests.
---

# Python CLI

Use for `python/` changes that do not alter shared scanner semantics, or together with the audit-contract skill when they do.

## Boundaries

- `audits.py` owns filesystem indexing and report generation.
- `cli.py` owns argument parsing, root/output handling, console output, and dispatch.
- `clipboard.py` is a platform adapter and must fail soft when clipboard tooling is unavailable.
- `gui.py` owns Tkinter UI only. CLI-only execution must not require GUI dependencies.
- `__main__.py` and `[project.scripts]` are entrypoint adapters, not business logic.

## Verification

```bash
python -m pip install -e ./python
python -m unittest discover -s python/tests -v
python -m awful_scripts --help
awful-audit --help
```

For root/path handling, test both a valid temporary directory and invalid/non-directory paths. For output behavior, use `--no-clipboard` in automated tests. Never require a desktop session for CLI tests.
