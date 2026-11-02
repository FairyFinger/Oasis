#ifndef SPACESCAVENGER_SCAVENGERDEBRIS_H
#define SPACESCAVENGER_SCAVENGERDEBRIS_H

#include <cstdint>

namespace spacescavenger {

/**
 * Struct representing a descending retro pop-culture relic or trap bomb.
 * Explicit 16-byte alignment for fast SIMD/cache line memory mapping.
 *
 * Types:
 * 0: NES/SNES Game Cartridge (30 pts)
 * 1: 3.5" Floppy Disk (20 pts)
 * 2: Pixel Arcade Coin (15 pts)
 * 3: Microchip CPU (25 pts)
 * 4: Mini-Joystick Arcade (50 pts - Rare)
 * 5: Nano Shield Core (+20 Shield, 10 pts)
 * 6: Corrupted Glitch Bomb (-20 Shield, Danger Trap!)
 * 7: Deflected Counter-Bomb (Parried weapon against Boss / Level 17 Titan)
 */
struct alignas(16) DebrisState {
    float x;           // X position (0.0 to 1.0 normalized)
    float y;           // Y position (0.0 to 1.0 normalized)
    float vx;          // X velocity
    float vy;          // Y velocity (descending speed)
    uint32_t type;     // Relic or Trap Type (0..7)
    int32_t points;    // Score reward
    float size;        // Collision hitbox size
    uint32_t state;    // 0: Active, 1: Captured, 2: Missed, 3: Secret Ghost Wall
};

} // namespace spacescavenger

#endif // SPACESCAVENGER_SCAVENGERDEBRIS_H
