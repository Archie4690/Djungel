#!/bin/sh

# Toggle bluetooth and auto-connect a device when enabling
if rfkill list bluetooth | grep -q "Soft blocked: yes"; then
    rfkill unblock bluetooth
    sleep 1
    bluetoothctl connect 10:94:97:4B:7E:76
else
    rfkill block bluetooth
fi
