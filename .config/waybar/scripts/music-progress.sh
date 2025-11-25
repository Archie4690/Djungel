#!/bin/bash

# Cider MPRIS player name
player=$(playerctl -l 2>/dev/null | grep chromium | tail -n1)

# Get status (Playing/Paused/Stopped). Suppress errors to avoid "No players found" messages.
status=$(playerctl -s -p "$PLAYER" status)
if [ $? -ne 0 ] || [ "$status" = "Stopped" ]; then
  # No player or no track playing
  echo "{\"text\": \"No music\", \"tooltip\": \"No music playing\"}"
  exit 0
fi

# Get current position (seconds, may be float) and total length (microseconds)
pos_seconds=$(playerctl -s -p "$PLAYER" position)               # e.g. 42.5
length_us=$(playerctl -s -p "$PLAYER" metadata mpris:length)    # e.g. 230000000 (microseconds)

# Fallback if length is not retrieved
if [ -z "$length_us" ] || [ -z "$pos_seconds" ]; then
  echo "{\"text\": \"No music\", \"tooltip\": \"No music playing\"}"
  exit 0
fi

# Convert microseconds to total seconds (integer) for length
# Using bc for precision in case of large numbers
length_seconds=$(echo "$length_us/1000000" | bc)  # bc truncates decimals by default

# Floor the position to an integer second for display
pos_sec_int=${pos_seconds%.*}  # truncate the decimal part

# Calculate hours, minutes, seconds for position and length
pos_h=$(( pos_sec_int / 3600 ))
pos_m=$(( (pos_sec_int % 3600) / 60 ))
pos_s=$(( pos_sec_int % 60 ))
len_h=$(( length_seconds / 3600 ))
len_m=$(( (length_seconds % 3600) / 60 ))
len_s=$(( length_seconds % 60 ))

# Format the time strings (H:MM:SS or M:SS)
if [ $len_h -gt 0 ]; then
  pos_time=$(printf "%d:%02d:%02d" $pos_h $pos_m $pos_s)
  len_time=$(printf "%d:%02d:%02d" $len_h $len_m $len_s)
else
  pos_time=$(printf "%d:%02d" $pos_m $pos_s)
  len_time=$(printf "%d:%02d" $len_m $len_s)
fi

# Build progress bar (10 segments)
filled=$(( 0 ))
if [ $length_seconds -gt 0 ]; then
  filled=$(( pos_sec_int * 10 / length_seconds ))
  if [ $filled -gt 10 ]; then
    filled=10  # safety cap, though pos <= length normally
  fi
fi
bar=""
for i in $(seq 1 10); do
  if [ $i -le $filled ]; then
    bar+="#"    # filled segment
  else
    bar+="_"    # empty segment (underscore or hyphen for visibility)
  fi
done

# Prepare main text and tooltip
output_text="$pos_time / $len_time [$bar]"
if [ "$status" = "Paused" ]; then
  output_text="$output_text ⏸"  # add pause symbol if paused
fi

# Tooltip could show full title (Artist - Title)
track_info=$(playerctl -s -p "$PLAYER" metadata --format '{{artist}} - {{title}}')
if [ -z "$track_info" ]; then
  track_info="Apple Music via Cider"  # fallback tooltip
fi

# JSON-escape the strings for safety
esc_text=${output_text//\\/\\\\}      # escape backslashes
esc_text=${esc_text//\"/\\\"}         # escape double quotes
esc_tooltip=${track_info//\\/\\\\}
esc_tooltip=${esc_tooltip//\"/\\\"}

# Print JSON output
echo "{\"text\": \"$esc_text\", \"tooltip\": \"$esc_tooltip\"}"
