# Smoke Test - v0.1.0 Offline Install

Date: 2026-07-09

## Scope

This smoke test validates the Behify EasyMesh offline-first installation flow and a basic two-server UDP mesh connection.

## Tested Core

```text
easytier-core 2.0.3-861d6584
easytier-cli 2.0.3-861d6584
```

## Server 1

```text
Hostname: serverkh
Mesh IP: 10.144.144.1/24
Tunnel protocol: udp
Service: easymesh.service
Status: active/running
```

## Server 2

```text
Hostname: dakhel
Mesh IP: 10.144.144.2/24
Tunnel protocol: udp
Service: easymesh.service
Status: active/running
```

## Results

```text
Peer discovery: OK
Route discovery: OK
UDP tunnel: OK
P2P connection: OK
Packet loss: 0%
Latency: ~28-29 ms
```

## Validation Commands

```bash
systemctl status easymesh.service --no-pager
/root/easytier/easytier-cli peer
/root/easytier/easytier-cli route
ping -c 4 10.144.144.1
ping -c 4 10.144.144.2
```

## Notes

The offline-first installation successfully installed EasyTier core binaries from the local package.

Known minor UI issues:

- The banner Telegram/channel line may overflow the ASCII box.
- CLI peer/route commands should show a friendly message when the service is not running.