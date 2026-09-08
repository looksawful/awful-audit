# Contributing

## Development setup

Python 3.10+:

```bash
python -m venv .venv
. .venv/bin/activate  # Windows PowerShell: .venv\Scripts\Activate.ps1
python -m pip install --upgrade pip
python -m pip install -e ./python
python -m unittest discover -s python/tests -v
```

PowerShell development requires PowerShell 7+. Installer/archive integration tests are Windows-oriented and are also executed in GitHub Actions.

## Working agreement

Start from an issue with observed behavior and acceptance criteria. Changes to shared audit semantics must inspect both languages. Add regression evidence before changing runtime behavior. Keep fixes narrow and avoid mixing report-format changes, scanner refactors, installer changes, and documentation cleanup in one PR.

Use `AGENTS.md` as the repository-level agent contract and the project-local skill matching the work area.

## Pull request evidence

A behavior-changing PR should state:

- the failing/incorrect behavior before the change;
- the RED test or characterization evidence;
- the files whose ownership is affected;
- Python and/or PowerShell commands executed;
- parity impact;
- any platform test that could not be run locally and the corresponding CI evidence.

Documentation-only and agent-tooling PRs must not claim runtime verification they did not perform.
