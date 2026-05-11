import time
from gi.repository import GLib
from bug import Bug
from sound import SoundManager

_SQUISH_TO_SPLAT_MS = 80
_SPLAT_RESPAWN_MS   = 1300


class BugController:

    def __init__(self, window, screen_w, screen_h):
        self._window   = window
        self._screen_w = screen_w
        self._screen_h = screen_h
        self._bugs     = []
        self._sound    = SoundManager()
        self._last_tick = time.monotonic()

    def start(self):
        self.add_bug()
        GLib.timeout_add(16, self._tick)  # 16 ms ≈ 60 fps

    def add_bug(self):
        bug = Bug(self._screen_w, self._screen_h)
        self._bugs.append(bug)
        self._window.set_bugs(self._bugs)

    def squish_all(self):
        for bug in self._bugs:
            if bug.is_alive():
                self._do_squish(bug)

    def handle_click(self, x, y):
        """Called by the overlay window on every button-press inside the input shape."""
        for bug in self._bugs:
            if not bug.is_alive():
                continue
            dist = ((bug.x - x) ** 2 + (bug.y - y) ** 2) ** 0.5
            if dist <= bug.HIT_RADIUS:
                self._do_squish(bug)
                return
            if dist <= bug.NEAR_MISS_RADIUS:
                self._sound.play_miss()
                return

    # -----------------------------------------------------------------------

    def _do_squish(self, bug):
        bug.squish()
        self._sound.play_squish()
        GLib.timeout_add(_SQUISH_TO_SPLAT_MS, lambda: self._become_splat(bug))
        GLib.timeout_add(_SPLAT_RESPAWN_MS,   lambda: self._respawn(bug))

    def _become_splat(self, bug):
        bug.become_splat()
        return False  # one-shot

    def _respawn(self, bug):
        bug.respawn()
        return False

    def _tick(self):
        now = time.monotonic()
        dt  = min(now - self._last_tick, 0.05)
        self._last_tick = now

        for bug in self._bugs:
            bug.update(dt)

        self._window.refresh()
        return True  # keep timer alive
