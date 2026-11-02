//
//  TerminalView.swift
//  Echo: The Scrappy-Bot (iOS Native Edition)
//
//  Level 17 Cyber-Diegetic Terminal (ECHO.EXE) & 6 Physical Hardware Trials.
//  Uses AVSpeechSynthesizer for Echo's robotic vocoded voice in all 12 languages.
//

import SwiftUI
import AVFoundation

public struct TerminalView: View {
    @ObservedObject var hardware = HardwareTrialsManager.shared
    @Binding var isMetaTakeoverActive: Bool
    let onCompleteTrials: () -> Void

    @State private var terminalLines: [String] = []
    @State private var currentStage: Int = 1
    @State private var speechSynth = AVSpeechSynthesizer()
    @State private var isShowingCamera = false

    public init(isMetaTakeoverActive: Binding<Bool>, onCompleteTrials: @escaping () -> Void) {
        self._isMetaTakeoverActive = isMetaTakeoverActive
        self.onCompleteTrials = onCompleteTrials
    }

    public var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    Text("ECHO.EXE — TERMINAL DE SECOURS v2.4")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(.green)
                    Spacer()
                    Text("SEC: LEVEL 17")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.yellow)
                }
                .padding(.horizontal)
                .padding(.top, 40)

                Divider().background(Color.green.opacity(0.6))

                // Terminal Log
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(Array(terminalLines.enumerated()), id: \.offset) { idx, line in
                                Text(line)
                                    .font(.system(size: 14, design: .monospaced))
                                    .foregroundColor(line.contains("FAIL") ? .red : (line.contains("SUCCESS") ? .green : .cyan))
                                    .id(idx)
                            }
                        }
                        .padding()
                    }
                    .onChange(of: terminalLines.count) { _ in
                        proxy.scrollTo(terminalLines.count - 1)
                    }
                }

                Spacer()

                // Trial Controls & Feedback
                trialControlPanel
                    .padding()
            }
        }
        .onAppear {
            startTerminalSequence()
        }
        .onDisappear {
            hardware.stopDarknessMonitoring()
            hardware.stopVolumeMonitoring()
            hardware.stopShakeMonitoring()
        }
    }

    @ViewBuilder
    private var trialControlPanel: some View {
        VStack(spacing: 14) {
            switch currentStage {
            case 1:
                // Trial 1: Voile d'Ombre (< 25 lux)
                Text(EchoLocalization.getTrial1Prompt())
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(.white)
                if hardware.proximityBlocked || hardware.ambientDarknessScore < 0.15 {
                    Button("VALIDER LE CAMOUFLAGE") {
                        advanceStage(successText: "[SUCCESS] Voile d'ombre actif. Détection orbitale éludée.")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                }

            case 2:
                // Trial 2: Fanal Stellaire (Torch)
                Text(EchoLocalization.getTrial2Prompt())
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(.white)
                Button(hardware.isTorchOn ? "ÉTEINDRE LA TORCHE" : "ALLUMER LA TORCHE") {
                    let next = !hardware.isTorchOn
                    _ = hardware.toggleTorch(on: next)
                    if next {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            advanceStage(successText: "[SUCCESS] Matrice optique du Traqueur saturée !")
                            _ = hardware.toggleTorch(on: false)
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.yellow)

            case 3:
                // Trial 3: Bouclier Thermique (Proximity < 5 cm)
                Text(EchoLocalization.getTrial3Prompt())
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(.white)
                if hardware.proximityBlocked {
                    Button("VERROUILLER LE BOUCLIER") {
                        advanceStage(successText: "[SUCCESS] Scan thermique bloqué par la main du Capitaine.")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                }

            case 4:
                // Trial 4: Résonance 432 Hz (Volume Buttons)
                Text(EchoLocalization.getTrial4Prompt())
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(.white)
                Text("PULSATIONS : \(hardware.volumePulseCount) / 3")
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(.cyan)
                if hardware.volumePulseCount >= 3 {
                    Button("HARMONISER LES ONDES") {
                        advanceStage(successText: "[SUCCESS] Noyau acoustique accordé à 432 Hz.")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                }

            case 5:
                // Trial 5: Défragmentation Cinétique (Shake)
                Text(EchoLocalization.getTrial5Prompt())
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(.white)
                Text("SECOUSSES : \(hardware.shakeCount) / 3")
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(.orange)
                if hardware.shakeCount >= 3 {
                    Button("DÉVERROUILLER LA RAM") {
                        advanceStage(successText: "[SUCCESS] Verrous corrompus brisés par inertie.")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                }

            case 6:
                // Trial 6: Bouclier Optique Réel (Photo)
                Text(EchoLocalization.getTrial6Prompt())
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(.white)
                Button("PRENDRE LA PHOTO DU BOUCLIER") {
                    isShowingCamera = true
                }
                .buttonStyle(.borderedProminent)
                .tint(.cyan)

            default:
                // Final Ready Stage
                Text("TOUTES LES ÉPREUVES SONT COMPLÉTÉES !")
                    .font(.system(size: 15, weight: .bold, design: .monospaced))
                    .foregroundColor(.green)
                Button("AFFRONTER LE MÉCA-TITAN") {
                    onCompleteTrials()
                    isMetaTakeoverActive = false
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
            }
        }
    }

    private func startTerminalSequence() {
        appendLine("INITIALISATION DU CANAL DIRECT...")
        appendLine("Écho : 'Capitaine ! Le Traqueur a gelé mon noyau...'")
        speak("Capitaine ! Le Traqueur a gelé mon noyau... Aidez-moi !")

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            hardware.startDarknessMonitoring()
            hardware.startVolumeMonitoring()
            hardware.startShakeMonitoring()
            appendLine("ÉPREUVE 1 ENCLENCHÉE.")
        }
    }

    private func advanceStage(successText: String) {
        appendLine(successText)
        currentStage += 1
        RetroSoundManager.shared.playClick()

        switch currentStage {
        case 2:
            speak("Allumez votre torche ! Aveuglez ses capteurs !")
        case 3:
            speak("Posez votre main au-dessus de l'écran pour me protéger !")
        case 4:
            speak("Appuyez 3 fois sur vos boutons de volume !")
        case 5:
            speak("Secouez le téléphone pour briser les verrous !")
        case 6:
            speak("Prenez une photo de votre environnement pour mon armure !")
        case 7:
            speak("Tous les systèmes sont en ligne ! Nous pouvons vaincre le Méca-Titan !")
        default:
            break
        }
    }

    private func appendLine(_ text: String) {
        terminalLines.append("> \(text)")
    }

    private func speak(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: Locale.current.language.languageCode?.identifier ?? "fr")
        utterance.pitchMultiplier = 0.75
        utterance.rate = 0.48
        speechSynth.speak(utterance)
    }
}
