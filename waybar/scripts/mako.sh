#!/bin/sh

if ! command -v makoctl >/dev/null 2>&1; then
  printf '{"text":"","class":"missing","tooltip":"makoctl not found"}'
  exit 0
fi

modes=$(makoctl mode 2>/dev/null)
if [ $? -ne 0 ] || [ -z "$modes" ]; then
  printf '{"text":"","class":"offline","tooltip":"mako not running"}'
  exit 0
fi

if printf '%s\n' "$modes" | grep -qiE '(do-not-disturb|dnd)'; then
  printf '{"text":"","class":"dnd","tooltip":"Notifications muted"}'
else
  printf '{"text":"","class":"on","tooltip":"Notifications on"}'
fi
