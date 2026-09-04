#!/usr/bin/env bash

set -Eeuo pipefail

archive="${1:?architecture package is required}"
architecture="${2:?architecture is required}"
service_file=/etc/systemd/system/easymesh.service
runtime_dir=/root/easytier
install_dir=/opt/behify-easymesh
backup_dir=/opt/behify-easymesh-backups
command_path=/usr/local/bin/easymesh
work_dir=""
resources_created=0

die() {
    printf 'Error: %s\n' "$*" >&2
    exit 1
}

cleanup() {
    set +e
    if [[ "$resources_created" == "1" ]]; then
        systemctl stop easymesh.service >/dev/null 2>&1 || true
        systemctl disable easymesh.service >/dev/null 2>&1 || true
        rm -f -- "$service_file"
        systemctl daemon-reload >/dev/null 2>&1 || true
        [[ ! -L "$command_path" || "$(readlink "$command_path")" != '/opt/behify-easymesh/easymesh' ]] || rm -f -- "$command_path"
        rm -rf -- "$runtime_dir" "$install_dir" "$backup_dir"
    fi
    [[ -z "$work_dir" || ! -d "$work_dir" ]] || rm -rf -- "$work_dir"
}
trap cleanup EXIT

[[ $EUID -eq 0 ]] || die "Run this disposable-host test as root."
[[ "$(uname -s)" == "Linux" ]] || die "This test requires Linux."
case "$(uname -m):$architecture" in
    x86_64:x86_64|amd64:x86_64|aarch64:aarch64|arm64:aarch64) ;;
    *) die "Runner architecture $(uname -m) does not match $architecture." ;;
esac
systemctl show --property=Version >/dev/null 2>&1 || die "A running systemd instance is required."
for path in "$service_file" "$runtime_dir" "$install_dir" "$backup_dir" "$command_path"; do
    [[ ! -e "$path" && ! -L "$path" ]] || die "Disposable runner path is not clean: $path"
done

work_dir=$(mktemp -d "${TMPDIR:-/tmp}/behify-systemd-smoke.XXXXXX")
tar -xzf "$archive" -C "$work_dir"
package_dir=$(find "$work_dir" -mindepth 1 -maxdepth 1 -type d -name 'behify-easymesh-*' -print -quit)
[[ -n "$package_dir" ]] || die "Package directory was not extracted."
resources_created=1

EASYMESH_OFFLINE=1 bash "$package_dir/install.sh"
"$runtime_dir/easytier-core" --version | grep -Fq '2.6.4'
"$runtime_dir/easytier-cli" --version | grep -Fq '2.6.4'
[[ -L "$command_path" && "$(readlink "$command_path")" == '/opt/behify-easymesh/easymesh' ]]

write_fake_runtime() {
    cat > "$runtime_dir/easytier-core" <<'EOF'
#!/usr/bin/env bash
if [[ "${1:-}" == "--version" ]]; then
    printf 'easytier-core 9.9.9-ci\n'
    exit 0
fi
while :; do sleep 60; done
EOF
    cat > "$runtime_dir/easytier-cli" <<'EOF'
#!/usr/bin/env bash
printf 'easytier-cli 9.9.9-ci\n'
EOF
    chmod 0755 "$runtime_dir/easytier-core" "$runtime_dir/easytier-cli"
}

write_service() {
    local extra_argument="${1:-}"
    cat > "$service_file" <<EOF
# Managed by Behify EasyMesh
[Unit]
Description=Behify EasyMesh disposable CI service
After=network.target

[Service]
Type=simple
PrivateNetwork=yes
ExecStart=/root/easytier/easytier-core -i 10.254.254.1 --hostname behify-ci --network-secret BehifyCiSecret123 --default-protocol tcp --listeners tcp://127.0.0.1:29999 --disable-ipv6 $extra_argument
Restart=no

[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload
}

# Active and disabled must remain active and disabled after an unsupported-runtime upgrade.
write_fake_runtime
write_service
systemctl start easymesh.service
systemctl is-active --quiet easymesh.service
! systemctl is-enabled --quiet easymesh.service
EASYMESH_OFFLINE=1 bash "$package_dir/install.sh"
systemctl is-active --quiet easymesh.service
! systemctl is-enabled --quiet easymesh.service
"$runtime_dir/easytier-core" --version | grep -Fq '2.6.4'

# Inactive and enabled must remain inactive and enabled.
systemctl stop easymesh.service
systemctl enable easymesh.service
write_fake_runtime
EASYMESH_OFFLINE=1 bash "$package_dir/install.sh"
! systemctl is-active --quiet easymesh.service
systemctl is-enabled --quiet easymesh.service
"$runtime_dir/easytier-core" --version | grep -Fq '2.6.4'

# A post-activation service failure must restore both old binaries and the active state.
systemctl disable easymesh.service
write_fake_runtime
old_core_hash=$(sha256sum "$runtime_dir/easytier-core" | awk '{print $1}')
old_cli_hash=$(sha256sum "$runtime_dir/easytier-cli" | awk '{print $1}')
write_service --behify-invalid-ci-option
systemctl start easymesh.service
if EASYMESH_OFFLINE=1 bash "$package_dir/install.sh"; then
    die "Installer accepted a runtime whose managed service could not start."
fi
[[ "$(sha256sum "$runtime_dir/easytier-core" | awk '{print $1}')" == "$old_core_hash" ]]
[[ "$(sha256sum "$runtime_dir/easytier-cli" | awk '{print $1}')" == "$old_cli_hash" ]]
systemctl is-active --quiet easymesh.service
! systemctl is-enabled --quiet easymesh.service
printf 'Disposable real-systemd %s install, state, and rollback checks passed.\n' "$architecture"
