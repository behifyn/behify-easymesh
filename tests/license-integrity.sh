#!/usr/bin/env bash

readonly LICENSE_BASELINE_SHA="b03be037e53e635e10dd8050fa2bdad637962f50"

verify_license_notice_integrity() {
    if ! git cat-file -e "${LICENSE_BASELINE_SHA}^{commit}" 2>/dev/null; then
        printf 'License integrity baseline is unavailable: %s\n' "$LICENSE_BASELINE_SHA" >&2
        printf 'Fetch the immutable baseline before running this check.\n' >&2
        return 1
    fi

    if git diff --quiet "$LICENSE_BASELINE_SHA" -- LICENSE NOTICE; then
        return 0
    else
        local diff_status=$?
    fi

    if [[ "$diff_status" -eq 1 ]]; then
        printf 'LICENSE or NOTICE changed from immutable baseline %s.\n' "$LICENSE_BASELINE_SHA" >&2
    else
        printf 'Could not compare LICENSE and NOTICE against immutable baseline %s.\n' "$LICENSE_BASELINE_SHA" >&2
    fi
    return 1
}
