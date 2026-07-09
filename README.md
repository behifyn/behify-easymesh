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
```

After installation:
```bash
sudo easymesh
```

Offline Core

The project is intended to include EasyTier core binaries locally under:

core/v2.0.3/

Future versions may include newer EasyTier core builds while keeping older versions as fallback.

Attribution

This project is based on Easy-Mesh by Musixal and uses EasyTier core.

The original LICENSE and NOTICE files are retained.


---