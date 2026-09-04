#!/usr/bin/env bash

set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
. "$repo_root/versions.env"
installer="${1:-$repo_root/release-output/online-install-v${BEHIFY_EASYMESH_VERSION}.sh}"
test_root=$(mktemp -d "${TMPDIR:-/tmp}/behify-online-test.XXXXXX")
trap 'rm -rf -- "$test_root"' EXIT
mock_bin="$test_root/bin"
mkdir -p "$mock_bin"

cat > "$mock_bin/curl" <<'EOF'
#!/usr/bin/env bash
exit 55
EOF
chmod 0755 "$mock_bin/curl"
if BEHIFY_TEST_MODE=1 BEHIFY_TEST_ARCH=x86_64 PATH="$mock_bin:$PATH" \
    bash "$installer" >"$test_root/download.log" 2>&1; then
    printf 'Online installer accepted a failed package download.\n' >&2
    exit 1
fi
grep -Fq 'Package download failed. The existing installation was not changed.' "$test_root/download.log"

cat > "$mock_bin/curl" <<'EOF'
#!/usr/bin/env bash
output=''
while [[ $# -gt 0 ]]; do
    if [[ "$1" == '--output' ]]; then
        output="$2"
        shift 2
    else
        shift
    fi
done
printf 'corrupt archive\n' > "$output"
EOF
cat > "$mock_bin/tar" <<EOF
#!/usr/bin/env bash
printf 'tar-called\n' >> '$test_root/tar.log'
exit 91
EOF
chmod 0755 "$mock_bin/curl" "$mock_bin/tar"
if BEHIFY_TEST_MODE=1 BEHIFY_TEST_ARCH=x86_64 PATH="$mock_bin:$PATH" \
    bash "$installer" >"$test_root/checksum.log" 2>&1; then
    printf 'Online installer accepted a corrupt package.\n' >&2
    exit 1
fi
grep -Fq 'Package SHA-256 verification failed. The archive was not extracted.' "$test_root/checksum.log"
[[ ! -e "$test_root/tar.log" ]]

if BEHIFY_TEST_MODE=1 BEHIFY_TEST_ARCH=armv7l PATH="$mock_bin:$PATH" \
    bash "$installer" >"$test_root/architecture.log" 2>&1; then
    printf 'Online installer accepted an unsupported architecture.\n' >&2
    exit 1
fi
grep -Fq 'supports only Linux x86_64 and aarch64' "$test_root/architecture.log"

printf 'Online installer failure checks passed.\n'
