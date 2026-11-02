#ifndef SPACESCAVENGER_SCAVENGERENGINE_H
#define SPACESCAVENGER_SCAVENGERENGINE_H

#include "ScavengerDebris.h"
#include <vector>
#include <mutex>
#include <random>

namespace spacescavenger {

class ScavengerEngine {
public:
    explicit ScavengerEngine(size_t maxDebris = 200);
    ~ScavengerEngine() = default;

    void setVesselPosition(float normX);
    [[nodiscard]] float getVesselPosition() const { return m_vesselX; }

    void step(float deltaTime);
    void reset(bool fullUnlocked = false);
    void restoreSession(
        int32_t level,
        int32_t score,
        int32_t shield,
        int32_t combo,
        int32_t maxCombo,
        int32_t baseStage,
        bool fullUnlocked,
        bool isHackedBossMode,
        int32_t bossHp,
        int32_t bossStage
    );
    void clearDebris();

    // Pause Control
    void setPaused(bool paused);
    [[nodiscard]] bool isPaused() const { return m_isPaused; }

    // Dev Level Selector
    void setDevLevel(int32_t level);

    // High Score Context
    void setHighScore(int32_t highScore);

    // Audio & Dynamic Feedback Event Flags
    [[nodiscard]] int32_t pollCapturedItemType();
    [[nodiscard]] bool pollBombExplosionEvent();
    [[nodiscard]] bool pollBaseTierUpgradedEvent();
    [[nodiscard]] bool pollCaptureSoundEvent();
    [[nodiscard]] bool pollDamageSoundEvent();
    [[nodiscard]] bool pollNewRecordSoundEvent();
    [[nodiscard]] bool pollComboSoundEvent();
    [[nodiscard]] float getGlitchIntensity() const;
    [[nodiscard]] bool pollMetaTakeoverEvent();
    [[nodiscard]] bool pollSecretGhostWallEvent();
    [[nodiscard]] bool pollDodgeBonusEvent();
    [[nodiscard]] bool pollSuperVacuumEvent();

    // Stats, Base Building & Gameplay State
    [[nodiscard]] int32_t getScore() const { return m_score; }
    [[nodiscard]] int32_t getShield() const { return m_shield; }
    [[nodiscard]] int32_t getLevel() const { return m_level; }
    [[nodiscard]] int32_t getBaseStage() const { return m_baseStage; }
    [[nodiscard]] int32_t getNextStageScore() const;
    [[nodiscard]] int32_t getCombo() const { return m_comboCount; }
    [[nodiscard]] int32_t getMaxCombo() const { return m_maxCombo; }
    [[nodiscard]] bool isGameOver() const { return m_shield <= 0; }

    [[nodiscard]] DebrisState* getDebrisBufferData() { return m_debrisList.data(); }
    [[nodiscard]] size_t getDebrisBufferByteSize() const { return m_maxDebris * sizeof(DebrisState); }
    [[nodiscard]] size_t getActiveDebrisCount() const { return m_activeCount; }

    void setCinematicMode(bool isCinematic);
    [[nodiscard]] bool isCinematicMode() const { return m_isCinematic; }

    // Part 2 Climax: Hacked Boss Mode (Echo vs Meca-Titan — 2-Stage Epic Battle + Death Cutscene)
    void setHackedBossMode(bool active);
    [[nodiscard]] bool isHackedBossMode() const { return m_isHackedBossMode; }
    [[nodiscard]] int32_t getBossHp() const { return m_bossHp; }
    [[nodiscard]] float getBossX() const { return m_bossX; }
    [[nodiscard]] int32_t getBossPhase() const { return m_bossPhase; }
    [[nodiscard]] int32_t getBossStage() const { return m_bossStage; }
    [[nodiscard]] int32_t getBossLaserCharge() const { return m_bossLaserCharge; }
    [[nodiscard]] int32_t getBossLaserRequiredCharge() const { return (m_bossLaserShotsInCycle >= 3) ? 8 : 4; }
    [[nodiscard]] bool pollBossHitEvent();
    [[nodiscard]] bool pollBossLaserDodgedEvent();
    [[nodiscard]] bool pollBossPhase2TransitionEvent();
    [[nodiscard]] bool pollBossDefeatedEvent();

private:
    bool tryDamageBoss(int32_t damage, bool canDodge);
public:

    // Tactical Magnetic Repulsion Pulse & Active Base Assist Modules
    bool triggerMagneticPulse();
    [[nodiscard]] float getMagneticPulseCooldown() const { return m_pulseCooldown; }
    [[nodiscard]] int32_t pollBaseAssistEvent();
    [[nodiscard]] float getLastAssistX() const { return m_lastAssistX; }
    [[nodiscard]] float getLastAssistY() const { return m_lastAssistY; }

    // Difficulty Mode Controller (0 = Easy, 1 = Medium/Normal, 2 = Hard) & Hardware Fusion Hooks
    // Rebalanced: Easy = former Medium, Medium = former Hard, Hard = brand-new "Nightmare" tier.
    void setDifficultyMode(int32_t mode);
    [[nodiscard]] int32_t getDifficultyMode() const { return m_difficultyMode; }
    // Critical Sectors after mid-campaign (0 = none, 1 = Corrupted Storm, 2 = Magnetic Abyss, 3 = Planet-X Gravity)
    [[nodiscard]] int32_t getCriticalSector() const { return computeCriticalSector(m_level); }
    void setCustomSpeedMultiplier(float multiplier);
    [[nodiscard]] float getCustomSpeedMultiplier() const { return m_customSpeedMultiplier; }
    void setGravityInverted(bool inverted);
    [[nodiscard]] bool isGravityInverted() const { return m_gravityInverted; }
    void triggerEmergencyQuantumShield();
    [[nodiscard]] bool isQuantumShieldActive() const { return m_invulnerableTimer > 0.0f; }
    [[nodiscard]] float getQuantumShieldTimer() const { return m_invulnerableTimer; }
    void transmuteBombsToGold(int32_t count);
    [[nodiscard]] int32_t getTransmuteBombsRemaining() const { return m_transmuteBombsCount; }
    void setPowerOvercharged(bool overcharged);
    [[nodiscard]] bool isPowerOvercharged() const { return m_isPowerOvercharged; }
    void applyOasisBeaconGift(int32_t bonusShield, int32_t bonusScore);

private:
    // Difficulty tuning helpers (indexed by m_difficultyMode, see ScavengerEngine.cpp)
    [[nodiscard]] float difficultySpeed() const;
    [[nodiscard]] int32_t computeCriticalSector(int32_t level) const;
    [[nodiscard]] bool isPostMidCampaign() const { return !m_isHackedBossMode && m_level >= 9; }

    size_t m_maxDebris;
    size_t m_activeCount{0};
    float m_vesselX{0.5f};
    float m_vesselWidth{0.18f};

    int32_t m_score{0};
    int32_t m_highScore{0};
    int32_t m_shield{100};
    int32_t m_level{1};
    int32_t m_baseStage{0}; // 0..4 in-level construction stage
    int32_t m_comboCount{0};
    int32_t m_maxCombo{0};
    static constexpr int32_t BOSS_MAX_HP = 420;
    int32_t m_bossHp{BOSS_MAX_HP};
    float m_bossX{0.5f};
    float m_bossVx{0.26f};
    float m_bossAttackTimer{0.0f};
    int32_t m_bossPhase{1};
    int32_t m_bossStage{1}; // 1: Phase 1 (Blindage Piraté), 2: Phase 2 (Surcharge Abyssale + Esquives Quantiques)
    int32_t m_bossLaserCharge{0};
    int32_t m_bossLaserShotsInCycle{0}; // 0..2: Normal (4 relics/shot), 3: Discharged (requires double resources = 8 relics!)

    bool m_isFullUnlocked{false};
    bool m_isPaused{false};
    bool m_isCinematic{false};
    bool m_isHackedBossMode{false};
    bool m_hasBeatenHighScore{false};

    float m_spawnTimer{0.0f};
    float m_spawnInterval{0.8f};

    int32_t m_lastCapturedType{-1};
    bool m_flagBombExplosion{false};
    bool m_flagBaseUpgraded{false};
    bool m_flagCaptureSound{false};
    bool m_flagDamageSound{false};
    bool m_flagNewRecordSound{false};
    bool m_flagComboSound{false};
    bool m_flagMetaTakeover{false};
    bool m_flagSecretGhostWall{false};
    bool m_flagDodgeBonus{false};
    bool m_flagSuperVacuum{false};
    bool m_flagBossHit{false};
    bool m_flagBossLaserDodged{false};
    bool m_flagBossPhase2Transition{false};
    bool m_flagBossDefeated{false};
    float m_glitchIntensity{0.0f};

    // Tactical Pulse, Active Base Modules, N+1 Mini-Titan Companion & Biome Physics timers
    float m_pulseCooldown{0.0f};
    float m_baseDroneTimer{0.0f};
    float m_baseHealTimer{0.0f};
    float m_baseTurretTimer{0.0f};
    float m_miniTitanTransmuteTimer{0.0f};
    float m_biomeWaveTime{0.0f};
    int32_t m_lastAssistType{0}; // 0: None, 1: Drone Rescue, 2: Shield Regen, 3: Turret Laser, 4: Mini-Titan Gold Transmute
    float m_lastAssistX{0.5f};
    float m_lastAssistY{0.4f};

    // Glitch effect state machine & Level 17 takeover timer
    float m_glitchTimer{0.0f};
    float m_glitchCooldown{0.0f};
    int m_glitchCountThisLevel{0};
    int m_lastGlitchLevel{0};
    float m_level17Elapsed{0.0f};

    // Difficulty Mode (0: Easy, 1: Medium/Normal, 2: Hard) & Hardware Overcharge state
    int32_t m_difficultyMode{1};
    float m_customSpeedMultiplier{1.0f};
    bool m_gravityInverted{false};
    float m_gravityInvertTimer{0.0f};
    float m_invulnerableTimer{0.0f};
    int32_t m_transmuteBombsCount{0};
    bool m_isPowerOvercharged{false};

    std::vector<DebrisState> m_debrisList;
    std::mt19937 m_rng{1337};
    mutable std::mutex m_engineMutex;
};

} // namespace spacescavenger

#endif // SPACESCAVENGER_SCAVENGERENGINE_H
