#!/usr/bin/env bash

set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
output_dir="${1:-$repo_root/release-output}"
. "$repo_root/versions.env"

bash "$repo_root/tests/static-smoke.sh"
if [[ -f "$output_dir/SHA256SUMS" ]]; then
    bash "$repo_root/tests/release-package-regression.sh" "$output_dir"
    bash "$repo_root/tests/online-installer-failure.sh" "$output_dir/online-install-v${BEHIFY_EASYMESH_VERSION}.sh"
else
    printf 'Release-output tests skipped because no built artifacts were supplied.\n'
fi
