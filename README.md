# awful-audit

Project audit tools for static front-end repositories.

Awful Audit scans a project folder and collects code, assets, CSS usage, Git state and build output into copy-ready reports.

The repository contains two implementations:

* `powershell/` — Windows PowerShell version with the `au` command
* `python/` — cross-platform Python version with CLI and Tkinter GUI

## Features

* Full source audit
* Asset map
* CSS usage report
* HTML-only report
* JavaScript and TypeScript report
* Final CSS report from `dist`
* Build output and large asset report from `dist`
* Combined report mode
* Clipboard output
* Optional file output in the Python version
* Optional GUI in the Python version

## Audit modes

| Mode      | Purpose                                      |
| --------- | -------------------------------------------- |
| `all`     | run all reports in order                     |
| `full`    | collect code, Git state and file inventory   |
| `assets`  | collect asset paths, sizes and references    |
| `css`     | collect CSS, imports, URLs and class mentions |
| `html`    | collect HTML files                           |
| `js`      | collect JavaScript and TypeScript files      |
| `cssdist` | collect source CSS and final CSS from `dist` |
| `dist`    | analyze built files, sizes and references    |

## PowerShell

Install from the repository root:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\powershell\install.ps1
```

Run from any project folder:

```powershell
au
au all
au full
au assets
au css
au html
au js
au cssdist
au dist
```

Run without installing:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\powershell\scripts\au.ps1 all
```

Uninstall:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\powershell\uninstall.ps1
```

## Python

Install from source:

```bash
cd python
python -m venv .venv
python -m pip install --upgrade pip build
python -m pip install -e .
```

Run from a project folder:

```bash
awful-audit
awful-audit all
awful-audit full
awful-audit assets
awful-audit css
awful-audit html
awful-audit js
awful-audit cssdist
awful-audit dist
```

Run against another folder:

```bash
awful-audit all --root path/to/project
```

Save report to a file:

```bash
awful-audit all --output audit.txt
```

Disable clipboard output:

```bash
awful-audit all --no-clipboard
```

Open GUI:

```bash
awful-audit gui
awful-audit gui --root path/to/project
```

## Python options

| Option             | Purpose                                  |
| ------------------ | ---------------------------------------- |
| `--root PATH`      | project folder to scan                   |
| `--output FILE`    | save report to a file                    |
| `--no-clipboard`   | do not copy report to clipboard          |
| `--help`           | show help                                |

## Skipped folders

Source audits skip generated and dependency folders:

* `.git`
* `node_modules`
* `dist`
* `build`
* `.next`
* `.vite`
* `coverage`
* `tmp`
* `temp`
* `.vercel`
* `.wrangler`

`dist` is scanned only by `dist` and `cssdist`.

## Files

| Path            | Purpose                    |
| --------------- | -------------------------- |
| `powershell/`   | PowerShell implementation  |
| `python/`       | Python implementation      |
| `README.md`     | project documentation      |
| `LICENSE`       | MIT license                |

## Requirements

PowerShell version:

* Windows
* PowerShell 7+

Python version:

* Python 3.10+
* Tkinter for GUI mode

## License and rights

Source code is licensed under the MIT License.

The Awful Audit name, visual identity and branding assets are copyright Ivan Krushinsky and are not licensed for reuse as branding assets.

## Author

Ivan Krushinsky / looksawful

https://looksawful.ru
