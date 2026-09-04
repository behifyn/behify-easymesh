#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
readonly expected_baseline_sha="b03be037e53e635e10dd8050fa2bdad637962f50"
temp_root=$(mktemp -d)
trap 'rm -rf "$temp_root"' EXIT

copy_license_integrity_helper() {
    local target_repo=$1
    cp "$repo_root/tests/license-integrity.sh" "$target_repo/tests/license-integrity.sh"
}

run_license_integrity() {
    local target_repo=$1
    (
        cd "$target_repo"
        source tests/license-integrity.sh
        verify_license_notice_integrity
    )
}

grep -Fqx 'source tests/license-integrity.sh' "$repo_root/tests/static-smoke.sh"

full_repo="$temp_root/full-history"
git clone --quiet --no-local "$repo_root" "$full_repo"
copy_license_integrity_helper "$full_repo"

if git -C "$full_repo" show-ref --verify --quiet refs/heads/main; then
    git -C "$full_repo" branch -D main >/dev/null
fi

if git -C "$full_repo" show-ref --verify --quiet refs/heads/main; then
    printf 'Expected regression fixture to have no local main branch.\n' >&2
    exit 1
fi

git -C "$full_repo" cat-file -e "${expected_baseline_sha}^{commit}"
run_license_integrity "$full_repo"

printf '\nregression change\n' >> "$full_repo/LICENSE"
if run_license_integrity "$full_repo" >"$temp_root/license-change.out" 2>&1; then
    printf 'Expected a changed LICENSE to fail the integrity check.\n' >&2
    exit 1
fi

grep -Fq "LICENSE or NOTICE changed from immutable baseline $expected_baseline_sha." \
    "$temp_root/license-change.out" || {
    printf 'Changed LICENSE did not produce the expected integrity diagnostic.\n' >&2
    exit 1
}

shallow_repo="$temp_root/missing-baseline"
git clone --quiet --depth 1 --branch "$(git -C "$repo_root" branch --show-current)" \
    "file://$repo_root" "$shallow_repo"
copy_license_integrity_helper "$shallow_repo"

if git -C "$shallow_repo" cat-file -e "${expected_baseline_sha}^{commit}" 2>/dev/null; then
    printf 'Expected shallow regression fixture to omit the immutable baseline.\n' >&2
    exit 1
fi

if run_license_integrity "$shallow_repo" >"$temp_root/missing-baseline.out" 2>&1; then
    printf 'Expected a missing baseline to fail the integrity check.\n' >&2
    exit 1
fi

grep -Fq "License integrity baseline is unavailable: $expected_baseline_sha" \
    "$temp_root/missing-baseline.out" || {
    printf 'Missing baseline did not produce the expected diagnostic.\n' >&2
    exit 1
}

printf 'License integrity regression checks passed.\n'
