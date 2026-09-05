# Historical Smoke Test - v0.1.3 with EasyTier v2.6.4

Date: 2026-07-09

This archived report records the pre-v1 test that established EasyTier v2.6.4 as the supported runtime. The old version-selector command is no longer supported; v1 release packages install v2.6.4 directly.

## Tested Runtime

```text
easytier-core 2.6.4-8428a89d
easytier-cli 2.6.4-8428a89d
```

## Topology

```text
Server 1: kharej, 10.144.144.1/24
Server 2: dakhel, 10.144.144.2/24
Protocol: udp
Connection: p2p
```

## Result

```text
Packet loss: 0%
Latency: ~26-27 ms
iperf3: ~160 Mbps forward, ~50 Mbps reverse
```

Equivalent v1 offline installation starts from the matching architecture Release package:

```bash
sudo EASYMESH_OFFLINE=1 bash install.sh
sudo easymesh
```
