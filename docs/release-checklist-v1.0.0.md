# Behify EasyMesh v1.0.0 Release Checklist

## Source and Validation

- Confirm the release commit is on `release/v1.0.0-prep` and the working tree is clean.
- Confirm `BEHIFY_EASYMESH_VERSION=1.0.0` and `EASYTIER_VERSION=v2.6.4` in `versions.env`.
- Confirm `LICENSE`, `NOTICE`, runtime scripts, installer behavior, networking, routing, relay behavior, service design, and secret handling match the validated RC3 source.
- Require successful Bash syntax, ShellCheck, static regressions, package checks, strict-offline tests, native x86_64, native aarch64, and real-systemd tests.
- Build stable artifacts from the clean stable-promotion commit; do not reuse RC3 artifacts.

## Exact Assets

- `behify-easymesh-v1.0.0-linux-x86_64.tar.gz`
- `behify-easymesh-v1.0.0-linux-aarch64.tar.gz`
- `online-install-v1.0.0.sh`
- `install.sh`
- `SHA256SUMS`
- `easytier-v2.6.4-source.tar.gz`

Reject missing, extra, stale, or differently named files. Verify every listed asset with `SHA256SUMS` and confirm `install.sh` is byte-identical to `online-install-v1.0.0.sh`.

## Publication Guardrails

- Confirm the published v1.0.0-rc.3 tag and release remain unchanged.
- Create no stable tag or release until the stable commit's CI run passes every required job.
- Verify the stable tag resolves exactly to the tested commit before publication.
- Publish only the six verified assets produced by that successful workflow.
