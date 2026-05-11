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
        ignoresMouseEvents = true      // click-through; global monitor handles hits
        level = .screenSaver           // above all app windows; change to .floating for softer mode
        collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        isReleasedWhenClosed = false
    }
}
