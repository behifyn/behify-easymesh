# Changelog

All notable changes to Behify EasyMesh are documented here.

## [1.0.0] - Unreleased

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
