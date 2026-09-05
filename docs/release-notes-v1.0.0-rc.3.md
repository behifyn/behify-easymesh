# Behify EasyMesh v1.0.0-rc.3

RC3 is a focused UX and release-readiness candidate built on the validated RC2 runtime and security design.

1. Connect to Mesh now opens with one concise peer/UDP hint instead of a multi-line explanation.
2. The generated 32-character network secret is highlighted in bold cyan and Enter accepts it directly.
3. Custom secret input is intentionally visible and editable; there is no hidden input, repeat verification, or second confirmation.
4. Stable and tagged-candidate installation commands are documented clearly. The installer exits after printing `Run: sudo easymesh` and does not launch the TUI automatically.
5. EasyTier remains pinned to v2.6.4. Routing, relay, and networking semantics are unchanged.
6. RC2's root-only secret storage, private config transport, secret-free process arguments, and WARN-level logging remain intact.

RC2 passed a real two-node x86_64 deployment, upgrade, restart, direct-P2P, and secret-exposure audit. RC3 still requires the same smoke test on two disposable servers before stable v1.0.0 can be considered.

RC2's published tag and assets remain immutable. RC3 must be built from its own clean commit and published as a separate prerelease.

Behify EasyMesh is based on [Easy-Mesh by Musixal](https://github.com/Musixal/Easy-Mesh). `LICENSE` and `NOTICE` are retained.
