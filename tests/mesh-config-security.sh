#!/usr/bin/env bash

set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
export EASYMESH_SOURCE_ONLY=1
# shellcheck source=../easymesh
source "$repo_root/easymesh"
test_root=$(mktemp -d "${TMPDIR:-/tmp}/behify-mesh-config.XXXXXX")
trap 'rm -rf -- "$test_root"' EXIT

is_valid_ip_address '10.144.144.1'
is_valid_ip_address '2001:db8::1'
! is_valid_ip_address '10.0.0.1 --hostname injected'
! is_valid_ip_address $'10.0.0.1\nEnvironment=BAD=1'
is_valid_hostname 'server-1.example'
! is_valid_hostname '--network-secret'
! is_valid_hostname $'server\nExecStart=/bin/sh'
is_valid_network_secret 'StrongSecret-123'
! is_valid_network_secret '-starts-with-option'
! is_valid_network_secret $'StrongSecret\nEnvironment=BAD'
is_integer_in_range 2090 1 65535
! is_integer_in_range '2090;id' 1 65535

build_peer_arguments '10.0.0.1, 2001:db8::2' udp 2090
[[ "$PEER_ARGUMENTS" == '--peers udp://10.0.0.1:2090 udp://[2001:db8::2]:2090' ]]
if build_peer_arguments '10.0.0.1,--hostname attacker' udp 2090; then
    printf 'Malicious peer input was accepted.\n' >&2
    exit 1
fi
many_peers='10.0.0.1'
for ((i = 0; i < 64; i++)); do
    many_peers+=',10.0.0.1'
done
if build_peer_arguments "$many_peers" udp 2090; then
    printf 'Oversized peer list was accepted.\n' >&2
    exit 1
fi

IP_ADDRESS='10.144.144.1'
PEER_ARGUMENTS='--peers udp://10.144.144.2:2090'
HOSTNAME='server-1'
NETWORK_SECRET='StrongSecret-123'
DEFAULT_PROTOCOL='udp'
LISTENERS='--listeners udp://[::]:2090 udp://0.0.0.0:2090'
MULTI_THREAD_OPTION='--multi-thread'
ENCRYPTION_OPTION=''
IPV6_OPTION=''
write_mesh_environment "$test_root/mesh.env"
write_mesh_service "$test_root/easymesh.service"

[[ "$(stat -c '%a' "$test_root/mesh.env")" == '600' ]]
grep -Fq 'EASYMESH_NETWORK_SECRET="StrongSecret-123"' "$test_root/mesh.env"
grep -Fqx 'EnvironmentFile=/etc/behify-easymesh/mesh.env' "$test_root/easymesh.service"
grep -Fq '${EASYMESH_NETWORK_SECRET}' "$test_root/easymesh.service"
if grep -Fq 'StrongSecret-123' "$test_root/easymesh.service"; then
    printf 'Mesh secret leaked into the service unit.\n' >&2
    exit 1
fi
if grep -Eq '(^|[[:space:]])eval([[:space:]]|$)' "$repo_root/easymesh"; then
    printf 'Mesh manager contains eval.\n' >&2
    exit 1
fi
resolve_release_architecture x86_64 | grep -Fxq x86_64
resolve_release_architecture aarch64 | grep -Fxq aarch64
if resolve_release_architecture armv7l >/dev/null; then
    printf 'Unsupported ARMv7 architecture was accepted.\n' >&2
    exit 1
fi

printf 'Mesh configuration security checks passed.\n'
