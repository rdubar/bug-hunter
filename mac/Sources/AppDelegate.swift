import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    private var window: OverlayWindow!
    private var bugView: BugView!
    private var controller: BugController!
    private var eventMonitor: Any?
    private var statusItem: NSStatusItem?
    private var accessibilityPoller: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)  // no Dock icon

        setupWindow()
        setupStatusItem()
        SoundManager.shared.preload()
        controller = BugController(view: bugView)
        setupEventMonitor()
        controller.start()
    }

    // MARK: - Window

    private func setupWindow() {
        guard let screen = NSScreen.main else { fatalError("No display found") }
        window  = OverlayWindow(frame: screen.frame)
        bugView = BugView(frame: NSRect(origin: .zero, size: screen.frame.size))
        window.contentView = bugView
        window.makeKeyAndOrderFront(nil)
    }

    // MARK: - Status bar menu

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let btn = statusItem?.button {
            btn.title = "🪲"
            btn.font  = NSFont.systemFont(ofSize: 14)
        }

        let menu = NSMenu()
        menu.addItem(item("Add Bug",    #selector(addBug)))
        menu.addItem(item("Squish All", #selector(squishAll)))
        menu.addItem(.separator())
        menu.addItem(item("Quit Bug Hunter", #selector(quitApp)))
        statusItem?.menu = menu
    }

    private func item(_ title: String, _ action: Selector) -> NSMenuItem {
        let it = NSMenuItem(title: title, action: action, keyEquivalent: "")
        it.target = self
        return it
    }

    @objc private func addBug()    { controller.addBug() }
    @objc private func squishAll() { controller.squishAll() }
    @objc private func quitApp()   { NSApp.terminate(nil) }

    // MARK: - Global mouse monitor

    private func setupEventMonitor() {
        // AXIsProcessTrustedWithOptions shows the native macOS permission dialog when needed.
        let opts = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        if AXIsProcessTrustedWithOptions(opts) {
            installMonitor()
        } else {
            // Poll until the user grants access. On most macOS versions the monitor
            // starts working immediately; on others a relaunch is required.
            accessibilityPoller = Timer.scheduledTimer(
                withTimeInterval: 2.0, repeats: true
            ) { [weak self] timer in
                if AXIsProcessTrusted() {
                    self?.installMonitor()
                    timer.invalidate()
                    self?.accessibilityPoller = nil
                }
            }
        }
    }

    private func installMonitor() {
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDown) { [weak self] _ in
            self?.controller.handleClick(at: NSEvent.mouseLocation)
        }
    }

    // MARK: - Cleanup

    func applicationWillTerminate(_ notification: Notification) {
        accessibilityPoller?.invalidate()
        if let m = eventMonitor { NSEvent.removeMonitor(m) }
    }
}
