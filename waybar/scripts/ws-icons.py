#!/usr/bin/env python3

import json
import re
import subprocess
import sys


def run_json(cmd):
    output = subprocess.check_output(cmd, text=True)
    return json.loads(output)


RULES = [
    ("title", re.compile(r"youtube", re.I), ""),
    ("class", re.compile(r"chromium", re.I), ""),
    ("title", re.compile(r" - Chromium", re.I), ""),
    ("class", re.compile(r"codium|vscodium", re.I), "󰨞"),
    ("title", re.compile(r"VSCodium", re.I), "󰨞"),
    ("class", re.compile(r"thunar", re.I), ""),
    ("class", re.compile(r"discord", re.I), ""),
    ("class", re.compile(r"steam", re.I), ""),
    ("class", re.compile(r"org\.telegram\.desktop", re.I), ""),
    ("class", re.compile(r"whatsdesk", re.I), ""),
    ("class", re.compile(r"kitty|alacritty", re.I), ""),
    ("class", re.compile(r"spotify", re.I), ""),
    ("class", re.compile(r"notion", re.I), ""),
    ("class", re.compile(r"unityhub|unity", re.I), ""),
    ("class", re.compile(r"zenity", re.I), ""),
    ("class", re.compile(r"mupdf", re.I), ""),
    ("title", re.compile(r"^Updates$", re.I), ""),
    ("title", re.compile(r"^Installed Packages$", re.I), ""),
]


def map_icon(window_class, window_title):
    for kind, pattern, icon in RULES:
        value = window_title if kind == "title" else window_class
        if pattern.search(value or ""):
            return icon
    return None


def main():
    try:
        active = run_json(["hyprctl", "activeworkspace", "-j"])
        active_id = active.get("id")
        clients = run_json(["hyprctl", "clients", "-j"])
    except Exception:
        print(json.dumps({"text": "", "class": "error", "tooltip": "hyprctl not available"}))
        return

    icons = []
    seen = set()

    for client in clients:
        ws = client.get("workspace", {}).get("id")
        if ws != active_id:
            continue
        if client.get("mapped") is False:
            continue
        icon = map_icon(client.get("class", ""), client.get("title", ""))
        if not icon:
            continue
        if icon not in seen:
            seen.add(icon)
            icons.append(icon)

    text = " ".join(icons)
    if text:
        print(json.dumps({"text": text, "class": "active", "tooltip": "Active workspace apps"}))
    else:
        print(json.dumps({"text": "", "class": "empty", "tooltip": "No apps"}))


if __name__ == "__main__":
    main()
