//
//  ContentView.swift
//  Echo: The Scrappy-Bot (iOS Native Edition)
//
//  Main Navigation Controller handling Menu, 60 FPS Arcade Gameplay,
//  Level 17 ECHO.EXE Hardware Terminal, and True Ending Epilogue.
//

import SwiftUI

public final class EngineBridgeHolder: ObservableObject {
    public let bridge: ScavengerBridge

    public init() {
        self.bridge = ScavengerBridge(maxDebris: 200)
    }
}

public struct ContentView: View {
    @StateObject private var bridgeHolder = EngineBridgeHolder()
    @State private var isPlaying: Bool = false
    @State private var isMetaTakeoverActive: Bool = false
    @State private var isGameOver: Bool = false
    @State private var isTrueEnding: Bool = false
    @State private var showingSettings: Bool = false

    @State private var currentHighScore: Int = 0
    @State private var captainName: String = ""
    @State private var difficultyMode: Int = 1

    public var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if isPlaying {
                RetroGameView(
                    bridgeHolder: bridgeHolder,
                    isMetaTakeoverActive: $isMetaTakeoverActive,
                    isGameOver: $isGameOver,
                    isTrueEnding: $isTrueEnding
                )
                .ignoresSafeArea()

                // Overlay Terminal if Level 17 ANR triggered
                if isMetaTakeoverActive {
                    TerminalView(isMetaTakeoverActive: $isMetaTakeoverActive) {
                        // Resumes gameplay directly into Level 17 Hacked Boss Mode!
                        bridgeHolder.bridge.setHackedBossMode(true)
                        bridgeHolder.bridge.setPaused(false)
                    }
                    .transition(.opacity)
                }

                // Game Over Overlay
                if isGameOver {
                    gameOverOverlay
                        .transition(.scale)
                }

                // True Ending Overlay
                if isTrueEnding {
                    trueEndingOverlay
                        .transition(.opacity)
                }
            } else {
                mainMenu
                    .transition(.opacity)
            }
        }
        .onAppear {
            loadState()
        }
    }

    // MARK: - Main Menu
    private var mainMenu: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 8) {
                Text("ECHO")
                    .font(.system(size: 44, weight: .black, design: .monospaced))
                    .foregroundColor(.cyan)
                    .shadow(color: .cyan.opacity(0.8), radius: 10)

                Text("THE SCRAPPY-BOT")
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .tracking(4)

                Text("ÉDITION NATIVE IPHONE")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(.yellow)
            }

            Spacer()

            VStack(spacing: 16) {
                Button(action: startNewGame) {
                    Text("NOUVELLE MISSION")
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.cyan)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 40)

                if let saved = ScoreManager.shared.getSavedSession() {
                    Button(action: resumeSavedGame) {
                        Text("REPRENDRE (NIV. \(saved.level))")
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.green.opacity(0.8))
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 40)
                }

                HStack(spacing: 20) {
                    VStack {
                        Text("MEILLEUR SCORE")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.gray)
                        Text("\(currentHighScore)")
                            .font(.system(size: 18, weight: .bold, design: .monospaced))
                            .foregroundColor(.yellow)
                    }

                    VStack {
                        Text("DIFFICULTÉ")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.gray)
                        Text(difficultyMode == 0 ? "FACILE" : (difficultyMode == 1 ? "MOYEN" : "EXPERT"))
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(.cyan)
                    }
                }
                .padding(.top, 12)
            }

            Spacer()

            Text("Design & Code © Antigravity & Le Capitaine")
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.gray.opacity(0.6))
                .padding(.bottom, 20)
        }
    }

    // MARK: - Game Over & True Ending
    private var gameOverOverlay: some View {
        ZStack {
            Color.black.opacity(0.85).ignoresSafeArea()

            VStack(spacing: 20) {
                Text("BOUCLIER ÉPUISÉ")
                    .font(.system(size: 28, weight: .black, design: .monospaced))
                    .foregroundColor(.red)

                Text("Score Final : \(bridgeHolder.bridge.getScore())")
                    .font(.system(size: 18, design: .monospaced))
                    .foregroundColor(.white)

                Button("RÉESSAYER") {
                    startNewGame()
                }
                .buttonStyle(.borderedProminent)
                .tint(.cyan)

                Button("MENU PRINCIPAL") {
                    isGameOver = false
                    isPlaying = false
                    loadState()
                }
                .buttonStyle(.bordered)
                .tint(.gray)
            }
        }
    }

    private var trueEndingOverlay: some View {
        ZStack {
            Color.black.opacity(0.92).ignoresSafeArea()

            VStack(spacing: 22) {
                Text("VICTOIRE ABSOLUE !")
                    .font(.system(size: 26, weight: .black, design: .monospaced))
                    .foregroundColor(.yellow)

                Text("Le Méca-Titan a implosé. L'Oasis Silicium est sauvée. Écho vous remet la couronne du Capitaine.")
                    .font(.system(size: 14, design: .monospaced))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
                    .padding(.horizontal, 30)

                Button("ÉPINGLER LE WIDGET & RETOURNER AU MENU") {
                    ScoreManager.shared.unlockTrueEnding()
                    isTrueEnding = false
                    isPlaying = false
                    loadState()
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
            }
        }
    }

    // MARK: - Game Lifecycle
    private func loadState() {
        currentHighScore = ScoreManager.shared.getHighScore()
        captainName = ScoreManager.shared.getCaptainName()
        difficultyMode = ScoreManager.shared.getDifficultyMode()
    }

    private func startNewGame() {
        isGameOver = false
        isTrueEnding = false
        isMetaTakeoverActive = false

        let bridge = bridgeHolder.bridge
        bridge.setDifficultyMode(Int32(difficultyMode))
        bridge.setHighScore(Int32(currentHighScore))
        bridge.reset(withFullUnlocked: ScoreManager.shared.isTrueEndingUnlocked())
        bridge.setPaused(false)

        isPlaying = true
    }

    private func resumeSavedGame() {
        guard let saved = ScoreManager.shared.getSavedSession() else { return }
        isGameOver = false
        isTrueEnding = false
        isMetaTakeoverActive = false

        let bridge = bridgeHolder.bridge
        bridge.setDifficultyMode(Int32(difficultyMode))
        bridge.setHighScore(Int32(currentHighScore))
        bridge.restoreSession(
            withLevel: Int32(saved.level),
            score: Int32(saved.score),
            shield: Int32(saved.shield),
            combo: Int32(saved.combo),
            maxCombo: Int32(saved.maxCombo),
            baseStage: Int32(saved.baseStage),
            fullUnlocked: saved.isFreeModeNPlusOne,
            isHackedBossMode: saved.isHackedBossMode,
            bossHp: Int32(saved.bossHp),
            bossStage: Int32(saved.bossStage)
        )
        bridge.setPaused(false)

        isPlaying = true
    }
}
