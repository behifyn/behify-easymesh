# Behify EasyMesh v1.0.0-rc.1

This prerelease prepares the first stable Behify EasyMesh release and pins EasyTier v2.6.4 for Linux x86_64 and aarch64.

## Included

- Verified architecture-specific packages assembled from pinned official EasyTier archives.
- Transactional application and runtime installation with rollback and service-state preservation.
- Root-only mesh secret storage and staged systemd configuration validation.
- Ownership-aware uninstall and explicit purge boundaries.
- Existing isolated Dokodemo-Door relay architecture and identities unchanged.

## Validation

The release artifacts must be built from the tagged commit and pass the GitHub Actions RC workflow. Each package must execute its matching EasyTier core and CLI natively and complete disposable real-systemd install, upgrade, state-preservation, and rollback checks before the draft release is approved.

## Operational Limitation

Pre-v1 installations may contain `/root/easytier/reset.sh` and a root-cron entry that performs global EasyTier process termination. The RC installer refuses to upgrade while either known legacy marker exists. Inspect them without executing or deleting them:

```bash
sudo test ! -e /root/easytier/reset.sh || sudo stat /root/easytier/reset.sh
sudo crontab -l 2>/dev/null | grep -F '/root/easytier/reset.sh' || true
```

Cleanup requires separate operational authorization. Initial RC testing should use a disposable or noncritical node.

This RC is not the stable v1.0.0 release. The repository remains private during draft validation, so anonymous installation is unavailable.
