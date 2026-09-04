#!/usr/bin/env bash

set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
output_dir="${1:-$repo_root/release-output}"
. "$repo_root/versions.env"
test_root=$(mktemp -d "${TMPDIR:-/tmp}/behify-package-test.XXXXXX")
trap 'rm -rf -- "$test_root"' EXIT

[[ -f "$output_dir/SHA256SUMS" ]]
(cd "$output_dir" && sha256sum --quiet -c SHA256SUMS)

manifest_value() {
    local manifest="$1" key="$2"
    awk -F= -v key="$key" '$1 == key { print substr($0, index($0, "=") + 1) }' "$manifest"
}

verify_package() {
    local architecture="$1" expected_machine expected_core_hash expected_cli_hash
    local package_name="behify-easymesh-v${BEHIFY_EASYMESH_VERSION}-linux-$architecture"
    local archive="$output_dir/$package_name.tar.gz" destination="$test_root/$architecture"
    local package_dir manifest machine core_count

    mkdir -p "$destination"
    tar -xzf "$archive" -C "$destination"
    package_dir="$destination/$package_name"
    manifest="$package_dir/manifest.txt"
    [[ -f "$package_dir/install.sh" && -f "$package_dir/uninstall.sh" ]]
    [[ -f "$package_dir/LICENSE" && -f "$package_dir/NOTICE" ]]
    [[ -f "$package_dir/THIRD_PARTY_NOTICES.md" ]]
    [[ -f "$package_dir/licenses/EasyTier-LGPL-3.0.txt" ]]
    [[ -f "$package_dir/licenses/Xray-core-MPL-2.0.txt" ]]
    [[ "$(manifest_value "$manifest" behify_easymesh_version)" == "$BEHIFY_EASYMESH_VERSION" ]]
    [[ "$(manifest_value "$manifest" easytier_version)" == "$EASYTIER_VERSION" ]]
    [[ "$(manifest_value "$manifest" architecture)" == "$architecture" ]]
    [[ "$(sha256sum "$package_dir/files.sha256" | awk '{print $1}')" == "$(manifest_value "$manifest" files_manifest_sha256)" ]]
    (cd "$package_dir" && sha256sum --quiet -c files.sha256)
    expected_core_hash=$(manifest_value "$manifest" easytier_core_sha256)
    expected_cli_hash=$(manifest_value "$manifest" easytier_cli_sha256)
    [[ "$(sha256sum "$package_dir/core/easytier-core" | awk '{print $1}')" == "$expected_core_hash" ]]
    [[ "$(sha256sum "$package_dir/core/easytier-cli" | awk '{print $1}')" == "$expected_cli_hash" ]]
    case "$architecture" in
        x86_64) expected_machine=62 ;;
        aarch64) expected_machine=183 ;;
        *) return 1 ;;
    esac
    machine=$(od -An -tu2 -j18 -N2 "$package_dir/core/easytier-core" | tr -d ' \n')
    [[ "$machine" == "$expected_machine" ]]
    machine=$(od -An -tu2 -j18 -N2 "$package_dir/core/easytier-cli" | tr -d ' \n')
    [[ "$machine" == "$expected_machine" ]]
    core_count=$(find "$package_dir/core" -type f | wc -l | tr -d ' ')
    [[ "$core_count" == '2' ]]
    if find "$package_dir" -type f \( -name xray -o -name behify-relayd \) -print -quit | grep -q .; then
        printf 'Release package unexpectedly contains an Xray executable.\n' >&2
        exit 1
    fi
}

verify_package x86_64
verify_package aarch64

if find "$output_dir" -mindepth 1 -maxdepth 1 -type f \
    -name 'behify-easymesh-v*-linux-*.tar.gz' \
    ! -name "behify-easymesh-v${BEHIFY_EASYMESH_VERSION}-linux-x86_64.tar.gz" \
    ! -name "behify-easymesh-v${BEHIFY_EASYMESH_VERSION}-linux-aarch64.tar.gz" \
    -print -quit | grep -q .; then
    printf 'Release output contains a stale architecture package.\n' >&2
    exit 1
fi
if find "$output_dir" -mindepth 1 -maxdepth 1 -type f -name 'online-install-v*.sh' \
    ! -name "online-install-v${BEHIFY_EASYMESH_VERSION}.sh" -print -quit | grep -q .; then
    printf 'Release output contains a stale online installer.\n' >&2
    exit 1
fi

x86_hash=$(sha256sum "$output_dir/behify-easymesh-v${BEHIFY_EASYMESH_VERSION}-linux-x86_64.tar.gz" | awk '{print $1}')
aarch64_hash=$(sha256sum "$output_dir/behify-easymesh-v${BEHIFY_EASYMESH_VERSION}-linux-aarch64.tar.gz" | awk '{print $1}')
online_installer="$output_dir/online-install-v${BEHIFY_EASYMESH_VERSION}.sh"
grep -Fq "BEHIFY_VERSION=\"$BEHIFY_EASYMESH_VERSION\"" "$online_installer"
grep -Fq "X86_64_SHA256=\"$x86_hash\"" "$online_installer"
grep -Fq "AARCH64_SHA256=\"$aarch64_hash\"" "$online_installer"
source_hash=$(awk -F= '$1 == "EASYTIER_SOURCE_SHA256" { print $2 }' "$repo_root/release/easytier-v2.6.4-assets.env")
[[ "$(sha256sum "$output_dir/easytier-v2.6.4-source.tar.gz" | awk '{print $1}')" == "$source_hash" ]]
tar -tzf "$output_dir/easytier-v2.6.4-source.tar.gz" | sed -n '1p' | \
    grep -Fxq 'EasyTier-8428a89d2dabc94c97d370ec607c6ca142473626/'

if git -C "$repo_root" ls-files 'core/**' | grep -q .; then
    printf 'EasyTier runtime binaries remain tracked under core/.\n' >&2
    exit 1
fi

printf 'Release package regression checks passed.\n'
