"""Sound manager for Linux.

Tries freedesktop sound files first, then falls back through common players,
then silently gives up. No extra Python dependencies required.
"""

import os
import subprocess


class SoundManager:
    _SQUISH_CANDIDATES = [
        '/usr/share/sounds/freedesktop/stereo/window-attention.oga',
        '/usr/share/sounds/ubuntu/stereo/window-attention.ogg',
        '/usr/share/sounds/gnome/default/alerts/bark.ogg',
    ]
    _MISS_CANDIDATES = [
        '/usr/share/sounds/freedesktop/stereo/button-pressed.oga',
        '/usr/share/sounds/ubuntu/stereo/button-pressed.ogg',
        '/usr/share/sounds/gnome/default/alerts/drip.ogg',
    ]
    _PLAYERS = ['paplay', 'aplay', 'ffplay', 'cvlc']

    def __init__(self):
        self._player = self._find_player()
        self._squish = self._find_file(self._SQUISH_CANDIDATES)
        self._miss   = self._find_file(self._MISS_CANDIDATES)

        if not self._player:
            print('Bug Hunter: no audio player found (paplay/aplay/ffplay). Running silent.')
        elif not self._squish:
            print('Bug Hunter: no system sound files found. Running silent.')

    def play_squish(self):
        self._play(self._squish)

    def play_miss(self):
        self._play(self._miss)

    # -----------------------------------------------------------------------

    def _play(self, path):
        if path and self._player:
            try:
                subprocess.Popen(
                    [self._player, path],
                    stdout=subprocess.DEVNULL,
                    stderr=subprocess.DEVNULL,
                )
            except OSError:
                pass

    @staticmethod
    def _find_player():
        for player in SoundManager._PLAYERS:
            try:
                subprocess.run(
                    [player, '--version'],
                    capture_output=True,
                    timeout=1,
                )
                return player
            except (FileNotFoundError, subprocess.TimeoutExpired, OSError):
                continue
        return None

    @staticmethod
    def _find_file(candidates):
        for path in candidates:
            if os.path.isfile(path):
                return path
        return None
