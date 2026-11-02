//
//  RetroGameView.swift
//  Echo: The Scrappy-Bot (iOS Native Edition)
//
//  High-performance 60/120 FPS Vector Canvas & Metal Shading Game View.
//  Replicates Android RetroGameView pixel-for-pixel with zero bitmap lag.
//

import SwiftUI

public struct RetroGameView: View {
    @ObservedObject var bridgeHolder: EngineBridgeHolder
    @StateObject private var soundManager = RetroSoundManager.shared
    @StateObject private var hardware = HardwareTrialsManager.shared

    @Binding var isMetaTakeoverActive: Bool
    @Binding var isGameOver: Bool
    @Binding var isTrueEnding: Bool

    @State private var floatingTexts: [FloatingTextItem] = []
    @State private var lastTickTime: Date = Date()
    @State private var bossLaserBeamTimer: Float = 0.0
    @State private var bossHitFlashTimer: Float = 0.0

    struct FloatingTextItem: Identifiable {
        let id = UUID()
        let text: String
        var x: CGFloat
        var y: CGFloat
        let color: Color
        var alpha: Double
    }

    public init(
        bridgeHolder: EngineBridgeHolder,
        isMetaTakeoverActive: Binding<Bool>,
        isGameOver: Binding<Bool>,
        isTrueEnding: Binding<Bool>
    ) {
        self.bridgeHolder = bridgeHolder
        self._isMetaTakeoverActive = isMetaTakeoverActive
        self._isGameOver = isGameOver
        self._isTrueEnding = isTrueEnding
    }

    public var body: some View {
        GeometryReader { geo in
            TimelineView(.animation) { timeline in
                Canvas { context, size in
                    let bridge = bridgeHolder.bridge
                    let now = timeline.date
                    let dt = Float(now.timeIntervalSince(lastTickTime)).clamped(to: 0.001...0.05)
                    DispatchQueue.main.async { lastTickTime = now }

                    // Advance engine step
                    if !bridge.isPaused() {
                        bridge.step(withDeltaTime: dt)
                    }

                    // Poll gameplay & audio events
                    pollEvents(bridge: bridge, size: size)

                    // Draw Background
                    drawBackground(context: context, size: size, bridge: bridge)

                    // Draw Oasis Base
                    drawBase(context: context, size: size, bridge: bridge)

                    // Draw Falling Debris & Relics
                    drawDebris(context: context, size: size, bridge: bridge)

                    // Draw Boss (Meca-Titan) if in Boss Mode
                    if bridge.isHackedBossMode() {
                        drawBoss(context: context, size: size, bridge: bridge, dt: dt)
                    }

                    // Draw Echo (The Player Vessel)
                    drawEcho(context: context, size: size, bridge: bridge)

                    // Draw HUD
                    drawHUD(context: context, size: size, bridge: bridge)

                    // Draw Floating Texts
                    drawFloatingTexts(context: context, dt: dt)
                }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let normX = Float(value.location.x / geo.size.width).clamped(to: 0.08...0.92)
                            bridgeHolder.bridge.setVesselPosition(normX)
                        }
                )
                .simultaneousGesture(
                    TapGesture(count: 2)
                        .onEnded {
                            _ = bridgeHolder.bridge.triggerMagneticPulse()
                            soundManager.playMagneticWave()
                        }
                )
            }
        }
        .onAppear {
            soundManager.start()
        }
    }

    // MARK: - Event Polling
    private func pollEvents(bridge: ScavengerBridge, size: CGSize) {
        let vesselX = CGFloat(bridge.getVesselPosition()) * size.width
        let vesselY = size.height * 0.86

        if bridge.pollCaptureSoundEvent() {
            let capturedType = Int(bridge.pollCapturedItemType())
            let combo = Int(bridge.getCombo())
            soundManager.playCapture(type: capturedType, combo: combo, normX: bridge.getVesselPosition())

            let label = capturedType == 5 ? "+SHIELD" : "+30"
            spawnFloatingText(label, x: vesselX, y: vesselY - 40, color: .cyan)
        }

        if bridge.pollDamageSoundEvent() || bridge.pollBombExplosionEvent() {
            soundManager.playBombHit(normX: bridge.getVesselPosition())
            spawnFloatingText("BOOM!", x: vesselX, y: vesselY - 40, color: .red)
        }

        if bridge.pollComboSoundEvent() {
            soundManager.playCombo(combo: Int(bridge.getCombo()))
        }

        if bridge.pollNewRecordSoundEvent() {
            soundManager.playNewRecord()
            spawnFloatingText("NEW RECORD!", x: size.width * 0.5, y: size.height * 0.3, color: .yellow)
        }

        if bridge.pollBossHitEvent() {
            soundManager.playLaserShot()
            bossLaserBeamTimer = 0.25
            bossHitFlashTimer = 0.35
            spawnFloatingText("LASER HIT!", x: size.width * CGFloat(bridge.getBossX()), y: size.height * 0.22, color: .orange)
        }

        if bridge.pollBossPhase2TransitionEvent() {
            soundManager.playBossPhase2()
            spawnFloatingText("PHASE 2: SURCHARGE!", x: size.width * 0.5, y: size.height * 0.4, color: .red)
        }

        if bridge.pollBossDefeatedEvent() {
            soundManager.playBossDefeated()
            spawnFloatingText("TITAN IMPLODED!", x: size.width * 0.5, y: size.height * 0.4, color: .green)
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                isTrueEnding = true
            }
        }

        if bridge.pollMetaTakeoverEvent() {
            bridge.setPaused(true)
            isMetaTakeoverActive = true
        }

        if bridge.getShield() <= 0 {
            bridge.setPaused(true)
            isGameOver = true
        }

        // Update audio telemetry
        soundManager.setTelemetry(
            level: Int(bridge.getLevel()),
            normX: bridge.getVesselPosition(),
            combo: Int(bridge.getCombo()),
            isBoss: bridge.isHackedBossMode()
        )
    }

    private func spawnFloatingText(_ text: String, x: CGFloat, y: CGFloat, color: Color) {
        floatingTexts.append(FloatingTextItem(text: text, x: x, y: y, color: color, alpha: 1.0))
    }

    // MARK: - Drawing Routines
    private func drawBackground(context: GraphicsContext, size: CGSize, bridge: ScavengerBridge) {
        let rect = CGRect(origin: .zero, size: size)
        let isBoss = bridge.isHackedBossMode()

        // Cyber grid gradient
        let topCol = isBoss ? Color(red: 0.18, green: 0.02, blue: 0.05) : Color(red: 0.02, green: 0.05, blue: 0.12)
        let botCol = isBoss ? Color(red: 0.08, green: 0.01, blue: 0.02) : Color(red: 0.01, green: 0.02, blue: 0.06)

        context.fill(Path(rect), with: .linearGradient(
            Gradient(colors: [topCol, botCol]),
            startPoint: .zero,
            endPoint: CGPoint(x: 0, y: size.height)
        ))

        // Parallax stars
        for i in 0..<24 {
            let px = (CGFloat(i * 47) + CGFloat(bridge.getScore() % 500) * 0.1).truncatingRemainder(dividingBy: size.width)
            let py = CGFloat(i * 37).truncatingRemainder(dividingBy: size.height)
            let starRect = CGRect(x: px, y: py, width: 2, height: 2)
            context.fill(Path(ellipseIn: starRect), with: .color(.white.opacity(0.6)))
        }
    }

    private func drawBase(context: GraphicsContext, size: CGSize, bridge: ScavengerBridge) {
        let baseStage = bridge.getBaseStage()
        let baseH: CGFloat = 28.0
        let baseRect = CGRect(x: 0, y: size.height - baseH, width: size.width, height: baseH)

        let baseColor = Color(red: 0.05, green: 0.12, blue: 0.22)
        context.fill(Path(baseRect), with: .color(baseColor))

        // Neon outline
        var borderPath = Path()
        borderPath.move(to: CGPoint(x: 0, y: size.height - baseH))
        borderPath.addLine(to: CGPoint(x: size.width, y: size.height - baseH))
        context.stroke(borderPath, with: .color(.cyan.opacity(0.8)), lineWidth: 2)

        // Stage lights
        for s in 0...4 {
            let lx = size.width * CGFloat(s + 1) / 6.0
            let ly = size.height - baseH + 12
            let dotRect = CGRect(x: lx - 4, y: ly - 4, width: 8, height: 8)
            let isLit = s <= baseStage
            context.fill(Path(ellipseIn: dotRect), with: .color(isLit ? .cyan : .gray.opacity(0.3)))
        }
    }

    private func drawDebris(context: GraphicsContext, size: CGSize, bridge: ScavengerBridge) {
        let count = bridge.getActiveDebrisCount()
        for idx in 0..<count {
            let d = bridge.getDebris(at: idx)
            if d.state != 0 && d.state != 3 { continue }

            let dx = CGFloat(d.x) * size.width
            let dy = CGFloat(d.y) * size.height
            let radius = CGFloat(d.size) * size.width * 0.5
            let dRect = CGRect(x: dx - radius, y: dy - radius, width: radius * 2, height: radius * 2)

            switch d.type {
            case 6: // Corrupted Glitch Bomb
                context.fill(Path(ellipseIn: dRect), with: .color(.red))
                context.stroke(Path(ellipseIn: dRect), with: .color(.yellow), lineWidth: 2)
            case 5: // Nano Shield Core
                context.fill(Path(ellipseIn: dRect), with: .color(.green))
                context.stroke(Path(ellipseIn: dRect), with: .color(.white), lineWidth: 2)
            case 7: // Deflected Counter-Bomb
                context.fill(Path(ellipseIn: dRect), with: .color(.orange))
                context.stroke(Path(ellipseIn: dRect), with: .color(.white), lineWidth: 2)
            case 4: // Rare Golden Console
                context.fill(Path(ellipseIn: dRect), with: .color(red: 1.0, green: 0.84, blue: 0.0))
            default: // Relics 0..3
                context.fill(Path(ellipseIn: dRect), with: .color(.cyan))
                context.stroke(Path(ellipseIn: dRect), with: .color(.blue), lineWidth: 1.5)
            }
        }
    }

    private func drawEcho(context: GraphicsContext, size: CGSize, bridge: ScavengerBridge) {
        let vx = CGFloat(bridge.getVesselPosition()) * size.width
        let vy = size.height * 0.86
        let echoW: CGFloat = 46.0
        let echoH: CGFloat = 38.0

        let bodyRect = CGRect(x: vx - echoW * 0.5, y: vy - echoH * 0.5, width: echoW, height: echoH)

        // Custom optical armor color if unlocked via photo
        let armorColor = Color(hex: hardware.shieldArmorColorHex)

        // Outer Hull
        context.fill(Path(roundedRect: bodyRect, cornerRadius: 14), with: .color(armorColor))
        context.stroke(Path(roundedRect: bodyRect, cornerRadius: 14), with: .color(.white.opacity(0.8)), lineWidth: 2)

        // Holodome Visor
        let visorRect = CGRect(x: vx - 16, y: vy - 10, width: 32, height: 16)
        context.fill(Path(roundedRect: visorRect, cornerRadius: 8), with: .color(Color(red: 0.05, green: 0.1, blue: 0.2)))

        // Glowing Visor Eyes
        let leftEye = CGRect(x: vx - 10, y: vy - 4, width: 6, height: 6)
        let rightEye = CGRect(x: vx + 4, y: vy - 4, width: 6, height: 6)
        context.fill(Path(ellipseIn: leftEye), with: .color(.cyan))
        context.fill(Path(ellipseIn: rightEye), with: .color(.cyan))

        // Magnetic Pulse Aura if active
        if bridge.getMagneticPulseCooldown() > 0.0 {
            let cdPct = CGFloat(bridge.getMagneticPulseCooldown() / 1.45)
            let auraRadius = echoW * (1.0 + (1.0 - cdPct) * 0.5)
            let auraRect = CGRect(x: vx - auraRadius, y: vy - auraRadius, width: auraRadius * 2, height: auraRadius * 2)
            context.stroke(Path(ellipseIn: auraRect), with: .color(.cyan.opacity(Double(1.0 - cdPct))), lineWidth: 2.5)
        }
    }

    private func drawBoss(context: GraphicsContext, size: CGSize, bridge: ScavengerBridge, dt: Float) {
        let bx = CGFloat(bridge.getBossX()) * size.width
        let by = size.height * 0.16
        let bossW: CGFloat = 80.0
        let bossH: CGFloat = 46.0

        let bossRect = CGRect(x: bx - bossW * 0.5, y: by - bossH * 0.5, width: bossW, height: bossH)

        // Hit flash effect
        let bossColor = bossHitFlashTimer > 0.0 ? Color.white : (bridge.getBossStage() == 2 ? Color.red : Color.purple)

        context.fill(Path(roundedRect: bossRect, cornerRadius: 12), with: .color(bossColor))
        context.stroke(Path(roundedRect: bossRect, cornerRadius: 12), with: .color(.yellow), lineWidth: 2.5)

        // Boss Eyes / Core
        let coreRect = CGRect(x: bx - 12, y: by - 8, width: 24, height: 16)
        context.fill(Path(ellipseIn: coreRect), with: .color(.yellow))

        // Laser beam if firing
        if bossLaserBeamTimer > 0.0 {
            var laserBeam = Path()
            let vesselX = CGFloat(bridge.getVesselPosition()) * size.width
            let vesselY = size.height * 0.86
            laserBeam.move(to: CGPoint(x: vesselX, y: vesselY - 20))
            laserBeam.addLine(to: CGPoint(x: bx, y: by + 20))
            context.stroke(laserBeam, with: .color(.cyan), lineWidth: 3.5)
        }
    }

    private func drawHUD(context: GraphicsContext, size: CGSize, bridge: ScavengerBridge) {
        // Shield Bar (Top Left)
        let shield = CGFloat(bridge.getShield()).clamped(to: 0...100)
        let barW: CGFloat = 140.0
        let barH: CGFloat = 12.0
        let bgRect = CGRect(x: 18, y: 52, width: barW, height: barH)
        let fgRect = CGRect(x: 18, y: 52, width: barW * (shield / 100.0), height: barH)

        context.fill(Path(roundedRect: bgRect, cornerRadius: 4), with: .color(.gray.opacity(0.4)))
        context.fill(Path(roundedRect: fgRect, cornerRadius: 4), with: .color(shield < 30 ? .red : .green))
        context.stroke(Path(roundedRect: bgRect, cornerRadius: 4), with: .color(.white), lineWidth: 1)

        // Boss Bar (Top Center if in Boss Mode: 420 Max HP per phase)
        if bridge.isHackedBossMode() {
            let maxHp: CGFloat = 420.0
            let hp = CGFloat(bridge.getBossHp()).clamped(to: 0...maxHp)
            let bossBarW: CGFloat = size.width - 120
            let bossBarRect = CGRect(x: 60, y: 78, width: bossBarW, height: 10)
            let bossFgRect = CGRect(x: 60, y: 78, width: bossBarW * (hp / maxHp), height: 10)

            context.fill(Path(roundedRect: bossBarRect, cornerRadius: 3), with: .color(.gray.opacity(0.4)))
            context.fill(Path(roundedRect: bossFgRect, cornerRadius: 3), with: .color(.red))
            context.stroke(Path(roundedRect: bossBarRect, cornerRadius: 3), with: .color(.yellow), lineWidth: 1)
        }
    }

    private func drawFloatingTexts(context: GraphicsContext, dt: Float) {
        for textItem in floatingTexts {
            let text = Text(textItem.text).font(.system(size: 16, weight: .bold)).foregroundColor(textItem.color.opacity(textItem.alpha))
            context.draw(text, at: CGPoint(x: textItem.x, y: textItem.y))
        }

        // Update alphas and positions
        floatingTexts = floatingTexts.compactMap { item in
            var updated = item
            updated.y -= CGFloat(dt * 35.0)
            updated.alpha -= Double(dt * 1.5)
            return updated.alpha > 0.05 ? updated : nil
        }
    }
}

// Simple Color hex helper
private extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 229, 255)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

private extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        min(max(self, limits.lowerBound), limits.upperBound)
    }
}
