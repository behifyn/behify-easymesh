# Smoke Test - v0.1.3 EasyTier v2.6.4

Date: 2026-07-09

## Scope

This smoke test validates strict offline installation with EasyTier v2.6.4 and a basic two-server UDP mesh connection.

## Command Used

```bash
sudo EASYMESH_OFFLINE=1 EASYMESH_CORE_VERSION=v2.6.4 ./easymesh
```

## Tested Core

```text
easytier-core 2.6.4-8428a89d
easytier-cli 2.6.4-8428a89d
```

## Server 1

```text
Hostname: kharej
Mesh IP: 10.144.144.1/24
Tunnel protocol: udp
Connection: p2p
Service: easymesh.service
```

## Server 2

```text
Hostname: dakhel
Mesh IP: 10.144.144.2/24
Tunnel protocol: udp
Connection: p2p
Service: easymesh.service
```

## Results

```text
Protocol: udp
Connection: p2p
Packet loss: 0%
Latency: ~26-27 ms
```
