//
//  HardwareTrialsManager.swift
//  Echo: The Scrappy-Bot (iOS Native Edition)
//
//  Bridges Level 17 & ECHO.EXE 4th-Wall Breaking Hardware Trials on iOS:
//  1. Voile d'Ombre (< 25 lux): Camera / proximity / screen brightness occlusion detection.
//  2. Fanal Stellaire (Torch 45s): AVCaptureDevice torch control.
//  3. Bouclier Thermique (< 5 cm): UIDevice proximity sensor.
//  4. Résonance 432 Hz: Physical volume button observation via AVAudioSession.
//  5. Défragmentation Cinétique: CMMotionManager accelerometer shake detection (> 13 m/s²).
//  6. Bouclier Optique Réel: Real photo captured in RAM, analyzed as 8-bit CRT shield texture.
//

import Foundation
import UIKit
import AVFoundation
import CoreMotion
import Combine

@MainActor
public final class HardwareTrialsManager: ObservableObject {
    public static let shared = HardwareTrialsManager()

    // Published states for SwiftUI
    @Published public var isTorchOn: Bool = false
    @Published public var proximityBlocked: Bool = false
    @Published public var volumePulseCount: Int = 0
    @Published public var shakeCount: Int = 0
    @Published public var ambientDarknessScore: Float = 1.0 // 0.0 (dark) to 1.0 (bright)
    @Published public var capturedShieldBitmap: UIImage? = nil
    @Published public var shieldArmorColorHex: String = "#00E5FF" // Cyan by default

    private let motionManager = CMMotionManager()
    private var volumeObservation: NSKeyValueObservation?
    private var initialVolume: Float = 0.5
    private var lastShakeTime: Date = .distantPast

    private init() {}

    // MARK: - Trial 1: Voile d'Ombre (< 25 lux / Obscurité Totale)
    public func startDarknessMonitoring() {
        UIDevice.current.isProximityMonitoringEnabled = true
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleProximityChange),
            name: UIDevice.proximityStateDidChangeNotification,
            object: nil
        )
        // Also observe screen brightness: when player covers phone or dims room
        self.ambientDarknessScore = Float(UIScreen.main.brightness)
    }

    public func stopDarknessMonitoring() {
        NotificationCenter.default.removeObserver(self, name: UIDevice.proximityStateDidChangeNotification, object: nil)
    }

    @objc private func handleProximityChange() {
        let isClose = UIDevice.current.proximityState
        self.proximityBlocked = isClose
        if isClose {
            self.ambientDarknessScore = 0.02 // Validates Voile d'Ombre immediately!
        }
    }

    // MARK: - Trial 2: Fanal Stellaire (Allumer la Lampe Torche dans les 45s)
    public func toggleTorch(on: Bool) -> Bool {
        guard let device = AVCaptureDevice.default(for: .video), device.hasTorch else {
            return false
        }
        do {
            try device.lockForConfiguration()
            device.torchMode = on ? .on : .off
            device.unlockForConfiguration()
            self.isTorchOn = on
            return true
        } catch {
            print("[HardwareTrialsManager] Torch error: \(error)")
            return false
        }
    }

    // MARK: - Trial 3: Bouclier Thermique (< 5 cm / Couvrir le haut de l'écran)
    public func startThermalShieldMonitoring() {
        UIDevice.current.isProximityMonitoringEnabled = true
        self.proximityBlocked = UIDevice.current.proximityState
    }

    // MARK: - Trial 4: Résonance 432 Hz (Boutons Physiques Volume +/-)
    public func startVolumeMonitoring() {
        let session = AVAudioSession.sharedInstance()
        try? session.setActive(true)
        initialVolume = session.outputVolume
        volumePulseCount = 0

        volumeObservation = session.observe(\.outputVolume, options: [.new]) { [weak self] _, change in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.volumePulseCount += 1
            }
        }
    }

    public func stopVolumeMonitoring() {
        volumeObservation?.invalidate()
        volumeObservation = nil
    }

    // MARK: - Trial 5: Défragmentation Cinétique (Secouer le téléphone 3 fois > 13 m/s²)
    public func startShakeMonitoring() {
        guard motionManager.isAccelerometerAvailable else { return }
        shakeCount = 0
        motionManager.accelerometerUpdateInterval = 1.0 / 60.0

        motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, _ in
            guard let self = self, let data = data else { return }

            // Magnitude in Gs (1.0 = normal Earth gravity ~9.81 m/s²)
            let totalG = sqrt(data.acceleration.x * data.acceleration.x +
                              data.acceleration.y * data.acceleration.y +
                              data.acceleration.z * data.acceleration.z)

            // > 1.35G = > 13.2 m/s² acceleration threshold
            if totalG > 1.35 {
                let now = Date()
                if now.timeIntervalSince(self.lastShakeTime) > 0.45 {
                    self.lastShakeTime = now
                    self.shakeCount += 1
                }
            }
        }
    }

    public func stopShakeMonitoring() {
        motionManager.stopAccelerometerUpdates()
    }

    // MARK: - Trial 6: Bouclier Optique Réel (Photo environnement -> texture CRT)
    public func applyOpticalShieldPhoto(_ image: UIImage) {
        self.capturedShieldBitmap = image

        // Analyze dominant color in image to customize Echo's energy armor
        guard let cgImage = image.cgImage else { return }
        let width = cgImage.width
        let height = cgImage.height

        guard let data = cgImage.dataProvider?.data,
              let ptr = CFDataGetBytePtr(data) else { return }

        var rTotal: Int64 = 0
        var gTotal: Int64 = 0
        var bTotal: Int64 = 0
        let step = max(1, (width * height) / 1000)

        for i in stride(from: 0, to: width * height * 4, by: step * 4) {
            rTotal += Int64(ptr[i])
            gTotal += Int64(ptr[i + 1])
            bTotal += Int64(ptr[i + 2])
        }

        let samples = Int64((width * height) / step)
        let avgR = samples > 0 ? Int(rTotal / samples) : 0
        let avgG = samples > 0 ? Int(gTotal / samples) : 229
        let avgB = samples > 0 ? Int(bTotal / samples) : 255

        if avgG > avgR && avgG > avgB {
            self.shieldArmorColorHex = "#00FF66" // Émeraude Bio-Synthétique
        } else if avgR > avgB {
            self.shieldArmorColorHex = "#FFD700" // Or Solaire Surchargé
        } else {
            self.shieldArmorColorHex = "#00E5FF" // Titane Cyan Pur
        }
    }
}
