# Agent guide

## Scope

awful-audit has two implementations of the same product contract:

- `powershell/` is the Windows-first `au` implementation, including install/uninstall and ZIP/file-clipboard behavior.
- `python/` is the cross-platform Python CLI and optional Tkinter GUI.

Treat duplicated behavior as a compatibility contract, not permission to change one implementation in isolation.

## Before changing code

1. Read `docs/architecture.md` and `docs/testing.md`.
2. Identify whether the change affects shared audit semantics, a platform adapter, packaging/installer behavior, or documentation only.
3. For shared audit semantics, characterize both implementations first. Preserve report headings, mode names, skip rules, truncation behavior, root `dist` semantics, and output/clipboard behavior unless the issue explicitly changes that contract.
4. Do not combine architectural extraction with user-visible behavior changes.

## Verification

Python:

```bash
python -m pip install -e ./python
python -m unittest discover -s python/tests -v
```

PowerShell on Windows / PowerShell 7+:

```powershell
./powershell/tests/archive.tests.ps1
./powershell/tests/install.tests.ps1
./powershell/tests/parity.tests.ps1
```

For a full repository change, run both suites. If the current machine cannot execute one platform, record that limitation and rely on the corresponding GitHub Actions job before merging.

## Change rules

- Prefer small contract-preserving changes.
- Add a failing regression test before fixing a proven bug.
- Keep PowerShell and Python mode names aligned: `all`, `full`, `assets`, `css`, `html`, `js`, `cssdist`, `dist`.
- Root `dist/` is excluded from source scans and included only where the mode contract explicitly asks for it.
- Keep source skip-directory semantics aligned across implementations.
- Do not silently change report format. Treat headings and truncation markers as public output consumed by humans and agents.
- Installer changes must be paired with lifecycle tests covering install, immediate use, persistence, uninstall, and restoration of user state.
- GUI-specific dependencies must not become accidental CLI dependencies.
- Never add generated audit output, temporary fixtures, virtual environments, or build artifacts to the repository.

## Project-local skills

Use only when the task matches their scope:

- `.agents/skills/audit-contract/SKILL.md` for shared scanner/report behavior.
- `.agents/skills/python-cli/SKILL.md` for Python CLI, packaging, clipboard, or GUI-boundary work.
- `.agents/skills/powershell-installer/SKILL.md` for Windows install/uninstall, `au`, profiles, PATH, archive, or file clipboard work.
