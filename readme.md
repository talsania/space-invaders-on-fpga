# Space Invaders on FPGA

This is a **Real-Time Streaming Graphics System** - essentially a Space Invaders-style game implemented on an FPGA with VGA output.

## Features

**Input Pipeline:**
- UART receiver (115200 baud) with 16x oversampling
- Byte-to-packet converter (8 bytes → 64-bit AXI-Stream packets)
- Packet type routing system (0x01=Player, 0x02=Bullet, 0x03=Enemy)

**Game Logic:**
- **Player control** (render_object_0): Green 16x16 sprite, movement via WASD-style packets, trigger signal for shooting
- **Projectile system** (render_object_1): White 4x8 bullets that spawn from player and move upward
- **Enemy grid** (render_group): 3×8 array of red 12x12 sprites with adaptive movement speed
- **Collision detection** (spatial_intersect): AABB-based collision between projectiles and enemies
- **State machine** (system_controller): MENU → PLAYING → VICTORY/GAMEOVER states

**Visual Output:**
- VGA 640×480 @ 60Hz timing generator
- Multi-layer rendering with priority mixing
- 16-LED status display with animated patterns

**Timing & Orchestration:**
- Adaptive scheduler that generates periodic events (faster when fewer enemies remain)
- Priority arbiter merging UART commands and timer events

## How It Works

### Data Flow

```
UART RX (Serial bytes)
  ↓
stream_adapter (Accumulates 8 bytes into 64-bit packets)
  ↓
stream_arbiter (Merges with scheduler_core timer events)
  ↓
stream_router (Routes by packet type: 0x01/0x02/0x03)
  ↓
┌─────────────┬──────────────┬─────────────┐
│ Port 0      │ Port 1       │ Port 3      │
│ Player      │ (Unused)     │ Enemy Grid  │
│ Movement    │              │ Movement    │
└─────────────┴──────────────┴─────────────┘
  ↓               ↓               ↓
render_object_0   (none)   render_group
  ↓                           ↓
Collision ← spatial_intersect → Detection
  ↓
VGA Mixer (Priority: Bullet > Player > Enemies)
  ↓
VGA Output (hsync/vsync/RGB)
```

### Packet Format

**Current UART packet (8 bytes = 64 bits):**
```
Byte 0: Packet Type (0x01=Player, 0x03=Enemy)
Byte 1: Direction (1=Up, 2=Down, 3=Left, 4=Right)
Byte 2: Action (1=Trigger)
Bytes 3-7: Reserved/unused
```

### State Machine

```
MENU (waiting) --[start_button]--> PLAYING
                                      ↓
                    ┌─────────────────┼─────────────────┐
                    ↓                 ↓                 ↓
               active_count==0    halt_condition    (continue)
                    ↓                 ↓
                 VICTORY          GAMEOVER
                    ↓                 ↓
              [start_button]   [start_button]
                    └─────────────────┘
                            ↓
                         MENU
```

## Work in progress...

Adding PS5 Controller Support via ESP32:

```
PS5 Controller (BLE)
  ↓
ESP32 BLE Stack (PS5 controller library)
  ↓
Parse controller state
  ↓
Format into 8-byte packets
  ↓
UART TX → FPGA RX
```
