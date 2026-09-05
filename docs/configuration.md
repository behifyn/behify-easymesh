# Configuration

## Mesh

Run `sudo easymesh` and select **Connect to the Mesh Network**. Behify validates addresses, ports, hostnames, and secrets before staging a replacement.

Defaults:

- Encryption: enabled and recommended. Disabling it shows the risk and requires explicit confirmation.
- Multi-thread: disabled. It can improve throughput on some systems but may increase instability or packet reordering on some paths.
- IPv6: enabled, preserving the existing behavior.

Behify generates a secret with `openssl rand -hex 16`. It displays that generated value once in the interactive terminal and keeps it visible during the hidden prompt. Press Enter to use it, or type a custom secret without echo. Menu option 5 is the only normal post-configuration reveal path.

Sensitive settings are stored in `/etc/behify-easymesh/mesh.env`; EasyTier reads the secret through `/etc/behify-easymesh/easytier.toml`. Both files are root-only mode `0600`. The systemd unit and process arguments do not contain the secret.

## Peer Direction

For two nodes, one side can initiate with the other node's reachable address while the listening/reverse side leaves peer addresses blank. If that direction fails, try the reverse direction and check UDP reachability, host and provider firewalls, NAT, and another supported protocol. EasyTier may establish direct P2P after one side initiates. Behify does not automatically add reverse peers or alter routing.

## Relay

Menu option **Relay / Port Routing** manages the isolated `behify-relay.service`. It supports TCP, UDP, or Both and does not require or modify 3x-ui, x-ui, Hiddify, or a system Xray installation.

Definitions are stored in `/etc/behify-easymesh/relay/relays.json`; generated Xray configuration is `/etc/behify-easymesh/relay/config.json`. Port conflicts and route reachability are checked before activation, and failed changes roll back.
