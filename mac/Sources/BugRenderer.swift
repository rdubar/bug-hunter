import AppKit

// All drawing is coordinate-system independent: caller sets up a CGContext
// transform (translate + rotate) so the bug is drawn centered at the origin
// facing right (+x). NSBezierPath draws into whatever the current context is.

struct BugRenderer {

    static func draw(bug: Bug) {
        switch bug.state {
        case .walking, .idle, .turning:
            drawAlive(bug: bug)
        case .squished:
            drawSquished(at: bug.position)
        case .splat:
            drawSplat(bug: bug)
        }
    }

    // MARK: - Live bug

    private static func drawAlive(bug: Bug) {
        withContext(at: bug.position, angle: bug.angle) {
            let phase = bug.legPhase * .pi * 2

            // Legs behind body
            let legColor = NSColor(red: 0.22, green: 0.13, blue: 0.04, alpha: 1)
            legColor.setStroke()
            for (i, ax) in ([-8.0, -2.0, 5.0] as [CGFloat]).enumerated() {
                let swing = sin(phase + CGFloat(i) * 2.1) * 4

                // Side A (positive-y)
                let la = NSBezierPath()
                la.move(to:  NSPoint(x: ax,      y:  5))
                la.line(to:  NSPoint(x: ax - 7,  y: 13 + swing))
                la.line(to:  NSPoint(x: ax - 14, y:  9 + swing))
                la.lineWidth = 1.5
                la.stroke()

                // Side B (negative-y)
                let lb = NSBezierPath()
                lb.move(to:  NSPoint(x: ax,      y:  -5))
                lb.line(to:  NSPoint(x: ax - 7,  y: -13 - swing))
                lb.line(to:  NSPoint(x: ax - 14, y:  -9 - swing))
                lb.lineWidth = 1.5
                lb.stroke()
            }

            // Abdomen (rear oval)
            NSColor(red: 0.33, green: 0.20, blue: 0.07, alpha: 1).setFill()
            NSBezierPath(ovalIn: NSRect(x: -14, y: -7,  width: 17, height: 14)).fill()

            // Abdomen highlight stripe
            NSColor(red: 0.48, green: 0.32, blue: 0.13, alpha: 0.55).setFill()
            NSBezierPath(ovalIn: NSRect(x: -11, y: -4,  width: 11, height:  8)).fill()

            // Thorax (mid-section)
            NSColor(red: 0.38, green: 0.23, blue: 0.09, alpha: 1).setFill()
            NSBezierPath(ovalIn: NSRect(x:  -3, y: -5,  width: 10, height: 10)).fill()

            // Head
            NSColor(red: 0.40, green: 0.25, blue: 0.10, alpha: 1).setFill()
            NSBezierPath(ovalIn: NSRect(x:   4, y: -4,  width:  9, height:  8)).fill()

            // Compound eyes (red)
            NSColor(red: 0.90, green: 0.06, blue: 0.03, alpha: 1).setFill()
            NSBezierPath(ovalIn: NSRect(x: 8.5, y:  0.5, width: 2.5, height: 2.5)).fill()
            NSBezierPath(ovalIn: NSRect(x: 8.5, y: -3.0, width: 2.5, height: 2.5)).fill()

            // Antennae (animated gentle sway)
            let sway = sin(phase * 0.35) * 2.5
            legColor.setStroke()

            let ant1 = NSBezierPath()
            ant1.move(to: NSPoint(x: 11, y:  2))
            ant1.curve(to:          NSPoint(x: 26, y:  13 + sway),
                       controlPoint1: NSPoint(x: 16, y:   5),
                       controlPoint2: NSPoint(x: 22, y:  10))
            ant1.lineWidth = 1.0
            ant1.stroke()

            let ant2 = NSBezierPath()
            ant2.move(to: NSPoint(x: 11, y: -2))
            ant2.curve(to:          NSPoint(x: 26, y: -13 - sway),
                       controlPoint1: NSPoint(x: 16, y:  -5),
                       controlPoint2: NSPoint(x: 22, y: -10))
            ant2.lineWidth = 1.0
            ant2.stroke()
        }
    }

    // MARK: - Squish frame (momentary flat-squash)

    private static func drawSquished(at pos: CGPoint) {
        withContext(at: pos) {
            NSColor(red: 0.38, green: 0.10, blue: 0.02, alpha: 1).setFill()
            NSBezierPath(ovalIn: NSRect(x: -24, y: -5, width: 48, height: 10)).fill()
        }
    }

    // MARK: - Splat decal (fades out over ~2 s)

    private static func drawSplat(bug: Bug) {
        guard !bug.splatShape.isEmpty else { return }
        withContext(at: bug.position) {
            // Main blob
            NSColor(red: 0.44, green: 0.09, blue: 0.02, alpha: bug.splatAlpha * 0.92).setFill()
            let path = NSBezierPath()
            path.move(to: NSPoint(x: bug.splatShape[0].x, y: bug.splatShape[0].y))
            for pt in bug.splatShape.dropFirst() {
                path.line(to: NSPoint(x: pt.x, y: pt.y))
            }
            path.close()
            path.fill()

            // Dark centre
            NSColor(red: 0.22, green: 0.04, blue: 0.01, alpha: bug.splatAlpha).setFill()
            NSBezierPath(ovalIn: NSRect(x: -6, y: -6, width: 12, height: 12)).fill()
        }
    }

    // MARK: - Helpers

    private static func withContext(at position: CGPoint, angle: CGFloat = 0, block: () -> Void) {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }
        ctx.saveGState()
        ctx.translateBy(x: position.x, y: position.y)
        if angle != 0 { ctx.rotate(by: angle) }
        block()
        ctx.restoreGState()
    }
}
