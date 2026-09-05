#!/usr/bin/env bash

set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
destination="${1:?destination is required}"
architecture="${2:-x86_64}"
. "$repo_root/versions.env"

rm -rf -- "$destination"
mkdir -p "$destination/core"
for file in easymesh install.sh uninstall.sh relay-manager versions.env README.md README.fa.md CHANGELOG.md SECURITY.md THIRD_PARTY_NOTICES.md LICENSE NOTICE; do
    cp -p "$repo_root/$file" "$destination/$file"
done
cp -a "$repo_root/docs" "$repo_root/licenses" "$destination/"

cat > "$destination/core/easytier-core" <<'EOF'
#!/usr/bin/env bash
printf 'easytier-core 2.6.4-test\n'
EOF
cat > "$destination/core/easytier-cli" <<'EOF'
#!/usr/bin/env bash
printf 'easytier-cli 2.6.4-test\n'
EOF
chmod 0755 "$destination/easymesh" "$destination/install.sh" "$destination/uninstall.sh" \
    "$destination/relay-manager" "$destination/core/easytier-core" "$destination/core/easytier-cli"

core_hash=$(sha256sum "$destination/core/easytier-core" | awk '{print $1}')
cli_hash=$(sha256sum "$destination/core/easytier-cli" | awk '{print $1}')
: > "$destination/files.sha256"
while IFS= read -r relative_file; do
    (cd "$destination" && sha256sum "$relative_file") >> "$destination/files.sha256"
done < <(cd "$destination" && find . -type f ! -name manifest.txt ! -name files.sha256 -print | LC_ALL=C sort)
files_hash=$(sha256sum "$destination/files.sha256" | awk '{print $1}')
cat > "$destination/manifest.txt" <<EOF
format=1
behify_easymesh_version=$BEHIFY_EASYMESH_VERSION
easytier_version=$EASYTIER_VERSION
architecture=$architecture
easytier_archive=test-fixture
easytier_archive_sha256=0000000000000000000000000000000000000000000000000000000000000000
easytier_core_sha256=$core_hash
easytier_cli_sha256=$cli_hash
files_manifest_sha256=$files_hash
EOF
