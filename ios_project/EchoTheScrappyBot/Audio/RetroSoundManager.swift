//
//  RetroSoundManager.swift
//  Echo: The Scrappy-Bot (iOS Native Edition)
//
//  Real-time 5-Layer DSP Procedural Sound Synthesizer & Spatialized Audio Engine.
//  Uses AVAudioEngine & AVAudioSourceNode for zero-latency 24 kHz 16-bit PCM streaming,
//  plus CoreHaptics / UIImpactFeedbackGenerator for rich physical tactile feedback.
//

import Foundation
import AVFoundation
import UIKit

public final class RetroSoundManager: @unchecked Sendable {
    public static let shared = RetroSoundManager()

    private let sampleRate: Double = 24000.0
    private var audioEngine: AVAudioEngine?
    private var sourceNode: AVAudioSourceNode?

    private var isRunning = false
    private var isBgmPaused = false
    private var activeLevel: Int = 1
    private var echoNormX: Float = 0.5
    private var activeCombo: Int = 1
    private var isBossFight: Bool = false

    // Synthesis phase accumulators
    private var phaseDrone: Double = 0.0
    private var phaseLfo: Double = 0.0
    private var phaseStep: Double = 0.0
    private var stepTick: Int = 0
    private var timeSeconds: Double = 0.0

    // One-shot procedural SFX synthesizer queue
    private struct ActiveSfx {
        var type: Int // 0: capture, 1: bomb, 2: wave, 3: laser, 4: combo, 5: levelUp, 6: bossDefeat
        var sampleIndex: Int
        var totalSamples: Int
        var freqStart: Double
        var freqEnd: Double
        var volume: Float
        var pan: Float
    }
    private var sfxQueue: [ActiveSfx] = []
    private let sfxLock = NSLock()

    // Haptic engines
    private let lightHaptic = UIImpactFeedbackGenerator(style: .light)
    private let mediumHaptic = UIImpactFeedbackGenerator(style: .medium)
    private let heavyHaptic = UIImpactFeedbackGenerator(style: .heavy)
    private let notificationHaptic = UINotificationFeedbackGenerator()

    private init() {
        setupAudioSession()
        prepareHaptics()
    }

    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.ambient, mode: .gameChat, options: [.mixWithOthers])
            try session.setPreferredSampleRate(sampleRate)
            try session.setActive(true)
        } catch {
            print("[RetroSoundManager] AudioSession setup error: \(error)")
        }
    }

    private func prepareHaptics() {
        lightHaptic.prepare()
        mediumHaptic.prepare()
        heavyHaptic.prepare()
        notificationHaptic.prepare()
    }

    public func start() {
        guard !isRunning else { return }

        let engine = AVAudioEngine()
        self.audioEngine = engine

        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2)!

        let node = AVAudioSourceNode { [weak self] _, _, frameCount, audioBufferList -> OSStatus in
            guard let self = self else { return noErr }
            let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)

            let left = ablPointer[0].mData?.assumingMemoryBound(to: Float.self)
            let right = ablPointer[1].mData?.assumingMemoryBound(to: Float.self)

            for frame in 0..<Int(frameCount) {
                let (lSample, rSample) = self.renderFrame()
                left?[frame] = lSample
                right?[frame] = rSample
            }

            return noErr
        }

        self.sourceNode = node
        engine.attach(node)
        engine.connect(node, to: engine.mainMixerNode, format: format)

        do {
            try engine.start()
            isRunning = true
        } catch {
            print("[RetroSoundManager] Failed to start engine: \(error)")
        }
    }

    public func stop() {
        audioEngine?.stop()
        isRunning = false
    }

    public func setPaused(_ paused: Bool) {
        isBgmPaused = paused
    }

    public func setTelemetry(level: Int, normX: Float, combo: Int, isBoss: Bool) {
        self.activeLevel = level
        self.echoNormX = normX
        self.activeCombo = combo
        self.isBossFight = isBoss
    }

    // MARK: - Frame Synthesis DSP
    private func renderFrame() -> (Float, Float) {
        guard isRunning && !isBgmPaused else { return (0, 0) }

        timeSeconds += 1.0 / sampleRate
        phaseLfo += 2.0 * .pi * 0.18 / sampleRate
        if phaseLfo > 2.0 * .pi { phaseLfo -= 2.0 * .pi }

        // 1. Couche 0 : Drone Harmonique
        let baseFreq = isBossFight ? 48.0 : (55.0 + Double(activeLevel % 5) * 5.0)
        let lfoMod = 1.0 + 0.08 * sin(phaseLfo)
        phaseDrone += 2.0 * .pi * (baseFreq * lfoMod) / sampleRate
        if phaseDrone > 2.0 * .pi { phaseDrone -= 2.0 * .pi }

        let droneSample = Float(sin(phaseDrone) * 0.45 + sin(phaseDrone * 1.5) * 0.25) * 0.12

        // 2. Couche 1 : Rythme 16-step Synthwave
        let bpm = isBossFight ? 134.0 : 120.0
        let samplesPerStep = Int((sampleRate * 60.0) / (bpm * 4.0))
        stepTick += 1
        var synthwaveSample: Float = 0.0
        if (stepTick % samplesPerStep) < (samplesPerStep / 4) {
            let stepPhase = Double(stepTick % samplesPerStep) / Double(samplesPerStep)
            let decay = Float(exp(-stepPhase * 8.0))
            synthwaveSample = Float(sin(Double(stepTick) * 0.08)) * decay * 0.08
        }

        // 3. Couche 4 : Mixage One-Shot SFX
        var sfxL: Float = 0.0
        var sfxR: Float = 0.0

        sfxLock.lock()
        var i = 0
        while i < sfxQueue.count {
            var sfx = sfxQueue[i]
            let progress = Double(sfx.sampleIndex) / Double(sfx.totalSamples)
            let currentFreq = sfx.freqStart + (sfx.freqEnd - sfx.freqStart) * progress
            let sampleVal = Float(sin(2.0 * .pi * currentFreq * Double(sfx.sampleIndex) / sampleRate))
            let env = Float(1.0 - progress)

            let gain = sampleVal * env * sfx.volume
            let panL = (1.0 - sfx.pan) * 0.5 + 0.5
            let panR = sfx.pan * 0.5 + 0.5

            sfxL += gain * panL
            sfxR += gain * panR

            sfx.sampleIndex += 1
            if sfx.sampleIndex >= sfx.totalSamples {
                sfxQueue.remove(at: i)
            } else {
                sfxQueue[i] = sfx
                i += 1
            }
        }
        sfxLock.unlock()

        let masterL = (droneSample + synthwaveSample + sfxL).clamped(to: -1.0...1.0)
        let masterR = (droneSample + synthwaveSample + sfxR).clamped(to: -1.0...1.0)

        return (masterL, masterR)
    }

    // MARK: - Procedural SFX Triggers
    public func playCapture(type: Int, combo: Int, normX: Float) {
        let baseF = 440.0 + Double(type * 60) + Double(min(combo, 10) * 35)
        enqueueSfx(ActiveSfx(
            type: 0,
            sampleIndex: 0,
            totalSamples: Int(sampleRate * 0.18),
            freqStart: baseF,
            freqEnd: baseF * 1.5,
            volume: 0.35,
            pan: (normX - 0.5) * 1.6
        ))
        lightHaptic.impactOccurred()
    }

    public func playBombHit(normX: Float) {
        enqueueSfx(ActiveSfx(
            type: 1,
            sampleIndex: 0,
            totalSamples: Int(sampleRate * 0.45),
            freqStart: 180.0,
            freqEnd: 35.0,
            volume: 0.65,
            pan: (normX - 0.5) * 1.6
        ))
        heavyHaptic.impactOccurred()
    }

    public func playMagneticWave() {
        enqueueSfx(ActiveSfx(
            type: 2,
            sampleIndex: 0,
            totalSamples: Int(sampleRate * 0.32),
            freqStart: 220.0,
            freqEnd: 880.0,
            volume: 0.50,
            pan: 0.0
        ))
        mediumHaptic.impactOccurred()
    }

    public func playLaserShot() {
        enqueueSfx(ActiveSfx(
            type: 3,
            sampleIndex: 0,
            totalSamples: Int(sampleRate * 0.22),
            freqStart: 960.0,
            freqEnd: 240.0,
            volume: 0.45,
            pan: 0.0
        ))
        lightHaptic.impactOccurred()
    }

    public func playCombo(combo: Int) {
        let pitch = 523.25 * pow(1.05946, Double(combo % 12))
        enqueueSfx(ActiveSfx(
            type: 4,
            sampleIndex: 0,
            totalSamples: Int(sampleRate * 0.25),
            freqStart: pitch,
            freqEnd: pitch * 1.2,
            volume: 0.38,
            pan: 0.0
        ))
    }

    public func playNewRecord() {
        enqueueSfx(ActiveSfx(
            type: 5,
            sampleIndex: 0,
            totalSamples: Int(sampleRate * 0.8),
            freqStart: 587.33,
            freqEnd: 1174.66,
            volume: 0.60,
            pan: 0.0
        ))
        notificationHaptic.notificationOccurred(.success)
    }

    public func playBossPhase2() {
        enqueueSfx(ActiveSfx(
            type: 6,
            sampleIndex: 0,
            totalSamples: Int(sampleRate * 1.2),
            freqStart: 90.0,
            freqEnd: 360.0,
            volume: 0.70,
            pan: 0.0
        ))
        heavyHaptic.impactOccurred()
    }

    public func playBossDefeated() {
        enqueueSfx(ActiveSfx(
            type: 6,
            sampleIndex: 0,
            totalSamples: Int(sampleRate * 2.0),
            freqStart: 220.0,
            freqEnd: 880.0,
            volume: 0.85,
            pan: 0.0
        ))
        notificationHaptic.notificationOccurred(.success)
    }

    public func playClick() {
        lightHaptic.impactOccurred()
    }

    private func enqueueSfx(_ sfx: ActiveSfx) {
        sfxLock.lock()
        if sfxQueue.count < 12 {
            sfxQueue.append(sfx)
        }
        sfxLock.unlock()
    }
}

private extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        min(max(self, limits.lowerBound), limits.upperBound)
    }
}
