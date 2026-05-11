"""GTK3 transparent always-on-top overlay window.

Key Linux advantage over macOS: input shapes let the window be click-through
everywhere EXCEPT the bug hit area. No accessibility permission required —
the OS routes clicks at the compositor level.
"""

import cairo
import gi
gi.require_version('Gtk', '3.0')
from gi.repository import Gtk, Gdk

from renderer import draw_bug


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
        display = Gdk.Display.get_default()
        monitor = display.get_primary_monitor()
        geom    = monitor.get_geometry()
        scale   = monitor.get_scale_factor()
        self.screen_w = geom.width  * scale
        self.screen_h = geom.height * scale
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
        region = cairo.Region()
        for bug in self._bugs:
            if bug.is_alive():
                r = bug.NEAR_MISS_RADIUS + 5
                rect = cairo.RectangleInt(
                    x=int(bug.x - r), y=int(bug.y - r),
                    width=int(r * 2), height=int(r * 2),
                )
                region.union(cairo.Region(rect))
        self.input_shape_combine_region(region)

    # -----------------------------------------------------------------------
    # Click handler

    def _on_click(self, widget, event):
        if event.button == 1 and self._controller:
            self._controller.handle_click(event.x, event.y)
        return True
