# Repository Tooling Audit Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add an evidence-based agent workflow, Python characterization, cross-language parity smoke, engineering documentation, and issue/Notion handoff without changing production audit behavior.

**Architecture:** Preserve the separate PowerShell and Python runtimes. Treat their common scanner behavior as a semantic contract protected by characterization and Windows parity tests, while platform-specific install/clipboard/GUI behavior remains in adapters.

**Tech Stack:** PowerShell 7+, Python 3.10+, standard-library `unittest`, GitHub Actions, Markdown, Notion.

**Spec:** `docs/superpowers/specs/2026-09-09-repo-tooling-audit-design.md`

## Global Constraints

- Do not change production scanner behavior in this tooling pass.
- Do not add runtime or test dependencies.
- Keep canonical modes aligned across both implementations.
- Preserve report headings and root `dist` ownership.
- Record observed defects as issues instead of opportunistically fixing them.

---

### Task 1: Add Python characterization and CI

**Files:**
- Create: `python/tests/test_characterization.py`
- Create: `python/tests/test_cli.py`
- Create: `.github/workflows/python-tests.yml`

**Interfaces:**
- Consumes: existing `awful_scripts.audits.run`, `index`, `ReportBuilder`, and `awful_scripts.cli.main`.
- Produces: a dependency-free behavior baseline and Python 3.10–3.13 CI matrix.

- [ ] **Step 1: Add characterization tests** for all canonical modes, canonical skip behavior, root `dist` ownership, truncation, and environment fallback.
- [ ] **Step 2: Add CLI tests** for parsing, `--output`, `--no-clipboard`, and `--print` behavior.
- [ ] **Step 3: Run locally** with `PYTHONPATH=python/src python -m unittest discover -s python/tests -v`; expected: all tests PASS.
- [ ] **Step 4: Add CI** that installs the package editable and runs the suite on Python 3.10, 3.11, 3.12, and 3.13.
- [ ] **Step 5: Commit** as tooling/test infrastructure only.

### Task 2: Add cross-implementation parity smoke

**Files:**
- Create: `powershell/tests/parity.tests.ps1`
- Modify: `.github/workflows/python-tests.yml`

**Interfaces:**
- Consumes: existing PowerShell mode wrappers and installed Python module entrypoint.
- Produces: semantic parity evidence on `windows-latest`.

- [ ] **Step 1: Generate one temporary static-project fixture** with HTML, TypeScript, CSS, an asset, root `dist`, and canonical `node_modules`.
- [ ] **Step 2: Run paired modes** `full`, `assets`, `cssdist`, and `dist` through both implementations.
- [ ] **Step 3: Compare semantic invariants**: source inclusion, canonical generated-dir exclusion, asset visibility, and root `dist` ownership. Do not compare timestamps/newlines byte-for-byte.
- [ ] **Step 4: Add the Windows parity job** after editable Python installation.
- [ ] **Step 5: Verify through GitHub Actions**; expected: parity PASS on the tooling branch.

### Task 3: Add agent and engineering documentation

**Files:**
- Create: `AGENTS.md`
- Create: `.agents/skills/audit-contract/SKILL.md`
- Create: `.agents/skills/python-cli/SKILL.md`
- Create: `.agents/skills/powershell-installer/SKILL.md`
- Create: `docs/architecture.md`
- Create: `docs/testing.md`
- Create: `docs/contributing.md`

**Interfaces:**
- Consumes: actual repository ownership and test commands.
- Produces: one repository-level agent contract plus three task-scoped workflows and maintainable engineering documentation.

- [ ] **Step 1: Document ownership boundaries** and shared semantic invariants in `AGENTS.md` and `docs/architecture.md`.
- [ ] **Step 2: Document exact verification commands and known evidence limitations** in `docs/testing.md`.
- [ ] **Step 3: Document PR evidence and small-change discipline** in `docs/contributing.md`.
- [ ] **Step 4: Add exactly three project-local skills** matching real boundaries; do not duplicate project state or generic Git advice.
- [ ] **Step 5: Review all docs against current paths and commands**; expected: no placeholders and no claimed test that was not run or backed by CI.

### Task 4: Publish audit findings

**Files:**
- GitHub issues in `looksawful/awful-audit`
- Notion engineering page under `Пет проекты`

**Interfaces:**
- Consumes: characterization, source inspection, current CI evidence, and branch results.
- Produces: prioritized, independently actionable defects and synchronized project documentation.

- [ ] **Step 1: Create one issue per proven defect** with reproduction/evidence, impact, acceptance criteria, and a minimal RED-test direction.
- [ ] **Step 2: Keep architecture debt separate** from correctness bugs and documentation drift.
- [ ] **Step 3: Create/update the Notion project page** with architecture, testing matrix, issue map, branch/PR, and recommended order.
- [ ] **Step 4: Link GitHub issues and branch/PR from Notion** and verify the final page content.

### Task 5: Verify branch and handoff

**Files:**
- No new production files.

**Interfaces:**
- Consumes: branch diff and GitHub Actions results.
- Produces: auditable tooling PR ready for review.

- [ ] **Step 1: Inspect the branch diff** and confirm production runtime files are unchanged.
- [ ] **Step 2: Run/inspect every available automated check** and record platform limitations honestly.
- [ ] **Step 3: Create a draft PR** targeting `main` with audit scope and issue links.
- [ ] **Step 4: Review CI results and fix only tooling/test defects introduced by the branch.**
