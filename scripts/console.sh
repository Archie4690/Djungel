#!/bin/bash

hosts=$(grep -E '^Host ' ~/.ssh/config | awk '{print $2}')

if command -v fzf &>/dev/null; then
    choice=$(echo "$hosts" | fzf --prompt="Connect to: " --height=~10 --border)
else
    echo "Select a host:"
    select choice in $hosts; do
        [[ -n "$choice" ]] && break
    done
fi

[[ -z "$choice" ]] && exit 0

case "$choice" in
    testserver)
        exec ~/.config/scripts/testserver.sh
        ;;
    cobblemon)
        exec ~/.config/scripts/cobblemon.sh
        ;;
    *)
        exec ssh "$choice"
        ;;
esac
