#!/usr/bin/env bash

set -euo pipefail

TEST_ROOT="${BEHIFY_TEST_ROOT:-}"
TEST_MODE="${BEHIFY_TEST_MODE:-0}"
PURGE=0
ASSUME_YES=0
TEST_CONFIRM=0

root_path() {
    printf '%s%s\n' "$TEST_ROOT" "$1"
}

INSTALL_DIR="$(root_path /opt/behify-easymesh)"
COMMAND_PATH="$(root_path /usr/local/bin/easymesh)"
CORE_DIR="$(root_path /root/easytier)"
MESH_CONFIG_DIR="$(root_path /etc/behify-easymesh)"
SERVICE_FILE="$(root_path /etc/systemd/system/easymesh.service)"
WATCHDOG_FILE="$(root_path /etc/systemd/system/easymesh-watchdog.service)"
MONITOR_SCRIPT="$(root_path /etc/monitor.sh)"
MONITOR_LOG="$(root_path /etc/monitor.log)"
OWNER_FILE="$INSTALL_DIR/.install-owner"
MANIFEST_FILE="$INSTALL_DIR/manifest.txt"
MESH_SERVICE_OWNED=0

die() {
    printf 'Error: %s\n' "$*" >&2
    exit 1
}

case "${1:-}" in
    "") ;;
    --purge) PURGE=1 ;;
    *) die "Usage: sudo /opt/behify-easymesh/uninstall.sh [--purge]" ;;
esac
if [[ "${2:-}" == "--yes" && "$TEST_MODE" == "1" && -n "$TEST_ROOT" ]]; then
    ASSUME_YES=1
elif [[ $# -gt 1 ]]; then
    die "Usage: sudo /opt/behify-easymesh/uninstall.sh [--purge]"
fi

if [[ -n "$TEST_ROOT" ]]; then
    [[ "$TEST_MODE" == "1" ]] || die "BEHIFY_TEST_ROOT is accepted only with BEHIFY_TEST_MODE=1."
    [[ "$TEST_ROOT" == /tmp/* || "$TEST_ROOT" == /var/tmp/* ]] || die "BEHIFY_TEST_ROOT must be below /tmp or /var/tmp."
    [[ "$TEST_ROOT" != *'/../'* && "$TEST_ROOT" != */.. ]] || die "BEHIFY_TEST_ROOT must not contain parent traversal."
fi
if [[ -z "$TEST_ROOT" && $EUID -ne 0 ]]; then
    die "Run the uninstaller as root."
fi
if [[ "$TEST_MODE" == "1" && -z "$TEST_ROOT" ]]; then
    die "BEHIFY_TEST_MODE requires BEHIFY_TEST_ROOT."
fi
if [[ "$TEST_MODE" == "1" && -n "$TEST_ROOT" && "${BEHIFY_TEST_CONFIRM:-0}" == "1" ]]; then
    TEST_CONFIRM=1
fi
for command_name in grep awk sha256sum mktemp sed rm rmdir systemctl readlink; do
    command -v "$command_name" >/dev/null 2>&1 || die "Required command '$command_name' is missing; no files were removed."
done
[[ -f "$OWNER_FILE" ]] || die "Installation ownership marker is missing; refusing to remove files."
[[ ! -L "$INSTALL_DIR" ]] || die "Installation directory is a symlink; refusing to remove files."
grep -Eq '^behify-easymesh:[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z][0-9A-Za-z.-]*)?$' "$OWNER_FILE" || die "Installation ownership marker is invalid."

manifest_value() {
    local key="$1"

    [[ -f "$MANIFEST_FILE" ]] || return 1
    awk -F= -v key="$key" '$1 == key { count++; value=substr($0, index($0, "=") + 1) } END { if (count != 1) exit 1; print value }' "$MANIFEST_FILE"
}

service_is_owned() {
    [[ -f "$SERVICE_FILE" && ! -L "$SERVICE_FILE" ]] &&
        { grep -Fqx '# Managed by Behify EasyMesh' "$SERVICE_FILE" ||
          grep -Fq 'ExecStart=/root/easytier/easytier-core ' "$SERVICE_FILE"; }
}

watchdog_is_owned() {
    [[ -f "$WATCHDOG_FILE" && ! -L "$WATCHDOG_FILE" ]] && grep -Fq 'ExecStart=/bin/bash /etc/monitor.sh' "$WATCHDOG_FILE"
}

remove_managed_cron() {
    local temp_crontab

    command -v crontab >/dev/null 2>&1 || return 0
    temp_crontab=$(mktemp) || return 1
    if crontab -l > "$temp_crontab" 2>/dev/null; then
        sed -i "/#easymesh\.service$/d; /# behify-easymesh-service-restart$/d" "$temp_crontab"
        crontab "$temp_crontab"
    fi
    rm -f "$temp_crontab"
}

remove_runtime_if_owned() {
    local core_hash cli_hash installed_core_hash installed_cli_hash

    if [[ -L "$CORE_DIR" ]]; then
        printf 'Preserved EasyTier runtime: runtime directory is a symlink.\n'
        return 0
    fi
    core_hash=$(manifest_value easytier_core_sha256 2>/dev/null || true)
    cli_hash=$(manifest_value easytier_cli_sha256 2>/dev/null || true)
    [[ "$core_hash" =~ ^[0-9a-f]{64}$ && "$cli_hash" =~ ^[0-9a-f]{64}$ ]] || {
        printf 'Preserved EasyTier runtime: package hashes were unavailable.\n'
        return 0
    }
    [[ ! -f "$CORE_DIR/easytier-core" ]] || installed_core_hash=$(sha256sum "$CORE_DIR/easytier-core" | awk '{print $1}')
    [[ ! -f "$CORE_DIR/easytier-cli" ]] || installed_cli_hash=$(sha256sum "$CORE_DIR/easytier-cli" | awk '{print $1}')
    if [[ ! -L "$CORE_DIR/easytier-core" && ! -L "$CORE_DIR/easytier-cli" &&
          "${installed_core_hash:-}" == "$core_hash" && "${installed_cli_hash:-}" == "$cli_hash" ]]; then
        rm -f -- "$CORE_DIR/easytier-core" "$CORE_DIR/easytier-cli"
        rmdir "$CORE_DIR" 2>/dev/null || true
        printf 'Removed the Behify-installed EasyTier runtime pair.\n'
    else
        printf 'Preserved EasyTier runtime: installed files are not both Behify-owned.\n'
    fi
}

remove_managed_application_files() {
    local path top_level
    local -a paths=(
        easymesh install.sh uninstall.sh versions.env manifest.txt files.sha256
        README.md README_FA.md CHANGELOG.md SECURITY.md THIRD_PARTY_NOTICES.md
        LICENSE NOTICE
        docs/release-checklist-v1.0.0-rc.1.md docs/release-notes-v1.0.0-rc.1.md
        docs/historical/smoke-test-v0.1.0.md docs/historical/smoke-test-v0.1.3-v2.6.4.md
        licenses/Easy-Mesh-ATTRIBUTION.md licenses/EasyTier-LGPL-3.0.txt licenses/Xray-core-MPL-2.0.txt
    )

    for path in "${paths[@]}"; do
        top_level=${path%%/*}
        if [[ "$path" == */* && -L "$INSTALL_DIR/$top_level" ]]; then
            printf 'Preserved symlinked application subtree: %s\n' "$INSTALL_DIR/$top_level"
            continue
        fi
        rm -f -- "$INSTALL_DIR/$path"
    done
    rm -f -- "$OWNER_FILE"
    rmdir "$INSTALL_DIR/docs/historical" "$INSTALL_DIR/docs" "$INSTALL_DIR/licenses" 2>/dev/null || true
    rmdir "$INSTALL_DIR" 2>/dev/null || true
}

if [[ "$PURGE" == "0" && "$TEST_CONFIRM" != "1" ]]; then
    read -r -p 'Uninstall Behify EasyMesh and preserve configuration? [y/N] ' confirmation || confirmation=""
    [[ "$confirmation" =~ ^[Yy]$ ]] || die "Uninstall cancelled."
elif [[ "$PURGE" == "1" && "$ASSUME_YES" != "1" ]]; then
    printf '%s\n' \
        'Purge removes Behify-owned mesh service files, mesh configuration, watchdog files, and rollback backups.' \
        'The isolated relay component and its service/configuration are preserved and must be removed from its own menu.'
    read -r -p 'Type PURGE to continue: ' confirmation || confirmation=""
    [[ "$confirmation" == "PURGE" ]] || die "Purge cancelled."
fi

service_is_owned && MESH_SERVICE_OWNED=1
if [[ "$MESH_SERVICE_OWNED" == "1" ]]; then
    systemctl stop easymesh.service >/dev/null 2>&1 || true
    systemctl disable easymesh.service >/dev/null 2>&1 || true
    printf 'Stopped and disabled Behify-owned easymesh.service.\n'
else
    printf 'Preserved easymesh.service: missing or not verified as Behify-owned.\n'
fi
if watchdog_is_owned; then
    systemctl stop easymesh-watchdog.service >/dev/null 2>&1 || true
    systemctl disable easymesh-watchdog.service >/dev/null 2>&1 || true
    printf 'Stopped and disabled Behify-owned easymesh-watchdog.service.\n'
fi
remove_managed_cron
if [[ ! -f "$SERVICE_FILE" || "$MESH_SERVICE_OWNED" == "1" ]]; then
    remove_runtime_if_owned
else
    printf 'Preserved EasyTier runtime because easymesh.service is not verified as Behify-owned.\n'
fi

if [[ -L "$COMMAND_PATH" && "$(readlink "$COMMAND_PATH")" == "/opt/behify-easymesh/easymesh" ]] ||
   { [[ "$TEST_MODE" == "1" && -f "$COMMAND_PATH" ]] && grep -Fqx '# Behify EasyMesh test command link' "$COMMAND_PATH"; }; then
    rm -f -- "$COMMAND_PATH"
    printf 'Removed /usr/local/bin/easymesh.\n'
else
    printf 'Preserved /usr/local/bin/easymesh: missing or not Behify-owned.\n'
fi

if [[ "$PURGE" == "1" ]]; then
    if [[ "$MESH_SERVICE_OWNED" == "1" ]]; then
        rm -f -- "$SERVICE_FILE"
        printf 'Removed Behify-owned easymesh.service.\n'
    fi
    if watchdog_is_owned; then
        rm -f -- "$WATCHDOG_FILE" "$MONITOR_SCRIPT" "$MONITOR_LOG"
        printf 'Removed Behify-owned watchdog files.\n'
    fi
    if [[ -L "$MESH_CONFIG_DIR" || -L "$MESH_CONFIG_DIR/mesh.env" || -L "$MESH_CONFIG_DIR/backups" ]]; then
        printf 'Preserved mesh configuration because a managed configuration path is a symlink.\n'
    elif [[ ! -f "$SERVICE_FILE" || "$MESH_SERVICE_OWNED" == "1" ]]; then
        rm -f -- "$MESH_CONFIG_DIR/mesh.env"
        if [[ -d "$MESH_CONFIG_DIR/backups" ]]; then
            rm -rf -- "$MESH_CONFIG_DIR/backups"
        fi
        printf 'Removed Behify-owned mesh configuration and backups.\n'
    else
        printf 'Preserved mesh configuration because easymesh.service is not verified as Behify-owned.\n'
    fi
    rmdir "$MESH_CONFIG_DIR" 2>/dev/null || true
    systemctl daemon-reload >/dev/null 2>&1 || true
else
    printf 'Preserved mesh configuration and service files. Use --purge for explicit removal.\n'
fi

remove_managed_application_files
printf '%s\n' \
    'Behify EasyMesh application files were removed.' \
    'The isolated relay directory, relay configuration, behify-relay.service, and unrelated Xray installations were preserved.'
