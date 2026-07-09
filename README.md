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
```

Strict offline:

```bash
sudo EASYMESH_OFFLINE=1 easymesh
sudo EASYMESH_OFFLINE=1 easymesh 2.6.4
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

Support for `v2.6.4` is prepared through `EASYMESH_CORE_VERSION`, but strict offline use requires adding matching local binaries under:

core/v2.6.4/

Future versions may include newer EasyTier core builds while keeping older versions as fallback.

Attribution

Based on Easy-Mesh by Musixal. LICENSE and NOTICE retained.


---
