#!/usr/bin/env bash

set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$repo_root"
source tests/license-integrity.sh

while IFS= read -r script; do
    bash -n "$script"
done < <(find . -type f \( -name '*.sh' -o -name '*.sh.in' \) -print | LC_ALL=C sort)
bash -n easymesh relay-manager

grep -Fqx 'BEHIFY_EASYMESH_VERSION=1.0.0-rc.2' versions.env
grep -Fqx 'EASYTIER_VERSION=v2.6.4' versions.env
grep -Fqx 'SERVICE_FILE="/etc/systemd/system/easymesh.service"' easymesh
grep -Fqx 'RELAY_SERVICE_NAME="behify-relay.service"' relay-manager
grep -Fqx 'RELAY_BINARY="$RELAY_BIN_DIR/behify-relayd"' relay-manager
grep -Fq 'root_path /opt/behify-easymesh' install.sh
grep -Fq 'root_path /usr/local/bin/easymesh' install.sh
grep -Fq 'root_path /root/easytier' install.sh
grep -Fq 'verify_relay_sockets' relay-manager
grep -Fq 'relay_service_is_owned' relay-manager

if git ls-files 'core/**' | grep -q .; then
    printf 'Tracked EasyTier runtime files remain under core/.\n' >&2
    exit 1
fi
if grep -Eq 'COLUMNS=|stty size|tput cols|cols=80' easymesh; then
    printf 'Mesh views still override EasyTier terminal-width handling.\n' >&2
    exit 1
fi
if grep -Eq 'EASY_CLIENT_NO_TRUNC|easy_client_supports_no_trunc|--no-trunc' easymesh; then
    printf 'Interactive mesh views still disable EasyTier default truncation.\n' >&2
    exit 1
fi
if grep -Eq 'v2\.0\.[35]|EASYMESH_CORE_VERSION|install_easytier|Musixal/Easy-Mesh/raw|pgrep[[:space:]]+easytier|kill[[:space:]]+-9' easymesh install.sh; then
    printf 'Legacy runtime selection, download, or global process logic remains.\n' >&2
    exit 1
fi
if grep -Eq 'curl|wget' easymesh; then
    printf 'Opening the mesh menu can still reach a download path.\n' >&2
    exit 1
fi
if grep -Eq 'curl|wget' install.sh; then
    printf 'Offline package installer contains a network command.\n' >&2
    exit 1
fi
if grep -Eq '/releases/(latest|download/latest)|/main/' release/build-release.sh release/easytier-v2.6.4-assets.env; then
    printf 'Release tooling references a moving upstream target.\n' >&2
    exit 1
fi
verify_license_notice_integrity
grep -Fq 'client_command="$quoted_client $view"' easymesh
grep -Fq 'local -a watch_options=(-n1 -t)' easymesh
grep -Fq 'watch "${watch_options[@]}" -- "$client_command"' easymesh
grep -Eq 'watch_mesh_view[[:space:]]+peer$' easymesh
grep -Eq 'watch_mesh_view[[:space:]]+route$' easymesh
grep -Eq 'watch_mesh_view[[:space:]]+peer-center$' easymesh
grep -Fq 'EnvironmentFile=/etc/behify-easymesh/mesh.env' easymesh
grep -Fq -- '--config-file /etc/behify-easymesh/easytier.toml' easymesh
grep -Fq -- '--console-log-level warn' easymesh
if grep -Eq 'ExecStart=.*--network-secret' easymesh; then
    printf 'The managed mesh service still exposes its secret through process arguments.\n' >&2
    exit 1
fi
if grep -Eq 'ExecStart=.*\$NETWORK_SECRET' easymesh; then
    printf 'A literal mesh secret variable remains in the service writer.\n' >&2
    exit 1
fi

bash tests/mesh-watch-regression.sh
bash tests/license-integrity-regression.sh
bash tests/temp-path-regression.sh
bash tests/neutral-runtime-regression.sh
bash tests/mesh-config-security.sh
bash tests/mesh-config-transaction.sh
bash tests/mesh-interactive-regression.sh
bash tests/installer-regression.sh
bash tests/uninstall-ownership.sh

printf 'Static smoke checks passed.\n'
