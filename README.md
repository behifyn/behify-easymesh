# Behify EasyMesh

Behify EasyMesh is a source-available Linux administration tool for building and operating an EasyTier mesh and an optional isolated Dokodemo-Door port relay.

Version `1.0.0-rc.1` is a prerelease candidate for the first stable release. It pins EasyTier `v2.6.4` and supports only Linux `x86_64` and `aarch64`.

## Project Relationship and License

Behify EasyMesh is directly derived from [Easy-Mesh by Musixal](https://github.com/Musixal/Easy-Mesh). The original project and author are credited, and the original `LICENSE` and `NOTICE` are retained unchanged. Behify EasyMesh is independently maintained and is not the official EasyTier project.

EasyTier is a separate upstream component distributed under LGPL-3.0. The optional relay uses a separately managed Xray-core runtime under MPL-2.0. See [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) and the `licenses/` directory.

This repository is source-available under the included custom license, not an OSI-approved open-source license. The custom license restricts use of the software in content published on YouTube and other video-sharing platforms. Read `LICENSE` before use or redistribution.

## Supported Systems

- Linux with systemd
- `x86_64` / `amd64`
- `aarch64` / `arm64`
- EasyTier `v2.6.4` only

ARMv7 and other architectures fail before installation changes the system.

The package installer requires `bash`, `awk`, `grep`, `sha256sum`, `od`, `mktemp`, and standard core utilities. The online bootstrap additionally requires `curl` and `tar`. Mesh address validation requires `python3`. Install missing prerequisites through your operating system package manager; Behify's installer does not install packages automatically.

## Verified Online Installation

Download the versioned bootstrap and published checksums, verify the bootstrap, then run it:

```bash
curl -fLO https://github.com/behifyn/behify-easymesh/releases/download/v1.0.0-rc.1/online-install-v1.0.0-rc.1.sh
curl -fLO https://github.com/behifyn/behify-easymesh/releases/download/v1.0.0-rc.1/SHA256SUMS
grep 'online-install-v1.0.0-rc.1.sh$' SHA256SUMS | sha256sum -c -
sudo bash online-install-v1.0.0-rc.1.sh
```

The bootstrap detects the architecture, downloads only the matching immutable Behify `v1.0.0-rc.1` package, verifies its embedded published SHA-256, validates the archive path list, and then invokes the package's offline installer. It never uses `curl | bash`.

## Strict Offline Installation

On a connected machine, download the correct Release asset and `SHA256SUMS`:

```text
behify-easymesh-v1.0.0-rc.1-linux-x86_64.tar.gz
behify-easymesh-v1.0.0-rc.1-linux-aarch64.tar.gz
```

Transfer the selected archive and checksum file to the target, then verify and install:

```bash
grep 'behify-easymesh-v1.0.0-rc.1-linux-x86_64.tar.gz$' SHA256SUMS | sha256sum -c -
tar -xzf behify-easymesh-v1.0.0-rc.1-linux-x86_64.tar.gz
cd behify-easymesh-v1.0.0-rc.1-linux-x86_64
sudo EASYMESH_OFFLINE=1 bash install.sh
```

Use the `aarch64` asset and directory name on ARM64. The architecture package contains only its matching `easytier-core` and `easytier-cli`. The installer performs no network operation and rejects missing, modified, wrong-version, or wrong-architecture files before changing the installed application.

GitHub's automatically generated source ZIP is not an offline installer. The exact EasyTier v2.6.4 corresponding source is published separately as `easytier-v2.6.4-source.tar.gz`.

## Usage

```bash
sudo easymesh
easymesh --version
```

Expected version output:

```text
Behify EasyMesh v1.0.0-rc.1
EasyTier v2.6.4
```

The menu manages an already installed runtime. Opening it never downloads, installs, or replaces EasyTier. Select **Connect to the Mesh Network** to create or replace the mesh configuration.

EasyTier attempts direct/P2P connectivity. When a direct path is unavailable, it may use a relay or multi-hop path through other peers. For example, `Iran1 -> Iran2 -> destination` can occur as fallback. Version 1.0.0-rc.1 intentionally preserves this tested behavior and does not impose endpoint-only or designated-relay roles.

## Runtime and Configuration Paths

| Purpose | Path or unit |
| --- | --- |
| Application | `/opt/behify-easymesh` |
| Command | `/usr/local/bin/easymesh` |
| EasyTier runtime | `/root/easytier/easytier-core`, `/root/easytier/easytier-cli` |
| Mesh service | `/etc/systemd/system/easymesh.service` |
| Root-only mesh settings | `/etc/behify-easymesh/mesh.env` |
| Mesh configuration backups | `/etc/behify-easymesh/backups/` |
| Installer backups | `/opt/behify-easymesh-backups/` |
| Watchdog service | `easymesh-watchdog.service` |

`mesh.env` is mode `0600`; the network secret is not written into the normally readable systemd unit. New configuration is staged and validated before activation, and failure restores the previous files and service state.

## Safe Upgrade and Rollback

Before upgrading an existing pre-v1 installation, inspect only the legacy maintenance locations:

```bash
sudo test ! -e /root/easytier/reset.sh || sudo stat /root/easytier/reset.sh
sudo crontab -l 2>/dev/null | grep -F '/root/easytier/reset.sh' || true
```

The RC installer refuses to proceed if that script or matching root-cron entry exists. Do not run or delete either item without separate operational authorization; unattended upgrade is not supported for affected installations.

Install a newer Behify package using the same verified process. If either installed EasyTier binary is missing, modified, or not v2.6.4, the installer treats the pair generically as unsupported, backs up existing files, stages and validates both v2.6.4 binaries, and replaces them while the managed mesh service is stopped.

The installer preserves whether `easymesh.service` was active and enabled. It does not start an inactive service or enable a disabled service. A failed activation or service validation restores the prior application, runtime pair, command path, and active state. Backups are retained under `/opt/behify-easymesh-backups/`.

## Uninstall and Purge

Normal uninstall removes verified Behify-owned application/runtime files but preserves mesh configuration, service files, backups, and the isolated relay:

```bash
sudo /opt/behify-easymesh/uninstall.sh
```

Explicit purge requires typing `PURGE` and additionally removes Behify-owned mesh configuration, mesh/watchdog units, and mesh backups:

```bash
sudo /opt/behify-easymesh/uninstall.sh --purge
```

The uninstaller refuses to operate without the installation ownership marker. It does not remove an unrelated `/usr/local/bin/easymesh`, unrecognized service file, unrelated EasyTier runtime, system Xray, x-ui/3x-ui, or Hiddify files. The isolated relay is removed only from its own relay menu.

## Isolated Relay

Menu option **Relay / Port Routing** manages a dedicated Xray Dokodemo-Door component. The user does not need 3x-ui, x-ui, Hiddify Manager, or a system Xray installation.

- Runtime: `/opt/behify-easymesh/relay/`
- Definitions: `/etc/behify-easymesh/relay/relays.json`
- Generated config: `/etc/behify-easymesh/relay/config.json`
- Service: `behify-relay.service`
- Process name: `behify-relayd`

For example, a UDP relay can listen on public port `443` and forward to mesh IP `10.144.144.1` port `443`. TCP, UDP, and Both modes are supported. Port conflicts and route reachability are checked before activation. Configuration updates validate in staging and roll back on service failure.

The relay manager does not modify or control `/etc/xray`, `/usr/local/etc/xray`, x-ui/3x-ui, Hiddify, `xray.service`, or unrelated Xray processes.

## Troubleshooting

Check installed and running versions:

```bash
/root/easytier/easytier-core --version
/root/easytier/easytier-cli --version
PID=$(systemctl show -p MainPID --value easymesh.service)
sudo /proc/$PID/exe --version
```

Check services and logs:

```bash
systemctl status easymesh.service
journalctl -u easymesh.service -n 100 --no-pager
systemctl status behify-relay.service
journalctl -u behify-relay.service -n 100 --no-pager
```

Peer and Peer-Center views use EasyTier's normal terminal formatting. Routes use `watch -w` only when the installed `watch` supports no-wrap mode; otherwise they safely fall back to normal wrapping.

Historical pre-v1 smoke reports are retained under `docs/historical/` for provenance and are not supported installation instructions.

## Security

See [SECURITY.md](SECURITY.md) for private vulnerability reporting. Do not include live mesh secrets or server credentials in public issues.
