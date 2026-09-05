#!/usr/bin/env bash

set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
output_dir="${1:?release output directory is required}"
architecture="${2:?architecture is required}"
. "$repo_root/versions.env"

case "$(uname -m):$architecture" in
    x86_64:x86_64|amd64:x86_64|aarch64:aarch64|arm64:aarch64) ;;
    *)
        printf 'Native runner architecture %s does not match package %s.\n' "$(uname -m)" "$architecture" >&2
        exit 1
        ;;
esac

archive="$output_dir/behify-easymesh-v${BEHIFY_EASYMESH_VERSION}-linux-${architecture}.tar.gz"
test_root=$(mktemp -d "${TMPDIR:-/tmp}/behify-native-package.XXXXXX")
trap 'rm -rf -- "$test_root"' EXIT
tar -xzf "$archive" -C "$test_root"
package_dir="$test_root/behify-easymesh-v${BEHIFY_EASYMESH_VERSION}-linux-${architecture}"

"$package_dir/core/easytier-core" --version | grep -Fq '2.6.4'
"$package_dir/core/easytier-cli" --version | grep -Fq '2.6.4'

mock_bin="$test_root/network-bin"
install_root="$test_root/rootfs"
mkdir -p "$mock_bin" "$install_root/systemctl-state"
cp "$repo_root/tests/mock-systemctl.sh" "$mock_bin/systemctl"
for command_name in curl wget; do
    cat > "$mock_bin/$command_name" <<'EOF'
#!/usr/bin/env bash
printf 'Unexpected network command during offline installation.\n' >&2
exit 99
EOF
done
chmod 0755 "$mock_bin/systemctl" "$mock_bin/curl" "$mock_bin/wget"

for pass in 1 2; do
    MOCK_SYSTEMCTL_STATE="$install_root/systemctl-state" \
    MOCK_INSTALL_ROOT="$install_root" \
    BEHIFY_TEST_ROOT="$install_root" \
    BEHIFY_TEST_MODE=1 \
    BEHIFY_TEST_ARCH="$architecture" \
    BEHIFY_TEST_VALIDATE_ELF=1 \
    BEHIFY_TEST_NATIVE_LINK=1 \
    EASYMESH_OFFLINE=1 \
    PATH="$mock_bin:$PATH" \
        bash "$package_dir/install.sh"
done

"$install_root/root/easytier/easytier-core" --version | grep -Fq '2.6.4'
"$install_root/root/easytier/easytier-cli" --version | grep -Fq '2.6.4'
[[ -L "$install_root/usr/local/bin/easymesh" ]]
[[ "$(readlink "$install_root/usr/local/bin/easymesh")" == '/opt/behify-easymesh/easymesh' ]]
printf 'Native %s package and strict-offline installation checks passed.\n' "$architecture"
