#!/usr/bin/env bash
# gtk4-layer-shell must be loaded before libwayland-client; Python loads
# libwayland first, so the preload shim is required here.
exec env LD_PRELOAD=/usr/lib/libgtk4-layer-shell.so \
  python3 "$(dirname "$(readlink -f "$0")")/dvd-screensaver.py" "$@"
