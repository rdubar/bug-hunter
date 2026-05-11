import AppKit

// Owns the list of bugs, drives the animation timer, and handles click events.
// Architecture note: adding multiple bugs, different species, or panic mode means
// extending this class — the Bug/BugRenderer split keeps species logic isolated.

class BugController {
    private weak var view: BugView!
    private var bugs: [Bug] = []
    private var animationTimer: Timer?
    private var lastTick: CFAbsoluteTime = CFAbsoluteTimeGetCurrent()

    // Tunable timings
    private let squishToSplatDelay: TimeInterval = 0.08
    private let splatRespawnDelay: TimeInterval  = 1.3

    init(view: BugView) {
        self.view = view
    }

    func start() {
        addBug()

        // Timer in .common mode so it fires during menu tracking, scroll events, etc.
        animationTimer = Timer.scheduledTimer(
            withTimeInterval: 1.0 / 60.0, repeats: true
        ) { [weak self] _ in self?.tick() }
        RunLoop.main.add(animationTimer!, forMode: .common)
    }

    func stop() {
        animationTimer?.invalidate()
        animationTimer = nil
    }

    func addBug() {
        guard let screen = NSScreen.main else { return }
        bugs.append(Bug(on: screen.frame))
        view.bugs = bugs
    }

    func squishAll() {
        for bug in bugs where isAlive(bug) {
            doSquish(bug)
        }
    }

    // Called from the global mouse monitor with NSEvent.mouseLocation (screen coords).
    // Bug positions are in the overlay view's local coordinate space, so we must
    // convert before comparing — otherwise multi-monitor origins break hit detection.
    func handleClick(at screenPoint: CGPoint) {
        guard let window = view?.window, let view = view else { return }
        let windowPoint = window.convertPoint(fromScreen: screenPoint)
        let localPoint  = view.convert(windowPoint, from: nil)

        for bug in bugs where isAlive(bug) {
            let d = hypot(bug.position.x - localPoint.x, bug.position.y - localPoint.y)
            if d <= bug.hitRadius {
                doSquish(bug)
                return           // first hit wins; no double-events
            }
            if d <= bug.nearMissRadius {
                SoundManager.shared.playMiss()
                return
            }
        }
    }

    // MARK: - Private

    private func isAlive(_ bug: Bug) -> Bool {
        bug.state == .walking || bug.state == .idle || bug.state == .turning
    }

    private func doSquish(_ bug: Bug) {
        bug.squish()
        SoundManager.shared.playSquish()

        DispatchQueue.main.asyncAfter(deadline: .now() + squishToSplatDelay) { [weak bug] in
            bug?.becomeSplat()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + splatRespawnDelay) { [weak bug] in
            guard let bug, let screen = NSScreen.main else { return }
            bug.respawn(on: screen.frame)
        }
    }

    private func tick() {
        let now = CFAbsoluteTimeGetCurrent()
        let dt  = min(now - lastTick, 0.05)  // cap to 50 ms to survive sleeps
        lastTick = now

        guard let screen = NSScreen.main else { return }
        for bug in bugs { bug.update(dt: dt, in: screen.frame) }

        view.setNeedsDisplay(view.bounds)
    }
}
