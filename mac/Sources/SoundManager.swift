import AppKit

// Uses built-in macOS system sounds — no resource files needed for v0.1.
// Swap in custom sounds later by pointing to file URLs instead of named sounds.

class SoundManager {
    static let shared = SoundManager()
    private var squishSound: NSSound?
    private var missSound: NSSound?

    private init() {}

    func preload() {
        squishSound = NSSound(named: "Basso")   // deep thud
        missSound   = NSSound(named: "Tink")    // light miss click
    }

    func playSquish() { play(squishSound) }
    func playMiss()   { play(missSound) }

    private func play(_ sound: NSSound?) {
        guard let s = sound else { return }
        s.stop()
        s.play()
    }
}
