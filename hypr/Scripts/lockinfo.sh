#!/usr/bin/env bash
# Status block for the hyprlock screen. One field per invocation:
#   lockinfo.sh host|kernel|uptime|memory|disk|net|corners
#
# Lines are padded to a fixed width with NBSP (U+00A0) rather than plain
# spaces: hyprlock renders via Pango, which trims trailing ordinary
# whitespace, and centred lines of unequal width would not column-align.
WIDTH=34
NBSP=$' '

emit() {
    local line="$1" n
    n=$(( WIDTH - ${#line} ))
    (( n > 0 )) && printf -v line '%s%*s' "$line" "$n" ""
    printf '%s\n' "${line// /$NBSP}"
}

case "${1:-}" in
  host)    emit "host      $(uname -n)" ;;
  kernel)  emit "kernel    $(uname -r)" ;;
  uptime)  emit "uptime    $(uptime -p 2>/dev/null | sed 's/^up //')" ;;
  memory)  emit "$(free -h | awk '/^Mem:/{printf "memory    %s / %s", $3, $2}')" ;;
  disk)    emit "$(df -h / | awk 'NR==2{printf "disk      %s free of %s", $4, $2}')" ;;
  net)     emit "network   $(ip route get 1.1.1.1 2>/dev/null | awk '{print $5; exit}' || echo down)" ;;
  corners)
    f="${XDG_STATE_HOME:-$HOME/.local/state}/dvd-screensaver/corners"
    c=$(cat "$f" 2>/dev/null); [[ "$c" =~ ^[0-9]+$ ]] || c=0
    emit "corners   $c hits" ;;
  *) exit 1 ;;
esac
