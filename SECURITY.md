# Security Policy

## Supported Version

Security fixes are provided for the current `1.0.x` release line. Older development tags and branches are unsupported.

## Reporting a Vulnerability

Do not open a public issue for a vulnerability that could put deployed systems at risk. Send a private report to the repository owner through GitHub Security Advisories or the private Behify contact channel.

Include the affected version, architecture, deployment context, reproduction steps, impact, and any proposed mitigation. Avoid including live mesh secrets, server credentials, or public exploit details.

## Scope

Reports may cover the Behify installer, mesh-management script, isolated relay manager, generated systemd units, configuration handling, upgrade/rollback behavior, and release-package integrity.

EasyTier and Xray-core are separate upstream components. Vulnerabilities in unmodified upstream binaries should also be reported to their respective upstream projects.
