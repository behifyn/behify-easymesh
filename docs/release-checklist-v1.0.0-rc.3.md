# Behify EasyMesh v1.0.0-rc.3 Release Checklist

## Repository and CI

- Confirm the release commit is on `release/v1.0.0-prep` and the working tree is clean.
- Confirm `LICENSE` and `NOTICE` match the immutable integrity baseline.
- Confirm EasyTier remains v2.6.4 and no runtime executable is tracked in Git.
- Require successful syntax, ShellCheck, regression, package, strict-offline, native x86_64, native aarch64, and real-systemd jobs.
- Build and upload only the exact artifacts produced by the successful RC3 workflow run.

## Exact Assets

- `behify-easymesh-v1.0.0-rc.3-linux-x86_64.tar.gz`
- `behify-easymesh-v1.0.0-rc.3-linux-aarch64.tar.gz`
- `online-install-v1.0.0-rc.3.sh`
- `install.sh`
- `SHA256SUMS`
- `easytier-v2.6.4-source.tar.gz`

Verify every asset with `SHA256SUMS` and confirm `install.sh` is byte-identical to the versioned bootstrap. Do not modify the RC2 tag or assets.

## Manual UX Checks

- Confirm Connect to Mesh shows only the concise peer/UDP hint before its prompts.
- Confirm the generated secret is bold cyan, is exactly 32 lowercase hex characters, and Enter selects it.
- Confirm custom secret input is visible and editable, accepted once, and not printed again by the program.
- Confirm there is no hidden secret read, repeat verification, or second secret confirmation.
- Confirm option 5 still reveals the stored secret only when explicitly selected.
- Confirm encryption and multi-thread warnings appear only at their respective prompts.
- Confirm installation exits after printing `Run: sudo easymesh` without launching the TUI.

## Two-Server RC3 Gate

- Install or upgrade RC3 on two disposable servers using the exact published assets.
- Confirm active and enabled service state, restart recovery, direct P2P, and bidirectional ping.
- Re-run the secret audit against the unit, process arguments, status output, and only new journal entries.
- Confirm both private config files are mode `0600` and owned by `root:root`.
- Treat old pre-RC2 journal entries as historical evidence; do not erase them automatically.
- Do not publish stable v1.0.0 until these RC3 checks pass.
