#!/bin/sh
FILE=$(ls -t "$HOME/Pictures/Screenshots"/*.png | head -n 1)
[ -n "$FILE" ] && swappy -f "$FILE"

