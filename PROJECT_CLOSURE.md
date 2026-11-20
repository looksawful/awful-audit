# Project closure: Awful Audit

Date: 2026-11-20
Status: Discontinued. Preserved for reference; no further maintenance planned.

## Decision
Awful Audit is no longer justified as a standalone maintained product. Stop feature work, releases and installation promotion. This is a strategic cancellation, not a claim that all planned work was completed.

## Preserved work
- PowerShell Windows CLI, installer/uninstaller and archive/clipboard support.
- Python cross-platform CLI and optional Tkinter GUI.
- Static front-end reporting for code, Git state, assets, CSS, HTML, JS and build output.
- Existing tests, documentation, Git history and MIT license.

## Future reuse
Reuse individual ideas or code only when another active project demonstrates a concrete need. Do not migrate or refactor speculatively. This decision does not apply to the separate Awful Post project.

## Closure checklist
- [x] Document decision in repository.
- [x] Update README with discontinued status.
- [x] Unpublish GitHub Pages and remove public installation promotion (REST status: `has_pages=false`).
- [x] Disable GitHub Actions (REST permissions: `enabled=false`).
- [x] Archive GitHub repository (read-only; final administrative action of this closure).
- [x] Verify 0 open GitHub issues and update existing completed Asana task. Separate Awful Post remains active.

## Reopening criteria
Reopen only with a named user, a specific unmet use case, and an owner willing to maintain it.
