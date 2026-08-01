#!/usr/bin/env bash

set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
export BEHIFY_RELAY_SOURCE_ONLY=1
# shellcheck source=../relay-manager
source "$repo_root/relay-manager"

run_temp_path_regression() {
    local temp_dir=""
    local temp_file=""
    local resolved_temp_root resolved_dir

    make_relay_temp_dir temp_dir
    [[ -n "$temp_dir" ]]
    [[ -d "$temp_dir" ]]
    resolved_temp_root=$(readlink -f "${TMPDIR:-/tmp}")
    resolved_dir=$(readlink -f "$temp_dir")
    [[ "$resolved_dir" == "$resolved_temp_root"/* ]]
    [[ "$temp_dir/relays.json" != "/relays.json" ]]

    make_relay_temp_file temp_file "$temp_dir/.relay-test.XXXXXX"
    [[ -n "$temp_file" ]]
    [[ -f "$temp_file" ]]
    [[ "$(readlink -f "$temp_file")" == "$resolved_dir"/* ]]

    if make_relay_temp_dir created_dir 2>/dev/null; then
        printf 'Unsafe helper-local output collision was accepted.\n' >&2
        return 1
    fi
    if make_relay_temp_file created_file "$temp_dir/.collision-test.XXXXXX" 2>/dev/null; then
        printf 'Unsafe file-helper output collision was accepted.\n' >&2
        return 1
    fi
}

run_temp_path_regression
printf 'Relay temporary-path regression checks passed.\n'
