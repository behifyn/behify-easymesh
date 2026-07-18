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
grep -Fqx 'RELAY_XRAY_ROOT="/opt/behify-easymesh/relay/xray"' relay-manager
grep -Fqx 'INSTALL_DIR="/opt/behify-easymesh"' install.sh
grep -Fqx 'COMMAND_PATH="/usr/local/bin/easymesh"' install.sh

grep -Fq 'easy_client_supports_no_trunc' easymesh
grep -Fq 'verify_relay_sockets' relay-manager
grep -Fq 'relay_service_is_owned' relay-manager

bash tests/temp-path-regression.sh

printf 'Static smoke checks passed.\n'
