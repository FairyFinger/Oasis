//
//  ScoreManager.swift
//  Echo: The Scrappy-Bot (iOS Native Edition)
//
//  UserDefaults persistence for game progress, High Scores, True Ending,
//  Difficulty Mode, and uninterrupted Auto-Save sessions.
//

import Foundation

public struct SavedSession: Codable {
    public var level: Int
    public var score: Int
    public var shield: Int
    public var combo: Int
    public var maxCombo: Int
    public var baseStage: Int
    public var isFreeModeNPlusOne: Bool
    public var isHackedBossMode: Bool
    public var bossHp: Int
    public var bossStage: Int
    public var isMetaTakeover: Bool
    public var metaChatStage: Int
}

public final class ScoreManager {
    public static let shared = ScoreManager()

    private let defaults = UserDefaults.standard
    private let keyHighScore = "echo_high_score"
    private let keyMaxCombo = "echo_max_combo"
    private let keyTotalGames = "echo_total_games"
    private let keyDifficulty = "echo_difficulty_mode"
    private let keyCaptainName = "echo_captain_name"
    private let keyTrueEnding = "echo_true_ending_unlocked"
    private let keyNPlusOne = "echo_n_plus_one_unlocked"
    private let keySavedSession = "echo_saved_game_session"

    private init() {}

    public func getHighScore() -> Int {
        defaults.integer(forKey: keyHighScore)
    }

    public func getMaxCombo() -> Int {
        defaults.integer(forKey: keyMaxCombo)
    }

    public func recordScore(score: Int, combo: Int) -> Bool {
        let currentHigh = getHighScore()
        let currentCombo = getMaxCombo()
        var isNewRecord = false

        if score > currentHigh {
            defaults.set(score, forKey: keyHighScore)
            isNewRecord = true
        }
        if combo > currentCombo {
            defaults.set(combo, forKey: keyMaxCombo)
        }
        let games = defaults.integer(forKey: keyTotalGames) + 1
        defaults.set(games, forKey: keyTotalGames)

        return isNewRecord
    }

    public func getDifficultyMode() -> Int {
        defaults.integer(forKey: keyDifficulty)
    }

    public func setDifficultyMode(_ mode: Int) {
        defaults.set(max(0, min(2, mode)), forKey: keyDifficulty)
    }

    public func getCaptainName() -> String {
        defaults.string(forKey: keyCaptainName) ?? "Capitaine"
    }

    public func setCaptainName(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        defaults.set(trimmed.isEmpty ? "Capitaine" : trimmed, forKey: keyCaptainName)
    }

    public func isTrueEndingUnlocked() -> Bool {
        defaults.bool(forKey: keyTrueEnding)
    }

    public func unlockTrueEnding() {
        defaults.set(true, forKey: keyTrueEnding)
        defaults.set(true, forKey: keyNPlusOne)
    }

    public func isNPlusOneUnlocked() -> Bool {
        defaults.bool(forKey: keyNPlusOne)
    }

    // Auto-Save active game session
    public func saveSession(_ session: SavedSession) {
        if let data = try? JSONEncoder().encode(session) {
            defaults.set(data, forKey: keySavedSession)
        }
    }

    public func getSavedSession() -> SavedSession? {
        guard let data = defaults.data(forKey: keySavedSession),
              let session = try? JSONDecoder().decode(SavedSession.self, from: data) else {
            return nil
        }
        return session
    }

    public func clearSavedSession() {
        defaults.removeObject(forKey: keySavedSession)
    }
}
