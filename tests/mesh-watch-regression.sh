#!/usr/bin/env bash

set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
watch_functions=$(sed -n '/^get_watch_no_wrap_option()/,/^display_peers()/p' \
    "$repo_root/easymesh")
watch_functions=${watch_functions%$'\n'display_peers\(\)}
[[ -n "$watch_functions" ]]
eval "$watch_functions"

EASY_CLIENT='/root/easytier/easytier-cli'
MOCK_WATCH_HELP_MODE="unsupported"
WATCH_CALL_ARGS=()

colorize() {
    :
}

watch() {
    if [[ "${1:-}" == "--help" ]]; then
        case "$MOCK_WATCH_HELP_MODE" in
            short) printf '  -w, --no-wrap  turn off line wrapping\n' ;;
            long) printf '      --no-wrap  turn off line wrapping\n' ;;
            unsupported) printf 'Usage: watch [-n seconds] command\n' ;;
        esac
        return 0
    fi
    WATCH_CALL_ARGS=("$@")
}

assert_watch_call() {
    local expected_view="$1"
    local expected_no_wrap="$2"
    local no_wrap_count=0 argument

    [[ "${WATCH_CALL_ARGS[0]}" == "-n1" ]]
    [[ "${WATCH_CALL_ARGS[1]}" == "-t" ]]
    [[ "${WATCH_CALL_ARGS[${#WATCH_CALL_ARGS[@]} - 2]}" == "--" ]]
    [[ "${WATCH_CALL_ARGS[${#WATCH_CALL_ARGS[@]} - 1]}" == "$EASY_CLIENT $expected_view" ]]
    for argument in "${WATCH_CALL_ARGS[@]}"; do
        [[ "$argument" != "-w" && "$argument" != "--no-wrap" ]] || \
            no_wrap_count=$((no_wrap_count + 1))
    done
    [[ "$no_wrap_count" == "$expected_no_wrap" ]]
}

MOCK_WATCH_HELP_MODE="short"
watch_mesh_view peer
assert_watch_call peer 0

watch_mesh_view peer-center
assert_watch_call peer-center 0

watch_mesh_view route
assert_watch_call route 1
[[ "${WATCH_CALL_ARGS[2]}" == "-w" ]]

MOCK_WATCH_HELP_MODE="long"
watch_mesh_view route
assert_watch_call route 1
[[ "${WATCH_CALL_ARGS[2]}" == "--no-wrap" ]]

MOCK_WATCH_HELP_MODE="unsupported"
watch_mesh_view route
assert_watch_call route 0

printf 'Mesh watch regression checks passed.\n'
