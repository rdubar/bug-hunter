import math
import random


class BugState:
    WALKING  = 'walking'
    IDLE     = 'idle'
    SQUISHED = 'squished'
    SPLAT    = 'splat'


class Bug:
    HIT_RADIUS      = 20   # direct squish
    NEAR_MISS_RADIUS = 55  # triggers miss sound

    def __init__(self, screen_w, screen_h):
        self._w = screen_w
        self._h = screen_h
        margin = 80
        self.x     = random.uniform(margin, screen_w - margin)
        self.y     = random.uniform(margin, screen_h - margin)
        self.angle = random.uniform(0, 2 * math.pi)
        self.speed = random.uniform(80, 145)
        self.state       = BugState.WALKING
        self.state_timer = random.uniform(1.0, 3.5)
        self.leg_phase   = 0.0
        self.splat_shape = []   # pre-computed polygon points (local coords)
        self.splat_alpha = 1.0

    # ------------------------------------------------------------------
    # Update

    def update(self, dt):
        self.state_timer -= dt

        if self.state == BugState.WALKING:
            self.leg_phase = (self.leg_phase + dt * 10) % 1.0
            self.x += math.cos(self.angle) * self.speed * dt
            self.y += math.sin(self.angle) * self.speed * dt
            self._bounce()
            if self.state_timer <= 0:
                if random.random() < 0.28:
                    self.state       = BugState.IDLE
                    self.state_timer = random.uniform(0.3, 1.4)
                else:
                    self.angle      += random.uniform(-1.1, 1.1)
                    self.state_timer = random.uniform(0.8, 3.0)

        elif self.state == BugState.IDLE:
            if self.state_timer <= 0:
                self.state       = BugState.WALKING
                self.state_timer = random.uniform(1.0, 3.5)

        elif self.state == BugState.SPLAT:
            self.splat_alpha -= dt * 0.55
            if self.splat_alpha < 0:
                self.splat_alpha = 0

    # ------------------------------------------------------------------
    # State transitions

    def squish(self):
        self.state = BugState.SQUISHED
        self._build_splat_shape()

    def become_splat(self):
        self.state       = BugState.SPLAT
        self.splat_alpha = 1.0

    def respawn(self):
        margin = 80
        self.x     = random.uniform(margin, self._w - margin)
        self.y     = random.uniform(margin, self._h - margin)
        self.angle = random.uniform(0, 2 * math.pi)
        self.speed = random.uniform(80, 145)
        self.state       = BugState.WALKING
        self.state_timer = random.uniform(1.0, 3.0)
        self.leg_phase   = 0.0
        self.splat_alpha = 1.0

    def is_alive(self):
        return self.state in (BugState.WALKING, BugState.IDLE)

    # ------------------------------------------------------------------
    # Internals

    def _bounce(self):
        m = 30
        if self.x < m:
            self.x     = m
            self.angle = math.pi - self.angle
        elif self.x > self._w - m:
            self.x     = self._w - m
            self.angle = math.pi - self.angle
        if self.y < m:
            self.y     = m
            self.angle = -self.angle
        elif self.y > self._h - m:
            self.y     = self._h - m
            self.angle = -self.angle

    def _build_splat_shape(self):
        """Pre-compute blob polygon so it's stable across frames."""
        self.splat_shape = []
        n = 14
        for i in range(n):
            a = i * 2 * math.pi / n
            r = random.uniform(14, 22) if i % 2 == 0 else random.uniform(7, 12)
            self.splat_shape.append((math.cos(a) * r, math.sin(a) * r))
