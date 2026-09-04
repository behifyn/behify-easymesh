#!/usr/bin/env bash

set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
export BEHIFY_RELAY_SOURCE_ONLY=1
export EASYMESH_OFFLINE=1
# shellcheck source=../relay-manager
source "$repo_root/relay-manager"

test_root=""
make_relay_temp_dir test_root

RELAY_ROOT="$test_root/opt/behify-easymesh/relay"
RELAY_BIN_DIR="$RELAY_ROOT/bin"
RELAY_BINARY="$RELAY_BIN_DIR/behify-relayd"
RELAY_RELEASES_DIR="$RELAY_ROOT/releases"
RELAY_BACKUPS_DIR="$RELAY_ROOT/backups"
RELAY_LEGACY_XRAY_ROOT="$RELAY_ROOT/xray"
RELAY_LEGACY_XRAY_CURRENT="$RELAY_LEGACY_XRAY_ROOT/current"
RELAY_LEGACY_XRAY_BINARY="$RELAY_LEGACY_XRAY_CURRENT/xray"
RELAY_CONFIG_DIR="$test_root/etc/behify-easymesh/relay"
RELAY_DEFINITIONS="$RELAY_CONFIG_DIR/relays.json"
RELAY_CONFIG="$RELAY_CONFIG_DIR/config.json"
RELAY_SERVICE_FILE="$test_root/etc/systemd/system/behify-relay.service"
RELAY_SERVICE_DROPIN_DIR="$test_root/etc/systemd/system/behify-relay.service.d"
RELAY_KNOWN_NEUTRAL_DROPIN="$RELAY_SERVICE_DROPIN_DIR/10-neutral-binary.conf"
execution_log="$test_root/executed-runtime-paths.log"
export execution_log

install -d "$RELAY_LEGACY_XRAY_CURRENT" "$RELAY_CONFIG_DIR" \
    "$(dirname "$RELAY_SERVICE_FILE")" "$RELAY_SERVICE_DROPIN_DIR"
cat > "$RELAY_LEGACY_XRAY_BINARY" <<'FAKE_XRAY'
#!/usr/bin/env bash
printf '%s\n' "$0" >> "$execution_log"
[[ "$(basename "$0")" == "behify-relayd" ]] || exit 90
case "${1:-}" in
    version)
        printf 'Xray 26.3.27 (Xray, Penetrates Everything.) d2758a0 (go1.26.1 linux/amd64)\n'
        sleep 0.05
        printf 'A unified platform for anti-censorship.\n'
        ;;
    run)
        if [[ "${2:-}" == "-test" ]]; then
            [[ "${3:-}" == "-config" && -f "${4:-}" ]]
        else
            [[ "${2:-}" == "-config" && -f "${3:-}" ]]
        fi
        ;;
    *) exit 1 ;;
esac
FAKE_XRAY
chmod 0755 "$RELAY_LEGACY_XRAY_BINARY"
printf '{}\n' > "$RELAY_CONFIG"
printf '%s\n' \
    '[Unit]' \
    'Description=Behify EasyMesh Dokodemo-Door Relay' \
    '' \
    '[Service]' \
    "ExecStart=$RELAY_LEGACY_XRAY_BINARY run -config $RELAY_CONFIG" \
    'Restart=on-failure' > "$RELAY_SERVICE_FILE"
printf '%s\n' \
    '[Service]' \
    'ExecStart=' \
    "ExecStart=$RELAY_BINARY run -config $RELAY_CONFIG" > "$RELAY_KNOWN_NEUTRAL_DROPIN"
printf '%s\n' '[Service]' 'Environment=ADMIN_SETTING=preserve' > \
    "$RELAY_SERVICE_DROPIN_DIR/99-admin.conf"

network_used=0
restart_count=0
systemctl() {
    case "${1:-}" in
        is-active|is-enabled) return 0 ;;
        restart) restart_count=$((restart_count + 1)); return 0 ;;
        daemon-reload|stop) return 0 ;;
        enable|disable)
            printf 'Migration changed service enablement.\n' >&2
            return 1
            ;;
        *) return 0 ;;
    esac
}
curl() {
    network_used=1
    return 1
}
verify_relay_process_name() { return 0; }
verify_relay_sockets() { return 0; }

migrate_legacy_relay_runtime

[[ "$network_used" == "0" ]]
[[ "$restart_count" == "1" ]]
[[ -x "$RELAY_BINARY" ]]
[[ "$(basename "$RELAY_BINARY")" == "behify-relayd" ]]
[[ "$(basename "$RELAY_BINARY")" != *xray* ]]
get_relay_runtime_version "$RELAY_BINARY" | grep -Fxq '26.3.27'
parse_relay_runtime_version_output "$(
    printf '%s\n' \
        'Xray 26.3.27 (Xray, Penetrates Everything.) d2758a0 (go1.26.1 linux/amd64)' \
        'A unified platform for anti-censorship.'
)" | grep -Fxq '26.3.27'
if parse_relay_runtime_version_output 'unrelated-tool 26.3.27'; then
    printf 'Unrelated version output was accepted as Xray.\n' >&2
    exit 1
fi
"$RELAY_BINARY" run -config "$RELAY_CONFIG"
while IFS= read -r executed_path; do
    [[ "$(basename "$executed_path")" == "behify-relayd" ]]
done < "$execution_log"
grep -Fqx "ExecStart=$RELAY_BINARY run -config $RELAY_CONFIG" "$RELAY_SERVICE_FILE"
if grep -Eq 'ExecStart=.*/xray([[:space:]]|$)' "$RELAY_SERVICE_FILE"; then
    printf 'Generated service still executes a path ending in /xray.\n' >&2
    exit 1
fi
[[ ! -e "$RELAY_KNOWN_NEUTRAL_DROPIN" ]]
[[ -f "$RELAY_SERVICE_DROPIN_DIR/99-admin.conf" ]]
find "$RELAY_RELEASES_DIR" -type f -name behify-relayd -print -quit | grep -q .
grep -Fq 'XRAY_CANDIDATE_BINARY="$temp_dir/unpacked/behify-relayd"' "$repo_root/relay-manager"
grep -Fq '"$WORK_DIR/application/relay/relay-manager" --migrate-runtime' "$repo_root/install.sh"
if find "$RELAY_RELEASES_DIR" -type f -name xray -print -quit | grep -q .; then
    printf 'Update or migration staging retained an xray runtime basename.\n' >&2
    exit 1
fi
if grep -Eq '/usr/local/(bin|etc)/xray|xray\.service|x-ui\.service|/usr/local/x-ui|Hiddify' \
    "$repo_root/relay-manager" "$repo_root/install.sh"; then
    printf 'Relay management references a forbidden system or panel Xray path.\n' >&2
    exit 1
fi

reuse_root="$test_root/reuse"
RELAY_ROOT="$reuse_root/opt/behify-easymesh/relay"
RELAY_BIN_DIR="$RELAY_ROOT/bin"
RELAY_BINARY="$RELAY_BIN_DIR/behify-relayd"
RELAY_RELEASES_DIR="$RELAY_ROOT/releases"
RELAY_BACKUPS_DIR="$RELAY_ROOT/backups"
RELAY_LEGACY_XRAY_ROOT="$RELAY_ROOT/xray"
RELAY_LEGACY_XRAY_CURRENT="$RELAY_LEGACY_XRAY_ROOT/current"
RELAY_LEGACY_XRAY_BINARY="$RELAY_LEGACY_XRAY_CURRENT/xray"
RELAY_CONFIG_DIR="$reuse_root/etc/behify-easymesh/relay"
RELAY_DEFINITIONS="$RELAY_CONFIG_DIR/relays.json"
RELAY_CONFIG="$RELAY_CONFIG_DIR/config.json"
RELAY_SERVICE_FILE="$reuse_root/etc/systemd/system/behify-relay.service"
RELAY_SERVICE_DROPIN_DIR="$reuse_root/etc/systemd/system/behify-relay.service.d"
RELAY_KNOWN_NEUTRAL_DROPIN="$RELAY_SERVICE_DROPIN_DIR/10-neutral-binary.conf"
execution_log="$reuse_root/executed-runtime-paths.log"
export execution_log
install -d "$RELAY_BIN_DIR" "$RELAY_CONFIG_DIR" \
    "$(dirname "$RELAY_SERVICE_FILE")" "$RELAY_SERVICE_DROPIN_DIR"
cat > "$RELAY_BINARY" <<'FAKE_NEUTRAL_REUSE'
#!/usr/bin/env bash
printf '%s\n' "$0" >> "$execution_log"
[[ "$(basename "$0")" == "behify-relayd" ]] || exit 90
case "${1:-}" in
    version)
        printf 'Xray 26.3.27 (Xray, Penetrates Everything.) d2758a0 (go1.26.1 linux/amd64)\n'
        sleep 0.05
        printf 'A unified platform for anti-censorship.\n'
        ;;
    run)
        [[ "${2:-}" == "-test" && "${3:-}" == "-config" && -f "${4:-}" ]]
        ;;
    *) exit 1 ;;
esac
FAKE_NEUTRAL_REUSE
chmod 0755 "$RELAY_BINARY"
printf '{}\n' > "$RELAY_CONFIG"
printf '%s\n' '[Service]' \
    "ExecStart=$RELAY_LEGACY_XRAY_BINARY run -config $RELAY_CONFIG" > "$RELAY_SERVICE_FILE"
printf '%s\n' '[Service]' 'ExecStart=' \
    "ExecStart=$RELAY_BINARY run -config $RELAY_CONFIG" > "$RELAY_KNOWN_NEUTRAL_DROPIN"
printf '%s\n' '[Service]' 'Environment=ADMIN_SETTING=preserve' > \
    "$RELAY_SERVICE_DROPIN_DIR/99-admin.conf"
reuse_digest=$(sha256sum "$RELAY_BINARY")
reuse_digest=${reuse_digest%% *}
restart_count=0

migrate_legacy_relay_runtime

reused_digest_after=$(sha256sum "$RELAY_BINARY")
reused_digest_after=${reused_digest_after%% *}
[[ "$reuse_digest" == "$reused_digest_after" ]]
[[ "$restart_count" == "1" ]]
grep -Fqx "ExecStart=$RELAY_BINARY run -config $RELAY_CONFIG" "$RELAY_SERVICE_FILE"
[[ ! -e "$RELAY_KNOWN_NEUTRAL_DROPIN" ]]
[[ -f "$RELAY_SERVICE_DROPIN_DIR/99-admin.conf" ]]
while IFS= read -r executed_path; do
    [[ "$(basename "$executed_path")" == "behify-relayd" ]]
done < "$execution_log"

validation_root="$test_root/validation"
validation_candidate="$validation_root/behify-relayd"
validation_config="$validation_root/config.json"
validation_state="$validation_root/production-state"
validation_state_backup="$validation_root/production-state.before"
validation_diagnostics="$validation_root/diagnostics.log"
install -d "$validation_root"
cat > "$validation_candidate" <<'FAKE_VALIDATION_RUNTIME'
#!/usr/bin/env bash
case "${1:-}" in
    version)
        case "${FAKE_RUNTIME_MODE:-valid}" in
            execution-fail) exit 42 ;;
            parse-fail) printf 'unrelated-tool 26.3.27\n' ;;
            *)
                printf 'Xray 26.3.27 (Xray, Penetrates Everything.) d2758a0 (go1.26.1 linux/amd64)\n'
                sleep 0.05
                printf 'A unified platform for anti-censorship.\n'
                ;;
        esac
        ;;
    run)
        [[ "${2:-}" == "-test" && "${3:-}" == "-config" && -f "${4:-}" ]] || exit 43
        [[ "${FAKE_RUNTIME_MODE:-valid}" != "config-fail" ]]
        ;;
    *) exit 1 ;;
esac
FAKE_VALIDATION_RUNTIME
chmod 0755 "$validation_candidate"
printf '{}\n' > "$validation_config"
printf 'preserve this production state\n' > "$validation_state"
cp "$validation_state" "$validation_state_backup"

expect_validation_failure() {
    local expected_diagnostic="$1"
    shift

    : > "$validation_diagnostics"
    if "$@" 2>"$validation_diagnostics"; then
        printf 'Validation unexpectedly succeeded; expected: %s\n' "$expected_diagnostic" >&2
        exit 1
    fi
    grep -Fq "$expected_diagnostic" "$validation_diagnostics"
    cmp -s "$validation_state" "$validation_state_backup"
}

cp "$validation_candidate" "$validation_root/.behify-relayd.tmp.123"
chmod 0755 "$validation_root/.behify-relayd.tmp.123"
expect_validation_failure 'Invalid runtime basename' \
    validate_relay_runtime_candidate "$validation_root/.behify-relayd.tmp.123" temporary ""

runtime_executable_predicate=$(declare -f relay_runtime_is_executable)
relay_runtime_is_executable() {
    return 1
}
expect_validation_failure 'Executable permission validation failed' \
    validate_relay_runtime_candidate "$validation_candidate" temporary ""
eval "$runtime_executable_predicate"

original_tmpdir=${TMPDIR-}
install -d "$validation_root/allowed-temp"
TMPDIR="$validation_root/allowed-temp"
export TMPDIR
expect_validation_failure 'Unsafe staging path' \
    validate_relay_runtime_candidate "$validation_candidate" temporary ""
if [[ -n "$original_tmpdir" ]]; then
    TMPDIR="$original_tmpdir"
    export TMPDIR
else
    unset TMPDIR
fi

install -d "$validation_root/symlink-temp"
ln -s "$validation_candidate" "$validation_root/symlink-temp/behify-relayd"
runtime_symlink_predicate=$(declare -f relay_runtime_is_symlink)
relay_runtime_is_symlink() {
    return 0
}
expect_validation_failure 'temporary relay candidates must not be symlinks' \
    validate_relay_runtime_candidate "$validation_root/symlink-temp/behify-relayd" temporary ""
eval "$runtime_symlink_predicate"

stat() {
    printf '%s\n' "$((EUID + 1))"
}
expect_validation_failure 'Runtime ownership validation failed' \
    validate_relay_runtime_candidate "$validation_candidate" temporary ""
unset -f stat

FAKE_RUNTIME_MODE=execution-fail
export FAKE_RUNTIME_MODE
expect_validation_failure 'Version execution failed' \
    validate_relay_runtime_candidate "$validation_candidate" temporary ""

FAKE_RUNTIME_MODE=parse-fail
expect_validation_failure 'Version parsing failed' \
    validate_relay_runtime_candidate "$validation_candidate" temporary ""

FAKE_RUNTIME_MODE=config-fail
expect_validation_failure 'Configuration validation failed' \
    validate_relay_runtime_candidate "$validation_candidate" temporary "$validation_config"
unset FAKE_RUNTIME_MODE

printf 'different bytes\n' > "$validation_root/different-runtime"
expect_validation_failure 'Source and staged digest mismatch' \
    verify_relay_copy_digest "$validation_candidate" "$validation_root/different-runtime"

copy_failure_root="$test_root/copy-failure"
RELAY_ROOT="$copy_failure_root/opt/behify-easymesh/relay"
RELAY_BIN_DIR="$RELAY_ROOT/bin"
RELAY_BINARY="$RELAY_BIN_DIR/behify-relayd"
RELAY_RELEASES_DIR="$RELAY_ROOT/releases"
RELAY_BACKUPS_DIR="$RELAY_ROOT/backups"
RELAY_LEGACY_XRAY_ROOT="$RELAY_ROOT/xray"
RELAY_LEGACY_XRAY_CURRENT="$RELAY_LEGACY_XRAY_ROOT/current"
RELAY_LEGACY_XRAY_BINARY="$RELAY_LEGACY_XRAY_CURRENT/xray"
RELAY_CONFIG_DIR="$copy_failure_root/etc/behify-easymesh/relay"
RELAY_DEFINITIONS="$RELAY_CONFIG_DIR/relays.json"
RELAY_CONFIG="$RELAY_CONFIG_DIR/config.json"
RELAY_SERVICE_FILE="$copy_failure_root/etc/systemd/system/behify-relay.service"
RELAY_SERVICE_DROPIN_DIR="$copy_failure_root/etc/systemd/system/behify-relay.service.d"
RELAY_KNOWN_NEUTRAL_DROPIN="$RELAY_SERVICE_DROPIN_DIR/10-neutral-binary.conf"
command install -d "$RELAY_LEGACY_XRAY_CURRENT"
command cp "$validation_candidate" "$RELAY_LEGACY_XRAY_BINARY"
command chmod 0755 "$RELAY_LEGACY_XRAY_BINARY"
install() {
    if [[ "${1:-}" == "-m" && "${2:-}" == "0755" && "${3:-}" == "$RELAY_LEGACY_XRAY_BINARY" ]]; then
        return 1
    fi
    command install "$@"
}
expect_validation_failure 'Staged copy failed' migrate_legacy_relay_runtime
unset -f install

rollback_root="$test_root/rollback"
RELAY_ROOT="$rollback_root/opt/behify-easymesh/relay"
RELAY_BIN_DIR="$RELAY_ROOT/bin"
RELAY_BINARY="$RELAY_BIN_DIR/behify-relayd"
RELAY_RELEASES_DIR="$RELAY_ROOT/releases"
RELAY_BACKUPS_DIR="$RELAY_ROOT/backups"
RELAY_LEGACY_XRAY_ROOT="$RELAY_ROOT/xray"
RELAY_LEGACY_XRAY_CURRENT="$RELAY_LEGACY_XRAY_ROOT/current"
RELAY_LEGACY_XRAY_BINARY="$RELAY_LEGACY_XRAY_CURRENT/xray"
RELAY_CONFIG_DIR="$rollback_root/etc/behify-easymesh/relay"
RELAY_DEFINITIONS="$RELAY_CONFIG_DIR/relays.json"
RELAY_CONFIG="$RELAY_CONFIG_DIR/config.json"
RELAY_SERVICE_FILE="$rollback_root/etc/systemd/system/behify-relay.service"
RELAY_SERVICE_DROPIN_DIR="$rollback_root/etc/systemd/system/behify-relay.service.d"
RELAY_KNOWN_NEUTRAL_DROPIN="$RELAY_SERVICE_DROPIN_DIR/10-neutral-binary.conf"
install -d "$RELAY_BIN_DIR" "$RELAY_CONFIG_DIR" \
    "$(dirname "$RELAY_SERVICE_FILE")" "$RELAY_SERVICE_DROPIN_DIR"
cat > "$RELAY_BINARY" <<'FAKE_NEUTRAL'
#!/usr/bin/env bash
case "${1:-}" in
    version)
        printf 'Xray 26.3.27 (Xray, Penetrates Everything.) d2758a0 (go1.26.1 linux/amd64)\n'
        sleep 0.05
        printf 'A unified platform for anti-censorship.\n'
        ;;
    run)
        [[ "${2:-}" == "-test" && "${3:-}" == "-config" && -f "${4:-}" ]]
        ;;
    *) exit 1 ;;
esac
FAKE_NEUTRAL
chmod 0755 "$RELAY_BINARY"
printf '{}\n' > "$RELAY_CONFIG"
printf '%s\n' '[Service]' \
    "ExecStart=$RELAY_LEGACY_XRAY_BINARY run -config $RELAY_CONFIG" > "$RELAY_SERVICE_FILE"
printf '%s\n' '[Service]' 'ExecStart=' \
    "ExecStart=$RELAY_BINARY run -config $RELAY_CONFIG" > "$RELAY_KNOWN_NEUTRAL_DROPIN"
printf '%s\n' '[Service]' 'Environment=ADMIN_SETTING=preserve' > \
    "$RELAY_SERVICE_DROPIN_DIR/99-admin.conf"

restart_count=0
systemctl() {
    case "${1:-}" in
        is-active|is-enabled) return 0 ;;
        restart)
            restart_count=$((restart_count + 1))
            [[ "$restart_count" -gt 1 ]]
            ;;
        daemon-reload|stop) return 0 ;;
        enable|disable) return 1 ;;
        *) return 0 ;;
    esac
}
if migrate_legacy_relay_runtime; then
    printf 'Migration unexpectedly succeeded after a forced service restart failure.\n' >&2
    exit 1
fi
[[ "$restart_count" == "2" ]]
[[ -x "$RELAY_BINARY" && ! -L "$RELAY_BINARY" ]]
grep -Fqx "ExecStart=$RELAY_LEGACY_XRAY_BINARY run -config $RELAY_CONFIG" "$RELAY_SERVICE_FILE"
known_neutral_dropin_matches
[[ -f "$RELAY_SERVICE_DROPIN_DIR/99-admin.conf" ]]

printf 'Neutral relay runtime regression checks passed.\n'
