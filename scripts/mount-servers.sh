#!/bin/bash

# Mounts the Minecraft servers over sshfs.
# agk and mrz authenticate with SSH keys. testserver and cobblemon still use
# passwords, read from ~/.config/.secrets/<host>.pass (chmod 600, never committed).

SECRETS="$HOME/.config/.secrets"

# Wait for network
sleep 5

mount_key() {
    local host="$1" dir="$HOME/$2"
    mountpoint -q "$dir" || sshfs "root@$host:/home/minecraft" "$dir"
}

mount_pass() {
    local host="$1" dir="$HOME/$2" passFile="$SECRETS/$1.pass"

    mountpoint -q "$dir" && return

    if [ ! -r "$passFile" ]; then
        echo "mount-servers: missing $passFile, skipping $host" >&2
        return 1
    fi

    printf '%s' "$(<"$passFile")" | sshfs "root@$host:/home/minecraft" "$dir" -o password_stdin
}

mount_key  agk        agk
mount_key  mrz        mrz
mount_pass testserver test
mount_pass cobblemon  cobblemon
