"""Cairo drawing routines.

All coordinates are in Cairo space (Y increases downward, origin = top-left).
Bugs are drawn in local space (origin = bug centre, facing +x when angle=0)
using ctx.translate + ctx.rotate, exactly mirroring the Swift/CoreGraphics
version on macOS.
"""

import math
import cairo
from bug import BugState


def draw_bug(ctx, bug):
    if bug.state in (BugState.WALKING, BugState.IDLE):
        _draw_alive(ctx, bug)
    elif bug.state == BugState.SQUISHED:
        _draw_squished(ctx, bug)
    elif bug.state == BugState.SPLAT:
        _draw_splat(ctx, bug)


# ---------------------------------------------------------------------------
# Live bug

def _draw_alive(ctx, bug):
    ctx.save()
    ctx.translate(bug.x, bug.y)
    ctx.rotate(bug.angle)

    phase = bug.leg_phase * 2 * math.pi

    # -- Legs (drawn behind body) --
    ctx.set_line_width(1.5)
    ctx.set_line_cap(cairo.LINE_CAP_ROUND)
    ctx.set_source_rgba(0.22, 0.13, 0.04, 1.0)

    for i, ax in enumerate([-8.0, -2.0, 5.0]):
        swing = math.sin(phase + i * 2.1) * 4

        # Side A (+y in local = downward on screen when angle=0)
        ctx.move_to(ax,       5)
        ctx.line_to(ax - 7,  13 + swing)
        ctx.line_to(ax - 14,  9 + swing)
        ctx.stroke()

        # Side B
        ctx.move_to(ax,       -5)
        ctx.line_to(ax - 7,  -13 - swing)
        ctx.line_to(ax - 14,  -9 - swing)
        ctx.stroke()

    # -- Abdomen --
    ctx.set_source_rgba(0.33, 0.20, 0.07, 1.0)
    _oval(ctx, -5.5, 0, 8.5, 7)
    ctx.fill()

    # Abdomen highlight stripe
    ctx.set_source_rgba(0.48, 0.32, 0.13, 0.55)
    _oval(ctx, -5.5, 0, 5.5, 4)
    ctx.fill()

    # -- Thorax --
    ctx.set_source_rgba(0.38, 0.23, 0.09, 1.0)
    _oval(ctx, 2, 0, 5, 5)
    ctx.fill()

    # -- Head --
    ctx.set_source_rgba(0.40, 0.25, 0.10, 1.0)
    _oval(ctx, 8.5, 0, 4.5, 4)
    ctx.fill()

    # -- Compound eyes --
    ctx.set_source_rgba(0.90, 0.06, 0.03, 1.0)
    ctx.arc(10,  1.5, 1.25, 0, 2 * math.pi); ctx.fill()
    ctx.arc(10, -1.5, 1.25, 0, 2 * math.pi); ctx.fill()

    # -- Antennae --
    sway = math.sin(phase * 0.35) * 2.5
    ctx.set_source_rgba(0.22, 0.13, 0.04, 1.0)
    ctx.set_line_width(1.0)

    ctx.move_to(11, 2)
    ctx.curve_to(16, 5, 22, 10, 26,  13 + sway)
    ctx.stroke()

    ctx.move_to(11, -2)
    ctx.curve_to(16, -5, 22, -10, 26, -13 - sway)
    ctx.stroke()

    ctx.restore()


# ---------------------------------------------------------------------------
# Squish frame

def _draw_squished(ctx, bug):
    ctx.save()
    ctx.translate(bug.x, bug.y)
    ctx.set_source_rgba(0.38, 0.10, 0.02, 1.0)
    _oval(ctx, 0, 0, 24, 5)
    ctx.fill()
    ctx.restore()


# ---------------------------------------------------------------------------
# Splat decal

def _draw_splat(ctx, bug):
    if not bug.splat_shape:
        return
    ctx.save()
    ctx.translate(bug.x, bug.y)

    ctx.set_source_rgba(0.44, 0.09, 0.02, bug.splat_alpha * 0.92)
    pts = bug.splat_shape
    ctx.move_to(*pts[0])
    for pt in pts[1:]:
        ctx.line_to(*pt)
    ctx.close_path()
    ctx.fill()

    ctx.set_source_rgba(0.22, 0.04, 0.01, bug.splat_alpha)
    ctx.arc(0, 0, 6, 0, 2 * math.pi)
    ctx.fill()

    ctx.restore()


# ---------------------------------------------------------------------------
# Helper: axis-aligned ellipse centred at (cx, cy)

def _oval(ctx, cx, cy, rx, ry):
    ctx.save()
    ctx.translate(cx, cy)
    ctx.scale(rx, ry)
    ctx.arc(0, 0, 1, 0, 2 * math.pi)
    ctx.restore()
