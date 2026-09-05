# Operations

## Paths and Services

| Purpose | Path or unit |
| --- | --- |
| Application | `/opt/behify-easymesh` |
| Command | `/usr/local/bin/easymesh` |
| EasyTier runtime | `/root/easytier/easytier-core`, `/root/easytier/easytier-cli` |
| Mesh service | `/etc/systemd/system/easymesh.service` |
| Private mesh environment | `/etc/behify-easymesh/mesh.env` |
| Private EasyTier config | `/etc/behify-easymesh/easytier.toml` |
| Mesh backups | `/etc/behify-easymesh/backups/` |
| Installer backups | `/opt/behify-easymesh-backups/` |
| Isolated relay service | `behify-relay.service` |

## Upgrade and Rollback

Before upgrading a pre-v1 installation, inspect the known legacy maintenance locations without executing or deleting them:

```bash
sudo test ! -e /root/easytier/reset.sh || sudo stat /root/easytier/reset.sh
sudo crontab -l 2>/dev/null | grep -F '/root/easytier/reset.sh' || true
```

The installer refuses an unattended upgrade while either legacy marker exists. For a recognized RC1 service, RC2 preserves `mesh.env` and its network options while migrating only the service's secret transport to the root-only EasyTier config. Candidate runtime and config validation happen before activation. Active/inactive and enabled/disabled states are preserved; failure restores the previous application, runtime pair, service file, private config, command path, and active state.

## Diagnostics

```bash
/root/easytier/easytier-core --version
/root/easytier/easytier-cli --version
PID=$(systemctl show -p MainPID --value easymesh.service)
sudo /proc/$PID/exe --version
systemctl status easymesh.service
journalctl -u easymesh.service -n 100 --no-pager
```

Do not paste service output into a public report without reviewing it. Managed RC2 services keep the mesh secret out of the unit, process arguments, normal status output, and WARN-level journal output.

For manual throughput testing, install `iperf3` separately. Retransmissions or packet reordering depend on the path and environment and are not by themselves proof of an EasyMesh defect.

## Removal

Normal uninstall preserves configuration and service files:

```bash
sudo /opt/behify-easymesh/uninstall.sh
```

Explicit purge requires typing `PURGE` and removes verified Behify-owned mesh configuration, units, and backups. The isolated relay is removed only from its own menu.

```bash
sudo /opt/behify-easymesh/uninstall.sh --purge
```
