//
//  ScavengerBridge.h
//  Echo: The Scrappy-Bot (iOS Native Edition)
//
//  Objective-C++ bridge wrapping the pure C++20 ScavengerEngine for Swift / SwiftUI.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Lightweight snapshot of a falling pop-culture relic or hazard bomb
typedef struct {
    float x;
    float y;
    float vx;
    float vy;
    uint32_t type;
    int32_t points;
    float size;
    uint32_t state;
} EchoDebrisSnapshot;

@interface ScavengerBridge : NSObject

- (instancetype)initWithMaxDebris:(NSInteger)maxDebris;

// Player Ship Control
- (void)setVesselPosition:(float)normX;
- (float)getVesselPosition;

// Core Engine Loop
- (void)stepWithDeltaTime:(float)deltaTime;
- (void)resetWithFullUnlocked:(BOOL)fullUnlocked;
- (void)restoreSessionWithLevel:(int32_t)level
                          score:(int32_t)score
                         shield:(int32_t)shield
                          combo:(int32_t)combo
                       maxCombo:(int32_t)maxCombo
                      baseStage:(int32_t)baseStage
                   fullUnlocked:(BOOL)fullUnlocked
               isHackedBossMode:(BOOL)isHackedBossMode
                         bossHp:(int32_t)bossHp
                      bossStage:(int32_t)bossStage;
- (void)clearDebris;

// Pause & Cinematic
- (void)setPaused:(BOOL)paused;
- (BOOL)isPaused;
- (void)setCinematicMode:(BOOL)isCinematic;
- (void)setDevLevel:(int32_t)level;
- (void)setHighScore:(int32_t)highScore;

// Tactile Magnetic Repulsion Wave (Parry)
- (BOOL)triggerMagneticPulse;
- (float)getMagneticPulseCooldown;
- (int32_t)pollBaseAssistEvent;
- (float)getLastAssistX;
- (float)getLastAssistY;

// Difficulty Modes & Power-Ups
- (void)setDifficultyMode:(int32_t)mode;
- (int32_t)getDifficultyMode;
- (int32_t)getCriticalSector;
- (void)setCustomSpeedMultiplier:(float)multiplier;
- (float)getCustomSpeedMultiplier;
- (void)setGravityInverted:(BOOL)inverted;
- (BOOL)isGravityInverted;
- (void)triggerEmergencyQuantumShield;
- (BOOL)isQuantumShieldActive;
- (float)getQuantumShieldTimer;
- (void)transmuteBombsToGold:(int32_t)count;
- (int32_t)getTransmuteBombsRemaining;
- (void)setPowerOvercharged:(BOOL)overcharged;
- (BOOL)isPowerOvercharged;
- (void)applyOasisBeaconGiftWithBonusShield:(int32_t)bonusShield bonusScore:(int32_t)bonusScore;

// Audio & Gameplay Feedback Event Flags
- (int32_t)pollCapturedItemType;
- (BOOL)pollBombExplosionEvent;
- (BOOL)pollBaseTierUpgradedEvent;
- (BOOL)pollCaptureSoundEvent;
- (BOOL)pollDamageSoundEvent;
- (BOOL)pollNewRecordSoundEvent;
- (BOOL)pollComboSoundEvent;
- (BOOL)pollMetaTakeoverEvent;
- (BOOL)pollSecretGhostWallEvent;

// Telemetry & State
- (int32_t)getScore;
- (int32_t)getShield;
- (int32_t)getLevel;
- (int32_t)getCombo;
- (int32_t)getMaxCombo;
- (int32_t)getBaseStage;
- (int32_t)getNextStageScore;
- (NSInteger)getActiveDebrisCount;
- (float)getGlitchIntensity;

// Direct Fast Memory Access for Swift Rendering
- (EchoDebrisSnapshot)getDebrisAtIndex:(NSInteger)index;

// Part 2: Meca-Titan Final Boss Mode
- (void)setHackedBossMode:(BOOL)active;
- (BOOL)isHackedBossMode;
- (int32_t)getBossHp;
- (float)getBossX;
- (int32_t)getBossPhase;
- (int32_t)getBossStage;
- (int32_t)getBossLaserCharge;
- (int32_t)getBossLaserRequiredCharge;
- (BOOL)pollBossHitEvent;
- (BOOL)pollBossLaserDodgedEvent;
- (BOOL)pollBossPhase2TransitionEvent;
- (BOOL)pollBossDefeatedEvent;

@end

NS_ASSUME_NONNULL_END
