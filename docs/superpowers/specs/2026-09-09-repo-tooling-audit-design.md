# Repository Tooling and Audit Design

## Goal

Make `looksawful/awful-audit` safe and efficient for agent-assisted maintenance without changing production audit behavior in the tooling pass.

## Current shape

The product has two implementations of the same conceptual scanner: a Windows-first PowerShell implementation and a cross-platform Python implementation with CLI and Tkinter GUI. Shared semantics are duplicated rather than expressed through a common runtime. This is acceptable for the project size only if a behavioral contract and parity evidence prevent silent drift.

At the audited `main` HEAD, Windows archive/installer tests exist and pass in GitHub Actions. Python has no committed tests or CI. Characterization proves the Python modes execute on a synthetic project but also exposes root-validation and case-sensitive skip-directory defects. Static/runtime inspection exposes a Tkinter CLI dependency and incomplete PowerShell uninstall cleanup.

## Design

### Agent layer

Add one root `AGENTS.md` as the authoritative repository workflow contract. Add only three project-local skills, each tied to a real ownership boundary: shared audit semantics, Python CLI/adapters, and PowerShell installer/Windows adapters. Do not introduce a parallel project-state system.

### Test layer

Add standard-library Python `unittest` characterization so the test suite does not need a new runtime dependency. Cover non-buggy mode/report semantics, root `dist` boundaries, canonical skip behavior, truncation, and CLI output behavior.

Add a Windows parity smoke that runs both implementations on the same generated fixture and compares semantic invariants rather than byte-identical reports. Run Python on 3.10 through 3.13 and parity on `windows-latest` in a new workflow, leaving the existing PowerShell workflow intact.

### Documentation layer

Add concise architecture, testing, and contributing docs. GitHub issues remain the source of truth for defects and future behavior changes. Notion mirrors the reviewed architecture, issue map, evidence, and recommended order but does not replace repository contracts.

## Non-goals

- No production scanner fixes in the tooling branch.
- No report-format redesign.
- No shared cross-language runtime/code generation.
- No package dependency expansion for testing.
- No broad README rewrite.

## Success criteria

- Agents can determine ownership and required verification before editing.
- Python has executable characterization on all supported CPython minors currently targeted by CI.
- A Windows job checks semantic parity between the two implementations.
- Proven defects are represented by separate GitHub issues with reproduction evidence and acceptance criteria.
- Architecture/testing/contribution guidance exists in-repo and a synchronized engineering audit exists in Notion.
