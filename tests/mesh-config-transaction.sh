#!/usr/bin/env bash

set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
export EASYMESH_SOURCE_ONLY=1
# shellcheck source=../easymesh
source "$repo_root/easymesh"
test_root=$(mktemp -d "${TMPDIR:-/tmp}/behify-mesh-transaction.XXXXXX")
trap 'rm -rf -- "$test_root"' EXIT

MESH_CONFIG_DIR="$test_root/etc/behify-easymesh"
MESH_ENV_FILE="$MESH_CONFIG_DIR/mesh.env"
MESH_CORE_CONFIG="$MESH_CONFIG_DIR/easytier.toml"
SERVICE_FILE="$test_root/etc/systemd/system/easymesh.service"
state_dir="$test_root/state"
mkdir -p "$MESH_CONFIG_DIR/backups" "$(dirname "$SERVICE_FILE")" "$state_dir"
chmod 0700 "$MESH_CONFIG_DIR" "$MESH_CONFIG_DIR/backups"

printf 'OLD_ENV=preserve\n' > "$MESH_ENV_FILE"
printf 'OLD_CONFIG=preserve\n' > "$MESH_CORE_CONFIG"
printf '%s\n' '# Managed by Behify EasyMesh' 'Description=OLD_SERVICE' > "$SERVICE_FILE"
printf 'NEW_ENV=activate\n' > "$test_root/new.env"
printf 'NEW_CONFIG=activate\n' > "$test_root/new.toml"
printf '%s\n' '# Managed by Behify EasyMesh' 'Description=NEW_SERVICE' > "$test_root/new.service"
touch "$state_dir/active" "$state_dir/enabled"

systemctl() {
    printf '%s\n' "$*" >> "$state_dir/calls.log"
    case "${1:-}" in
        is-active) [[ -f "$state_dir/active" ]] ;;
        is-enabled) [[ -f "$state_dir/enabled" ]] ;;
        stop) rm -f "$state_dir/active" ;;
        start)
            if [[ -f "$state_dir/fail-new" ]] && grep -Fq 'NEW_SERVICE' "$SERVICE_FILE"; then
                return 1
            fi
            touch "$state_dir/active"
            ;;
        enable) touch "$state_dir/enabled" ;;
        disable) rm -f "$state_dir/enabled" ;;
        daemon-reload) ;;
        *) ;;
    esac
}

touch "$state_dir/fail-new"
if activate_mesh_configuration "$test_root/new.env" "$test_root/new.toml" "$test_root/new.service"; then
    printf 'Forced mesh service failure unexpectedly succeeded.\n' >&2
    exit 1
fi
grep -Fqx 'OLD_ENV=preserve' "$MESH_ENV_FILE"
grep -Fqx 'OLD_CONFIG=preserve' "$MESH_CORE_CONFIG"
grep -Fq 'Description=OLD_SERVICE' "$SERVICE_FILE"
[[ -f "$state_dir/active" && -f "$state_dir/enabled" ]]
find "$MESH_CONFIG_DIR/backups" -type f -name mesh.env -print -quit | grep -q .
find "$MESH_CONFIG_DIR/backups" -type f -name easytier.toml -print -quit | grep -q .

rm -f "$state_dir/fail-new"
activate_mesh_configuration "$test_root/new.env" "$test_root/new.toml" "$test_root/new.service"
grep -Fqx 'NEW_ENV=activate' "$MESH_ENV_FILE"
grep -Fqx 'NEW_CONFIG=activate' "$MESH_CORE_CONFIG"
grep -Fq 'Description=NEW_SERVICE' "$SERVICE_FILE"
[[ -f "$state_dir/active" && -f "$state_dir/enabled" ]]

printf '%s\n' '[Service]' 'ExecStart=/usr/bin/unrelated' > "$SERVICE_FILE"
cp "$SERVICE_FILE" "$test_root/unrelated.before"
if activate_mesh_configuration "$test_root/new.env" "$test_root/new.toml" "$test_root/new.service"; then
    printf 'Unrecognized service file was overwritten.\n' >&2
    exit 1
fi
cmp -s "$SERVICE_FILE" "$test_root/unrelated.before"

printf 'Mesh configuration transaction checks passed.\n'
