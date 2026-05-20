# Bug Hunter 🪲

A retro desktop toy in the tradition of Neko and XPenguins.
A cockroach crawls around your screen over all your windows. Try to squish it.

- **Click directly on the bug** → squish sound + splat + respawn somewhere else
- **Click near it but miss** → miss sound
- **Menu bar icon** (🪲) → Add Bug / Squish All / Quit

Runs on **macOS** (Swift + AppKit) and **Linux** (Python + GTK3).

> **Linux users:** [jump to Linux instructions ↓](#linux)

---

## macOS

### Download and run

**[Download BugHunter for Mac →](https://github.com/rdubar/bug-hunter/releases/latest)**

1. Download `BugHunter-mac.zip` from the latest release
2. Unzip and drag `BugHunter.app` to your Applications folder
3. Double-click to run — look for 🪲 in the menu bar

The release build is signed with a Developer ID certificate and notarized by
Apple, so macOS can verify that the downloaded app is from the registered
developer and was not damaged after packaging.

No Accessibility permission required.

### Build from source

Requires macOS 13+ and Xcode Command Line Tools:

```bash
xcode-select --install   # if not already installed
cd mac
./build.sh --package
open BugHunter.app
```

By default, the build uses an ad-hoc signature suitable for local testing. For a
public macOS download, build with a Developer ID certificate, notarize, staple,
and re-package the app before uploading the zip:

```bash
CODESIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" ./build.sh --package
xcrun notarytool submit ../BugHunter-mac.zip --keychain-profile "bug-hunter-notary" --wait
xcrun stapler staple BugHunter.app
cd ..
ditto -c -k --keepParent mac/BugHunter.app BugHunter-mac.zip
```

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

**macOS:** `BugView.hitTest` returns the view only when a click lands near a living
bug — otherwise it returns `nil`, and AppKit lets the click fall through to whatever
is beneath. No special permissions needed.

**Linux:** GTK3 *input shapes* tell the compositor to route pointer events only to the
circular region around each bug. Everything else passes through — the OS handles the
routing.

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
│   │   ├── AppDelegate.swift   Setup, menu bar icon
│   │   ├── OverlayWindow.swift Transparent borderless NSWindow
│   │   ├── Bug.swift           State machine + movement AI
│   │   ├── BugRenderer.swift   NSBezierPath drawing
│   │   ├── BugView.swift       Full-screen NSView, hit testing
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

**Graphics:** bug sprites are drawn procedurally at runtime using `NSBezierPath`
(macOS) and Cairo (Linux). The macOS app icon is included as a generated PNG and
`.icns` asset.

**Sounds (macOS):** uses Apple's built-in system sounds via `NSSound(named:)`
(`Basso`, `Tink`). These are part of macOS and require no attribution.

**Sounds (Linux):** references sound files from the
[freedesktop sound theme](https://freedesktop.org/wiki/Specifications/sound-theme-spec/)
(`window-attention.oga`, `button-pressed.oga`) which are already installed on the
user's system. Bug Hunter does not distribute these files. The freedesktop theme
is typically provided under CC0 or LGPL; check your distro's package for exact terms.

---

## License

[MIT](LICENSE) — © 2026 Roger Dubar.

---

## Credits

Built with Swift + AppKit (macOS) and Python + GTK3 (Linux).
Inspired by [Neko](https://en.wikipedia.org/wiki/Neko_(software)), XPenguins, and **Alphapet Tech Days 2026**.
