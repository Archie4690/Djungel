#!/bin/bash
# Password lives in ~/.config/.secrets/testserver.pass (chmod 600, never committed).
# sshpass -f keeps it out of the process list, unlike -p.

passFile="$HOME/.config/.secrets/testserver.pass"

if [ ! -r "$passFile" ]; then
    echo "testserver: missing $passFile" >&2
    exit 1
fi

exec sshpass -f "$passFile" ssh testserver
