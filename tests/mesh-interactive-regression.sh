#!/usr/bin/env bash

set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
export EASYMESH_SOURCE_ONLY=1
# shellcheck source=../easymesh
source "$repo_root/easymesh"
test_root=$(mktemp -d "${TMPDIR:-/tmp}/behify-mesh-interactive.XXXXXX")
trap 'rm -rf -- "$test_root"' EXIT

generated_marker=0123456789abcdef0123456789abcdef
custom_marker=CustomSecret-Rc3-Marker
generate_random_secret() {
    printf '%s\n' "$generated_marker"
}

NETWORK_SECRET=''
prompt_network_secret <<< '' > "$test_root/generated.out" 2>&1
[[ "$NETWORK_SECRET" == "$generated_marker" ]]
[[ "$(grep -Foc "$generated_marker" "$test_root/generated.out")" == '1' ]]
grep -Fqx 'Generated Network Secret:' "$test_root/generated.out"
styled_secret=$(printf '\033[1m\033[36m%s\033[0m' "$generated_marker")
grep -Fqx "$styled_secret" "$test_root/generated.out"

NETWORK_SECRET=''
prompt_network_secret <<< "$custom_marker" > "$test_root/custom.out" 2>&1
[[ "$NETWORK_SECRET" == "$custom_marker" ]]
! grep -Fq "$custom_marker" "$test_root/custom.out"

secret_prompt_source=$(sed -n '/^prompt_network_secret()/,/^}/p' "$repo_root/easymesh")
[[ "$(grep -Ec '^[[:space:]]*read[[:space:]]' <<< "$secret_prompt_source")" == '1' ]]
! grep -Eq 'read[[:space:]].*-[^[:space:]]*s([^[:alnum:]_]|$)' <<< "$secret_prompt_source"
grep -Fq 'Press Enter to use it, or enter a custom secret: ' <<< "$secret_prompt_source"
! grep -Fq 'Use this secret?' <<< "$secret_prompt_source"

read_arguments=''
read_value=''
read() {
    read_arguments="$*"
    printf -v "${!#}" '%s' "$read_value"
}
read_value=$custom_marker
NETWORK_SECRET=''
prompt_network_secret > "$test_root/visible-custom.out" 2>&1
[[ "$NETWORK_SECRET" == "$custom_marker" ]]
[[ " $read_arguments " != *' -s '* ]]
[[ "$read_arguments" == *'Press Enter to use it, or enter a custom secret: '* ]]
unset -f read

EASYMESH_SOURCE_ONLY=0
NETWORK_SECRET='unchanged'
if prompt_network_secret <<< '' > "$test_root/noninteractive-generate.out" 2>&1; then
    printf 'Non-interactive generated-secret display was accepted.\n' >&2
    exit 1
fi
[[ "$NETWORK_SECRET" == 'unchanged' ]]
! grep -Fq "$generated_marker" "$test_root/noninteractive-generate.out"
EASYMESH_SOURCE_ONLY=1

ENCRYPTION_OPTION=unset
prompt_encryption_option <<< '' >/dev/null
[[ -z "$ENCRYPTION_OPTION" ]]
ENCRYPTION_OPTION=unset
prompt_encryption_option <<< 'yes' >/dev/null
[[ -z "$ENCRYPTION_OPTION" ]]
ENCRYPTION_OPTION=unset
prompt_encryption_option < <(printf 'no\nyes\n') >/dev/null
[[ "$ENCRYPTION_OPTION" == '--disable-encryption' ]]
ENCRYPTION_OPTION=unset
prompt_encryption_option < <(printf 'no\nno\n') >/dev/null
[[ -z "$ENCRYPTION_OPTION" ]]

MULTI_THREAD_OPTION=unset
prompt_multi_thread_option <<< '' >/dev/null
[[ -z "$MULTI_THREAD_OPTION" ]]
MULTI_THREAD_OPTION=unset
prompt_multi_thread_option <<< 'no' >/dev/null
[[ -z "$MULTI_THREAD_OPTION" ]]
MULTI_THREAD_OPTION=unset
prompt_multi_thread_option <<< 'yes' >/dev/null
[[ "$MULTI_THREAD_OPTION" == '--multi-thread' ]]

grep -Fq 'case "$IPV6_CHOICE"' "$repo_root/easymesh"
grep -Fq '[Nn]*) IPV6_OPTION="--disable-ipv6"' "$repo_root/easymesh"
grep -Fq '*) IPV6_OPTION=""' "$repo_root/easymesh"

MESH_ENV_FILE="$test_root/mesh.env"
printf 'EASYMESH_NETWORK_SECRET="%s"\n' "$custom_marker" > "$MESH_ENV_FILE"
show_network_secret <<< '' > "$test_root/reveal.out" 2>&1
[[ "$(grep -Foc "$custom_marker" "$test_root/reveal.out")" == '1' ]]
EASYMESH_SOURCE_ONLY=0
if show_network_secret <<< '' > "$test_root/noninteractive-reveal.out" 2>&1; then
    printf 'Non-interactive stored-secret display was accepted.\n' >&2
    exit 1
fi
! grep -Fq "$custom_marker" "$test_root/noninteractive-reveal.out"
EASYMESH_SOURCE_ONLY=1

clear() { :; }
get_main_core_version() { printf '2.6.4\n'; }
get_service_status() { printf 'inactive\n'; }
display_menu > "$test_root/menu.out"
[[ "$(grep -Fc 'EasyTier:' "$test_root/menu.out")" == '1' ]]
! grep -Fq 'Installed:' "$test_root/menu.out"
! grep -Fq "$custom_marker" "$test_root/menu.out"

connect_source=$(sed -n '/^connect_network_pool()/,/^}/p' "$repo_root/easymesh")
grep -Fq 'Tip: leave Peer blank for reverse mode; UDP is recommended.' <<< "$connect_source"
! grep -Fq "Ws and wss modes are not recommended" <<< "$connect_source"

printf 'Mesh interactive regression checks passed.\n'
