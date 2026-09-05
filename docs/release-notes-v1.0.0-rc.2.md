# Behify EasyMesh v1.0.0-rc.2

RC2 contains six focused changes:

1. Managed mesh services keep the network secret out of process arguments and suppress EasyTier's INFO-level effective-config output.
2. New 32-character generated secrets are displayed once during interactive setup; custom input remains hidden.
3. Encryption defaults to enabled, multi-thread defaults to disabled, and IPv6 retains its existing default.
4. The dashboard shows one concise EasyTier version row.
5. Troubleshooting now explains one-way peer initiation, reverse attempts, firewall checks, and direct P2P behavior.
6. Release assets include a checksummed `install.sh` alias that is byte-identical to the versioned online bootstrap.

This remains a prerelease, not stable v1.0.0. Real deployment testing remains pending.

Pre-v1 installations with `/root/easytier/reset.sh` or the matching root cron entry still require separate, supervised cleanup before upgrade. The installer does not execute or remove those legacy maintenance items.

Behify EasyMesh is based on [Easy-Mesh by Musixal](https://github.com/Musixal/Easy-Mesh). `LICENSE` and `NOTICE` are retained.
