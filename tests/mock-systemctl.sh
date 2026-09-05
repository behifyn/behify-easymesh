#!/usr/bin/env bash

set -u

state_dir=${MOCK_SYSTEMCTL_STATE:?}
mkdir -p "$state_dir"
printf '%s\n' "$*" >> "$state_dir/calls.log"

case "${1:-}" in
    is-active)
        if [[ -f "$state_dir/transient-new-runtime-failure" ]]; then
            rm -f "$state_dir/transient-new-runtime-failure" "$state_dir/active"
            exit 1
        fi
        [[ -f "$state_dir/active" ]]
        ;;
    is-enabled)
        [[ -f "$state_dir/enabled" ]]
        ;;
    stop)
        rm -f "$state_dir/active"
        ;;
    start|restart)
        if [[ -f "$state_dir/fail-new-runtime" ]] && grep -Fq '2.6.4' "$MOCK_INSTALL_ROOT/root/easytier/easytier-core" 2>/dev/null; then
            touch "$state_dir/transient-new-runtime-failure"
        fi
        touch "$state_dir/active"
        ;;
    enable)
        touch "$state_dir/enabled"
        ;;
    disable)
        rm -f "$state_dir/enabled"
        ;;
    daemon-reload)
        ;;
    show)
        printf '12345\n'
        ;;
    *)
        ;;
esac
