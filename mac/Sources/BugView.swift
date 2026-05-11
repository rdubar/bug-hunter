import AppKit

// Full-screen transparent overlay. The window is click-through (ignoresMouseEvents=true);
// the BugController handles hit detection via a global mouse event monitor.

class BugView: NSView {
    var bugs: [Bug] = []

    override var isFlipped: Bool { false }  // origin = bottom-left, matches screen coords

    override func draw(_ dirtyRect: NSRect) {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }

        // Clear to transparent so the desktop shows through
        ctx.clear(bounds)

        for bug in bugs {
            BugRenderer.draw(bug: bug)
        }
    }
}
