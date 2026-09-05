# Behify EasyMesh v1.0.0-rc.2 Release Checklist

## Repository

- Confirm the branch and approved release commit.
- Confirm `LICENSE` and `NOTICE` match the immutable integrity baseline.
- Confirm no EasyTier or Xray executable is tracked in Git.
- Build only from a clean committed tree.

## Automated Gates

```bash
bash tests/run-all.sh release-output
git diff --check
git diff main...HEAD --check
```

CI must pass syntax checks, ShellCheck, regressions, package validation, strict-offline installation, native EasyTier execution, and disposable real-systemd upgrade/rollback tests on both x86_64 and aarch64. Skipped native jobs are not validated.

The systemd tests must confirm that a unique fake secret is absent from the service unit, process arguments, `systemctl` output, and journal after RC1 migration. They must also confirm root-only config permissions and preservation of service state and existing mesh options.

## Exact Assets

- `behify-easymesh-v1.0.0-rc.2-linux-x86_64.tar.gz`
- `behify-easymesh-v1.0.0-rc.2-linux-aarch64.tar.gz`
- `online-install-v1.0.0-rc.2.sh`
- `install.sh`
- `SHA256SUMS`
- `easytier-v2.6.4-source.tar.gz`

Verify every asset with `SHA256SUMS` and confirm `install.sh` is byte-identical to the versioned bootstrap. Do not publish from a dirty tree or reuse an earlier release-output directory.

## Manual Linux Checks

- Confirm the generated secret is shown exactly once and Enter selects it.
- Confirm custom secret entry is hidden and not repeated afterward.
- Confirm option 5 reveals the stored secret only when explicitly selected.
- Confirm encryption, multi-thread, and IPv6 defaults.
- Confirm peer, route, and Peer-Center displays on narrow and wide SSH terminals.
- Confirm one-way initiation and the reverse-direction troubleshooting path on disposable nodes.
- Review real service status, journal, and `/proc/$PID/cmdline` for secret exposure.
