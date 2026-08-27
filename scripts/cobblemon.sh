#!/bin/bash
# Password lives in ~/.config/.secrets/cobblemon.pass (chmod 600, never committed).
# sshpass -f keeps it out of the process list, unlike -p.

passFile="$HOME/.config/.secrets/cobblemon.pass"

if [ ! -r "$passFile" ]; then
    echo "cobblemon: missing $passFile" >&2
    exit 1
fi

exec sshpass -f "$passFile" ssh cobblemon
