#!/bin/bash
# ── bluetooth-toggle.sh ──────────────────────────────────────────────────────
# Toggle Bluetooth on/off using rfkill.
# Usage: Waybar `bluetooth` module :on-click
# Output: (changes state only)
# ───────────────────────────────────────────────────────────────────────────── 

if rfkill list bluetooth | grep -q "Soft blocked: yes"; then
    rfkill unblock bluetooth
    sleep 1
    bluetoothctl connect 10:94:97:4B:7E:76
else
    rfkill block bluetooth
fi

