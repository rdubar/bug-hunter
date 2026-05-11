# Bug Hunter 🪲

A retro desktop toy in the tradition of Neko and XPenguins.
A cockroach crawls around your screen over all your windows. Try to squish it.

- **Click directly on the bug** → squish sound + splat + respawn somewhere else
- **Click near it but miss** → miss sound
- **Right-click the tray/menu bar icon** → Add Bug / Squish All / Quit

Runs on **macOS** (Swift + AppKit) and **Linux** (Python + GTK3).

---

## macOS

### Requirements

- macOS 13 Ventura or later
- Xcode Command Line Tools

```bash
xcode-select --install   # if not already installed
```

### Build & run

```bash
cd mac
./build.sh
open BugHunter.app
```

First launch: macOS may block an unsigned app. Right-click the app and choose **Open**,
or clear the quarantine flag yourself:

```bash
xattr -d com.apple.quarantine mac/BugHunter.app
open mac/BugHunter.app
```

### Accessibility permission (required to squish bugs)

Bug Hunter uses a global mouse monitor so the overlay window can be fully click-through
while still detecting clicks on the bug. macOS requires **Accessibility** access for this.

A prompt appears on first launch. If you missed it:

> **System Settings → Privacy & Security → Accessibility → Bug Hunter → ON**

Then relaunch. Without this the bug is immortal.

**Privacy note:** the monitor only reads the mouse location of each click — it does
not log keystrokes, record cursor movement, or make any network calls. Everything
runs locally. The source is here for you to verify.

**Note for distributors:** the current bundle ID (`com.bughunter.app`) is a
placeholder. For signed/notarized releases, replace it with your own reverse-DNS
identifier and sign with a Developer ID certificate before distributing outside
this repo.

### Tray icon

Look for 🪲 in the menu bar. Click it for Add Bug / Squish All / Quit.

---

## Linux

### Requirements

- Python 3.8+
- GTK 3.22+ (usually pre-installed)
- PyGObject + pycairo
- A compositor (for transparent background)

Install the Python/GTK bindings:

```bash
# Ubuntu / Debian / Pop!_OS
sudo apt install python3-gi python3-gi-cairo gir1.2-gtk-3.0

# Fedora / RHEL / CentOS Stream
sudo dnf install python3-gobject gtk3

# Arch Linux / Manjaro
sudo pacman -S python-gobject gtk3 python-cairo

# openSUSE
sudo zypper install python3-gobject gtk3
```

### Compositor (required for transparent background)

On GNOME or KDE the compositor is already running. On bare i3, openbox, or similar:

```bash
picom &   # or: compton &
```

Without a compositor the background turns opaque black instead of transparent.

### Run

```bash
cd linux
./run.sh             # one bug
./run.sh --bugs 4    # start with four bugs
```

On **Wayland** the script automatically sets `GDK_BACKEND=x11` to run under
XWayland, where input shapes and the system tray icon work correctly.

### System tray

A 🪲 icon appears in the system tray. Left-click to add a bug; right-click for the
full menu. On pure Wayland without XWayland it may not appear — use Ctrl+C to quit.

### Sound

Uses freedesktop sound files played via `paplay` (PulseAudio) or `aplay` (ALSA).
Falls back silently if neither is found.

---

## How it works

### Click-through windows

Both versions show a borderless, transparent, always-on-top overlay window covering
the full screen. The bug is drawn on it; everything else is transparent so your real
windows stay usable.

**macOS:** the window has `ignoresMouseEvents = true`, and a global `NSEvent` monitor
catches every left-click on the system. This requires Accessibility permission.
Clicks are processed entirely on-device; no data is logged or transmitted.

**Linux:** GTK3 *input shapes* tell the compositor to route pointer events only to the
circular region around each bug. Everything else passes through with zero system
permissions required — the OS handles the routing.

### Animation

A 60 fps timer updates each bug's position using a simple state machine:
`walking → idle → turn → walking` with random direction changes and edge bouncing.
Leg animation is driven by a continuous phase value; antennae sway gently.
Sprites are drawn procedurally with `NSBezierPath` (macOS) / Cairo (Linux) —
no image files needed.

---

## Project layout

```
bug-hunter/
├── mac/
│   ├── Sources/
│   │   ├── main.swift          Entry point
│   │   ├── AppDelegate.swift   Setup, menu bar icon, accessibility prompt
│   │   ├── OverlayWindow.swift Transparent borderless NSWindow
│   │   ├── Bug.swift           State machine + movement AI
│   │   ├── BugRenderer.swift   NSBezierPath drawing
│   │   ├── BugView.swift       Full-screen NSView
│   │   ├── BugController.swift 60 fps timer, click dispatch
│   │   └── SoundManager.swift  NSSound wrapper
│   ├── Resources/
│   │   └── Info.plist
│   └── build.sh
└── linux/
    ├── main.py        Entry point, tray icon
    ├── overlay.py     GTK window, input shapes, draw signal
    ├── bug.py         State machine + movement AI  ← same logic as Bug.swift
    ├── renderer.py    Cairo drawing               ← mirrors BugRenderer.swift
    ├── controller.py  GLib timer, click dispatch
    ├── sound.py       paplay/aplay wrapper
    └── run.sh         Dep check + launcher
```

The `Bug` state machine and movement AI are identical across both platforms.
Only the platform layer (window, drawing surface, sound player) differs.

---

## Future ideas

- Multiple bug species (spider, ant, fly) with different movement styles
- Panic mode — spawn a swarm all at once
- Bugs that run away from the cursor
- Custom sound packs
- Linux: bugs crawl along real window edges using X11 window geometry

---

## Assets & open-source attribution

**Graphics:** all sprites are drawn procedurally at runtime using `NSBezierPath`
(macOS) and Cairo (Linux). No image files are included or distributed.

**Sounds (macOS):** uses Apple's built-in system sounds via `NSSound(named:)`
(`Basso`, `Tink`). These are part of macOS and require no attribution.

**Sounds (Linux):** references sound files from the
[freedesktop sound theme](https://freedesktop.org/wiki/Specifications/sound-theme-spec/)
(`window-attention.oga`, `button-pressed.oga`) which are already installed on the
user's system. Bug Hunter does not distribute these files. The freedesktop theme
is typically provided under CC0 or LGPL; check your distro's package for exact terms.

---

## License

[MIT](LICENSE) — © 2026 Alphapet Tech Days.

---

## Credits

Made at **Alphapet Tech Days 2026**.

Built with Swift + AppKit (macOS) and Python + GTK3 (Linux).
Inspired by [Neko](https://en.wikipedia.org/wiki/Neko_(software)) and XPenguins.
