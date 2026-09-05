#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ASSET_METADATA="$REPO_ROOT/release/easytier-v2.6.4-assets.env"
VERSION_METADATA="$REPO_ROOT/versions.env"
OUTPUT_DIR="${1:-$REPO_ROOT/release-output}"
CACHE_DIR="${BEHIFY_RELEASE_CACHE:-$REPO_ROOT/.release-cache}"
STAGING_DIR=""
BUILT_PACKAGE=""

die() {
    printf 'Error: %s\n' "$*" >&2
    exit 1
}

require_command() {
    command -v "$1" >/dev/null 2>&1 || die "Required command '$1' is missing. Install it and retry."
}

cleanup() {
    [[ -z "$STAGING_DIR" || ! -d "$STAGING_DIR" ]] || rm -rf -- "$STAGING_DIR"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

# shellcheck source=../versions.env
. "$VERSION_METADATA"
# shellcheck source=easytier-v2.6.4-assets.env
. "$ASSET_METADATA"
[[ "$BEHIFY_EASYMESH_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z][0-9A-Za-z.-]*)?$ ]] || die "Invalid Behify release version metadata."
[[ "$EASYTIER_VERSION" == "v2.6.4" ]] || die "Unexpected EasyTier release version metadata."
for command_name in curl sha256sum unzip tar awk grep od tr find sort install mktemp sed git cp chmod mkdir rm mv basename cmp; do
    require_command "$command_name"
done
if [[ "${BEHIFY_ALLOW_DIRTY_BUILD:-0}" != "1" ]] && [[ -n "$(git -C "$REPO_ROOT" status --porcelain --untracked-files=normal)" ]]; then
    die "Release builds require a clean Git working tree. Commit or stash changes first."
fi

[[ ! -L "$OUTPUT_DIR" ]] || die "Refusing to write release artifacts through a symlinked output directory."
mkdir -p "$CACHE_DIR" "$OUTPUT_DIR"
find "$OUTPUT_DIR" -mindepth 1 -maxdepth 1 -type f -delete
find "$OUTPUT_DIR" -mindepth 1 -maxdepth 1 -type l -delete
if find "$OUTPUT_DIR" -mindepth 1 -maxdepth 1 -print -quit | grep -q .; then
    die "Release output contains a directory or unsupported entry that was not removed."
fi
STAGING_DIR=$(mktemp -d "${TMPDIR:-/tmp}/behify-easymesh-release.XXXXXX")
chmod 0700 "$STAGING_DIR"

fetch_verified() {
    local url="$1" expected_hash="$2" destination="$3" partial

    partial="${destination}.part"

    if [[ -f "$destination" ]] && [[ "$(sha256sum "$destination" | awk '{print $1}')" == "$expected_hash" ]]; then
        printf 'Using verified cache: %s\n' "$(basename "$destination")"
        return 0
    fi
    rm -f -- "$partial"
    curl --fail --location --proto '=https' --tlsv1.2 --output "$partial" "$url"
    [[ "$(sha256sum "$partial" | awk '{print $1}')" == "$expected_hash" ]] || {
        rm -f -- "$partial"
        die "SHA-256 mismatch for $url"
    }
    mv -f -- "$partial" "$destination"
}

verify_elf_architecture() {
    local binary="$1" architecture="$2" magic machine expected

    magic=$(od -An -tx1 -N4 "$binary" | tr -d ' \n')
    [[ "$magic" == "7f454c46" ]] || die "Not an ELF executable: $binary"
    machine=$(od -An -tu2 -j18 -N2 "$binary" | tr -d ' \n')
    case "$architecture" in
        x86_64) expected=62 ;;
        aarch64) expected=183 ;;
        *) die "Unsupported build architecture: $architecture" ;;
    esac
    [[ "$machine" == "$expected" ]] || die "ELF architecture mismatch for $binary"
}

reported_version() {
    "$1" --version 2>/dev/null | head -n 1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -n 1
}

host_architecture() {
    [[ "$(uname -s)" == "Linux" ]] || {
        printf 'unsupported\n'
        return 0
    }
    case "$(uname -m)" in
        x86_64|amd64) printf 'x86_64\n' ;;
        aarch64|arm64) printf 'aarch64\n' ;;
        *) printf 'unsupported\n' ;;
    esac
}

copy_release_files() {
    local package_dir="$1" item

    for item in easymesh install.sh uninstall.sh relay-manager versions.env README.md README.fa.md CHANGELOG.md SECURITY.md THIRD_PARTY_NOTICES.md LICENSE NOTICE; do
        install -m 0644 "$REPO_ROOT/$item" "$package_dir/$item"
    done
    chmod 0755 "$package_dir/easymesh" "$package_dir/install.sh" "$package_dir/uninstall.sh" "$package_dir/relay-manager"
    cp -a "$REPO_ROOT/docs" "$REPO_ROOT/licenses" "$package_dir/"
}

generate_file_manifest() {
    local package_dir="$1" relative_file

    : > "$package_dir/files.sha256"
    while IFS= read -r relative_file; do
        (cd "$package_dir" && sha256sum "$relative_file") >> "$package_dir/files.sha256"
    done < <(cd "$package_dir" && find . -type f ! -name manifest.txt ! -name files.sha256 -print | LC_ALL=C sort)
}

build_architecture_package() {
    local architecture="$1" asset url archive_hash core_hash cli_hash upstream_dir
    local archive extract_dir package_name package_dir files_hash package_archive

    case "$architecture" in
        x86_64)
            asset="$EASYTIER_X86_64_ASSET"
            url="$EASYTIER_X86_64_URL"
            archive_hash="$EASYTIER_X86_64_ARCHIVE_SHA256"
            core_hash="$EASYTIER_X86_64_CORE_SHA256"
            cli_hash="$EASYTIER_X86_64_CLI_SHA256"
            upstream_dir=easytier-linux-x86_64
            ;;
        aarch64)
            asset="$EASYTIER_AARCH64_ASSET"
            url="$EASYTIER_AARCH64_URL"
            archive_hash="$EASYTIER_AARCH64_ARCHIVE_SHA256"
            core_hash="$EASYTIER_AARCH64_CORE_SHA256"
            cli_hash="$EASYTIER_AARCH64_CLI_SHA256"
            upstream_dir=easytier-linux-aarch64
            ;;
        *) die "Unsupported build architecture: $architecture" ;;
    esac

    archive="$CACHE_DIR/$asset"
    fetch_verified "$url" "$archive_hash" "$archive"
    unzip -Z1 "$archive" | awk '/(^|\/)\.\.($|\/)|^\// { exit 1 }' || die "Unsafe path in $asset"
    extract_dir="$STAGING_DIR/upstream-$architecture"
    mkdir -p "$extract_dir"
    unzip -p "$archive" "$upstream_dir/easytier-core" > "$extract_dir/easytier-core"
    unzip -p "$archive" "$upstream_dir/easytier-cli" > "$extract_dir/easytier-cli"
    chmod 0755 "$extract_dir/easytier-core" "$extract_dir/easytier-cli"
    [[ "$(sha256sum "$extract_dir/easytier-core" | awk '{print $1}')" == "$core_hash" ]] || die "Extracted core hash mismatch for $architecture"
    [[ "$(sha256sum "$extract_dir/easytier-cli" | awk '{print $1}')" == "$cli_hash" ]] || die "Extracted CLI hash mismatch for $architecture"
    verify_elf_architecture "$extract_dir/easytier-core" "$architecture"
    verify_elf_architecture "$extract_dir/easytier-cli" "$architecture"
    if [[ "$(host_architecture)" == "$architecture" ]]; then
        [[ "$(reported_version "$extract_dir/easytier-core")" == "2.6.4" ]] || die "Core version mismatch for $architecture"
        [[ "$(reported_version "$extract_dir/easytier-cli")" == "2.6.4" ]] || die "CLI version mismatch for $architecture"
        printf 'Native runtime validation passed for %s.\n' "$architecture"
    else
        printf 'Static ELF/hash validation passed for %s; native execution remains a release gate.\n' "$architecture"
    fi

    package_name="behify-easymesh-v${BEHIFY_EASYMESH_VERSION}-linux-${architecture}"
    package_dir="$STAGING_DIR/$package_name"
    mkdir -p "$package_dir/core"
    copy_release_files "$package_dir"
    install -m 0755 "$extract_dir/easytier-core" "$package_dir/core/easytier-core"
    install -m 0755 "$extract_dir/easytier-cli" "$package_dir/core/easytier-cli"
    generate_file_manifest "$package_dir"
    files_hash=$(sha256sum "$package_dir/files.sha256" | awk '{print $1}')
    cat > "$package_dir/manifest.txt" <<EOF
format=1
behify_easymesh_version=$BEHIFY_EASYMESH_VERSION
easytier_version=$EASYTIER_VERSION
architecture=$architecture
easytier_archive=$asset
easytier_archive_sha256=$archive_hash
easytier_core_sha256=$core_hash
easytier_cli_sha256=$cli_hash
files_manifest_sha256=$files_hash
EOF
    package_archive="$OUTPUT_DIR/$package_name.tar.gz"
    rm -f -- "$package_archive"
    tar --sort=name --owner=0 --group=0 --numeric-owner --mtime='UTC 2026-09-04' \
        --pax-option=delete=atime,delete=ctime -czf "$package_archive" -C "$STAGING_DIR" "$package_name"
    BUILT_PACKAGE="$package_archive"
}

build_architecture_package x86_64
X86_PACKAGE="$BUILT_PACKAGE"
build_architecture_package aarch64
AARCH64_PACKAGE="$BUILT_PACKAGE"
X86_PACKAGE_HASH=$(sha256sum "$X86_PACKAGE" | awk '{print $1}')
AARCH64_PACKAGE_HASH=$(sha256sum "$AARCH64_PACKAGE" | awk '{print $1}')

ONLINE_INSTALLER="$OUTPUT_DIR/online-install-v${BEHIFY_EASYMESH_VERSION}.sh"
sed -e "s/@BEHIFY_VERSION@/$BEHIFY_EASYMESH_VERSION/g" \
    -e "s/@X86_64_PACKAGE_SHA256@/$X86_PACKAGE_HASH/g" \
    -e "s/@AARCH64_PACKAGE_SHA256@/$AARCH64_PACKAGE_HASH/g" \
    "$REPO_ROOT/release/online-install.sh.in" > "$ONLINE_INSTALLER"
chmod 0755 "$ONLINE_INSTALLER"
cp -p "$ONLINE_INSTALLER" "$OUTPUT_DIR/install.sh"
cmp -s "$ONLINE_INSTALLER" "$OUTPUT_DIR/install.sh" || die "Stable installer alias does not match the versioned bootstrap."

fetch_verified "$EASYTIER_SOURCE_URL" "$EASYTIER_SOURCE_SHA256" "$CACHE_DIR/$EASYTIER_SOURCE_ASSET"
cp -p "$CACHE_DIR/$EASYTIER_SOURCE_ASSET" "$OUTPUT_DIR/$EASYTIER_SOURCE_ASSET"

(
    cd "$OUTPUT_DIR"
    sha256sum \
        "$(basename "$X86_PACKAGE")" \
        "$(basename "$AARCH64_PACKAGE")" \
        "$(basename "$ONLINE_INSTALLER")" \
        "install.sh" \
        "$EASYTIER_SOURCE_ASSET" > SHA256SUMS
)
printf 'Release artifacts written to: %s\n' "$OUTPUT_DIR"
