#!/usr/bin/env bash

set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$repo_root"

bash -n easymesh
bash -n relay-manager
bash -n install.sh

grep -Fqx 'DEFAULT_CORE_VERSION="v2.0.3"' easymesh
grep -Fqx 'SERVICE_FILE="/etc/systemd/system/easymesh.service"' easymesh
grep -Fqx 'RELAY_SERVICE_NAME="behify-relay.service"' relay-manager
grep -Fqx 'RELAY_BINARY="$RELAY_BIN_DIR/behify-relayd"' relay-manager
grep -Fqx 'INSTALL_DIR="/opt/behify-easymesh"' install.sh
grep -Fqx 'COMMAND_PATH="/usr/local/bin/easymesh"' install.sh

grep -Fq 'verify_relay_sockets' relay-manager
grep -Fq 'relay_service_is_owned' relay-manager

if grep -Eq 'COLUMNS=|stty size|tput cols|cols=80' easymesh; then
    printf 'Mesh views still override EasyTier terminal-width handling.\n' >&2
    exit 1
fi
if grep -Eq 'EASY_CLIENT_NO_TRUNC|easy_client_supports_no_trunc|--no-trunc' easymesh; then
    printf 'Interactive mesh views still disable EasyTier default truncation.\n' >&2
    exit 1
fi
grep -Fq 'client_command="$quoted_client $view"' easymesh
grep -Fq 'local -a watch_options=(-n1 -t)' easymesh
grep -Fq 'watch "${watch_options[@]}" -- "$client_command"' easymesh
grep -Eq 'watch_mesh_view[[:space:]]+peer$' easymesh
grep -Eq 'watch_mesh_view[[:space:]]+route$' easymesh
grep -Eq 'watch_mesh_view[[:space:]]+peer-center$' easymesh

bash tests/mesh-watch-regression.sh
bash tests/temp-path-regression.sh
bash tests/neutral-runtime-regression.sh

printf 'Static smoke checks passed.\n'
