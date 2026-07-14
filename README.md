# Behify EasyMesh

Private Behify build of EasyMesh for offline server deployment and customized server-side usage.

## Status

This repository is currently a private modified build based on the original Easy-Mesh project.

Current focus:

- Keep the v2 script as the main version
- Prepare offline installation support
- Keep local EasyTier core binaries inside the repository
- Customize visible branding for Behify
- Improve reliability step by step

## Install

Clone or upload this repository to your server, then run:

```bash
sudo bash install.sh
sudo easymesh
```

Use EasyTier v2.6.4:

```bash
sudo easymesh 2.6.4
sudo easymesh --core v2.6.4
```

Strict offline:

```bash
sudo EASYMESH_OFFLINE=1 easymesh
sudo EASYMESH_OFFLINE=1 easymesh 2.6.4
```

## Architecture-safe core selection

Local core packages are selected from the detected system architecture:

- `x86_64` or `amd64`: `easytier-linux-x86_64`
- `aarch64` or `arm64`: `easytier-linux-aarch64`

Existing ARMv7 package selection remains supported where matching local binaries are present. Unknown architectures stop safely and are never redirected to an x86_64 package.

Running `sudo easymesh 2.6.4` when another core version is installed offers a core-only upgrade. Both candidate binaries are copied to temporary files and executed for architecture and version validation before the current service is stopped. After confirmation, the script backs up and replaces only `easytier-core` and `easytier-cli`; the existing `easymesh.service` file, its `ExecStart`, and the mesh configuration are preserved. A failed installation or service restart automatically restores the backup.

## Relay / Port Routing

Menu option `[12] Relay / Port Routing` provides an optional Dokodemo-Door relay. The end user does not need 3x-ui, Hiddify Manager, or an existing Xray installation. Behify downloads and runs a dedicated Xray binary that is isolated from any panel-managed Xray already installed on the server.

Xray is downloaded only after explicit confirmation. The manager accepts only a stable, non-draft, non-prerelease release from the official `XTLS/Xray-core` GitHub repository. The archive must include an official GitHub SHA-256 digest, and checksum or archive-path validation failure stops installation before the binary is executed or activated.

Relay modes are `tcp`, `udp`, and `both`. For example, a UDP relay can listen on public port `443` and forward it to EasyTier mesh address `10.144.144.1` port `443`:

```text
Name: mesh-udp-443
Protocol: udp
Listen address: 0.0.0.0
Listen port: 443
Destination IP: 10.144.144.1
Destination port: 443
```

Dedicated relay paths:

```text
/opt/behify-easymesh/relay/xray/current/xray
/etc/behify-easymesh/relay/relays.json
/etc/behify-easymesh/relay/config.json
/etc/systemd/system/behify-relay.service
```

TCP and UDP conflicts are checked separately with `ss`. Sensitive ports such as SSH port `22` produce an additional confirmation warning. EasyTier route checks are advisory: a route warning does not overwrite or remove the existing relay configuration.

Every configuration change backs up the current relay files, generates and validates temporary JSON, tests it with the dedicated Xray binary, and then atomically installs it. Only `behify-relay.service` is restarted. If validation, installation, or service startup fails, the previous relay configuration is restored automatically. The relay service uses `Wants=easymesh.service`; it does not contain or modify mesh IP, secret, peer, or `ExecStart` configuration.

When the last enabled relay is removed, the validated empty configuration is retained and `behify-relay.service` is stopped and disabled. The relay manager remains installed so another relay can be added later.

Check installed/running core version:

```bash
/root/easytier/easytier-core --version
PID=$(systemctl show -p MainPID --value easymesh.service); sudo /proc/$PID/exe --version
```

Smoke/offline test package:

```bash
unzip behify-easymesh-test.zip
cd behify-easymesh-test
sudo EASYMESH_OFFLINE=1 easymesh
```

After installation:
```bash
sudo easymesh
```

Offline Core

The project is intended to include EasyTier core binaries locally under:

core/v2.0.3/

The default selected core is `v2.0.3`, which is the currently smoke-tested version.

Local `v2.6.4` packages for x86_64 and aarch64 are stored under:

core/v2.6.4/

Future versions may include newer EasyTier core builds while keeping older versions as fallback.

Future stability test candidates are documented only and are not enabled by default:

```text
--enable-kcp-proxy
--enable-quic-proxy
--compression zstd
--multi-thread
```

Attribution

Based on Easy-Mesh by Musixal. LICENSE and NOTICE retained.


---
