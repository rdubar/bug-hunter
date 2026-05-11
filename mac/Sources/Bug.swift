import AppKit

enum BugState: Equatable {
    case walking
    case idle
    case turning
    case squished
    case splat
}

class Bug {
    var position: CGPoint
    var angle: CGFloat        // radians; 0 = facing right (+x)
    var speed: CGFloat        // pixels per second
    var state: BugState = .walking
    var stateTimer: TimeInterval = 0
    var legPhase: CGFloat = 0 // 0.0–1.0 cycling, drives leg swing animation
    var splatShape: [CGPoint] = []
    var splatAlpha: CGFloat = 1.0

    // Tunable radii
    let hitRadius: CGFloat = 20
    let nearMissRadius: CGFloat = 55

    init(on screen: NSRect) {
        let m: CGFloat = 80
        position = CGPoint(
            x: .random(in: m...(screen.width - m)),
            y: .random(in: m...(screen.height - m))
        )
        angle = .random(in: 0...(2 * .pi))
        speed = .random(in: 80...145)
        stateTimer = .random(in: 1.0...3.5)
    }

    func update(dt: TimeInterval, in screen: NSRect) {
        stateTimer -= dt

        switch state {
        case .walking:
            legPhase += CGFloat(dt) * 10
            if legPhase > 1 { legPhase -= 1 }

            position.x += cos(angle) * speed * CGFloat(dt)
            position.y += sin(angle) * speed * CGFloat(dt)
            bounceEdges(in: screen)

            if stateTimer <= 0 {
                if Double.random(in: 0...1) < 0.28 {
                    state = .idle
                    stateTimer = .random(in: 0.3...1.4)
                } else {
                    angle += .random(in: -1.1...1.1)
                    stateTimer = .random(in: 0.8...3.0)
                }
            }

        case .idle:
            if stateTimer <= 0 {
                state = .walking
                stateTimer = .random(in: 1.0...3.5)
            }

        case .turning:
            // reserved for future smooth-turn AI upgrade
            state = .walking
            stateTimer = .random(in: 1.0...3.0)

        case .squished:
            break  // BugController drives transition → splat

        case .splat:
            splatAlpha -= CGFloat(dt) * 0.55
            if splatAlpha < 0 { splatAlpha = 0 }
        }
    }

    func squish() {
        state = .squished
        buildSplatShape()
    }

    func becomeSplat() {
        state = .splat
        splatAlpha = 1.0
    }

    func respawn(on screen: NSRect) {
        let m: CGFloat = 80
        position = CGPoint(
            x: .random(in: m...(screen.width - m)),
            y: .random(in: m...(screen.height - m))
        )
        angle = .random(in: 0...(2 * .pi))
        speed = .random(in: 80...145)
        state = .walking
        stateTimer = .random(in: 1.0...3.0)
        legPhase = 0
        splatAlpha = 1.0
    }

    private func bounceEdges(in screen: NSRect) {
        let m: CGFloat = 30
        if position.x < m          { position.x = m;               angle = .pi - angle }
        if position.x > screen.width  - m { position.x = screen.width  - m; angle = .pi - angle }
        if position.y < m          { position.y = m;               angle = -angle }
        if position.y > screen.height - m { position.y = screen.height - m; angle = -angle }
    }

    // Pre-compute splat polygon so it's stable across frames (no jitter)
    private func buildSplatShape() {
        splatShape = []
        let numSpikes = 14
        for i in 0..<numSpikes {
            let a = CGFloat(i) * 2 * .pi / CGFloat(numSpikes)
            // Alternate long/short spikes for blobby look
            let r: CGFloat = i % 2 == 0
                ? .random(in: 14...22)
                : .random(in: 7...12)
            splatShape.append(CGPoint(x: cos(a) * r, y: sin(a) * r))
        }
    }
}
