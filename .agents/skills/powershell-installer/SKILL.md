---
name: awful-audit-powershell-installer
description: Change awful-audit PowerShell install/uninstall, command aliases, archive output, PATH/profile state, or Windows clipboard behavior safely.
---

# PowerShell Installer and Windows Adapters

Use for `powershell/install.ps1`, `powershell/uninstall.ps1`, `powershell/bin`, archive/file-clipboard behavior, or command persistence.

## State owned by the installer

The installer may create or modify:

- the install directory;
- `au.cmd`;
- user `PATH`;
- marked `# awful-audit` profile blocks;
- current-session `au` and `ау` functions.

Uninstall must reverse only state owned by awful-audit and must preserve unrelated profile/PATH content.

## Workflow

1. Back up every user-state surface touched by a test.
2. Install into a temporary directory.
3. Verify `au` and `ау` work immediately.
4. Verify persisted profile/PATH behavior where the test environment supports it.
5. Run uninstall and verify the install directory, PATH entry, marked profile blocks, and current-session functions are gone.
6. Restore original environment/profile state in `finally`, even when assertions fail.
7. Run archive and installer suites on `windows-latest` before merge.

Never test install/uninstall against the developer's real default install directory.
