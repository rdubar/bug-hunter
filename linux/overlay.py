"""GTK3 transparent always-on-top overlay window.

Key Linux advantage over macOS: input shapes let the window be click-through
everywhere EXCEPT the bug hit area. No accessibility permission required —
the OS routes clicks at the compositor level.
"""

import math
import cairo
import gi
gi.require_version('Gtk', '3.0')
from gi.repository import Gtk, Gdk

from renderer import draw_bug


def _circle_region(cx, cy, radius):
    """Return a pixel-accurate circular cairo.Region via horizontal scan lines.

    Using a geometric circle means the input-shape boundary matches the circular
    near-miss detection radius exactly — no silent corner zones.
    """
    cx, cy, r = int(cx), int(cy), int(radius)
    region = cairo.Region()
    for dy in range(-r, r + 1):
        dx = int(math.sqrt(max(0, r * r - dy * dy)))
        if dx > 0:
            region.union(cairo.Region(cairo.RectangleInt(
                x=cx - dx, y=cy + dy, width=dx * 2, height=1,
            )))
    return region


class OverlayWindow(Gtk.Window):

    def __init__(self):
        super().__init__()
        self._bugs      = []
        self._controller = None

        # --- Window chrome ---
        self.set_decorated(False)
        self.set_keep_above(True)
        self.set_app_paintable(True)
        self.set_skip_taskbar_hint(True)
        self.set_skip_pager_hint(True)
        self.stick()                                         # all workspaces
        self.set_type_hint(Gdk.WindowTypeHint.NOTIFICATION)  # overlay; not a panel

        # --- Geometry: primary monitor ---
        # Use logical pixel dimensions only. GTK, Cairo, draw coords, input-shape
        # coords, and event.x/y are all in logical pixels; multiplying by the
        # HiDPI scale factor would make screen_w/h physical pixels while everything
        # else stays logical, causing bugs to spawn off-screen on scaled displays.
        display = Gdk.Display.get_default()
        monitor = display.get_primary_monitor()
        geom    = monitor.get_geometry()
        self.screen_w = geom.width
        self.screen_h = geom.height
        self.move(geom.x, geom.y)
        self.resize(geom.width, geom.height)

        # --- RGBA visual (compositor transparency) ---
        visual = Gdk.Screen.get_default().get_rgba_visual()
        if visual:
            self.set_visual(visual)
        else:
            print('Bug Hunter: no RGBA visual — is a compositor running? '
                  '(try: picom &   or   compton &)')

        # --- Events ---
        self.add_events(Gdk.EventMask.BUTTON_PRESS_MASK)
        self.connect('draw', self._on_draw)
        self.connect('button-press-event', self._on_click)
        self.connect('delete-event', Gtk.main_quit)

    # -----------------------------------------------------------------------
    # Public interface used by BugController

    def set_bugs(self, bugs):
        self._bugs = bugs

    def set_controller(self, controller):
        self._controller = controller

    def refresh(self):
        """Update input shape then schedule redraw."""
        self._update_input_shape()
        self.queue_draw()

    # -----------------------------------------------------------------------
    # Drawing

    def _on_draw(self, widget, ctx):
        # Clear to fully transparent so the desktop shows through
        ctx.set_operator(cairo.OPERATOR_CLEAR)
        ctx.paint()
        ctx.set_operator(cairo.OPERATOR_OVER)

        for bug in self._bugs:
            draw_bug(ctx, bug)

        return False

    # -----------------------------------------------------------------------
    # Click-through via input shape
    #
    # Only the region around each living bug receives pointer events.
    # Everything else passes straight through to whatever is underneath.

    def _update_input_shape(self):
        # Circular region matches the circular near-miss detection geometry exactly,
        # so no corner areas are silently swallowed or inadvertently passed through.
        region = cairo.Region()
        for bug in self._bugs:
            if bug.is_alive():
                region.union(_circle_region(bug.x, bug.y, bug.NEAR_MISS_RADIUS))
        self.input_shape_combine_region(region)

    # -----------------------------------------------------------------------
    # Click handler

    def _on_click(self, widget, event):
        if event.button == 1 and self._controller:
            self._controller.handle_click(event.x, event.y)
        return True
