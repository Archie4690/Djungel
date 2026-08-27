#!/usr/bin/env python3

import fcntl
import json
import os
import re
import subprocess
import sys
import time

CACHE_PATH = "/tmp/waybar-ws-icons.json"
CACHE_TTL_SECONDS = 2.0
LOCK_PATH = "/tmp/waybar-ws-icons.lock"

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


def run_json(cmd):
    output = subprocess.check_output(cmd, text=True)
    return json.loads(output)


def map_icon(window_class, window_title):
    for kind, pattern, icon in RULES:
        value = window_title if kind == "title" else window_class
        if pattern.search(value or ""):
            return icon
    return None


def load_cache():
    try:
        st = os.stat(CACHE_PATH)
        with open(CACHE_PATH, "r", encoding="utf-8") as handle:
            return json.load(handle), time.time() - st.st_mtime
    except Exception:
        return None, None


def write_cache(data):
    try:
        tmp_path = f"{CACHE_PATH}.tmp"
        with open(tmp_path, "w", encoding="utf-8") as handle:
            json.dump(data, handle)
        os.replace(tmp_path, CACHE_PATH)
    except Exception:
        pass


def try_acquire_lock():
    try:
        fd = os.open(LOCK_PATH, os.O_CREAT | os.O_RDWR, 0o644)
        fcntl.flock(fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
        return fd
    except Exception:
        return None


def release_lock(fd):
    try:
        fcntl.flock(fd, fcntl.LOCK_UN)
        os.close(fd)
    except Exception:
        pass


def compute_state():
    active = run_json(["hyprctl", "activeworkspace", "-j"])
    active_id = active.get("id")
    clients = run_json(["hyprctl", "clients", "-j"])

    ws_map = {}

    for client in clients:
        ws_id = client.get("workspace", {}).get("id")
        if ws_id is None:
            continue
        if client.get("mapped") is False:
            continue

        entry = ws_map.setdefault(ws_id, {
            "icons": [],
            "seen": set(),
            "classes": [],
            "seen_classes": set(),
            "has_windows": False,
            "unknown": False,
        })

        entry["has_windows"] = True

        window_class = client.get("class", "") or ""
        window_title = client.get("title", "") or ""
        icon = map_icon(window_class, window_title)

        if icon:
            if icon not in entry["seen"]:
                entry["seen"].add(icon)
                entry["icons"].append(icon)
        else:
            entry["unknown"] = True

        label = window_class or window_title
        if label and label not in entry["seen_classes"]:
            entry["seen_classes"].add(label)
            entry["classes"].append(label)

    for entry in ws_map.values():
        entry["seen"] = list(entry["seen"])
        entry["seen_classes"] = list(entry["seen_classes"])

    return {
        "active_id": active_id,
        "ws_map": ws_map,
    }


def build_output(workspace_id, state):
    ws_map = state.get("ws_map", {})
    active_id = state.get("active_id")

    entry = ws_map.get(workspace_id, {
        "icons": [],
        "classes": [],
        "has_windows": False,
        "unknown": False,
    })

    icons = entry.get("icons", [])
    if not icons and entry.get("unknown"):
        icons = ["?"]

    text = str(workspace_id)
    if icons:
        text = f"{text} {' '.join(icons)}"

    classes = ["ws"]
    if workspace_id == active_id:
        classes.append("active")
    elif not entry.get("has_windows"):
        classes.append("empty")
    else:
        classes.append("occupied")

    tooltip = f"Workspace {workspace_id}"
    if entry.get("classes"):
        tooltip += "\n" + ", ".join(entry["classes"])

    return {
        "text": text,
        "class": " ".join(classes),
        "tooltip": tooltip,
    }


def main():
    if len(sys.argv) < 2:
        print(json.dumps({"text": "", "class": "error", "tooltip": "missing workspace id"}))
        return

    try:
        workspace_id = int(sys.argv[1])
    except ValueError:
        print(json.dumps({"text": "", "class": "error", "tooltip": "invalid workspace id"}))
        return

    state, age = load_cache()
    if state is None or age is None or age > CACHE_TTL_SECONDS:
        lock_fd = try_acquire_lock()
        if lock_fd is not None:
            try:
                state = compute_state()
                write_cache(state)
            except Exception:
                if state is None:
                    print(json.dumps({"text": str(workspace_id), "class": "ws error", "tooltip": "hyprctl error"}))
                    return
            finally:
                release_lock(lock_fd)
        else:
            time.sleep(0.05)
            state, _ = load_cache()
            if state is None:
                print(json.dumps({"text": str(workspace_id), "class": "ws error", "tooltip": "hyprctl error"}))
                return

    output = build_output(workspace_id, state)
    print(json.dumps(output))


if __name__ == "__main__":
    main()
