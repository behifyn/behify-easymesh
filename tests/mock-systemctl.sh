#!/usr/bin/env bash

set -u

state_dir=${MOCK_SYSTEMCTL_STATE:?}
mkdir -p "$state_dir"
printf '%s\n' "$*" >> "$state_dir/calls.log"

case "${1:-}" in
    is-active)
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
            exit 1
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
