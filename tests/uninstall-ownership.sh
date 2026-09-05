#!/usr/bin/env bash

set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
test_root=$(mktemp -d "${TMPDIR:-/tmp}/behify-uninstall-test.XXXXXX")
trap 'rm -rf -- "$test_root"' EXIT
. "$repo_root/versions.env"

grep -Fq 'if [[ "$TEST_MODE" == "1" && -n "$TEST_ROOT" && "${BEHIFY_TEST_CONFIRM:-0}" == "1" ]]' "$repo_root/uninstall.sh"
grep -Fq 'if [[ "$PURGE" == "0" && "$TEST_CONFIRM" != "1" ]]' "$repo_root/uninstall.sh"
package_dir="$test_root/package"
mock_bin="$test_root/mock-bin"
mkdir -p "$mock_bin"
cp "$repo_root/tests/mock-systemctl.sh" "$mock_bin/systemctl"
chmod 0755 "$mock_bin/systemctl"
bash "$repo_root/tests/make-test-package.sh" "$package_dir" x86_64

run_uninstaller() {
    local root="$1"
    shift
    mkdir -p "$root/systemctl-state"
    MOCK_SYSTEMCTL_STATE="$root/systemctl-state" \
    MOCK_INSTALL_ROOT="$root" \
    BEHIFY_TEST_ROOT="$root" \
    BEHIFY_TEST_MODE=1 \
    BEHIFY_TEST_CONFIRM=1 \
    PATH="$mock_bin:$PATH" \
        bash "$repo_root/uninstall.sh" "$@"
}

protected_root="$test_root/protected"
mkdir -p "$protected_root/opt/behify-easymesh/relay" "$protected_root/root/easytier" \
    "$protected_root/usr/local/bin" "$protected_root/etc/systemd/system" \
    "$protected_root/etc/behify-easymesh" "$protected_root/etc/xray"
printf 'behify-easymesh:%s\n' "$BEHIFY_EASYMESH_VERSION" > "$protected_root/opt/behify-easymesh/.install-owner"
cp "$package_dir/manifest.txt" "$protected_root/opt/behify-easymesh/manifest.txt"
cp "$repo_root/README.md" "$protected_root/opt/behify-easymesh/README.md"
printf 'relay state\n' > "$protected_root/opt/behify-easymesh/relay/state"
cp "$package_dir/core/easytier-core" "$protected_root/root/easytier/easytier-core"
cp "$package_dir/core/easytier-cli" "$protected_root/root/easytier/easytier-cli"
printf 'unrelated command\n' > "$protected_root/usr/local/bin/easymesh"
printf '[Service]\nExecStart=/usr/bin/unrelated\n' > "$protected_root/etc/systemd/system/easymesh.service"
printf 'secret config\n' > "$protected_root/etc/behify-easymesh/mesh.env"
printf 'private core config\n' > "$protected_root/etc/behify-easymesh/easytier.toml"
printf 'system xray\n' > "$protected_root/etc/xray/config.json"
run_uninstaller "$protected_root"
[[ -f "$protected_root/root/easytier/easytier-core" ]]
[[ -f "$protected_root/usr/local/bin/easymesh" ]]
[[ -f "$protected_root/etc/systemd/system/easymesh.service" ]]
[[ -f "$protected_root/etc/behify-easymesh/mesh.env" ]]
[[ -f "$protected_root/etc/behify-easymesh/easytier.toml" ]]
[[ -f "$protected_root/opt/behify-easymesh/relay/state" ]]
[[ -f "$protected_root/etc/xray/config.json" ]]
if grep -Eq '^(stop|disable) easymesh\.service$' "$protected_root/systemctl-state/calls.log" 2>/dev/null; then
    printf 'Unrecognized service was controlled.\n' >&2
    exit 1
fi

purge_root="$test_root/purge"
mkdir -p "$purge_root/opt/behify-easymesh/relay" "$purge_root/root/easytier" \
    "$purge_root/usr/local/bin" "$purge_root/etc/systemd/system" \
    "$purge_root/etc/behify-easymesh/backups" "$purge_root/etc/behify-easymesh/relay" \
    "$purge_root/etc/xray"
printf 'behify-easymesh:%s\n' "$BEHIFY_EASYMESH_VERSION" > "$purge_root/opt/behify-easymesh/.install-owner"
cp "$package_dir/manifest.txt" "$purge_root/opt/behify-easymesh/manifest.txt"
cp "$package_dir/core/easytier-core" "$purge_root/root/easytier/easytier-core"
cp "$package_dir/core/easytier-cli" "$purge_root/root/easytier/easytier-cli"
chmod 0755 "$purge_root/root/easytier/easytier-core" "$purge_root/root/easytier/easytier-cli"
printf '%s\n' '#!/usr/bin/env bash' '# Behify EasyMesh test command link' > "$purge_root/usr/local/bin/easymesh"
printf '%s\n' '# Managed by Behify EasyMesh' > "$purge_root/etc/systemd/system/easymesh.service"
printf '%s\n' '[Service]' 'ExecStart=/bin/bash /etc/monitor.sh' > "$purge_root/etc/systemd/system/easymesh-watchdog.service"
printf 'monitor\n' > "$purge_root/etc/monitor.sh"
printf 'log\n' > "$purge_root/etc/monitor.log"
printf 'secret\n' > "$purge_root/etc/behify-easymesh/mesh.env"
printf 'private core config\n' > "$purge_root/etc/behify-easymesh/easytier.toml"
printf 'backup\n' > "$purge_root/etc/behify-easymesh/backups/config"
printf 'relay definitions\n' > "$purge_root/etc/behify-easymesh/relay/relays.json"
printf 'relay runtime\n' > "$purge_root/opt/behify-easymesh/relay/state"
printf 'system xray\n' > "$purge_root/etc/xray/config.json"
run_uninstaller "$purge_root" --purge --yes
[[ ! -e "$purge_root/root/easytier/easytier-core" ]]
[[ ! -e "$purge_root/usr/local/bin/easymesh" ]]
[[ ! -e "$purge_root/etc/systemd/system/easymesh.service" ]]
[[ ! -e "$purge_root/etc/systemd/system/easymesh-watchdog.service" ]]
[[ ! -e "$purge_root/etc/behify-easymesh/mesh.env" ]]
[[ ! -e "$purge_root/etc/behify-easymesh/easytier.toml" ]]
[[ -f "$purge_root/etc/behify-easymesh/relay/relays.json" ]]
[[ -f "$purge_root/opt/behify-easymesh/relay/state" ]]
[[ -f "$purge_root/etc/xray/config.json" ]]

printf 'Uninstall ownership checks passed.\n'
