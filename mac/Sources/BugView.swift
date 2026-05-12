import AppKit

// Full-screen transparent overlay. ignoresMouseEvents is false; we override hitTest
// to return self only when a click lands near a living bug — all other clicks pass
// through to the desktop or whatever app is beneath. No Accessibility permission needed.

class BugView: NSView {
    var bugs: [Bug] = []
    var onHit: ((CGPoint) -> Void)?

    override var isFlipped: Bool { false }
    override var acceptsFirstResponder: Bool { true }

    // point is in window coordinates, which for our borderless window at (0,0) equals
    // Cocoa screen coordinates — the same space bug positions live in.
    override func hitTest(_ point: NSPoint) -> NSView? {
        for bug in bugs {
            guard bug.state == .walking || bug.state == .idle || bug.state == .turning else { continue }
            let d = hypot(bug.position.x - point.x, bug.position.y - point.y)
            if d <= bug.nearMissRadius { return self }
        }
        return nil  // click passes through to whatever is beneath
    }

    override func mouseDown(with event: NSEvent) {
        onHit?(event.locationInWindow)
    }

    override func draw(_ dirtyRect: NSRect) {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }
        ctx.clear(bounds)
        for bug in bugs {
            BugRenderer.draw(bug: bug)
        }
    }
}
