import AppKit

class OverlayWindow: NSWindow {

    init(frame: NSRect) {
        super.init(
            contentRect: frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        backgroundColor = .clear
        isOpaque = false
        hasShadow = false
        // ignoresMouseEvents stays false — BugView.hitTest returns nil for non-bug clicks,
        // causing them to pass through to the desktop without needing Accessibility permission.
        level = .screenSaver           // above all app windows; change to .floating for softer mode
        collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        isReleasedWhenClosed = false
    }
}
