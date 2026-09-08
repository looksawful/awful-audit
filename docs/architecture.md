# Architecture

## Product boundary

awful-audit is a small static-project inspection tool with two runtime implementations. Both expose the same canonical audit modes and produce plain-text reports for human and agent review.

The repository intentionally does not share executable scanner code between PowerShell and Python. The shared unit is the behavior contract: file discovery, skip rules, mode semantics, report sections, truncation, `dist` handling, and output expectations.

## PowerShell implementation

`powershell/scripts/_audit-lib.ps1` contains filesystem indexing and report generation. Thin `audit-*.ps1` scripts expose one mode each and delegate output to `_archive-lib.ps1` / `Complete-AwfulAudit`. `au.ps1` is the user-facing dispatcher. `install.ps1` and `uninstall.ps1` own Windows command persistence and user-state integration.

Platform-specific behavior that belongs here includes Windows profile/PATH installation and file clipboard support.

## Python implementation

`python/src/awful_scripts/audits.py` contains indexing and report generation. `cli.py` owns arguments and output dispatch, `clipboard.py` owns platform clipboard adapters, and `gui.py` owns Tkinter UI. `__main__.py` and `pyproject.toml` expose module/console entrypoints.

The GUI is an adapter. It must not define scanner semantics or become a mandatory dependency for CLI-only execution.

## Shared contract

The canonical modes are `all`, `full`, `assets`, `css`, `html`, `js`, `cssdist`, and `dist`.

Source scans exclude generated/vendor directories. Root `dist/` is a special boundary: ordinary source scans exclude it; `cssdist` can include source CSS plus root `dist` CSS; `dist` scans root `dist` only.

Reports have stable human-readable headings and explicit truncation markers. Exact byte-for-byte parity is not required because platform paths/newlines and intentionally platform-specific metadata can differ. Semantic inclusion/exclusion and section ownership should remain aligned.

## Architecture risks found in the 2026-09-09 audit

1. Shared scanner behavior is duplicated across languages without a previous parity test, so small edits can drift silently.
2. Python CLI imports the GUI module at startup, making Tkinter an accidental CLI import-time dependency.
3. Installer lifecycle state is broader than uninstall cleanup: install writes profile functions, while current uninstall removes only PATH/install directory.
4. Python root validation is permissive enough to produce a successful-looking empty report for a missing path.
5. Skip-directory case handling differs: PowerShell uses an ordinal-ignore-case set, Python uses a case-sensitive set membership check.
6. Python had no automated CI coverage at the audited `main` HEAD.

These are tracked as GitHub issues rather than silently refactored in the tooling branch.

## Change strategy

Prefer contract tests before extraction. Avoid introducing a cross-language shared runtime or code generator unless duplication becomes materially harder to maintain than the synchronization contract. A small duplicated implementation plus strong parity evidence is simpler than a new portability layer for this project.
