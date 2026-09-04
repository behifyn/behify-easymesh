#!/usr/bin/env bash

set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
test_root=$(mktemp -d "${TMPDIR:-/tmp}/behify-installer-test.XXXXXX")
trap 'rm -rf -- "$test_root"' EXIT
package_dir="$test_root/package"
mock_bin="$test_root/mock-bin"
network_log="$test_root/network.log"
mkdir -p "$mock_bin"
cp "$repo_root/tests/mock-systemctl.sh" "$mock_bin/systemctl"
chmod 0755 "$mock_bin/systemctl"
cat > "$mock_bin/curl" <<EOF
#!/usr/bin/env bash
printf 'curl\n' >> '$network_log'
exit 90
EOF
cat > "$mock_bin/wget" <<EOF
#!/usr/bin/env bash
printf 'wget\n' >> '$network_log'
exit 90
EOF
cat > "$mock_bin/crontab" <<'EOF'
#!/usr/bin/env bash
if [[ "${1:-}" == "-l" && "${MOCK_LEGACY_CRON:-0}" == "1" ]]; then
    printf '0 * * * * /root/easytier/reset.sh # legacy EasyMesh\n'
    exit 0
fi
exit 1
EOF
chmod 0755 "$mock_bin/curl" "$mock_bin/wget" "$mock_bin/crontab"
bash "$repo_root/tests/make-test-package.sh" "$package_dir" x86_64

run_installer() {
    local root="$1"
    shift
    mkdir -p "$root" "$root/systemctl-state"
    MOCK_SYSTEMCTL_STATE="$root/systemctl-state" \
    MOCK_INSTALL_ROOT="$root" \
    BEHIFY_TEST_ROOT="$root" \
    BEHIFY_TEST_MODE=1 \
    BEHIFY_TEST_ARCH=x86_64 \
    EASYMESH_OFFLINE=1 \
    PATH="$mock_bin:$PATH" \
        "$@" bash "$package_dir/install.sh"
}

unsupported_root="$test_root/unsupported"
if MOCK_SYSTEMCTL_STATE="$unsupported_root/state" MOCK_INSTALL_ROOT="$unsupported_root" \
    BEHIFY_TEST_ROOT="$unsupported_root" BEHIFY_TEST_MODE=1 BEHIFY_TEST_ARCH=armv7l \
    PATH="$mock_bin:$PATH" bash "$package_dir/install.sh" >"$test_root/unsupported.log" 2>&1; then
    printf 'Unsupported architecture was accepted.\n' >&2
    exit 1
fi
grep -Fq 'supports only Linux x86_64 and aarch64' "$test_root/unsupported.log"
[[ ! -e "$unsupported_root/opt/behify-easymesh" ]]

invalid_package="$test_root/invalid-package"
cp -a "$package_dir" "$invalid_package"
rm -f "$invalid_package/core/easytier-cli"
invalid_root="$test_root/invalid-root"
if MOCK_SYSTEMCTL_STATE="$invalid_root/state" MOCK_INSTALL_ROOT="$invalid_root" \
    BEHIFY_TEST_ROOT="$invalid_root" BEHIFY_TEST_MODE=1 BEHIFY_TEST_ARCH=x86_64 \
    PATH="$mock_bin:$PATH" bash "$invalid_package/install.sh" >"$test_root/invalid.log" 2>&1; then
    printf 'Incomplete package was accepted.\n' >&2
    exit 1
fi
[[ ! -e "$invalid_root/opt/behify-easymesh" ]]

unowned_root="$test_root/unowned-service"
mkdir -p "$unowned_root/etc/systemd/system" "$unowned_root/opt/behify-easymesh" "$unowned_root/systemctl-state"
printf '%s\n' '[Service]' 'ExecStart=/usr/bin/unrelated' > "$unowned_root/etc/systemd/system/easymesh.service"
printf 'preserve application\n' > "$unowned_root/opt/behify-easymesh/sentinel"
if run_installer "$unowned_root" env >"$test_root/unowned.log" 2>&1; then
    printf 'Installer accepted an unrecognized service file.\n' >&2
    exit 1
fi
grep -Fq 'Refusing to control an unrecognized or symlinked easymesh.service file.' "$test_root/unowned.log"
[[ -f "$unowned_root/opt/behify-easymesh/sentinel" ]]
[[ ! -e "$unowned_root/root/easytier/easytier-core" ]]

legacy_script_root="$test_root/legacy-script"
mkdir -p "$legacy_script_root/root/easytier"
printf '#!/usr/bin/env bash\nexit 0\n' > "$legacy_script_root/root/easytier/reset.sh"
if run_installer "$legacy_script_root" env >"$test_root/legacy-script.log" 2>&1; then
    printf 'Installer accepted a legacy reset.sh setup.\n' >&2
    exit 1
fi
grep -Fq 'Unsafe pre-v1 EasyTier maintenance was detected.' "$test_root/legacy-script.log"
[[ ! -e "$legacy_script_root/opt/behify-easymesh" ]]

legacy_cron_root="$test_root/legacy-cron"
if run_installer "$legacy_cron_root" env MOCK_LEGACY_CRON=1 >"$test_root/legacy-cron.log" 2>&1; then
    printf 'Installer accepted a legacy root-cron setup.\n' >&2
    exit 1
fi
grep -Fq 'Unsafe pre-v1 EasyTier maintenance was detected.' "$test_root/legacy-cron.log"
[[ ! -e "$legacy_cron_root/opt/behify-easymesh" ]]

symlink_install_root="$test_root/symlink-install-root"
mkdir -p "$symlink_install_root/opt" "$symlink_install_root/unrelated"
if ln -s "$symlink_install_root/unrelated" "$symlink_install_root/opt/behify-easymesh" 2>/dev/null &&
   [[ -L "$symlink_install_root/opt/behify-easymesh" ]]; then
    if run_installer "$symlink_install_root" env >"$test_root/symlink-install.log" 2>&1; then
        printf 'Installer accepted a symlinked application directory.\n' >&2
        exit 1
    fi
    grep -Fq 'Refusing to use a symlinked Behify installation directory.' "$test_root/symlink-install.log"
    [[ ! -e "$symlink_install_root/root/easytier/easytier-core" ]]
elif [[ "$(uname -s)" == "Linux" ]]; then
    printf 'Could not create the application-directory symlink required by the Linux regression.\n' >&2
    exit 1
else
    printf 'Application-directory symlink check skipped: native symlinks are unavailable.\n'
fi

fresh_root="$test_root/fresh"
run_installer "$fresh_root" env
[[ -x "$fresh_root/opt/behify-easymesh/easymesh" ]]
[[ -x "$fresh_root/root/easytier/easytier-core" ]]
grep -Fqx '# Behify EasyMesh test command link' "$fresh_root/usr/local/bin/easymesh"
[[ ! -s "$network_log" ]]
first_core_hash=$(sha256sum "$fresh_root/root/easytier/easytier-core" | awk '{print $1}')
run_installer "$fresh_root" env
[[ "$(sha256sum "$fresh_root/root/easytier/easytier-core" | awk '{print $1}')" == "$first_core_hash" ]]
[[ ! -s "$network_log" ]]

upgrade_root="$test_root/upgrade"
mkdir -p "$upgrade_root/root/easytier" "$upgrade_root/etc/systemd/system" "$upgrade_root/systemctl-state"
printf '#!/usr/bin/env bash\nprintf "easytier-core 9.9.9-test\\n"\n' > "$upgrade_root/root/easytier/easytier-core"
printf '#!/usr/bin/env bash\nprintf "easytier-cli 9.9.9-test\\n"\n' > "$upgrade_root/root/easytier/easytier-cli"
chmod 0755 "$upgrade_root/root/easytier/easytier-core" "$upgrade_root/root/easytier/easytier-cli"
printf '%s\n' '# Managed by Behify EasyMesh' > "$upgrade_root/etc/systemd/system/easymesh.service"
touch "$upgrade_root/systemctl-state/active" "$upgrade_root/systemctl-state/enabled"
run_installer "$upgrade_root" env
"$upgrade_root/root/easytier/easytier-core" --version | grep -Fq '2.6.4'
[[ -f "$upgrade_root/systemctl-state/active" && -f "$upgrade_root/systemctl-state/enabled" ]]
grep -Fq 'stop easymesh.service' "$upgrade_root/systemctl-state/calls.log"
grep -Fq 'start easymesh.service' "$upgrade_root/systemctl-state/calls.log"
if grep -Eq '^(enable|disable) easymesh\.service$' "$upgrade_root/systemctl-state/calls.log"; then
    printf 'Installer changed service enablement.\n' >&2
    exit 1
fi
find "$upgrade_root/opt/behify-easymesh-backups" -type f -name easytier-core -print -quit | grep -q .

make_rollback_root() {
    local root="$1"
    mkdir -p "$root/root/easytier" "$root/etc/systemd/system" "$root/systemctl-state" "$root/opt/behify-easymesh"
    printf '#!/usr/bin/env bash\nprintf "easytier-core 8.8.8-old\\n"\n' > "$root/root/easytier/easytier-core"
    printf '#!/usr/bin/env bash\nprintf "easytier-cli 8.8.8-old\\n"\n' > "$root/root/easytier/easytier-cli"
    chmod 0755 "$root/root/easytier/easytier-core" "$root/root/easytier/easytier-cli"
    printf '%s\n' '# Managed by Behify EasyMesh' > "$root/etc/systemd/system/easymesh.service"
    printf 'preserve application\n' > "$root/opt/behify-easymesh/sentinel"
    touch "$root/systemctl-state/active" "$root/systemctl-state/enabled"
}

partial_root="$test_root/partial"
make_rollback_root "$partial_root"
old_core_hash=$(sha256sum "$partial_root/root/easytier/easytier-core" | awk '{print $1}')
chmod 0711 "$partial_root/root/easytier/easytier-core"
old_core_mode=$(stat -c '%a' "$partial_root/root/easytier/easytier-core")
if run_installer "$partial_root" env BEHIFY_TEST_FAIL_AFTER_CORE=1 >"$test_root/partial.log" 2>&1; then
    printf 'Forced partial activation unexpectedly succeeded.\n' >&2
    exit 1
fi
[[ "$(sha256sum "$partial_root/root/easytier/easytier-core" | awk '{print $1}')" == "$old_core_hash" ]]
[[ "$(stat -c '%a' "$partial_root/root/easytier/easytier-core")" == "$old_core_mode" ]]
[[ -f "$partial_root/opt/behify-easymesh/sentinel" ]]
[[ -f "$partial_root/systemctl-state/active" && -f "$partial_root/systemctl-state/enabled" ]]
grep -Fq 'Rollback completed' "$test_root/partial.log"

symlink_root="$test_root/symlink-rollback"
make_rollback_root "$symlink_root"
mv "$symlink_root/root/easytier/easytier-core" "$symlink_root/root/easytier/legacy-core"
mv "$symlink_root/root/easytier/easytier-cli" "$symlink_root/root/easytier/legacy-cli"
if ln -s legacy-core "$symlink_root/root/easytier/easytier-core" 2>/dev/null &&
   ln -s legacy-cli "$symlink_root/root/easytier/easytier-cli" 2>/dev/null &&
   [[ -L "$symlink_root/root/easytier/easytier-core" ]]; then
    if run_installer "$symlink_root" env BEHIFY_TEST_FAIL_AFTER_CORE=1 >"$test_root/symlink.log" 2>&1; then
        printf 'Symlink rollback failure injection unexpectedly succeeded.\n' >&2
        exit 1
    fi
    [[ -L "$symlink_root/root/easytier/easytier-core" && -L "$symlink_root/root/easytier/easytier-cli" ]]
    [[ "$(readlink "$symlink_root/root/easytier/easytier-core")" == 'legacy-core' ]]
    [[ "$(readlink "$symlink_root/root/easytier/easytier-cli")" == 'legacy-cli' ]]
else
    printf 'Symlink rollback check skipped: native symlinks are unavailable.\n'
fi

service_failure_root="$test_root/service-failure"
make_rollback_root "$service_failure_root"
old_core_hash=$(sha256sum "$service_failure_root/root/easytier/easytier-core" | awk '{print $1}')
touch "$service_failure_root/systemctl-state/fail-new-runtime"
if run_installer "$service_failure_root" env >"$test_root/service-failure.log" 2>&1; then
    printf 'Forced service validation failure unexpectedly succeeded.\n' >&2
    exit 1
fi
[[ "$(sha256sum "$service_failure_root/root/easytier/easytier-core" | awk '{print $1}')" == "$old_core_hash" ]]
[[ -f "$service_failure_root/systemctl-state/active" && -f "$service_failure_root/systemctl-state/enabled" ]]
[[ -f "$service_failure_root/opt/behify-easymesh/sentinel" ]]

inactive_root="$test_root/inactive"
mkdir -p "$inactive_root/etc/systemd/system" "$inactive_root/systemctl-state"
printf '%s\n' '# Managed by Behify EasyMesh' > "$inactive_root/etc/systemd/system/easymesh.service"
run_installer "$inactive_root" env
[[ ! -f "$inactive_root/systemctl-state/active" && ! -f "$inactive_root/systemctl-state/enabled" ]]
if grep -Eq '^(start|stop|enable|disable) easymesh\.service$' "$inactive_root/systemctl-state/calls.log"; then
    printf 'Installer changed an inactive/disabled service state.\n' >&2
    exit 1
fi

command_root="$test_root/command-owner"
mkdir -p "$command_root/usr/local/bin" "$command_root/systemctl-state"
printf 'unrelated command\n' > "$command_root/usr/local/bin/easymesh"
run_installer "$command_root" env
grep -Fqx '# Behify EasyMesh test command link' "$command_root/usr/local/bin/easymesh"
find "$command_root/opt/behify-easymesh-backups" -type f -name command-easymesh -exec grep -Fq 'unrelated command' {} \;

printf 'Installer regression checks passed.\n'
