# Behify EasyMesh v1.0.0-rc.1 Release Checklist

This checklist is for the release owner. It does not replace automated CI.

## Repository

- Confirm the release branch is based on the approved `main` commit.
- Confirm `LICENSE` and `NOTICE` are unchanged.
- Confirm no EasyTier or Xray executable is tracked in Git.
- Confirm the working tree is clean before running `release/build-release.sh`.

## Automated Validation

```bash
bash tests/run-all.sh release-output
git diff --check
git diff main...HEAD --check
```

CI must complete Bash syntax checks, ShellCheck, regressions, package construction, strict-offline installation, package checksum validation, native EasyTier execution, and disposable real-systemd tests on both supported architectures.

## Manual Linux Gates

- Install the x86_64 package on a disposable systemd host and verify fresh install, repeated install, active-service upgrade, inactive-service upgrade, and rollback after a forced service failure.
- Install the aarch64 package on a native ARM64 systemd host and run both bundled binaries with `--version` before opening the menu.
- Confirm `/usr/local/bin/easymesh` resolves to `/opt/behify-easymesh/easymesh`.
- Confirm `easymesh --version` reports Behify `v1.0.0-rc.1` and EasyTier `v2.6.4`.
- Confirm an offline install succeeds while outbound network access is blocked.
- Confirm the menu starts without a network attempt or runtime replacement.
- Join a disposable two-node mesh and verify peer, route, and Peer-Center terminal views.
- Verify the existing two-server UDP/P2P scenario and document whether direct or fallback multi-hop routing is observed.
- Inspect `/root/easytier/reset.sh` and the matching root-cron entry without executing or deleting either one. The RC installer refuses affected upgrades; cleanup requires separate authorization.
- Exercise relay add/remove/rollback on a disposable host and verify system Xray, x-ui/3x-ui, and Hiddify paths remain untouched.

## Release Assets

- `behify-easymesh-v1.0.0-rc.1-linux-x86_64.tar.gz`
- `behify-easymesh-v1.0.0-rc.1-linux-aarch64.tar.gz`
- `online-install-v1.0.0-rc.1.sh`
- `SHA256SUMS`
- `easytier-v2.6.4-source.tar.gz`

Verify every published byte against the locally generated `SHA256SUMS`. Do not use GitHub's automatic source archives as offline installers.

## Optional Post-RC Improvements

- Signed checksums or provenance attestations
- SBOM generation
- Dependabot configuration
- Branch protection and repository security settings
