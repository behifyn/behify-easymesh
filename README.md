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
