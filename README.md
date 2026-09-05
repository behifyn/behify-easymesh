# Behify EasyMesh

Behify EasyMesh is a source-available Linux administration tool for an EasyTier mesh and an optional isolated Dokodemo-Door relay. Release candidate `1.0.0-rc.3` pins EasyTier `v2.6.4` and supports Linux `x86_64` and `aarch64`.

Persian documentation: [README.fa.md](README.fa.md)

## Attribution and License

Behify EasyMesh is based on [Easy-Mesh by Musixal](https://github.com/Musixal/Easy-Mesh). `LICENSE` and `NOTICE` are retained unchanged. [EasyTier](https://github.com/EasyTier/EasyTier) and the optional Xray-core relay runtime are separate upstream projects; see [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

This repository uses the included custom source-available license, not an OSI-approved open-source license. The Software shall not be used to create or be included in any form of video content published on YouTube or any other video-sharing platform. Read [LICENSE](LICENSE) before use or redistribution.

## Requirements

- Linux with systemd
- `x86_64` / `amd64` or `aarch64` / `arm64`
- `bash`, OpenSSL, Python 3, and standard GNU utilities
- `curl`, CA certificates, and `tar` for online installation

The installer does not install operating-system packages. `iperf3` is optional and used only for manual throughput tests.

## Install

For the stable release, installation is one command:

```bash
curl -fsSL https://github.com/behifyn/behify-easymesh/releases/latest/download/install.sh | sudo bash
```

This URL intentionally targets the latest non-prerelease GitHub release and will become active when stable v1.0.0 is published. The installer exits after printing `Run: sudo easymesh`; it does not open the TUI automatically.

To install and then launch the stable release in one command:

```bash
curl -fsSL https://github.com/behifyn/behify-easymesh/releases/latest/download/install.sh -o /tmp/behify-install.sh && sudo bash /tmp/behify-install.sh && sudo easymesh
```

After RC3 is published, its exact tagged bootstrap can also be installed directly:

```bash
curl -fsSL https://github.com/behifyn/behify-easymesh/releases/download/v1.0.0-rc.3/install.sh | sudo bash
```

The pipe forms are convenient but do not independently verify the bootstrap. The recommended RC3 flow is download-first verification:

```bash
version=v1.0.0-rc.3
curl -fLO "https://github.com/behifyn/behify-easymesh/releases/download/$version/install.sh"
curl -fLO "https://github.com/behifyn/behify-easymesh/releases/download/$version/SHA256SUMS"
grep ' install.sh$' SHA256SUMS | sha256sum -c -
sudo bash install.sh
```

The versioned `online-install-v1.0.0-rc.3.sh` has identical bytes to `install.sh`. Both detect the host architecture, download the matching immutable package, verify its SHA-256, validate archive paths, and invoke the offline package installer.

For a strict offline install, transfer the matching package and `SHA256SUMS` to the target:

```bash
grep 'behify-easymesh-v1.0.0-rc.3-linux-x86_64.tar.gz$' SHA256SUMS | sha256sum -c -
tar -xzf behify-easymesh-v1.0.0-rc.3-linux-x86_64.tar.gz
cd behify-easymesh-v1.0.0-rc.3-linux-x86_64
sudo EASYMESH_OFFLINE=1 bash install.sh
```

Use the `aarch64` package name on ARM64. GitHub's automatic source archives are not offline installers.

## Use

```bash
sudo easymesh
easymesh --version
```

Opening the menu never downloads or replaces EasyTier. **Connect to the Mesh Network** creates or replaces the mesh configuration. Its public defaults are encryption enabled, multi-thread disabled, and IPv6 enabled as in the existing behavior. The generated 32-character secret is highlighted once in the interactive terminal; pressing Enter accepts it, or a custom secret can be typed visibly and edited before Enter. The program does not repeat a custom value after entry.

The root-only files `/etc/behify-easymesh/mesh.env` and `/etc/behify-easymesh/easytier.toml` are mode `0600`. The managed service reads the secret through the private config, keeps it out of process arguments, and uses WARN console logging to avoid EasyTier's INFO-level effective-config output. Menu option 5 reveals the stored secret only when explicitly selected.

See [Configuration](docs/configuration.md) for mesh and relay settings, and [Operations](docs/operations.md) for upgrades, rollback, service paths, diagnostics, and removal.

## Connectivity Notes

One node may initiate by entering the other node's reachable address while the listening/reverse node leaves the peer field blank. If A cannot initiate to B, try B to A and check UDP reachability, host firewalls, provider firewalls, NAT, and another supported protocol. A direct P2P path may appear after only one side initiates; Behify does not automatically add reverse peers or change EasyTier routing.

Peer and Peer-Center views use EasyTier's terminal formatting. Routes uses `watch` no-wrap mode when available and otherwise falls back to normal wrapping.

## Security

Report vulnerabilities privately as described in [SECURITY.md](SECURITY.md). Never include a live mesh secret or server credential in public reports.

RC2 passed a real two-node deployment, upgrade, restart, direct-P2P, bidirectional-ping, and secret-exposure audit. RC3 remains a prerelease and must repeat the two-server smoke test before stable v1.0.0 is published.
