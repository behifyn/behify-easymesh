#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_ROOT="${BEHIFY_TEST_ROOT:-}"
TEST_MODE="${BEHIFY_TEST_MODE:-0}"

root_path() {
    printf '%s%s\n' "$TEST_ROOT" "$1"
}

INSTALL_DIR="$(root_path /opt/behify-easymesh)"
BACKUP_PARENT="$(root_path /opt/behify-easymesh-backups)"
COMMAND_PATH="$(root_path /usr/local/bin/easymesh)"
CORE_DIR="$(root_path /root/easytier)"
SERVICE_FILE="$(root_path /etc/systemd/system/easymesh.service)"
MANIFEST_FILE="$SCRIPT_DIR/manifest.txt"
FILES_MANIFEST="$SCRIPT_DIR/files.sha256"
VERSION_FILE="$SCRIPT_DIR/versions.env"
CANDIDATE_CORE="$SCRIPT_DIR/core/easytier-core"
CANDIDATE_CLI="$SCRIPT_DIR/core/easytier-cli"
WORK_DIR=""
BACKUP_DIR=""
APP_BACKED_UP=0
APP_INSTALLED=0
CORE_CHANGED=0
CORE_DIR_EXISTED=0
CORE_NEW_PATH=""
CLI_NEW_PATH=""
COMMAND_BACKED_UP=0
COMMAND_INSTALLED=0
SERVICE_WAS_ACTIVE=0
SERVICE_WAS_ENABLED=0
TRANSACTION_STARTED=0

die() {
    printf 'Error: %s\n' "$*" >&2
    exit 1
}

require_command() {
    command -v "$1" >/dev/null 2>&1 || die "Required command '$1' is missing. Install it with your operating system package manager and retry."
}

cleanup() {
    [[ -z "$WORK_DIR" || ! -d "$WORK_DIR" ]] || rm -rf -- "$WORK_DIR"
}

safe_remove_install_dir() {
    local expected="${TEST_ROOT}/opt/behify-easymesh"

    [[ -n "$expected" && "$INSTALL_DIR" == "$expected" ]] || return 1
    [[ ! -e "$INSTALL_DIR" ]] || rm -rf -- "$INSTALL_DIR"
}

restore_transaction() {
    local rollback_ok=1

    set +e
    trap - ERR
    if [[ "$SERVICE_WAS_ACTIVE" == "1" && -f "$SERVICE_FILE" ]]; then
        systemctl stop easymesh.service >/dev/null 2>&1 || true
    fi
    if [[ "$CORE_CHANGED" == "1" ]]; then
        rm -f -- "$CORE_NEW_PATH" "$CLI_NEW_PATH" "$CORE_DIR/easytier-core" "$CORE_DIR/easytier-cli"
        [[ ! -e "$BACKUP_DIR/core/easytier-core" && ! -L "$BACKUP_DIR/core/easytier-core" ]] || cp -a -- "$BACKUP_DIR/core/easytier-core" "$CORE_DIR/easytier-core" || rollback_ok=0
        [[ ! -e "$BACKUP_DIR/core/easytier-cli" && ! -L "$BACKUP_DIR/core/easytier-cli" ]] || cp -a -- "$BACKUP_DIR/core/easytier-cli" "$CORE_DIR/easytier-cli" || rollback_ok=0
        if [[ "$CORE_DIR_EXISTED" == "0" ]]; then
            rmdir "$CORE_DIR" 2>/dev/null || true
        fi
    fi
    if [[ "$APP_INSTALLED" == "1" ]]; then
        safe_remove_install_dir || rollback_ok=0
    fi
    if [[ "$APP_BACKED_UP" == "1" ]]; then
        mv -- "$BACKUP_DIR/application" "$INSTALL_DIR" || rollback_ok=0
    fi
    if [[ "$COMMAND_INSTALLED" == "1" ]]; then
        rm -f -- "$COMMAND_PATH"
    fi
    if [[ "$COMMAND_BACKED_UP" == "1" ]]; then
        mv -- "$BACKUP_DIR/command-easymesh" "$COMMAND_PATH" || rollback_ok=0
    fi
    if [[ "$SERVICE_WAS_ACTIVE" == "1" && -f "$SERVICE_FILE" ]]; then
        systemctl start easymesh.service >/dev/null 2>&1 || rollback_ok=0
    fi
    if [[ "$SERVICE_WAS_ENABLED" == "1" && -f "$SERVICE_FILE" ]]; then
        systemctl is-enabled --quiet easymesh.service || rollback_ok=0
    fi
    if [[ "$rollback_ok" == "1" ]]; then
        printf 'Rollback completed. The previous installation and service state were restored.\n' >&2
    else
        printf 'Rollback needs manual attention. Backup retained at: %s\n' "$BACKUP_DIR" >&2
    fi
}

on_error() {
    local line="$1"

    if [[ "$TRANSACTION_STARTED" == "1" ]]; then
        printf 'Installation failed at line %s. Starting rollback.\n' "$line" >&2
        restore_transaction
    fi
    exit 1
}

trap cleanup EXIT
trap 'on_error "$LINENO"' ERR

resolve_architecture() {
    local machine

    if [[ "$TEST_MODE" == "1" && -n "$TEST_ROOT" && -n "${BEHIFY_TEST_ARCH:-}" ]]; then
        machine="$BEHIFY_TEST_ARCH"
    else
        machine=$(uname -m)
    fi
    case "$machine" in
        x86_64|amd64) printf 'x86_64\n' ;;
        aarch64|arm64) printf 'aarch64\n' ;;
        *) die "Unsupported architecture '$machine'. Behify EasyMesh v1 supports only Linux x86_64 and aarch64." ;;
    esac
}

manifest_value() {
    local key="$1"

    awk -F= -v key="$key" '
        $1 == key { count++; value=substr($0, index($0, "=") + 1) }
        END { if (count != 1) exit 1; print value }
    ' "$MANIFEST_FILE"
}

verify_elf_architecture() {
    local binary="$1" architecture="$2" magic machine expected

    magic=$(od -An -tx1 -N4 "$binary" | tr -d ' \n')
    [[ "$magic" == "7f454c46" ]] || return 1
    machine=$(od -An -tu2 -j18 -N2 "$binary" | tr -d ' \n')
    case "$architecture" in
        x86_64) expected=62 ;;
        aarch64) expected=183 ;;
        *) return 1 ;;
    esac
    [[ "$machine" == "$expected" ]]
}

reported_version() {
    local binary="$1"

    "$binary" --version 2>/dev/null | head -n 1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -n 1
}

verify_candidate_runtime() {
    local architecture="$1" expected_core_hash="$2" expected_cli_hash="$3"
    local staged_core="$WORK_DIR/easytier-core" staged_cli="$WORK_DIR/easytier-cli"

    [[ -f "$CANDIDATE_CORE" && ! -L "$CANDIDATE_CORE" ]] || die "Package is missing a regular core/easytier-core file."
    [[ -f "$CANDIDATE_CLI" && ! -L "$CANDIDATE_CLI" ]] || die "Package is missing a regular core/easytier-cli file."
    [[ "$(sha256sum "$CANDIDATE_CORE" | awk '{print $1}')" == "$expected_core_hash" ]] || die "easytier-core hash mismatch."
    [[ "$(sha256sum "$CANDIDATE_CLI" | awk '{print $1}')" == "$expected_cli_hash" ]] || die "easytier-cli hash mismatch."
    install -m 0755 "$CANDIDATE_CORE" "$staged_core"
    install -m 0755 "$CANDIDATE_CLI" "$staged_cli"
    if [[ "$TEST_MODE" != "1" || "${BEHIFY_TEST_VALIDATE_ELF:-0}" == "1" ]]; then
        verify_elf_architecture "$staged_core" "$architecture" || die "easytier-core ELF architecture does not match $architecture."
        verify_elf_architecture "$staged_cli" "$architecture" || die "easytier-cli ELF architecture does not match $architecture."
    elif [[ -z "$TEST_ROOT" ]]; then
        die "BEHIFY_TEST_MODE requires BEHIFY_TEST_ROOT."
    fi
    [[ "$(reported_version "$staged_core")" == "2.6.4" ]] || die "easytier-core did not report version 2.6.4."
    [[ "$(reported_version "$staged_cli")" == "2.6.4" ]] || die "easytier-cli did not report version 2.6.4."
}

verify_package() {
    local architecture="$1" manifest_arch manifest_version easytier_version files_hash
    local core_hash cli_hash

    [[ -f "$MANIFEST_FILE" && ! -L "$MANIFEST_FILE" ]] || die "Release manifest is missing. Install from an architecture-specific Behify Release archive."
    [[ -f "$FILES_MANIFEST" && ! -L "$FILES_MANIFEST" ]] || die "Package file manifest is missing."
    manifest_version=$(manifest_value behify_easymesh_version) || die "Release manifest has no unique Behify version."
    easytier_version=$(manifest_value easytier_version) || die "Release manifest has no unique EasyTier version."
    manifest_arch=$(manifest_value architecture) || die "Release manifest has no unique architecture."
    core_hash=$(manifest_value easytier_core_sha256) || die "Release manifest has no unique core hash."
    cli_hash=$(manifest_value easytier_cli_sha256) || die "Release manifest has no unique CLI hash."
    files_hash=$(manifest_value files_manifest_sha256) || die "Release manifest has no unique file-manifest hash."
    [[ "$manifest_version" == "$BEHIFY_EASYMESH_VERSION" ]] || die "Package version '$manifest_version' does not match versions.env."
    [[ "$easytier_version" == "v2.6.4" ]] || die "Unsupported EasyTier package version '$easytier_version'."
    [[ "$manifest_arch" == "$architecture" ]] || die "Package architecture '$manifest_arch' does not match system architecture '$architecture'."
    [[ "$core_hash" =~ ^[0-9a-f]{64}$ && "$cli_hash" =~ ^[0-9a-f]{64}$ && "$files_hash" =~ ^[0-9a-f]{64}$ ]] || die "Release manifest contains an invalid SHA-256 value."
    [[ "$(sha256sum "$FILES_MANIFEST" | awk '{print $1}')" == "$files_hash" ]] || die "Package file-manifest hash mismatch."
    (cd "$SCRIPT_DIR" && sha256sum --quiet -c files.sha256) || die "Package file validation failed."
    verify_candidate_runtime "$architecture" "$core_hash" "$cli_hash"
}

unsafe_legacy_maintenance_detected() {
    if [[ -e "$CORE_DIR/reset.sh" || -L "$CORE_DIR/reset.sh" ]]; then
        return 0
    fi
    command -v crontab >/dev/null 2>&1 &&
        crontab -l 2>/dev/null | grep -Fq '/root/easytier/reset.sh'
}

stage_application() {
    local destination="$WORK_DIR/application" item

    mkdir -p "$destination/relay"
    if [[ -d "$INSTALL_DIR/relay" ]]; then
        cp -a "$INSTALL_DIR/relay/." "$destination/relay/"
    fi
    for item in easymesh install.sh uninstall.sh relay-manager versions.env manifest.txt files.sha256 README.md README_FA.md CHANGELOG.md SECURITY.md THIRD_PARTY_NOTICES.md LICENSE NOTICE; do
        [[ -f "$SCRIPT_DIR/$item" ]] || die "Required package file is missing: $item"
        if [[ "$item" == "relay-manager" ]]; then
            install -m 0755 "$SCRIPT_DIR/$item" "$destination/relay/relay-manager"
        else
            cp -p "$SCRIPT_DIR/$item" "$destination/$item"
        fi
    done
    for item in docs licenses; do
        [[ ! -d "$SCRIPT_DIR/$item" ]] || cp -a "$SCRIPT_DIR/$item" "$destination/"
    done
    chmod 0755 "$destination/easymesh" "$destination/install.sh" "$destination/uninstall.sh"
    printf 'behify-easymesh:%s\n' "$(manifest_value behify_easymesh_version)" > "$destination/.install-owner"
    chmod 0644 "$destination/.install-owner"
}

installed_runtime_matches() {
    local expected_core_hash="$1" expected_cli_hash="$2"

    [[ -f "$CORE_DIR/easytier-core" && ! -L "$CORE_DIR/easytier-core" && -x "$CORE_DIR/easytier-core" ]] || return 1
    [[ -f "$CORE_DIR/easytier-cli" && ! -L "$CORE_DIR/easytier-cli" && -x "$CORE_DIR/easytier-cli" ]] || return 1
    [[ "$(sha256sum "$CORE_DIR/easytier-core" | awk '{print $1}')" == "$expected_core_hash" ]] || return 1
    [[ "$(sha256sum "$CORE_DIR/easytier-cli" | awk '{print $1}')" == "$expected_cli_hash" ]] || return 1
    [[ "$(reported_version "$CORE_DIR/easytier-core")" == "2.6.4" ]] || return 1
    [[ "$(reported_version "$CORE_DIR/easytier-cli")" == "2.6.4" ]]
}

service_is_owned() {
    [[ -f "$SERVICE_FILE" && ! -L "$SERVICE_FILE" ]] &&
        { grep -Fqx '# Managed by Behify EasyMesh' "$SERVICE_FILE" ||
          grep -Fq 'ExecStart=/root/easytier/easytier-core ' "$SERVICE_FILE"; }
}

capture_service_state() {
    [[ -f "$SERVICE_FILE" ]] || return 0
    service_is_owned || die "Refusing to control an unrecognized or symlinked easymesh.service file."
    systemctl is-active --quiet easymesh.service && SERVICE_WAS_ACTIVE=1
    systemctl is-enabled --quiet easymesh.service && SERVICE_WAS_ENABLED=1
    return 0
}

backup_existing_installation() {
    mkdir -p "$BACKUP_DIR/core"
    chmod 0700 "$BACKUP_DIR" "$BACKUP_DIR/core"
    [[ ! -d "$CORE_DIR" ]] || CORE_DIR_EXISTED=1
    if [[ -e "$INSTALL_DIR" ]]; then
        mv -- "$INSTALL_DIR" "$BACKUP_DIR/application"
        APP_BACKED_UP=1
    fi
    [[ ! -e "$CORE_DIR/easytier-core" && ! -L "$CORE_DIR/easytier-core" ]] || cp -a -- "$CORE_DIR/easytier-core" "$BACKUP_DIR/core/easytier-core"
    [[ ! -e "$CORE_DIR/easytier-cli" && ! -L "$CORE_DIR/easytier-cli" ]] || cp -a -- "$CORE_DIR/easytier-cli" "$BACKUP_DIR/core/easytier-cli"
    if [[ -e "$COMMAND_PATH" || -L "$COMMAND_PATH" ]]; then
        if [[ -L "$COMMAND_PATH" && "$(readlink "$COMMAND_PATH")" == "/opt/behify-easymesh/easymesh" ]] ||
           { [[ "$TEST_MODE" == "1" && -f "$COMMAND_PATH" ]] && grep -Fqx '# Behify EasyMesh test command link' "$COMMAND_PATH"; }; then
            : # The managed link is replaced atomically after application activation.
        else
            mv -- "$COMMAND_PATH" "$BACKUP_DIR/command-easymesh"
            COMMAND_BACKED_UP=1
            printf 'Existing command path was not Behify-owned and was backed up to: %s\n' "$BACKUP_DIR/command-easymesh"
        fi
    fi
}

activate_runtime() {
    local expected_core_hash="$1" expected_cli_hash="$2"

    if installed_runtime_matches "$expected_core_hash" "$expected_cli_hash"; then
        printf 'EasyTier v2.6.4 runtime is already verified; binaries were not replaced.\n'
        return 0
    fi
    [[ "$SERVICE_WAS_ACTIVE" != "1" ]] || systemctl stop easymesh.service >/dev/null 2>&1
    if [[ ! -d "$CORE_DIR" ]]; then
        install -d -m 0755 "$CORE_DIR"
    fi
    CORE_NEW_PATH="$CORE_DIR/.easytier-core.new.$$"
    CLI_NEW_PATH="$CORE_DIR/.easytier-cli.new.$$"
    CORE_CHANGED=1
    install -m 0755 "$WORK_DIR/easytier-core" "$CORE_NEW_PATH"
    install -m 0755 "$WORK_DIR/easytier-cli" "$CLI_NEW_PATH"
    mv -f -- "$CORE_NEW_PATH" "$CORE_DIR/easytier-core"
    if [[ "$TEST_MODE" == "1" && -n "$TEST_ROOT" && "${BEHIFY_TEST_FAIL_AFTER_CORE:-0}" == "1" ]]; then
        return 97
    fi
    mv -f -- "$CLI_NEW_PATH" "$CORE_DIR/easytier-cli"
    installed_runtime_matches "$expected_core_hash" "$expected_cli_hash"
}

activate_application() {
    local new_link="${COMMAND_PATH}.new.$$"

    mv -- "$WORK_DIR/application" "$INSTALL_DIR"
    APP_INSTALLED=1
    mkdir -p "$(dirname "$COMMAND_PATH")"
    if [[ "$TEST_MODE" == "1" && "${BEHIFY_TEST_NATIVE_LINK:-0}" != "1" ]]; then
        {
            printf '%s\n' '#!/usr/bin/env bash' '# Behify EasyMesh test command link'
            printf 'exec %q "$@"\n' "$INSTALL_DIR/easymesh"
        } > "$new_link"
        chmod 0755 "$new_link"
    else
        ln -s "/opt/behify-easymesh/easymesh" "$new_link"
    fi
    mv -f -- "$new_link" "$COMMAND_PATH"
    COMMAND_INSTALLED=1
}

validate_service_after_upgrade() {
    local pid running_version enabled_now=0

    [[ -f "$SERVICE_FILE" ]] || return 0
    if [[ "$SERVICE_WAS_ACTIVE" == "1" ]]; then
        systemctl start easymesh.service >/dev/null 2>&1
        systemctl is-active --quiet easymesh.service
        if [[ "$TEST_MODE" != "1" ]]; then
            pid=$(systemctl show -p MainPID --value easymesh.service 2>/dev/null)
            [[ "$pid" =~ ^[1-9][0-9]*$ && -x "/proc/$pid/exe" ]]
            running_version=$(reported_version "/proc/$pid/exe")
            [[ "$running_version" == "2.6.4" ]]
        fi
    else
        ! systemctl is-active --quiet easymesh.service
    fi
    systemctl is-enabled --quiet easymesh.service && enabled_now=1
    [[ "$enabled_now" == "$SERVICE_WAS_ENABLED" ]]
}

if [[ -n "$TEST_ROOT" ]]; then
    [[ "$TEST_MODE" == "1" ]] || die "BEHIFY_TEST_ROOT is accepted only with BEHIFY_TEST_MODE=1."
    [[ "$TEST_ROOT" == /tmp/* || "$TEST_ROOT" == /var/tmp/* ]] || die "BEHIFY_TEST_ROOT must be below /tmp or /var/tmp."
    [[ "$TEST_ROOT" != *'/../'* && "$TEST_ROOT" != */.. ]] || die "BEHIFY_TEST_ROOT must not contain parent traversal."
fi
if [[ -z "$TEST_ROOT" && $EUID -ne 0 ]]; then
    die "Run this package installer as root: sudo EASYMESH_OFFLINE=1 bash install.sh"
fi
if [[ "$TEST_MODE" == "1" && -z "$TEST_ROOT" ]]; then
    die "BEHIFY_TEST_MODE requires BEHIFY_TEST_ROOT."
fi
if [[ "$TEST_MODE" != "1" && "$(uname -s)" != "Linux" ]]; then
    die "Unsupported operating system '$(uname -s)'. Behify EasyMesh v1 supports Linux only."
fi
for command_name in awk grep sha256sum od tr head mktemp install cp mv readlink date chmod mkdir rm ln dirname uname systemctl; do
    require_command "$command_name"
done
[[ -f "$VERSION_FILE" && ! -L "$VERSION_FILE" ]] || die "Package version metadata is missing."
# shellcheck source=versions.env
. "$VERSION_FILE"
[[ "$BEHIFY_EASYMESH_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z][0-9A-Za-z.-]*)?$ ]] || die "Package version metadata is invalid."
[[ "$EASYTIER_VERSION" == "v2.6.4" ]] || die "Package EasyTier version metadata is invalid."
[[ ! -L "$INSTALL_DIR" ]] || die "Refusing to use a symlinked Behify installation directory."
[[ ! -L "$CORE_DIR" && ! -L "$BACKUP_PARENT" ]] || die "Refusing to use a symlinked runtime or backup root."
[[ ! -L "$INSTALL_DIR/relay" ]] || die "Refusing to migrate a symlinked Behify relay directory."
if unsafe_legacy_maintenance_detected; then
    die "Unsafe pre-v1 EasyTier maintenance was detected. Inspect /root/easytier/reset.sh and 'sudo crontab -l' without executing or deleting them, then obtain separate cleanup authorization before upgrading."
fi

ARCHITECTURE=$(resolve_architecture)
WORK_DIR=$(mktemp -d "${TMPDIR:-/tmp}/behify-easymesh-install.XXXXXX")
chmod 0700 "$WORK_DIR"
verify_package "$ARCHITECTURE"
stage_application
capture_service_state

if [[ "$TEST_MODE" != "1" && -d "/opt/behify-easymesh/relay" ]]; then
    "$WORK_DIR/application/relay/relay-manager" --migrate-runtime || die "Existing isolated relay runtime migration failed; main installation was not changed."
fi

BACKUP_DIR="$BACKUP_PARENT/install-$(date +%Y%m%d-%H%M%S)-$$"
mkdir -p "$BACKUP_PARENT"
TRANSACTION_STARTED=1
backup_existing_installation
EXPECTED_CORE_HASH=$(manifest_value easytier_core_sha256)
EXPECTED_CLI_HASH=$(manifest_value easytier_cli_sha256)
activate_runtime "$EXPECTED_CORE_HASH" "$EXPECTED_CLI_HASH"
activate_application
validate_service_after_upgrade
TRANSACTION_STARTED=0

printf '%s\n' \
    'Behify EasyMesh installed successfully.' \
    'Installed path: /opt/behify-easymesh' \
    'Command path: /usr/local/bin/easymesh -> /opt/behify-easymesh/easymesh' \
    "Runtime: EasyTier v2.6.4 ($ARCHITECTURE)" \
    "Backup: ${BACKUP_DIR#$TEST_ROOT}" \
    '' \
    'Run: sudo easymesh'
