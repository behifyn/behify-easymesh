# Changelog

All notable changes to Behify EasyMesh are documented here.

## [1.0.0-rc.3] - 2026-09-05

### Changed

- Reduced the Connect to Mesh introduction to one concise peer/UDP hint.
- Styled the generated 32-character network secret for visibility and made custom secret entry visible and directly editable.
- Removed the secret verification step and all second-confirmation behavior from network-secret entry.
- Clarified one-command stable and versioned candidate installation while keeping the installer non-interactive after installation.

### Security

- Preserved RC2's root-only secret files, config-based secret transport, secret-free service arguments, and WARN-level managed-service logging.
- Documented that visible interactive secret entry can be captured by terminal history or observers; the program does not repeat a custom value after entry.

## [1.0.0-rc.2] - 2026-09-05

### Changed

- Kept mesh secrets out of service arguments and INFO-level effective-config logs.
- Generated 32-character secrets are shown once for interactive copying; custom entry stays hidden.
- Encryption now defaults on, multi-thread defaults off, and IPv6 keeps its previous default.
- Removed the duplicate EasyTier version row from the dashboard.
- Clarified one-way peer initiation and connectivity troubleshooting.
- Added a checksummed, byte-identical `install.sh` release bootstrap alias.

## [1.0.0-rc.1] - 2026-09-04

### Added

- Verified architecture-specific release packages for Linux x86_64 and aarch64.
- Transactional installation, runtime upgrade, rollback, and bounded uninstall workflows.
- Isolated Dokodemo-Door relay management through `behify-relay.service`.
- Public security reporting guidance and third-party license notices.

### Changed

- EasyTier v2.6.4 is the only supported runtime.
- Runtime binaries are assembled from pinned official EasyTier release assets instead of being stored in Git.
- Mesh secrets are stored in a root-only environment file instead of the systemd unit.

### Removed

- Legacy EasyTier v2.0.3 binaries, selectors, and download fallbacks.
- Global EasyTier process termination from maintenance tasks.
