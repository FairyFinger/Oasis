//
//  ScavengerBridge.mm
//  Echo: The Scrappy-Bot (iOS Native Edition)
//
//  Objective-C++ implementation wrapping ScavengerEngine.
//

#import "ScavengerBridge.h"
#include "ScavengerEngine.h"
#include <memory>

@implementation ScavengerBridge {
    std::unique_ptr<spacescavenger::ScavengerEngine> _engine;
}

- (instancetype)initWithMaxDebris:(NSInteger)maxDebris {
    self = [super init];
    if (self) {
        size_t safeCount = static_cast<size_t>(std::clamp((int)maxDebris, 20, 500));
        _engine = std::make_unique<spacescavenger::ScavengerEngine>(safeCount);
    }
    return self;
}

- (void)setVesselPosition:(float)normX {
    if (_engine) _engine->setVesselPosition(normX);
}

- (float)getVesselPosition {
    return _engine ? _engine->getVesselPosition() : 0.5f;
}

- (void)stepWithDeltaTime:(float)deltaTime {
    if (_engine) _engine->step(deltaTime);
}

- (void)resetWithFullUnlocked:(BOOL)fullUnlocked {
    if (_engine) _engine->reset(fullUnlocked);
}

- (void)restoreSessionWithLevel:(int32_t)level
                          score:(int32_t)score
                         shield:(int32_t)shield
                          combo:(int32_t)combo
                       maxCombo:(int32_t)maxCombo
                      baseStage:(int32_t)baseStage
                   fullUnlocked:(BOOL)fullUnlocked
               isHackedBossMode:(BOOL)isHackedBossMode
                         bossHp:(int32_t)bossHp
                      bossStage:(int32_t)bossStage {
    if (_engine) {
        _engine->restoreSession(
            level,
            score,
            shield,
            combo,
            maxCombo,
            baseStage,
            fullUnlocked,
            isHackedBossMode,
            bossHp,
            bossStage
        );
    }
}

- (void)clearDebris {
    if (_engine) _engine->clearDebris();
}

- (void)setPaused:(BOOL)paused {
    if (_engine) _engine->setPaused(paused);
}

- (BOOL)isPaused {
    return _engine ? _engine->isPaused() : NO;
}

- (void)setCinematicMode:(BOOL)isCinematic {
    if (_engine) _engine->setCinematicMode(isCinematic);
}

- (void)setDevLevel:(int32_t)level {
    if (_engine) _engine->setDevLevel(level);
}

- (void)setHighScore:(int32_t)highScore {
    if (_engine) _engine->setHighScore(highScore);
}

- (BOOL)triggerMagneticPulse {
    return _engine ? _engine->triggerMagneticPulse() : NO;
}

- (float)getMagneticPulseCooldown {
    return _engine ? _engine->getMagneticPulseCooldown() : 0.0f;
}

- (int32_t)pollBaseAssistEvent {
    return _engine ? _engine->pollBaseAssistEvent() : 0;
}

- (float)getLastAssistX {
    return _engine ? _engine->getLastAssistX() : 0.5f;
}

- (float)getLastAssistY {
    return _engine ? _engine->getLastAssistY() : 0.85f;
}

- (void)setDifficultyMode:(int32_t)mode {
    if (_engine) _engine->setDifficultyMode(mode);
}

- (int32_t)getDifficultyMode {
    return _engine ? _engine->getDifficultyMode() : 1;
}

- (int32_t)getCriticalSector {
    return _engine ? _engine->getCriticalSector() : 0;
}

- (void)setCustomSpeedMultiplier:(float)multiplier {
    if (_engine) _engine->setCustomSpeedMultiplier(multiplier);
}

- (float)getCustomSpeedMultiplier {
    return _engine ? _engine->getCustomSpeedMultiplier() : 1.0f;
}

- (void)setGravityInverted:(BOOL)inverted {
    if (_engine) _engine->setGravityInverted(inverted);
}

- (BOOL)isGravityInverted {
    return _engine ? _engine->isGravityInverted() : NO;
}

- (void)triggerEmergencyQuantumShield {
    if (_engine) _engine->triggerEmergencyQuantumShield();
}

- (BOOL)isQuantumShieldActive {
    return _engine ? _engine->isQuantumShieldActive() : NO;
}

- (float)getQuantumShieldTimer {
    return _engine ? _engine->getQuantumShieldTimer() : 0.0f;
}

- (void)transmuteBombsToGold:(int32_t)count {
    if (_engine) _engine->transmuteBombsToGold(count);
}

- (int32_t)getTransmuteBombsRemaining {
    return _engine ? _engine->getTransmuteBombsRemaining() : 0;
}

- (void)setPowerOvercharged:(BOOL)overcharged {
    if (_engine) _engine->setPowerOvercharged(overcharged);
}

- (BOOL)isPowerOvercharged {
    return _engine ? _engine->isPowerOvercharged() : NO;
}

- (void)applyOasisBeaconGiftWithBonusShield:(int32_t)bonusShield bonusScore:(int32_t)bonusScore {
    if (_engine) _engine->applyOasisBeaconGift(bonusShield, bonusScore);
}

- (int32_t)pollCapturedItemType {
    return _engine ? _engine->pollCapturedItemType() : -1;
}

- (BOOL)pollBombExplosionEvent {
    return _engine ? _engine->pollBombExplosionEvent() : NO;
}

- (BOOL)pollBaseTierUpgradedEvent {
    return _engine ? _engine->pollBaseTierUpgradedEvent() : NO;
}

- (BOOL)pollCaptureSoundEvent {
    return _engine ? _engine->pollCaptureSoundEvent() : NO;
}

- (BOOL)pollDamageSoundEvent {
    return _engine ? _engine->pollDamageSoundEvent() : NO;
}

- (BOOL)pollNewRecordSoundEvent {
    return _engine ? _engine->pollNewRecordSoundEvent() : NO;
}

- (BOOL)pollComboSoundEvent {
    return _engine ? _engine->pollComboSoundEvent() : NO;
}

- (BOOL)pollMetaTakeoverEvent {
    return _engine ? _engine->pollMetaTakeoverEvent() : NO;
}

- (BOOL)pollSecretGhostWallEvent {
    return _engine ? _engine->pollSecretGhostWallEvent() : NO;
}

- (int32_t)getScore {
    return _engine ? _engine->getScore() : 0;
}

- (int32_t)getShield {
    return _engine ? _engine->getShield() : 100;
}

- (int32_t)getLevel {
    return _engine ? _engine->getLevel() : 1;
}

- (int32_t)getCombo {
    return _engine ? _engine->getCombo() : 0;
}

- (int32_t)getMaxCombo {
    return _engine ? _engine->getMaxCombo() : 0;
}

- (int32_t)getBaseStage {
    return _engine ? _engine->getBaseStage() : 0;
}

- (int32_t)getNextStageScore {
    return _engine ? _engine->getNextStageScore() : 100;
}

- (NSInteger)getActiveDebrisCount {
    return _engine ? static_cast<NSInteger>(_engine->getActiveDebrisCount()) : 0;
}

- (float)getGlitchIntensity {
    return _engine ? _engine->getGlitchIntensity() : 0.0f;
}

- (EchoDebrisSnapshot)getDebrisAtIndex:(NSInteger)index {
    EchoDebrisSnapshot snap = {0.0f, 0.0f, 0.0f, 0.0f, 0, 0, 0.0f, 0};
    if (!_engine) return snap;

    size_t count = _engine->getActiveDebrisCount();
    if (index < 0 || static_cast<size_t>(index) >= count) return snap;

    const auto* buffer = static_cast<const spacescavenger::DebrisState*>(_engine->getDebrisBufferData());
    if (buffer) {
        const auto& d = buffer[index];
        snap.x = d.x;
        snap.y = d.y;
        snap.vx = d.vx;
        snap.vy = d.vy;
        snap.type = d.type;
        snap.points = d.points;
        snap.size = d.size;
        snap.state = d.state;
    }
    return snap;
}

- (void)setHackedBossMode:(BOOL)active {
    if (_engine) _engine->setHackedBossMode(active);
}

- (BOOL)isHackedBossMode {
    return _engine ? _engine->isHackedBossMode() : NO;
}

- (int32_t)getBossHp {
    return _engine ? _engine->getBossHp() : 420;
}

- (float)getBossX {
    return _engine ? _engine->getBossX() : 0.5f;
}

- (int32_t)getBossPhase {
    return _engine ? _engine->getBossPhase() : 1;
}

- (int32_t)getBossStage {
    return _engine ? _engine->getBossStage() : 1;
}

- (int32_t)getBossLaserCharge {
    return _engine ? _engine->getBossLaserCharge() : 0;
}

- (int32_t)getBossLaserRequiredCharge {
    return _engine ? _engine->getBossLaserRequiredCharge() : 4;
}

- (BOOL)pollBossHitEvent {
    return _engine ? _engine->pollBossHitEvent() : NO;
}

- (BOOL)pollBossLaserDodgedEvent {
    return _engine ? _engine->pollBossLaserDodgedEvent() : NO;
}

- (BOOL)pollBossPhase2TransitionEvent {
    return _engine ? _engine->pollBossPhase2TransitionEvent() : NO;
}

- (BOOL)pollBossDefeatedEvent {
    return _engine ? _engine->pollBossDefeatedEvent() : NO;
}

@end
