# Testing

## Baseline

The audited `main` HEAD is `87c1445c290e5397a114f3e8d16fe9937a86d53d`.

At that revision the existing GitHub Actions PowerShell workflow passes on `windows-latest` and runs archive plus installer tests. Python had no repository test suite or CI job.

Local characterization on 2026-09-09 ran the Python implementation through all canonical modes against a synthetic project. `full`, `assets`, `css`, `html`, `js`, `cssdist`, `dist`, and `all` completed; canonical lowercase `node_modules` was skipped; root `dist` behavior and output-file mode worked; report truncation emitted the explicit marker.

The same characterization also proved two behavioral defects: a missing Python `--root` returns a successful-looking report instead of rejecting the path, and differently cased skip directories such as `NODE_MODULES` are scanned by Python while PowerShell's skip set is case-insensitive.

The current execution environment did not provide PowerShell, so local PowerShell execution was not claimed. PowerShell evidence comes from repository tests and GitHub Actions; branch parity tests run on `windows-latest`.

## Commands

Python:

```bash
python -m pip install -e ./python
python -m unittest discover -s python/tests -v
```

PowerShell:

```powershell
./powershell/tests/archive.tests.ps1
./powershell/tests/install.tests.ps1
./powershell/tests/parity.tests.ps1
```

## Test layers

### Characterization

`python/tests/test_characterization.py` protects current non-buggy scanner semantics with temporary fixture projects. It is intentionally behavior-focused rather than implementation-focused.

### CLI

`python/tests/test_cli.py` protects module/console dispatch and output-file behavior without requiring clipboard access.

### Cross-implementation parity

`powershell/tests/parity.tests.ps1` creates one synthetic project, runs both implementations, and compares semantic invariants such as source inclusion, skipped generated directories, assets, and root `dist` ownership. It does not demand byte-identical output.

### Existing Windows lifecycle tests

`archive.tests.ps1` protects ZIP-only output and Windows file clipboard behavior. `install.tests.ps1` protects immediate post-install command availability. Uninstall cleanup is not covered at the audited baseline and is tracked separately.

## RED-first rule

For each proven bug, first add a test that fails for the exact observed reason. Do not weaken a RED test to match current behavior. Then make the smallest runtime change needed for GREEN and run the full relevant platform suite.
