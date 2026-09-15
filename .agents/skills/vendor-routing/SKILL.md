---
name: vendor-routing
description: Use external Agent Skills selectively in awful-audit without breaking the Python/PowerShell compatibility contract or overriding local audit, CLI and installer skills.
---

# Curated external skills for awful-audit

Project-local skills are authoritative:

- `audit-contract` for shared scanner/report semantics;
- `python-cli` for Python CLI, packaging, clipboard and GUI boundaries;
- `powershell-installer` for Windows installation, archive and profile/PATH behavior.

External skills may supplement those rules but never replace them.

## Approved methods

- `obra/superpowers`: `systematic-debugging`. Use to reproduce and isolate defects before patching.
- `obra/superpowers`: `verification-before-completion`. Use as a completion gate, then apply this repository's requirement to run both Python and PowerShell suites for cross-cutting changes.
- `affaan-m/ECC`: `python-patterns`. Use only for Python implementation quality. Do not let Python idioms redefine the shared product contract or PowerShell behavior.
- `gwagjiug/technical-writing`: `technical-writing`. Use for architecture, testing, install and troubleshooting documentation.

## Compatibility rule

Any external recommendation that changes shared audit semantics must be checked against both implementations before adoption. Preserve report headings, mode names, skip rules, truncation behavior, root `dist` semantics and output/clipboard behavior unless the scoped task explicitly changes the contract.

A Python-only improvement is not complete when it creates PowerShell divergence. A PowerShell installer simplification is not complete when it changes lifecycle or user-state restoration guarantees.

## Excluded

- Broad ECC, Superpowers or wshobson whole-pack installs.
- React, Next.js, Tailwind, UI/design and browser-app skills.
- Generic packaging advice that bypasses the project-local `python-cli` or `powershell-installer` contracts.

Install or copy only a named external skill when its exact workflow is needed. Record source/revision and license when vendoring. Never use `--all` in this repository.
