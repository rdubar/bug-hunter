#!/usr/bin/env python3
"""Bug Hunter — desktop bug toy for Linux.

Usage:
    python3 main.py          # start with one bug
    python3 main.py --bugs 5 # start with five bugs

Requires: python3-gi, gir1.2-gtk-3.0, python3-cairo, a compositor for alpha.
See README.md for install instructions.
"""

import signal
import argparse
import gi
gi.require_version('Gtk', '3.0')
from gi.repository import Gtk, Gdk

from overlay import OverlayWindow
from controller import BugController


def build_tray_menu(controller):
    """Gtk.StatusIcon right-click menu (works on X11/XWayland)."""
    menu = Gtk.Menu()

    def item(label, cb):
        it = Gtk.MenuItem(label=label)
        it.connect('activate', cb)
        menu.append(it)

    item('Add Bug',    lambda *_: controller.add_bug())
    item('Squish All', lambda *_: controller.squish_all())
    menu.append(Gtk.SeparatorMenuItem())
    item('Quit Bug Hunter', lambda *_: Gtk.main_quit())
    menu.show_all()
    return menu


def main():
    parser = argparse.ArgumentParser(description='Bug Hunter desktop toy')
    parser.add_argument('--bugs', type=int, default=1,
                        help='Number of bugs to start with (default: 1)')
    args = parser.parse_args()

    win = OverlayWindow()
    ctrl = BugController(win, win.screen_w, win.screen_h)
    win.set_controller(ctrl)

    # Status icon (tray) — deprecated API but works everywhere on X11
    icon = Gtk.StatusIcon()
    icon.set_from_icon_name('dialog-warning')
    icon.set_tooltip_text('Bug Hunter 🪲')

    tray_menu = build_tray_menu(ctrl)
    icon.connect('activate',   lambda *_: ctrl.add_bug())
    icon.connect('popup-menu', lambda i, btn, t: tray_menu.popup(
        None, None, None, i, btn, t))

    win.show_all()

    # Start all requested bugs
    ctrl.start()                               # adds first bug + timer
    for _ in range(args.bugs - 1):
        ctrl.add_bug()

    # Let Ctrl+C work in the terminal
    signal.signal(signal.SIGINT, signal.SIG_DFL)

    Gtk.main()


if __name__ == '__main__':
    main()
