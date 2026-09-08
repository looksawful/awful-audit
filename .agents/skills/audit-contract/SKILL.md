---
name: awful-audit-contract
description: Characterize and change shared awful-audit scanning/report semantics without drifting the PowerShell and Python implementations.
---

# Awful Audit Contract

Use this skill when a change touches modes, file discovery, skip directories, report headings, asset/CSS scanning, `dist`, truncation, or other behavior implemented in both languages.

## Workflow

1. Read `docs/architecture.md` and identify the matching function in both `powershell/scripts/_audit-lib.ps1` and `python/src/awful_scripts/audits.py`.
2. Build the smallest synthetic project that demonstrates the behavior. Include source files and root `dist/` when relevant.
3. Run the current behavior in both implementations before editing.
4. State the invariant in plain language. Distinguish intentional platform formatting differences from semantic drift.
5. Add a RED regression test for a bug or a GREEN characterization test for existing behavior.
6. Change the smallest implementation slice required.
7. Run Python tests, PowerShell tests, and `powershell/tests/parity.tests.ps1` where available.
8. Document any intentional parity exception in `docs/architecture.md`.

## Shared invariants

- Canonical modes remain aligned.
- Source scans exclude configured generated/vendor directories.
- Root `dist/` is excluded from ordinary source scans.
- `cssdist` may include source CSS plus root `dist` CSS.
- `dist` scans only root `dist/`.
- Report truncation is explicit, never silent.
- A behavior change in one language requires evidence for the other language, even when only one file needs modification.
