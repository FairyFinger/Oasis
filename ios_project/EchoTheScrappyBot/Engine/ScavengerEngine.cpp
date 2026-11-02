#include "ScavengerEngine.h"
#include <algorithm>
#include <cmath>

namespace spacescavenger {

ScavengerEngine::ScavengerEngine(size_t maxDebris)
    : m_maxDebris(maxDebris) {
    m_debrisList.resize(maxDebris);
    reset(false);
}

void ScavengerEngine::setVesselPosition(float normX) {
    if (std::isnan(normX) || std::isinf(normX)) return;
    std::lock_guard<std::mutex> lock(m_engineMutex);
    m_vesselX = std::clamp(normX, 0.08f, 0.92f);
}

void ScavengerEngine::setPaused(bool paused) {
    std::lock_guard<std::mutex> lock(m_engineMutex);
    m_isPaused = paused;
}

void ScavengerEngine::setDevLevel(int32_t level) {
    std::lock_guard<std::mutex> lock(m_engineMutex);
    m_level = std::max(1, std::min(level, 17));
    m_score = (m_level - 1) * m_level * 350;
    m_baseStage = 0;
    m_isCinematic = false;
    m_isHackedBossMode = false;
    if (m_level == 17) {
        // Ensure Dev Menu Level 17 always tests the Story Level 17 Meca-Titan trap & ANR takeover
        m_isFullUnlocked = false;
    }
    m_bossHp = BOSS_MAX_HP;
    m_bossX = 0.5f;
    m_bossVx = 0.26f;
    m_bossAttackTimer = 0.0f;
    m_bossPhase = 1;
    m_bossStage = 1;
    m_bossLaserCharge = 0;
    m_bossLaserShotsInCycle = 0;
    m_flagBossHit = false;
    m_flagBossLaserDodged = false;
    m_flagBossPhase2Transition = false;
    m_flagBossDefeated = false;
    m_flagMetaTakeover = false;
    m_glitchIntensity = 0.0f;
    m_glitchTimer = 0.0f;
    m_glitchCountThisLevel = 0;
    m_lastGlitchLevel = m_level - 1;
    m_level17Elapsed = 0.0f;
}

void ScavengerEngine::setHackedBossMode(bool active) {
    std::lock_guard<std::mutex> lock(m_engineMutex);
    m_isHackedBossMode = active;
    if (active) {
        m_bossHp = BOSS_MAX_HP;
        m_bossX = 0.5f;
        m_bossVx = 0.26f;
        m_bossAttackTimer = 0.0f;
        m_bossPhase = 1;
        m_bossStage = 1;
        m_bossLaserCharge = 0;
        m_bossLaserShotsInCycle = 0;
        m_flagBossHit = false;
        m_flagBossLaserDodged = false;
        m_flagBossPhase2Transition = false;
        m_flagBossDefeated = false;
        m_shield = 100;
        m_level = 17;
        m_baseStage = 4;
        if (m_score < 16 * 17 * 350) {
            m_score = 16 * 17 * 350; // Preserve accumulated run score or set Level 17 floor if launched via Dev Menu
        }
        m_activeCount = 0;
        m_isCinematic = false;
        m_isPaused = false;
        m_flagMetaTakeover = false; // Must be false so MainActivity stays in the 8-bit game!
        m_glitchIntensity = 0.10f;
        m_level17Elapsed = 0.0f;
    } else {
        m_glitchIntensity = 0.0f;
    }
}

bool ScavengerEngine::tryDamageBoss(int32_t damage, bool canDodge) {
    // In Stage 2 (Phase 2), the Meca-Titan sometimes performs a Quantum Side-Step to evade Echo's plasma laser!
    if (canDodge && m_bossStage == 2 && m_bossHp > 4) {
        int dodgeChancePct = (m_difficultyMode == 0) ? 32 : ((m_difficultyMode == 1) ? 44 : 54);
        std::uniform_int_distribution<int> dodgeRoll(0, 99);
        if (dodgeRoll(m_rng) < dodgeChancePct) {
            // Boss evades horizontally!
            float step = (m_bossX < 0.5f) ? 0.22f : -0.22f;
            m_bossX = std::clamp(m_bossX + step, 0.18f, 0.82f);
            m_bossVx = -m_bossVx;
            m_flagBossLaserDodged = true;
            return false;
        }
    }

    m_bossHp = std::max(0, m_bossHp - damage);
    m_flagBossHit = true;

    if (m_bossHp <= 0) {
        if (m_bossStage == 1) {
            // PHASE 1 DEFEATED -> TRIGGER PHASE 2 AWAKENING & MESSAGE!
            m_bossStage = 2;
            m_bossHp = BOSS_MAX_HP;
            m_bossPhase = 2;
            m_bossLaserCharge = 0;
            m_bossLaserShotsInCycle = 0;
            m_shield = std::min(100, m_shield + 35); // Tactical shield boost before Phase 2!
            m_bossAttackTimer = 0.0f; // Give breathing room before Phase 2 salvos
            m_flagBossPhase2Transition = true;
        } else if (!m_flagBossDefeated) {
            // PHASE 2 DEFEATED -> FINAL VICTORY!
            m_flagBossDefeated = true;
        }
    }
    return true;
}

bool ScavengerEngine::pollBossHitEvent() {
    std::lock_guard<std::mutex> lock(m_engineMutex);
    bool evt = m_flagBossHit;
    m_flagBossHit = false;
    return evt;
}

bool ScavengerEngine::pollBossLaserDodgedEvent() {
    std::lock_guard<std::mutex> lock(m_engineMutex);
    bool evt = m_flagBossLaserDodged;
    m_flagBossLaserDodged = false;
    return evt;
}

bool ScavengerEngine::pollBossPhase2TransitionEvent() {
    std::lock_guard<std::mutex> lock(m_engineMutex);
    bool evt = m_flagBossPhase2Transition;
    m_flagBossPhase2Transition = false;
    return evt;
}

bool ScavengerEngine::pollBossDefeatedEvent() {
    std::lock_guard<std::mutex> lock(m_engineMutex);
    bool evt = m_flagBossDefeated;
    m_flagBossDefeated = false;
    return evt;
}

void ScavengerEngine::setHighScore(int32_t highScore) {
    std::lock_guard<std::mutex> lock(m_engineMutex);
    m_highScore = highScore;
}

void ScavengerEngine::setCinematicMode(bool isCinematic) {
    std::lock_guard<std::mutex> lock(m_engineMutex);
    m_isCinematic = isCinematic;
    m_activeCount = 0;
    m_spawnTimer = 0.0f;
    m_flagDamageSound = false;
}

void ScavengerEngine::clearDebris() {
    std::lock_guard<std::mutex> lock(m_engineMutex);
    m_activeCount = 0;
}

int32_t ScavengerEngine::pollCapturedItemType() {
    std::lock_guard<std::mutex> lock(m_engineMutex);
    int32_t item = m_lastCapturedType;
    m_lastCapturedType = -1;
    return item;
}

int32_t ScavengerEngine::getNextStageScore() const {
    int32_t nextLvl = m_level;
    return nextLvl * (nextLvl + 1) * 350;
}

bool ScavengerEngine::pollBombExplosionEvent() {
    std::lock_guard<std::mutex> lock(m_engineMutex);
    bool evt = m_flagBombExplosion;
    m_flagBombExplosion = false;
    return evt;
}

bool ScavengerEngine::pollBaseTierUpgradedEvent() {
    std::lock_guard<std::mutex> lock(m_engineMutex);
    bool evt = m_flagBaseUpgraded;
    m_flagBaseUpgraded = false;
    return evt;
}

bool ScavengerEngine::pollCaptureSoundEvent() {
    std::lock_guard<std::mutex> lock(m_engineMutex);
    bool evt = m_flagCaptureSound;
    m_flagCaptureSound = false;
    return evt;
}

bool ScavengerEngine::pollDamageSoundEvent() {
    std::lock_guard<std::mutex> lock(m_engineMutex);
    bool evt = m_flagDamageSound;
    m_flagDamageSound = false;
    return evt;
}

bool ScavengerEngine::pollNewRecordSoundEvent() {
    std::lock_guard<std::mutex> lock(m_engineMutex);
    bool evt = m_flagNewRecordSound;
    m_flagNewRecordSound = false;
    return evt;
}

bool ScavengerEngine::pollComboSoundEvent() {
    std::lock_guard<std::mutex> lock(m_engineMutex);
    bool evt = m_flagComboSound;
    m_flagComboSound = false;
    return evt;
}

float ScavengerEngine::getGlitchIntensity() const {
    return m_glitchIntensity;
}

bool ScavengerEngine::pollMetaTakeoverEvent() {
    std::lock_guard<std::mutex> lock(m_engineMutex);
    bool evt = m_flagMetaTakeover;
    m_flagMetaTakeover = false;
    return evt;
}

bool ScavengerEngine::pollSecretGhostWallEvent() {
    std::lock_guard<std::mutex> lock(m_engineMutex);
    bool evt = m_flagSecretGhostWall;
    m_flagSecretGhostWall = false;
    return evt;
}

bool ScavengerEngine::pollDodgeBonusEvent() {
    std::lock_guard<std::mutex> lock(m_engineMutex);
    bool evt = m_flagDodgeBonus;
    m_flagDodgeBonus = false;
    return evt;
}

bool ScavengerEngine::pollSuperVacuumEvent() {
    std::lock_guard<std::mutex> lock(m_engineMutex);
    bool evt = m_flagSuperVacuum;
    m_flagSuperVacuum = false;
    return evt;
}

float ScavengerEngine::difficultySpeed() const {
    switch (m_difficultyMode) {
        case 0: return 0.92f; // Facile / Explorateur (smooth, forgiving rhythm)
        case 1: return 1.08f; // Moyen / Capitaine (balanced standard arcade pace)
        case 2: return 1.22f; // Difficile / Vétéran (nervous, intense yet 100% humanly completable)
        default: return 1.00f;
    }
}

int32_t ScavengerEngine::computeCriticalSector(int32_t level) const {
    if (m_isHackedBossMode) return 0;
    if (level == 11) return 1; // IEM Corrupted Storm
    if (level == 14) return 2; // Abyssal Rift
    if (level == 16) return 3; // Titan Outpost
    return 0;
}

void ScavengerEngine::setDifficultyMode(int32_t mode) {
    std::lock_guard<std::mutex> lock(m_engineMutex);
    m_difficultyMode = std::clamp(mode, 0, 2);
    m_customSpeedMultiplier = difficultySpeed();
    m_flagComboSound = true;
}

void ScavengerEngine::setCustomSpeedMultiplier(float multiplier) {
    std::lock_guard<std::mutex> lock(m_engineMutex);
    m_customSpeedMultiplier = std::clamp(multiplier, 0.35f, 1.60f);
    m_flagComboSound = true;
}

void ScavengerEngine::setGravityInverted(bool inverted) {
    std::lock_guard<std::mutex> lock(m_engineMutex);
    m_gravityInverted = inverted;
    m_gravityInvertTimer = inverted ? 15.0f : 0.0f;
    m_flagComboSound = true;
    if (inverted) {
        for (size_t i = 0; i < m_activeCount; ++i) {
            if (m_debrisList[i].state == 0 && m_debrisList[i].type == 6 && !m_isHackedBossMode) {
                // Reverse active bombs upward into orbit!
                m_debrisList[i].vy = -std::abs(m_debrisList[i].vy) * 0.85f;
            }
        }
    }
}

void ScavengerEngine::triggerEmergencyQuantumShield() {
    std::lock_guard<std::mutex> lock(m_engineMutex);
    m_shield = 100;
    m_invulnerableTimer = 14.0f;
    m_flagComboSound = true;
}

void ScavengerEngine::transmuteBombsToGold(int32_t count) {
    std::lock_guard<std::mutex> lock(m_engineMutex);
    m_transmuteBombsCount = std::max(0, m_transmuteBombsCount + count);
    m_flagComboSound = true;
    for (size_t i = 0; i < m_activeCount; ++i) {
        if (m_debrisList[i].state == 0 && m_debrisList[i].type == 6 && !m_isHackedBossMode) {
            m_debrisList[i].type = 4; // Golden Console Relic!
            m_debrisList[i].points = 150;
        }
    }
}

void ScavengerEngine::setPowerOvercharged(bool overcharged) {
    std::lock_guard<std::mutex> lock(m_engineMutex);
    m_isPowerOvercharged = overcharged;
}

void ScavengerEngine::applyOasisBeaconGift(int32_t bonusShield, int32_t bonusScore) {
    std::lock_guard<std::mutex> lock(m_engineMutex);
    m_shield = std::clamp(m_shield + bonusShield, 1, 100);
    m_score = std::max(0, m_score + bonusScore);
    m_flagComboSound = true;
}

bool ScavengerEngine::triggerMagneticPulse() {
    std::lock_guard<std::mutex> lock(m_engineMutex);
    if (m_isPaused || m_isCinematic || m_shield <= 0 || m_pulseCooldown > 0.0f) {
        return false;
    }
    bool isBossOrLevel17 = (m_isHackedBossMode || m_level == 17);
    float baseCooldown;
    if (isBossOrLevel17) {
        // Combat Overdrive in Level 17 & Boss Fight: fast recharge so the player can frequently parry bombs!
        baseCooldown = (m_difficultyMode == 0) ? 1.05f : ((m_difficultyMode == 1) ? 1.25f : 1.45f);
    } else {
        baseCooldown = (m_difficultyMode == 0) ? 3.0f : ((m_difficultyMode == 1) ? 3.6f : 4.4f);
    }
    int32_t crit = computeCriticalSector(m_level);
    if (crit == 1) {
        baseCooldown *= 1.20f; // Level 11 IEM Storm: Cooldown increased by +20%
    }
    if (m_isFullUnlocked) {
        baseCooldown *= 0.65f; // N+1 Royal Oasis Blessing: 35% faster Magnetic Pulse recharge!
    }
    m_pulseCooldown = m_isPowerOvercharged ? (baseCooldown * 0.5f) : baseCooldown;
    m_flagComboSound = true;

    int32_t pulsePoints = m_isFullUnlocked ? 115 : 75;
    float parryRangeX = isBossOrLevel17 ? 0.52f : 0.45f;
    float parryRangeY = isBossOrLevel17 ? 0.62f : 0.55f;
    for (size_t i = 0; i < m_activeCount; ++i) {
        if (m_debrisList[i].state != 0) continue;
        if (m_debrisList[i].type == 7) continue;
        float dx = m_vesselX - m_debrisList[i].x;
        float dy = 0.76f - m_debrisList[i].y;
        if (m_debrisList[i].type == 6) {
            // ONLY BOMBS (type == 6) can ever be parried upward!
            if (std::abs(dx) < parryRangeX && std::abs(dy) < parryRangeY) {
                if (isBossOrLevel17) {
                    // DEFLECTED COUNTER-BOMB: Parried into an upward kinetic missile aimed at the Boss (Level 17 & Boss fight ONLY)!
                    m_debrisList[i].type = 7;
                    m_debrisList[i].vy = -std::max(0.95f, std::abs(m_debrisList[i].vy) * 2.4f) * m_customSpeedMultiplier;
                    m_debrisList[i].vx = std::clamp((m_bossX - m_debrisList[i].x) * 2.6f, -0.50f, 0.50f) * m_customSpeedMultiplier;
                    m_debrisList[i].points = 350;
                    m_score += pulsePoints;
                    m_shield = std::min(100, m_shield + 10);
                    m_comboCount++;
                    if (m_comboCount > m_maxCombo) m_maxCombo = m_comboCount;
                } else {
                    // In Level 1 to 16: Neutralized in place safely (NO counter-bomb deflection)
                    m_debrisList[i].state = 1;
                    m_score += pulsePoints;
                    m_shield = std::min(100, m_shield + 6);
                    m_comboCount++;
                    if (m_comboCount > m_maxCombo) m_maxCombo = m_comboCount;
                }
            } else if (!isBossOrLevel17) {
                // In Level 1 to 16: Gently deflect distant bombs horizontally away from Echo
                float push = (dx < 0.0f) ? 0.20f : -0.20f;
                m_debrisList[i].vx = std::clamp(m_debrisList[i].vx + push, -0.30f, 0.30f);
            }
        } else {
            // Non-bomb artefacts (types 0..5): Gently pull horizontally toward Echo's suction cone,
            // and strictly guarantee they always continue falling downward (NEVER upward!).
            m_debrisList[i].vx = std::clamp(dx * 1.8f, -0.30f, 0.30f);
            m_debrisList[i].vy = std::max(0.20f, std::abs(m_debrisList[i].vy));
        }
    }
    return true;
}

int32_t ScavengerEngine::pollBaseAssistEvent() {
    std::lock_guard<std::mutex> lock(m_engineMutex);
    int32_t evt = m_lastAssistType;
    m_lastAssistType = 0;
    return evt;
}

void ScavengerEngine::step(float deltaTime) {
    if (std::isnan(deltaTime) || std::isinf(deltaTime) || deltaTime <= 0.0f) return;
    deltaTime = std::min(deltaTime, 0.1f);
    std::lock_guard<std::mutex> lock(m_engineMutex);
    if (m_isPaused || m_shield <= 0) return;

    m_biomeWaveTime += deltaTime;

    // Hardware Overcharge recharges Magnetic Pulse 2x faster!
    float cooldownRate = m_isPowerOvercharged ? 2.0f : 1.0f;
    if (m_pulseCooldown > 0.0f) {
        m_pulseCooldown = std::max(0.0f, m_pulseCooldown - deltaTime * cooldownRate);
    }

    // Prompt-to-Gameplay Quantum Shield & Anti-Gravity timers
    if (m_invulnerableTimer > 0.0f) {
        m_invulnerableTimer = std::max(0.0f, m_invulnerableTimer - deltaTime);
    }
    if (m_gravityInverted && m_gravityInvertTimer > 0.0f) {
        m_gravityInvertTimer -= deltaTime;
        if (m_gravityInvertTimer <= 0.0f) {
            m_gravityInverted = false;
            m_gravityInvertTimer = 0.0f;
        }
    }

    if (m_isHackedBossMode) {
        m_level = 17;
        m_baseStage = 4;

        // Multi-phase Boss AI on Level 17 (Stage 1: Blindage Piraté | Stage 2: Surcharge Abyssale + Esquives Quantiques)
        if (m_bossStage == 1) {
            if (m_bossHp > BOSS_MAX_HP / 2) {
                m_bossPhase = 1;
                m_glitchIntensity = 0.06f;
            } else {
                m_bossPhase = 2;
                m_glitchIntensity = 0.12f;
            }
        } else {
            if (m_bossHp > BOSS_MAX_HP / 2) {
                m_bossPhase = 2;
                m_glitchIntensity = 0.16f;
            } else {
                m_bossPhase = 3;
                m_glitchIntensity = 0.24f;
            }
        }

        float baseBossSpeed = (m_bossStage == 1)
            ? ((m_bossPhase == 1) ? 0.25f : 0.34f)
            : ((m_bossPhase == 2) ? 0.44f : 0.54f);
        float bossSpeed = baseBossSpeed * m_customSpeedMultiplier;
        float dir = (m_bossVx >= 0.0f) ? 1.0f : -1.0f;
        m_bossVx = dir * bossSpeed;
        m_bossX += m_bossVx * deltaTime;

        if (m_bossX < 0.18f) {
            m_bossX = 0.18f;
            m_bossVx = std::abs(m_bossVx);
        } else if (m_bossX > 0.82f) {
            m_bossX = 0.82f;
            m_bossVx = -std::abs(m_bossVx);
        }

        // Targeted Boss Salvo Attacks: Measured, telegraphed bomb shots aimed at Echo so the player can cleanly parry or dodge them!
        if (!m_isCinematic && m_bossHp > 0) {
            m_bossAttackTimer += deltaTime * m_customSpeedMultiplier;
            float salvoInterval = (m_bossStage == 1)
                ? ((m_bossPhase == 1) ? 3.8f : 3.2f)
                : ((m_bossPhase == 2) ? 4.2f : 3.6f);
            if (m_bossAttackTimer >= salvoInterval && m_activeCount + 4 < m_maxDebris) {
                m_bossAttackTimer = 0.0f;
                int salvoCount = 1; // Single telegraphed bomb per salvo (especially cleaner in Phase 2!)
                for (int s = 0; s < salvoCount; ++s) {
                    size_t idx = m_activeCount++;
                    float offset = (s - (salvoCount - 1) * 0.5f) * 0.18f;
                    m_debrisList[idx].x = std::clamp(m_bossX + offset, 0.08f, 0.92f);
                    m_debrisList[idx].y = 0.22f;
                    float aimVx = std::clamp((m_vesselX - m_debrisList[idx].x) * 0.22f + offset * 0.30f, -0.13f, 0.13f);
                    m_debrisList[idx].vx = aimVx * m_customSpeedMultiplier;
                    m_debrisList[idx].vy = (0.22f + (m_bossPhase * 0.022f) + (m_bossStage == 2 ? 0.025f : 0.0f)) * m_customSpeedMultiplier;
                    // Salvo projectiles are Corrupted Glitch Bombs aimed to test player reflexes!
                    m_debrisList[idx].type = 6;
                    m_debrisList[idx].points = 150;
                    m_debrisList[idx].size = 0.09f;
                    m_debrisList[idx].state = 0;
                }
            }
        }
    } else {
        // 1. Dynamic Base Stage & Level Progression
        int32_t previousLevel = m_level;

        // Determine level based on exponential score curve
        int32_t calculatedLevel = 1;
        while (m_score >= calculatedLevel * (calculatedLevel + 1) * 350) {
            calculatedLevel++;
        }
        // In New Game+ / Free Mode (m_isFullUnlocked), levels continue infinitely beyond 17!
        m_level = m_isFullUnlocked ? calculatedLevel : std::min(calculatedLevel, 17);

        // Base Stage progresses from 0 to 4 over the course of each level as the base is built!
        int32_t scoreStart = (m_level - 1) * m_level * 350;
        int32_t scoreEnd = m_level * (m_level + 1) * 350;
        int32_t span = std::max(1, scoreEnd - scoreStart);
        float inLevelProgress = std::clamp(static_cast<float>(m_score - scoreStart) / static_cast<float>(span), 0.0f, 1.0f);
        m_baseStage = std::clamp(static_cast<int32_t>(inLevelProgress * 5.0f), 0, 4);

        if (m_level > previousLevel) {
            m_flagBaseUpgraded = true;
            m_isCinematic = true;
            m_activeCount = 0;
            m_spawnTimer = 0.0f;
            m_flagDamageSound = false;
            // Level-clear shield recovery bonus (stronger in N+1 to sustain long multi-loop runs!)
            int32_t levelClearHeal = m_isFullUnlocked ? 12 : 6;
            m_shield = std::min(100, m_shield + levelClearHeal);
        }

        // Meta Takeover & Glitch logic (Only in Story Run before Echo is freed!)
        if (!m_isFullUnlocked) {
            if (m_level > m_lastGlitchLevel) {
                m_lastGlitchLevel = m_level;
                m_glitchCountThisLevel = 0;
                m_glitchTimer = 0.0f;
                std::uniform_real_distribution<float> dist(2.0f, 6.0f);
                m_glitchCooldown = dist(m_rng);
            }

            if (m_level >= 12 && m_level <= 17 && !m_flagMetaTakeover) {
                int maxGlitches = (m_level < 16) ? 1 : 6;

                if (m_glitchTimer > 0.0f) {
                    m_glitchTimer -= deltaTime;
                    if (m_glitchTimer <= 0.0f) {
                        m_glitchIntensity = 0.0f; // Turn off glitch
                        std::uniform_real_distribution<float> dist(8.0f, 18.0f);
                        m_glitchCooldown = (m_level >= 16) ? dist(m_rng) * 0.35f : dist(m_rng);
                    } else {
                        std::uniform_real_distribution<float> distIntens(0.4f, 1.0f);
                        m_glitchIntensity = distIntens(m_rng);
                    }
                } else if (m_glitchCountThisLevel < maxGlitches) {
                    m_glitchCooldown -= deltaTime;
                    if (m_glitchCooldown <= 0.0f) {
                        m_glitchCountThisLevel++;
                        std::uniform_real_distribution<float> distTime(0.35f, 0.85f);
                        m_glitchTimer = (m_level >= 16) ? distTime(m_rng) * 1.8f : distTime(m_rng);
                    }
                }
            } else if (!m_flagMetaTakeover) {
                m_glitchIntensity = 0.0f;
            }

            // Reliable Level 17 -> Part 2 Takeover (triggers after ~24s of active play in Level 17 OR reaching Level 17 score target)
            if (m_level == 17 && !m_flagMetaTakeover) {
                if (!m_isCinematic) {
                    m_level17Elapsed += deltaTime;

                    // Colossal Meca-Titan stalks Echo across the apocalyptic horizon in Part 1
                    float dir = (m_bossVx >= 0.0f) ? 1.0f : -1.0f;
                    m_bossVx = dir * 0.18f;
                    m_bossX += m_bossVx * deltaTime;
                    if (m_bossX < 0.25f) {
                        m_bossX = 0.25f;
                        m_bossVx = std::abs(m_bossVx);
                    } else if (m_bossX > 0.75f) {
                        m_bossX = 0.75f;
                        m_bossVx = -std::abs(m_bossVx);
                    }
                }
                int scoreReqPrev = 16 * 17 * 350;
                int scoreReqCur = 17 * 18 * 350;
                int takeoverTarget = scoreReqPrev + (scoreReqCur - scoreReqPrev);

                // Progressive warning glitches in the final 8 seconds before takeover
                if (m_level17Elapsed >= 16.0f && m_level17Elapsed < 24.0f) {
                    float warnProgress = (m_level17Elapsed - 16.0f) / 8.0f;
                    m_glitchIntensity = std::max(m_glitchIntensity, 0.15f + warnProgress * 0.65f);
                }

                if (m_score >= takeoverTarget || m_level17Elapsed >= 24.0f) {
                    m_flagMetaTakeover = true;
                    m_glitchIntensity = 1.0f;
                }
            }
        } else {
            m_glitchIntensity = 0.0f;
        }
    }

    // 2. Smoothly Calibrated Difficulty & Logarithmic N+1 Scaling (Playable Across Infinite Loops!)
    float effectiveLevel;
    if (m_level <= 10) {
        effectiveLevel = static_cast<float>(m_level);
    } else if (m_level <= 17) {
        effectiveLevel = 10.0f + static_cast<float>(m_level - 10) * 0.42f; // Reaches 12.94 at Level 17
    } else {
        // N+1 Endless Mode (Level 18+): Logarithmic smoothing + subtle breathing wave at the start of each 16-biome loop
        float logLoops = std::log2(1.0f + static_cast<float>(m_level - 17)) * 1.10f;
        int32_t biomeInLoop = ((m_level - 1) % 16) + 1;
        float loopWave = (biomeInLoop <= 4) ? -0.65f : ((biomeInLoop <= 10) ? 0.0f : 0.35f);
        effectiveLevel = std::clamp(12.94f + logLoops + loopWave, 12.0f, 18.5f);
    }

    float rawSpeedMult = (0.80f + (effectiveLevel * 0.040f) + (m_baseStage * 0.030f)) * m_customSpeedMultiplier;
    float maxPlayableSpeed = (m_difficultyMode == 0) ? 1.52f : ((m_difficultyMode == 1) ? 1.72f : 1.88f);
    float speedMultiplier = std::min(rawSpeedMult, maxPlayableSpeed);

    // Balanced spawn density from Level 1 to Level 17+ and fair rhythm in Boss Mode across all 3 difficulties
    float minSpawnInterval = (m_difficultyMode == 0) ? 0.46f : ((m_difficultyMode == 1) ? 0.42f : 0.39f);
    m_spawnInterval = m_isHackedBossMode
        ? (m_bossStage == 2 ? (minSpawnInterval + 0.16f) : (minSpawnInterval + 0.14f))
        : std::max(minSpawnInterval, 1.48f - (effectiveLevel * 0.050f) - (m_baseStage * 0.030f));

    // 3. Continuous Relic & Bomb Spawning (Level 17 8-Bit Layout + Hacked Physics in Boss Mode)
    if (!m_isCinematic) {
        m_spawnTimer += deltaTime;
        if (m_spawnTimer >= m_spawnInterval && m_activeCount < m_maxDebris) {
            m_spawnTimer = 0.0f;

            int32_t critSector = computeCriticalSector(m_level);
            float maxVx = 0.042f + (effectiveLevel * 0.0018f);
            std::uniform_real_distribution<float> distX(0.08f, 0.92f);
            std::uniform_real_distribution<float> distVx(-maxVx, maxVx);

            std::uniform_int_distribution<int> rollDist(0, 99);
            int roll = rollDist(m_rng);

            uint32_t chosenType = 0;
            int32_t itemPoints = 10;

            if (m_isHackedBossMode) {
                // FEWER BOMBS & MORE ARTEFACTS IN FINAL BOSS FIGHT (ESPECIALLY IN PHASE 2):
                // Since the Boss also fires targeted salvos, sky spawns are 80%-88% beneficial Artefacts & Shield Cores!
                int diffBombAdj = (m_difficultyMode == 0) ? -3 : ((m_difficultyMode == 2) ? 3 : 0);
                int bombChance = std::clamp(((m_bossStage == 2) ? 15 : 18) + diffBombAdj, 12, 22);
                if (roll < bombChance) {
                    chosenType = 6; // Corrupted Glitch Bomb (Parry with Magnetic Wave or dodge for +50 pts!)
                    itemPoints = 150;
                } else {
                    // Generous flow of Nano Shield Cores and retro relics to boost shield and recharge Magnetic Wave!
                    int subRoll = rollDist(m_rng);
                    if (subRoll < 44) {
                        chosenType = 5; itemPoints = 25; // Nano Shield Core (+18% Shield + Magnetic Boost)
                    } else if (subRoll < 68) {
                        chosenType = 4; itemPoints = 50; // Console relic
                    } else if (subRoll < 86) {
                        chosenType = 3; itemPoints = 30; // Microchip CPU
                    } else {
                        chosenType = 0; itemPoints = 30; // Game Cartridge
                    }
                }
            } else {
                // Smoothly scaled bomb chance with GUARANTEED Nano Shield Core band in all levels, difficulties, and N+1!
                int baseBombPct = 12 + static_cast<int>(effectiveLevel * 0.85f);
                if (m_difficultyMode == 0) baseBombPct -= 3;
                else if (m_difficultyMode == 2) baseBombPct += 4;

                if (!m_isFullUnlocked) {
                    if (critSector == 1) baseBombPct += 4;      // Level 11: Extra bombs in IEM storm
                    else if (critSector == 2) baseBombPct += 6; // Level 14: Bomb surge in rift
                    else if (critSector == 3) baseBombPct += 5; // Level 16: Bomb barrage at Titan Outpost
                }

                int maxBombPct = (m_difficultyMode == 0) ? 26 : ((m_difficultyMode == 1) ? 30 : 34);
                int bombPct = std::clamp(baseBombPct, 9, maxBombPct);

                // Dedicated Nano Shield Core spawn slice (12% to 17% of all spawns, NEVER overwritten by bombs!)
                int shieldCorePct = (m_difficultyMode == 0) ? 15 : ((m_difficultyMode == 1) ? 13 : 12);
                if (m_isFullUnlocked) {
                    shieldCorePct += 2; // Extra shield core sustain for long N+1 endless runs!
                } else if (critSector == 2) {
                    shieldCorePct = std::max(9, shieldCorePct - 3); // Level 14 rift still keeps >= 9% shield cores
                }

                int bombCutoff = 100 - bombPct;
                int shieldCutoff = bombCutoff - shieldCorePct;

                if (roll >= bombCutoff) {
                    if (m_transmuteBombsCount > 0) {
                        // Prompt-to-Gameplay: Transmute incoming bomb into Golden Console Relic!
                        chosenType = 4;
                        itemPoints = 150;
                        m_transmuteBombsCount--;
                    } else {
                        chosenType = 6; itemPoints = 0; // Corrupted Glitch Bomb
                    }
                } else if (roll >= shieldCutoff) {
                    chosenType = 5; itemPoints = 15; // Guaranteed Nano Shield Core!
                } else {
                    // Distribute remaining roll cleanly across the 5 Retro Relic tiers (0..4)
                    int relicRoll = (roll * 100) / std::max(1, shieldCutoff);
                    if (relicRoll < 30) {
                        chosenType = 0; itemPoints = 30; // Game Cartridge
                    } else if (relicRoll < 58) {
                        chosenType = 1; itemPoints = 20; // Floppy Disk
                    } else if (relicRoll < 78) {
                        chosenType = 2; itemPoints = 15; // Pixel Coin
                    } else if (relicRoll < 90) {
                        chosenType = 3; itemPoints = 25; // Microchip CPU / Computer
                    } else {
                        chosenType = 4; itemPoints = 50; // Arcade Joystick / Console
                    }
                }
            }

            float vyMult = speedMultiplier;
            if (critSector == 3 && chosenType == 6 && !m_isFullUnlocked) {
                vyMult *= 1.14f; // Level 16: Bombs drop 14% faster
            }
            if (m_isHackedBossMode && chosenType == 6) {
                // In boss mode, add varying bomb descent speeds (some rapid plasma drops, some standard)
                float bossBombBoost = (m_bossStage == 2) ? 1.18f : 1.08f;
                vyMult *= bossBombBoost;
            }
            std::uniform_real_distribution<float> distVy(0.15f * vyMult, 0.24f * vyMult);

            size_t index = m_activeCount++;
            // Same 8-bit sky spawning as Level 17 in Part 1 so the full screen width is active and playable
            m_debrisList[index].x = distX(m_rng);
            m_debrisList[index].y = -0.05f;
            m_debrisList[index].vx = distVx(m_rng);
            m_debrisList[index].vy = distVy(m_rng);
            m_debrisList[index].type = chosenType;
            m_debrisList[index].points = itemPoints;
            m_debrisList[index].size = 0.09f; // Enlarged hitbox for giant arcade relics
            m_debrisList[index].state = 0; // 0: Active

            // Spawn Oasis Ghost Beacon secret debris if level >= 2 (2.5% chance)
            std::uniform_int_distribution<int> dist100(0, 99);
            if (!m_isHackedBossMode && m_level >= 2 && chosenType != 6 && (dist100(m_rng) < 3)) {
                m_debrisList[index].state = 3; // Oasis Ghost Beacon from another Captain!
            }
        }
    }

    // 3b. Active Base Construction Modules + N+1 Tamed Mini-Titan Companion!
    if (!m_isCinematic) {
        float assistMultiplier = m_isPowerOvercharged ? 1.5f : 1.0f;
        float royalMult = m_isFullUnlocked ? 1.5f : 1.0f;
        int32_t critAssist = computeCriticalSector(m_level);

        // Module 1 (Stage >= 1 OR always active in N+1 via Tamed Mini-Titan!): Auto-rescues missed relics near the ground!
        if (m_baseStage >= 1 || m_isFullUnlocked) {
            m_baseDroneTimer += deltaTime * assistMultiplier;
            float rescueInterval = m_isFullUnlocked ? 2.1f : ((critAssist == 3) ? 4.2f : 3.0f);
            if (m_baseDroneTimer >= rescueInterval) {
                for (size_t k = 0; k < m_activeCount; ++k) {
                    if (m_debrisList[k].state == 0 && m_debrisList[k].type < 6 && m_debrisList[k].y > 0.78f && m_debrisList[k].y < 0.96f) {
                        m_debrisList[k].state = 1;
                        m_score += static_cast<int32_t>(m_debrisList[k].points * royalMult);
                        if (m_debrisList[k].type == 5) {
                            m_shield = std::min(100, m_shield + 8); // Drone rescue of a Shield Core also heals Echo!
                        }
                        m_lastAssistType = 1;
                        m_lastAssistX = m_debrisList[k].x;
                        m_lastAssistY = m_debrisList[k].y;
                        m_baseDroneTimer = 0.0f;
                        break;
                    }
                }
            }
        }

        // N+1 Exclusive Module: Tamed Mini-Titan Companion transmutes an incoming red bomb into a Golden Relic (+150 pts) every ~6.0s!
        if (m_isFullUnlocked && !m_isHackedBossMode) {
            m_miniTitanTransmuteTimer += deltaTime * assistMultiplier;
            if (m_miniTitanTransmuteTimer >= 6.0f) {
                for (size_t k = 0; k < m_activeCount; ++k) {
                    if (m_debrisList[k].state == 0 && m_debrisList[k].type == 6 && m_debrisList[k].y > 0.16f && m_debrisList[k].y < 0.68f) {
                        m_debrisList[k].type = 4; // Golden Console Relic!
                        m_debrisList[k].points = 150;
                        m_lastAssistType = 4; // 4: Mini-Titan Gold Transmutation Beam!
                        m_lastAssistX = m_debrisList[k].x;
                        m_lastAssistY = m_debrisList[k].y;
                        m_miniTitanTransmuteTimer = 0.0f;
                        break;
                    }
                }
            }
        }

        // Module 2 (Stage >= 2, or Stage >= 1 in N+1): Sanctuary Shield Regeneration Dome when Echo stands near the Base Portal!
        float domeRange = m_isFullUnlocked ? 0.18f : 0.14f;
        if ((m_baseStage >= 2 || (m_isFullUnlocked && m_baseStage >= 1)) && m_shield < 100 && std::abs(m_vesselX - 0.5f) < domeRange) {
            m_baseHealTimer += deltaTime * assistMultiplier;
            float healInterval = m_isFullUnlocked ? 1.5f : ((critAssist == 3) ? 2.6f : 1.8f);
            if (m_baseHealTimer >= healInterval) {
                m_baseHealTimer = 0.0f;
                m_shield = std::min(100, m_shield + (m_isFullUnlocked ? 4 : 3));
                m_lastAssistType = 2;
                m_lastAssistX = 0.5f;
                m_lastAssistY = 0.72f;
            }
        }

        // Module 3 (Stage >= 3, or Stage >= 2 in N+1): Base Laser Defense Turret shoots down incoming bombs!
        if (m_baseStage >= 3 || (m_isFullUnlocked && m_baseStage >= 2)) {
            m_baseTurretTimer += deltaTime * assistMultiplier;
            float turretInterval = m_isHackedBossMode ? 3.5f : (m_isFullUnlocked ? 2.6f : ((critAssist == 3) ? 4.0f : 3.0f));
            if (m_baseTurretTimer >= turretInterval) {
                for (size_t k = 0; k < m_activeCount; ++k) {
                    if (m_debrisList[k].state == 0 && m_debrisList[k].type == 6 && m_debrisList[k].y > 0.20f && m_debrisList[k].y < 0.68f) {
                        m_debrisList[k].state = 1;
                        m_score += 45;
                        m_lastAssistType = 3;
                        m_lastAssistX = m_debrisList[k].x;
                        m_lastAssistY = m_debrisList[k].y;
                        m_baseTurretTimer = 0.0f;
                        break;
                    }
                }
            }
        }
    }

    // 4. Collision Detection, Biome Physics & Vacuum Catch Checks
    float vesselY = 0.76f; // Moved UP to 76% height so bottom 24% is clear for thumb sliding!
    float catchRangeX = m_vesselWidth * 0.85f;
    int32_t biomeInCycle = m_isHackedBossMode ? 17 : (((m_level - 1) % 16) + 1);

    size_t i = 0;
    while (i < m_activeCount) {
        // Biome-Specific Weather & Gravity Physics (cycles smoothly across 16-biome N+1 loops!)
        if (biomeInCycle == 4 || biomeInCycle == 8) {
            // Alpine & Arctic Blizzard Wind Drift
            m_debrisList[i].x += std::sin(m_biomeWaveTime * 2.4f + static_cast<float>(i)) * 0.045f * deltaTime;
        } else if (biomeInCycle == 13 || biomeInCycle == 14) {
            // Abyssal Underwater Currents & Level 14 rift tides (smoothed in N+1)
            float currStrength = (biomeInCycle == 14 && !m_isFullUnlocked) ? 0.068f : 0.042f;
            m_debrisList[i].x += std::cos(m_biomeWaveTime * 2.0f + m_debrisList[i].y * 6.0f) * currStrength * deltaTime;
        } else if (biomeInCycle == 15 || biomeInCycle == 16) {
            // Cosmic Nebula & Planet X Gravitational Pull toward center
            m_debrisList[i].vx += (0.5f - m_debrisList[i].x) * 0.12f * deltaTime;
        }

        // Prompt-to-Gameplay: Anti-Gravity Inversion!
        if (m_gravityInverted) {
            if (m_debrisList[i].type == 6 && !m_isHackedBossMode) {
                // Bombs float upward and away from Echo!
                m_debrisList[i].vy -= 0.45f * deltaTime;
            } else if (m_debrisList[i].type < 6) {
                // Good relics gently home toward Echo's horizontal position in low gravity!
                m_debrisList[i].vx += (m_vesselX - m_debrisList[i].x) * 0.85f * deltaTime;
                m_debrisList[i].vy = std::clamp(m_debrisList[i].vy, 0.08f, 0.16f);
            }
        }

        // Strict Invariant: Non-bomb artefacts (types 0..5) NEVER move upward under any circumstance!
        // Only parried bombs (type == 7) or anti-gravity bombs (type == 6) can ever have vy < 0.
        if (m_debrisList[i].type < 6 && m_debrisList[i].vy < 0.10f) {
            m_debrisList[i].vy = std::max(0.15f, std::abs(m_debrisList[i].vy));
        }

        m_debrisList[i].x += m_debrisList[i].vx * deltaTime;
        m_debrisList[i].y += m_debrisList[i].vy * deltaTime;

        // Bounce horizontal bounds
        if (m_debrisList[i].x < 0.04f || m_debrisList[i].x > 0.96f) {
            m_debrisList[i].vx = -m_debrisList[i].vx;
        }

        // Type 7: Deflected Counter-Bomb Homing & Boss Impact Check (Level 17 & Boss Mode)
        if (m_debrisList[i].type == 7 && m_debrisList[i].state == 0) {
            float toBoss = m_bossX - m_debrisList[i].x;
            m_debrisList[i].vx += std::clamp(toBoss * 3.6f, -0.6f, 0.6f) * deltaTime;

            float distBossX = std::abs(m_debrisList[i].x - m_bossX);
            if (m_debrisList[i].y <= 0.25f && distBossX < 0.24f) {
                m_debrisList[i].state = 1; // Direct hit on Boss!
                m_flagBombExplosion = true;
                m_flagComboSound = true;
                m_lastCapturedType = 7;
                if (m_isHackedBossMode) {
                    tryDamageBoss(16, false); // Direct 16 HP damage! (Cannot dodge reflected counter-bombs)
                    m_score += 500;
                    m_comboCount += 2;
                    if (m_comboCount > m_maxCombo) m_maxCombo = m_comboCount;
                    if (m_flagBossPhase2Transition || m_flagBossDefeated) {
                        m_activeCount = 0;
                        break;
                    }
                } else if (m_level == 17) {
                    // Level 17 Part 1: Staggers the looming Meca-Titan!
                    m_score += 750;
                    m_comboCount += 2;
                    if (m_comboCount > m_maxCombo) m_maxCombo = m_comboCount;
                    m_glitchIntensity = 0.85f;
                    m_level17Elapsed += 4.5f;
                    m_bossVx = (m_bossVx > 0.0f) ? -0.35f : 0.35f;
                }
            } else if (m_debrisList[i].y < -0.15f) {
                m_debrisList[i].state = 2; // Flew off top of screen
            }
        }

        // Suction Vacuum Capture check
        float dx = std::abs(m_debrisList[i].x - m_vesselX);
        float dy = std::abs(m_debrisList[i].y - vesselY);

        if (!m_isCinematic && dy < 0.06f && dx < catchRangeX && m_debrisList[i].type != 7 && (m_debrisList[i].state == 0 || m_debrisList[i].state == 3)) {

            if (m_debrisList[i].state == 3) {
                m_flagSecretGhostWall = true;
                m_debrisList[i].state = 1; // Captured Oasis Ghost Beacon!
                m_lastCapturedType = m_debrisList[i].type;
                m_flagCaptureSound = true;
            } else {
                m_debrisList[i].state = 1; // Captured!

                if (m_debrisList[i].type == 6) {
                    if (m_invulnerableTimer > 0.0f) {
                        // Quantum Shield Dome absorbs bomb harmlessly and converts it into +100 pts!
                        m_score += 100;
                        m_comboCount++;
                        if (m_comboCount > m_maxCombo) m_maxCombo = m_comboCount;
                        m_flagCaptureSound = true;
                    } else {
                        // Caught a Corrupted Glitch Bomb without parrying! Explodes on Echo
                        int normalDmg = (m_difficultyMode == 0) ? 18 : ((m_difficultyMode == 1) ? 24 : 28);
                        int bossDmg = (m_difficultyMode == 0) ? 12 : ((m_difficultyMode == 1) ? 16 : 20);
                        int bombDmg = m_isHackedBossMode ? bossDmg : normalDmg;
                        m_shield = std::max(0, m_shield - bombDmg);
                        m_comboCount = 0;
                        m_lastCapturedType = 6;
                        m_flagBombExplosion = true;
                        m_flagDamageSound = true;
                    }
                } else {
                    // Captured a Retro Relic
                    m_comboCount++;
                    if (m_comboCount > m_maxCombo) {
                        m_maxCombo = m_comboCount;
                    }

                    float comboBonus = 1.0f + std::min(m_comboCount, 10) * 0.1f;
                    float royalBonus = m_isFullUnlocked ? 1.5f : 1.0f;
                    int32_t finalPoints = static_cast<int32_t>(m_debrisList[i].points * comboBonus * royalBonus);
                    m_score += finalPoints;

                    if (m_debrisList[i].type == 5) {
                        int baseHeal = m_isHackedBossMode ? 18 : ((m_difficultyMode == 0) ? 16 : ((m_difficultyMode == 1) ? 14 : 12));
                        if (computeCriticalSector(m_level) == 1 && !m_isFullUnlocked) {
                            baseHeal = std::max(9, (baseHeal * 3) / 4); // Level 11 IEM storm slightly dampens shield capacitors (-25%)
                        }
                        m_shield = std::min(100, m_shield + baseHeal); // Shield Repair scaled by Difficulty Mode
                    } else if (m_isHackedBossMode || m_level == 17) {
                        // In Boss / Level 17 mode: catching any relic also boosts Echo's magnetic shield (+4%)!
                        m_shield = std::min(100, m_shield + 4);
                    } else if (m_isFullUnlocked && m_debrisList[i].type == 4) {
                        // In N+1: catching Golden Console Relics (including Mini-Titan transmuted bombs!) restores +3% shield!
                        m_shield = std::min(100, m_shield + 3);
                    }

                    if (m_isHackedBossMode || m_level == 17) {
                        // Catching any relic boosts the Magnetic Wave recharge so you can parry bombs much more often!
                        m_pulseCooldown = std::max(0.0f, m_pulseCooldown - 0.65f);
                        if (m_isHackedBossMode) {
                            // Boss Plasma Laser Capacitor with Slower 3-Shot Discharge Cycle:
                            // - First 3 shots of a burst require 4 artifacts per shot.
                            // - After 3 shots, the capacitor enters Discharge and requires DOUBLE resources (8 artifacts) to recharge!
                            int32_t requiredCharge = getBossLaserRequiredCharge();
                            m_bossLaserCharge++;
                            if (m_bossLaserCharge >= requiredCharge) {
                                m_bossLaserCharge = 0;
                                if (m_bossLaserShotsInCycle >= 3) {
                                    m_bossLaserShotsInCycle = 0; // Heavy recharge completed -> Fresh 3-shot burst cycle!
                                } else {
                                    m_bossLaserShotsInCycle++;
                                }
                                tryDamageBoss(6, true);
                            }
                        }
                    }

                    m_lastCapturedType = static_cast<int32_t>(m_debrisList[i].type);

                    // High Score Record Check
                    if (m_highScore > 0 && m_score > m_highScore && !m_hasBeatenHighScore) {
                        m_hasBeatenHighScore = true;
                        m_flagNewRecordSound = true;
                    }

                    if (m_comboCount % 5 == 0) {
                        m_flagComboSound = true;
                    }

                    // Super Vacuum Burst: Every 10 combo (10/10 on Combo Bar) triggers Quantum Super-Aspiration (+50% bonus on relics)!
                    if (m_comboCount > 0 && (m_comboCount % 10 == 0) && !m_flagSuperVacuum) {
                        m_flagSuperVacuum = true;
                        for (size_t k = 0; k < m_activeCount; ++k) {
                            if ((m_debrisList[k].state == 0 || m_debrisList[k].state == 3) && m_debrisList[k].type < 6) {
                                m_debrisList[k].state = 1; // Instantly captured!
                                m_score += static_cast<int32_t>(m_debrisList[k].points * 1.5f);
                            }
                        }
                    }

                    m_flagCaptureSound = true;
                }
            }
        } else if (m_debrisList[i].y > 0.98f && (m_debrisList[i].state == 0 || m_debrisList[i].state == 3)) {
            if (!m_isCinematic) {
                if (m_debrisList[i].type == 6) {
                    // Successfully dodged a bomb (in ALL levels including Boss Mode!):
                    // Never lowers health or resets combo; awards +50 pts and boosts the Magnetic Shield & Wave!
                    m_score += 50;
                    m_flagDodgeBonus = true;
                    if (m_isHackedBossMode || m_level == 17) {
                        m_shield = std::min(100, m_shield + 2);
                        m_pulseCooldown = std::max(0.0f, m_pulseCooldown - 0.65f);
                    }
                } else if (m_debrisList[i].state != 3 && m_invulnerableTimer <= 0.0f && !m_isHackedBossMode) {
                    // Missed a valid relic in normal levels -> Fair, balanced shield chip damage (gentler in N+1 for long runs!)
                    m_comboCount = 0;
                    int normalMissDmg = m_isFullUnlocked
                        ? ((m_difficultyMode == 0) ? 4 : ((m_difficultyMode == 1) ? 5 : 7))
                        : ((m_difficultyMode == 0) ? 5 : ((m_difficultyMode == 1) ? 7 : 9));
                    m_shield = std::max(0, m_shield - normalMissDmg);
                    m_flagDamageSound = true;
                }
            }
            m_debrisList[i].state = 2; // Missed
        } else if (m_debrisList[i].y < -0.25f) {
            // Reversed bomb floated off the top of the screen!
            m_debrisList[i].state = 2;
            m_score += 50;
            m_flagDodgeBonus = true;
        }

        if (m_flagBossPhase2Transition || m_flagBossDefeated) {
            // Boss Phase 1 defeated or final victory reached!
            // Cleanly clear arena and break collision loop to prevent any use-after-clear or out-of-bounds recycling!
            m_activeCount = 0;
            break;
        }

        // Recycle inactive/captured/missed items
        if (((m_debrisList[i].state != 0 && m_debrisList[i].state != 3) || m_debrisList[i].y > 1.05f || m_debrisList[i].y < -0.25f)) {
            if (m_activeCount > 0 && i < m_activeCount - 1) {
                m_debrisList[i] = m_debrisList[m_activeCount - 1];
            }
            if (m_activeCount > 0) {
                --m_activeCount;
            } else {
                break;
            }
        } else {
            ++i;
        }
    }
}

void ScavengerEngine::reset(bool fullUnlocked) {
    std::lock_guard<std::mutex> lock(m_engineMutex);
    m_activeCount = 0;
    m_vesselX = 0.5f;
    m_score = 0;
    m_shield = 100;
    m_level = 1;
    m_baseStage = 0;
    m_comboCount = 0;
    m_maxCombo = 0;
    m_bossHp = BOSS_MAX_HP;
    m_bossX = 0.5f;
    m_bossVx = 0.26f;
    m_bossAttackTimer = 0.0f;
    m_bossPhase = 1;
    m_bossStage = 1;
    m_bossLaserCharge = 0;
    m_bossLaserShotsInCycle = 0;
    m_spawnTimer = 0.0f;
    m_isFullUnlocked = fullUnlocked;
    m_isPaused = false;
    m_isCinematic = false;
    m_isHackedBossMode = false;
    m_hasBeatenHighScore = false;
    m_lastCapturedType = -1;
    m_flagBombExplosion = false;
    m_flagBaseUpgraded = false;
    m_flagCaptureSound = false;
    m_flagDamageSound = false;
    m_flagNewRecordSound = false;
    m_flagComboSound = false;
    m_flagMetaTakeover = false;
    m_flagSecretGhostWall = false;
    m_flagDodgeBonus = false;
    m_flagSuperVacuum = false;
    m_flagBossHit = false;
    m_flagBossLaserDodged = false;
    m_flagBossPhase2Transition = false;
    m_flagBossDefeated = false;
    m_glitchIntensity = 0.0f;
    m_glitchTimer = 0.0f;
    m_glitchCooldown = 0.0f;
    m_glitchCountThisLevel = 0;
    m_lastGlitchLevel = 0;
    m_level17Elapsed = 0.0f;
    m_pulseCooldown = 0.0f;
    m_baseDroneTimer = 0.0f;
    m_baseHealTimer = 0.0f;
    m_baseTurretTimer = 0.0f;
    m_miniTitanTransmuteTimer = 0.0f;
    m_biomeWaveTime = 0.0f;
    m_lastAssistType = 0;
    m_customSpeedMultiplier = difficultySpeed();
    m_gravityInverted = false;
    m_gravityInvertTimer = 0.0f;
    m_invulnerableTimer = 0.0f;
    m_transmuteBombsCount = 0;

    for (auto& d : m_debrisList) {
        d.x = 0.0f; d.y = 0.0f;
        d.vx = 0.0f; d.vy = 0.0f;
        d.type = 0; d.points = 0; d.size = 0.04f; d.state = 0;
    }
}

void ScavengerEngine::restoreSession(
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
) {
    reset(fullUnlocked);
    std::lock_guard<std::mutex> lock(m_engineMutex);
    m_level = std::max(1, fullUnlocked ? level : std::min(level, 17));
    int32_t minScoreForLevel = (m_level - 1) * m_level * 350;
    m_score = std::max(minScoreForLevel, score);
    m_shield = std::clamp(shield, 1, 100);
    m_comboCount = std::max(0, combo);
    m_maxCombo = std::max(m_comboCount, maxCombo);
    m_baseStage = std::clamp(baseStage, 0, 4);
    m_isFullUnlocked = fullUnlocked;
    m_isHackedBossMode = isHackedBossMode;
    m_bossHp = std::clamp(bossHp, 1, BOSS_MAX_HP);
    m_bossStage = std::clamp(bossStage, 1, 2);
    m_bossPhase = (m_bossStage == 1) ? ((m_bossHp > BOSS_MAX_HP / 2) ? 1 : 2) : ((m_bossHp > BOSS_MAX_HP / 2) ? 2 : 3);
    m_lastGlitchLevel = m_level - 1;
    m_isCinematic = false;
    m_isPaused = false;
}

} // namespace spacescavenger
