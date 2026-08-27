#!/usr/bin/env python3
"""Multi-monitor DVD-bounce screensaver for Hyprland.

One process owns a layer-shell overlay surface per monitor. The logo's
position is tracked in *global* compositor coordinates, so it genuinely
travels between outputs instead of each screen bouncing independently.

Exits on any key, click or pointer motion (after a short grace period).
"""

import argparse
import colorsys
import fcntl
import math
import os
import random
import sys

import cairo
import gi

gi.require_version("Gtk", "4.0")
gi.require_version("Gdk", "4.0")
gi.require_version("Gtk4LayerShell", "1.0")
gi.require_version("GdkPixbuf", "2.0")
from gi.repository import Gdk, GdkPixbuf, GLib, Gtk  # noqa: E402
from gi.repository import Gtk4LayerShell as LayerShell  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))

STATE_DIR = os.path.join(
    os.environ.get("XDG_STATE_HOME", os.path.expanduser("~/.local/state")),
    "dvd-screensaver",
)
COUNTER = os.path.join(STATE_DIR, "corners")


def read_corner_count():
    try:
        with open(COUNTER) as fh:
            return int(fh.read().strip() or 0)
    except (OSError, ValueError):
        return 0


def write_corner_count(n):
    try:
        os.makedirs(STATE_DIR, exist_ok=True)
        tmp = COUNTER + ".tmp"
        with open(tmp, "w") as fh:
            fh.write(str(n))
        os.replace(tmp, COUNTER)  # atomic; waybar may read at any moment
    except OSError:
        pass

# gruvbox — same palette as waybar / rofi / mako
COLOURS = [
    (0x45, 0x85, 0x88),  # teal
    (0x83, 0xA5, 0x98),  # light blue
    (0xD7, 0x99, 0x21),  # yellow
    (0xCC, 0x24, 0x1D),  # red
    (0xB8, 0xBB, 0x26),  # green
    (0xD3, 0x86, 0x9B),  # purple
    (0xEB, 0xDB, 0xB2),  # cream
]


class Arena:
    """Union of all monitor rectangles, in global compositor coordinates."""

    def __init__(self, rects):
        self.rects = rects

    def covers(self, px, py):
        return any(
            r.x <= px < r.x + r.width and r.y <= py < r.y + r.height
            for r in self.rects
        )


class Logo:
    def __init__(self, arena, w, h, speed):
        self.arena = arena
        self.w = w
        self.h = h
        angle = math.radians(random.uniform(25, 55))
        self.vx = speed * math.cos(angle) * random.choice([1, -1])
        self.vy = speed * math.sin(angle) * random.choice([1, -1])
        self.colour = random.randrange(len(COLOURS))
        self.corner_hits = read_corner_count()
        self.star_frames = 0   # >0 while the Mario-star effect is running
        self.hue = 0.0
        self.on_corner = None

        r = arena.rects[0]
        self.x = r.x + (r.width - w) / 2
        self.y = r.y + (r.height - h) / 2

    def _edge_clear(self, nx, ny, axis):
        """Is the leading edge still over a real screen?

        Sampling the edge *midpoint* rather than the corners is what lets the
        logo cross the seam between monitors that aren't vertically aligned:
        it passes when the midpoint is inside the shared band, and bounces off
        the resulting 'wall' when it isn't.
        """
        if axis == "x":
            px = nx + self.w if self.vx > 0 else nx
            return self.arena.covers(px, ny + self.h / 2)
        py = ny + self.h if self.vy > 0 else ny
        return self.arena.covers(nx + self.w / 2, py)

    def rgb(self):
        """Current draw colour: rainbow cycle during star mode, else palette."""
        if self.star_frames > 0:
            r, g, b = colorsys.hsv_to_rgb(self.hue % 1.0, 1.0, 1.0)
            return int(r * 255), int(g * 255), int(b * 255)
        return COLOURS[self.colour]

    def step(self):
        if self.star_frames > 0:
            self.star_frames -= 1
            self.hue += self.star_hue_step
            if self.star_frames == 0:            # star over, back to normal speed
                self.vx /= self.star_boost
                self.vy /= self.star_boost

        nx, ny = self.x + self.vx, self.y + self.vy
        hit_x = hit_y = False

        if not self._edge_clear(nx, self.y, "x"):
            self.vx = -self.vx
            hit_x = True
            nx = self.x
        if not self._edge_clear(nx, ny, "y"):
            self.vy = -self.vy
            hit_y = True
            ny = self.y

        self.x, self.y = nx, ny

        if hit_x or hit_y:
            self.colour = (self.colour + 1) % len(COLOURS)
        if hit_x and hit_y:
            self.corner_hits += 1
            write_corner_count(self.corner_hits)
            print(f"CORNER HIT #{self.corner_hits}", flush=True)
            if self.star_frames == 0:   # don't stack boosts on a re-trigger
                self.vx *= self.star_boost
                self.vy *= self.star_boost
            self.star_frames = self.star_length
            if self.on_corner:
                self.on_corner(self.corner_hits)


class Screensaver:
    def __init__(self, opts, loop):
        self.opts = opts
        self.loop = loop
        self.windows = []
        self.areas = []
        self.quitting = False
        self.armed = False  # input is ignored until the grace period elapses

        display = Gdk.Display.get_default()
        if display is None:
            sys.exit("no display — is this running inside the Wayland session?")

        monitors = list(display.get_monitors())
        if not monitors:
            sys.exit("no monitors found")

        rects = [m.get_geometry() for m in monitors]
        for m, r in zip(monitors, rects):
            print(f"{m.get_connector()}: {r.width}x{r.height} at ({r.x},{r.y})")

        self.arena = Arena(rects)
        self.mask = self._load_mask(opts.scale)
        self.logo = Logo(
            self.arena, self.mask.get_width(), self.mask.get_height(), opts.speed
        )
        self.logo.star_boost = opts.star_boost
        self.logo.star_length = int(opts.star_seconds * opts.fps)
        # ~2 full rainbow cycles per second
        self.logo.star_hue_step = 2.0 / opts.fps

        for m, r in zip(monitors, rects):
            self._make_window(m, r)

        GLib.timeout_add(int(opts.grace * 1000), self._arm)

    def _load_mask(self, scale):
        pb = GdkPixbuf.Pixbuf.new_from_file(os.path.join(HERE, "dvd.png"))
        if scale != 1.0:
            pb = pb.scale_simple(
                max(1, int(pb.get_width() * scale)),
                max(1, int(pb.get_height() * scale)),
                GdkPixbuf.InterpType.BILINEAR,
            )
        surf = cairo.ImageSurface(cairo.FORMAT_ARGB32, pb.get_width(), pb.get_height())
        ctx = cairo.Context(surf)
        Gdk.cairo_set_source_pixbuf(ctx, pb, 0, 0)
        ctx.paint()
        return surf

    def _arm(self):
        self.armed = True
        return False

    def _make_window(self, monitor, rect):
        win = Gtk.Window()
        LayerShell.init_for_window(win)
        LayerShell.set_monitor(win, monitor)
        LayerShell.set_layer(win, LayerShell.Layer.OVERLAY)
        LayerShell.set_namespace(win, "dvd-screensaver")
        LayerShell.set_exclusive_zone(win, -1)
        LayerShell.set_keyboard_mode(win, LayerShell.KeyboardMode.EXCLUSIVE)
        for edge in ("TOP", "BOTTOM", "LEFT", "RIGHT"):
            LayerShell.set_anchor(win, getattr(LayerShell.Edge, edge), True)

        area = Gtk.DrawingArea()
        area.set_draw_func(self._draw, rect)
        win.set_child(area)

        keys = Gtk.EventControllerKey()
        keys.connect("key-pressed", self._dismiss)
        win.add_controller(keys)

        click = Gtk.GestureClick()
        click.connect("pressed", self._dismiss)
        win.add_controller(click)

        motion = Gtk.EventControllerMotion()
        motion.connect("motion", self._on_motion)
        win.add_controller(motion)

        win.present()
        self.windows.append(win)
        self.areas.append(area)

    def _draw(self, area, cr, width, height, rect):
        cr.set_source_rgb(0, 0, 0)
        cr.paint()

        lx = self.logo.x - rect.x  # global -> this monitor's local coords
        ly = self.logo.y - rect.y
        if lx + self.logo.w < 0 or ly + self.logo.h < 0:
            return
        if lx > width or ly > height:
            return

        r, g, b = self.logo.rgb()
        cr.set_source_rgb(r / 255, g / 255, b / 255)
        cr.mask_surface(self.mask, lx, ly)

    def _on_motion(self, ctl, x, y):
        if not hasattr(self, "_last_pointer"):
            self._last_pointer = (x, y)
            return
        px, py = self._last_pointer
        if math.hypot(x - px, y - py) > 8:
            self._dismiss()

    def _dismiss(self, *args):
        if self.quitting or not self.armed:
            return True
        self.quitting = True
        for w in self.windows:
            w.close()
        self.loop.quit()
        return True

    def tick(self):
        if self.quitting:
            return False
        self.logo.step()
        for a in self.areas:
            a.queue_draw()
        return True


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--speed", type=float, default=6.0, help="pixels per frame")
    ap.add_argument("--scale", type=float, default=1.0, help="logo scale factor")
    ap.add_argument("--fps", type=int, default=60)
    ap.add_argument("--grace", type=float, default=1.0,
                    help="seconds before input dismisses it")
    ap.add_argument("--timeout", type=int, default=0,
                    help="failsafe auto-exit after N seconds (0 = never)")
    ap.add_argument("--star-seconds", type=float, default=5.0,
                    help="length of the corner-hit star effect")
    ap.add_argument("--star-boost", type=float, default=2.5,
                    help="speed multiplier during the star effect")
    opts = ap.parse_args()

    # single instance: hypridle can re-fire on-timeout, and stacked
    # fullscreen keyboard-grabbing surfaces would be a bad day
    lock_path = os.path.join(
        os.environ.get("XDG_RUNTIME_DIR", "/tmp"), "dvd-screensaver.lock"
    )
    lock = open(lock_path, "w")
    try:
        fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except BlockingIOError:
        print("already running", file=sys.stderr)
        return
    globals()["_lock"] = lock  # keep the fd alive for the process lifetime

    loop = GLib.MainLoop()
    saver = Screensaver(opts, loop)
    GLib.timeout_add(int(1000 / opts.fps), saver.tick)
    if opts.timeout > 0:
        GLib.timeout_add_seconds(opts.timeout, lambda: saver._dismiss() and False)

    try:
        loop.run()
    except KeyboardInterrupt:
        pass


if __name__ == "__main__":
    main()
