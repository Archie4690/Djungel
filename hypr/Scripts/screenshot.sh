!/bin/sh

DIR="$HOME/Pictures/Screenshots"
mkdir -p "$DIR"

FILE="$DIR/$(date +'%Y-%m-%d_%H-%M-%S').png"

grim -g "$(slurp)" - | tee "$FILE" | wl-copy

notify-send \
  -a "Screenshot" \
  -i "$FILE" \
  "Screenshot saved" \
  "Click to annotate" \
  -u low \
  -A "annotate=Annotate"

# Handle notification action
while read -r action; do
  [ "$action" = "annotate" ] && swappy -f "$FILE"
done

