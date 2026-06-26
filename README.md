# awful-audit

Audit tools for static front-end projects.

Two versions are included:

- `powershell/` — Windows PowerShell scripts with the `au` command.
- `python/` — cross-platform Python CLI and Tkinter GUI.

## Clone

```bash
git clone https://github.com/looksawful/awful-audit.git
cd awful-audit
```

## Modes

`all`, `full`, `assets`, `css`, `html`, `js`, `cssdist`, `dist`.

## PowerShell

Install:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\powershell\install.ps1
```

Run from any project folder:

```powershell
au
au all
au css
au html
au assets
au js
au cssdist
au dist
```

Uninstall:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\powershell\uninstall.ps1
```

## Python

Install:

```bash
cd python
python -m venv .venv
python -m pip install --upgrade pip build
python -m pip install -e .
```

Run:

```bash
awful-audit
awful-audit all --root .
awful-audit css --root .
awful-audit gui --root .
```

Build:

```bash
cd python
python -m build
```
