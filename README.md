# awful-audit

[Website](https://looksawful.github.io/awful-audit/) · [Download ZIP](https://github.com/looksawful/awful-audit/archive/refs/heads/main.zip) · [looksawful.ru](https://looksawful.ru)

Small audit tool for static front-end projects.

Awful Audit reads a project folder and builds plain text reports for code review, cleanup and AI-assisted analysis.

Beta: it works, but report formats and installers may still change.

## Versions

* powershell/ — Windows version with the au command
* python/ — cross-platform CLI and an optional Tkinter GUI

Both implementations expose the same canonical audit modes and keep file inclusion, skip-directory rules and root `dist` ownership aligned. Platform-specific paths, newlines and adapter messages do not need to be byte-identical.

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

`-ArchivePath` implies `-Archive`. Unless `-NoClipboard` is used, the generated ZIP is copied to the Windows clipboard as a file and can be pasted into Explorer or applications that accept pasted files.

Run without installing:

    pwsh -NoProfile -ExecutionPolicy Bypass -File .\powershell\scripts\au.ps1 all

Uninstall:

    pwsh -NoProfile -ExecutionPolicy Bypass -File .\powershell\uninstall.ps1

The uninstaller removes awful-audit's install directory, user `PATH` entry, marked PowerShell profile block and current-session `au` / `ау` functions while leaving unrelated profile content alone.

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

`--root` must point to an existing directory. Invalid or file paths fail with exit code 2 instead of producing an empty-looking audit.

Save to file:

    awful-audit all --output audit.txt

Save to file and also print the complete report:

    awful-audit all --output audit.txt --print

Do not use clipboard:

    awful-audit all --no-clipboard

Open GUI:

    awful-audit gui
    awful-audit gui --root path/to/project

Tkinter is imported only when GUI mode is selected. Normal CLI modes do not require Tkinter.

## Python options

| Option | Meaning |
| --- | --- |
| --root PATH | folder to scan; must be an existing directory |
| --output FILE | save report to file |
| --no-clipboard | do not copy report or saved-path message to clipboard |
| --print | print the full report even when `--output` is used |
| --help | show help |

## Clipboard limits

Direct full-report text copies use `AWFUL_AUDIT_MAX_CLIPBOARD_MB`. The default is 2 MB.

If a report is larger than that limit, the report is still built and printed, but the text clipboard copy is skipped with `clipboard: skipped (report too large)`.

When `--output` or `-Output` is used, the complete report is still written to disk and only the short saved-path message is copied, so the report-size limit does not block that clipboard action.

PowerShell ZIP/archive mode uses file clipboard rather than text clipboard and is not governed by `AWFUL_AUDIT_MAX_CLIPBOARD_MB`.

## Skipped folders

Source reports skip these directory names case-insensitively:

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
* .cache
* .turbo
* .parcel-cache
* .svelte-kit
* .nuxt
* .output
* out
* vendor

Root `dist` is a special boundary. Ordinary source scans exclude it. `cssdist` can include source CSS plus CSS from root `dist`, while `dist` scans root `dist` only.

## Requirements

PowerShell version: Windows, PowerShell 7+.

Python CLI: Python 3.10+.

Python GUI: Python 3.10+ with Tkinter available.

## Testing

Python:

    python -m pip install -e ./python
    python -m unittest discover -s python/tests -v

PowerShell on Windows with PowerShell 7+:

    ./powershell/tests/archive.tests.ps1
    ./powershell/tests/install.tests.ps1
    ./powershell/tests/clipboard.tests.ps1
    ./powershell/tests/parity.tests.ps1

GitHub Actions runs Python characterization on CPython 3.10–3.13 and checks PowerShell/Python semantic parity on Windows.

## License

MIT.

## Author

Ivan Krushinsky / looksawful

https://looksawful.ru
