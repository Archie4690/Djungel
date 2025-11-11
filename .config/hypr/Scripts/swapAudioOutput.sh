#!/usr/bin/env bash
# Moves audio output to the next avaliable option. 

# Get list of audio sink
mapfile -t sinks < <(pactl list short sinks | awk '{print $2}')

# Outline current audio sink
current=$(pactl get-default-sink)

# Loop through sinks to find current index
for i in "${!sinks[@]}"; do
  if [[ "${sinks[$i]}" == "$current" ]]; then
    current_index=$i
    break
  fi
done

# Adds one to the index, or defaults to 0 if at end of list
next_index=$(( (current_index + 1) % ${#sinks[@]} ))
target="${sinks[$next_index]}"

pactl set-default-sink "$target"

pactl list short sink-inputs | awk '{print $1}' | xargs -r -I{} pactl move-sink-input {} "$target"

notify-send "Audio output switched" "Now using: $target"

# Dependencies: pactl, notify-send