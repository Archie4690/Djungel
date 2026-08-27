#!/usr/bin/env bash
# Moves audio output to the next available option.

# Get list of audio sinks (ignoring HDMI)
mapfile -t sinks < <(pactl list short sinks | awk '{print $2}' | grep -v "hdmi")

# Get current default sink
current=$(pactl get-default-sink)

# Find current index
for i in "${!sinks[@]}"; do
  if [[ "${sinks[$i]}" == "$current" ]]; then
    current_index=$i
    break
  fi
done

# Next sink index
next_index=$(( (current_index + 1) % ${#sinks[@]} ))
target="${sinks[$next_index]}"

# Set default and move streams
pactl set-default-sink "$target"
pactl list short sink-inputs | awk '{print $1}' | xargs -r -I{} pactl move-sink-input {} "$target"

# ---- Human-friendly names ----
case "$target" in
    *88_C9_E8_DF_3C_9A*)
        friendly="🎧 Headphones"
        ;;
    *10_94_97_4B_7E_76*)
        friendly="🔊 Speakers"
        ;;
    *)
        friendly="$target"   # fallback to raw name
        ;;
esac

# Notification
notify-send "Now playing from $friendly"

# Dependencies: pactl, notify-send
