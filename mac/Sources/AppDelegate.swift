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
        menu.addItem(item("Quit Bug Hunter", #selector(NSApplication.terminate(_:))))
        statusItem?.menu = menu
    }

    private func item(_ title: String, _ action: Selector) -> NSMenuItem {
        let it = NSMenuItem(title: title, action: action, keyEquivalent: "")
        it.target = self
        return it
    }

    @objc private func addBug()    { controller.addBug() }
    @objc private func squishAll() { controller.squishAll() }

    // MARK: - Global mouse monitor

    private func setupEventMonitor() {
        if AXIsProcessTrusted() {
            installMonitor()
        } else {
            showAccessibilityPrompt()
            // Poll until user grants access (they'll need to relaunch, but
            // some macOS versions grant it live — handle both)
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

    private func showAccessibilityPrompt() {
        let alert = NSAlert()
        alert.messageText = "Bug Hunter needs Accessibility access"
        alert.informativeText = """
            To squish the bugs, grant Accessibility permission, then relaunch Bug Hunter.

            System Settings → Privacy & Security → Accessibility
            """
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "Later")
        NSApp.activate(ignoringOtherApps: true)
        if alert.runModal() == .alertFirstButtonReturn {
            let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
            NSWorkspace.shared.open(url)
        }
    }

    // MARK: - Cleanup

    func applicationWillTerminate(_ notification: Notification) {
        accessibilityPoller?.invalidate()
        if let m = eventMonitor { NSEvent.removeMonitor(m) }
    }
}
