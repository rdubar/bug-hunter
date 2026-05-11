#!/usr/bin/env bash
# run.sh — launch Bug Hunter on Linux
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

# ------------------------------------------------------------------
# Dependency check

check_deps() {
    python3 -c "
import gi
gi.require_version('Gtk', '3.0')
from gi.repository import Gtk, Gdk
import cairo
" 2>/dev/null && return 0

    echo "Error: missing Python/GTK dependencies."
    echo ""
    echo "Install with:"
    echo "  Ubuntu/Debian:  sudo apt install python3-gi python3-gi-cairo gir1.2-gtk-3.0"
    echo "  Fedora/RHEL:    sudo dnf install python3-gobject gtk3"
    echo "  Arch Linux:     sudo pacman -S python-gobject gtk3 python-cairo"
    echo "  openSUSE:       sudo zypper install python3-gobject gtk3"
    return 1
}

check_deps || exit 1

# ------------------------------------------------------------------
# Wayland: force XWayland so input shapes and StatusIcon work

if [ "${XDG_SESSION_TYPE:-}" = "wayland" ]; then
    echo "Note: Wayland detected — forcing GDK_BACKEND=x11 (XWayland)."
    export GDK_BACKEND=x11
fi

# ------------------------------------------------------------------
# Compositor check (non-fatal)

if ! pgrep -x picom picom-git compton mutter kwin_x11 xfwm4 openbox >/dev/null 2>&1; then
    echo "Warning: no compositor detected. Transparency may not work."
    echo "  Try: picom &   (then rerun this script)"
fi

# ------------------------------------------------------------------

exec python3 main.py "$@"
