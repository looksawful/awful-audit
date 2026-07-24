# awful-audit

[Website](https://looksawful.github.io/awful-audit/) · [Download ZIP](https://github.com/looksawful/awful-audit/archive/refs/heads/main.zip) · [looksawful.ru](https://looksawful.ru)

Small audit tool for static front-end projects.

Awful Audit reads a project folder and builds plain text reports for code review, cleanup and AI-assisted analysis.

Beta: it works, but report formats and installers may still change.

## Versions

* powershell/ — Windows version with the au command
* python/ — cross-platform CLI and a simple Tkinter GUI

## What it scans

* source code
* Git state
* file inventory
* assets and their references
* CSS imports, URLs and class mentions
* JavaScript and TypeScript imports
* final CSS from dist
* built files and large assets from dist

## Modes

| Mode | What it does |
| --- | --- |
| all | runs all reports in order |
| full | collects code, Git state and file inventory |
| assets | collects asset paths, sizes and references |
| css | collects CSS, imports, URLs and class mentions |
| html | collects HTML files |
| js | collects JavaScript and TypeScript files |
| cssdist | collects source CSS and final CSS from dist |
| dist | checks built files, sizes and references |

## PowerShell

Install from the repository root:

    pwsh -NoProfile -ExecutionPolicy Bypass -File .\powershell\install.ps1

Run from any project folder:

    au
    au all
    au full
    au assets
    au css
    au html
    au js
    au cssdist
    au dist

Save a standalone text report:

    au all -Output _awful-audit\audit-all.txt -NoClipboard

Create a ZIP directly from the in-memory report without creating a standalone text file:

    au all -Archive
    au all -Zip
    au all -ArchivePath _awful-audit\custom-audit.zip

`-ArchivePath` implies `-Archive`. Unless `-NoClipboard` is used, the generated ZIP is copied to the Windows clipboard as a file and can be pasted into Explorer, a browser upload field or a messenger.

Run without installing:

    pwsh -NoProfile -ExecutionPolicy Bypass -File .\powershell\scripts\au.ps1 all

Uninstall:

    pwsh -NoProfile -ExecutionPolicy Bypass -File .\powershell\uninstall.ps1

## Python

Install from source:

    cd python
    python -m venv .venv
    python -m pip install --upgrade pip build
    python -m pip install -e .

Run from a project folder:

    awful-audit
    awful-audit all
    awful-audit full
    awful-audit assets
    awful-audit css
    awful-audit html
    awful-audit js
    awful-audit cssdist
    awful-audit dist

Run another folder:

    awful-audit all --root path/to/project

Save to file:

    awful-audit all --output audit.txt

Do not use clipboard:

    awful-audit all --no-clipboard

Open GUI:

    awful-audit gui
    awful-audit gui --root path/to/project

## Python options

| Option | Meaning |
| --- | --- |
| --root PATH | folder to scan |
| --output FILE | save report to file |
| --no-clipboard | do not copy report to clipboard |
| --help | show help |

## Skipped folders

Source reports skip:

* .git
* node_modules
* dist
* build
* .next
* .vite
* coverage
* tmp
* temp
* .vercel
* .wrangler

dist is scanned only by dist and cssdist.

## Requirements

PowerShell version: Windows, PowerShell 7+.

Python version: Python 3.10+, Tkinter for GUI mode.

## License

MIT.

## Author

Ivan Krushinsky / looksawful

https://looksawful.ru
