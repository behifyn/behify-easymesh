# Behify EasyMesh v1.0.0

Behify EasyMesh v1.0.0 promotes the published v1.0.0-rc.3 candidate to the first stable release without changing its runtime behavior.

## Validated Release

- EasyTier remains pinned to v2.6.4.
- CI passed validate-and-build, package validation, strict-offline installation, native x86_64, native aarch64, and disposable real-systemd installation, upgrade, and rollback tests.
- RC3 was installed on two real x86_64 servers with both `easymesh.service` instances active and enabled.
- Direct P2P/DIRECT routing and bidirectional ping passed with 0% packet loss.
- Transactional installation, service-state preservation, rollback, architecture validation, and exact release checksums remain unchanged.
- Root-only secret storage, config-based secret transport, secret-free process arguments, and WARN-level managed-service logging remain unchanged.
- The isolated Dokodemo-Door relay and existing EasyTier networking and routing behavior remain unchanged.

Stable v1.0.0 changes release metadata and documentation only. It does not change the RC3 runtime, installer, service design, networking, routing, relay, or secret handling.

Behify EasyMesh is based on [Easy-Mesh by Musixal](https://github.com/Musixal/Easy-Mesh). `LICENSE` and `NOTICE` are retained.
