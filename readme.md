# Space Invaders on FPGA
Real-time streaming graphics system implementing Space Invaders on FPGA with VGA output and wireless PS5 controller support.

![Pi7_Gif (2)](https://github.com/user-attachments/assets/7a15b16e-33c9-46ed-bb4e-4b35170f9f7e)
![PXL_20260125_151322105 MP](https://github.com/user-attachments/assets/1050ab68-de02-48a6-b7e5-e06620c5af32)

## Hardware
- **FPGA:** Nexys A7 100T (Artix-7 FPGA)
- **Controller:** PS5 DualSense controller
- **Bridge:** ESP32 dev board
- **Display:** VGA monitor (640×480 @ 60Hz)

## Features

**Graphics & Game Logic:**
- VGA 640×480 @ 60Hz output
- Player ship (green 16×16 sprite) with WASD-style movement
- Projectile system (white 4×8 bullets)
- Enemy grid (3×8 red 12×12 sprites, adaptive speed)
- AABB collision detection
- State machine: MENU → PLAYING → VICTORY/GAMEOVER
- 16-LED animated status display

**Input & Control:**
- **PS5 DualSense wireless controller** via ESP32 bridge (see `esp32/`)
- UART receiver (115200 baud, 16× oversampling)
- Packet-based command routing (Player/Bullet/Enemy)

## Quick Start

1. **FPGA:** See 'Building from Source' below
2. **ESP32:** Wire GPIO17→C17, GPIO16←D18, GND→GND
3. **Controller:** Follow `esp32/README.md` for DualSense pairing
4. **Play:** Press PS button, game auto-starts

## Building from Source

Requires **Vivado 2022.x or later**.

1. Clone the repo:
```bash
   git clone https://github.com/talsania/space-invaders-on-fpga.git
```
2. Open Vivado and in the Tcl Console run:
```tcl
   cd /path/to/space-invaders-on-fpga
   source create_project.tcl
```
3. Vivado will recreate the project with all RTL sources and constraints linked.
4. Click **Generate Bitstream**, then program the Nexys A7.

## Architecture
```
PS5 Controller (BLE) → ESP32 → UART → stream_adapter → stream_router
                                            ↓
                            ┌───────────────┼───────────────┐
                            ↓               ↓               ↓
                       Player Ship     Projectiles     Enemy Grid
                            ↓               ↓               ↓
                          Collision Detection (spatial_intersect)
                                            ↓
                      VGA Mixer (Priority: Bullet > Player > Enemies)
                                            ↓
                              VGA Output (640×480 @ 60Hz)
```

## Controls

| Input | Action |
|-------|--------|
| D-Pad / Left Stick | Move ship |
| X Button | Shoot |
| OPTIONS | Restart game |

## Packet Format

8-byte UART packets @ 115200 baud:

| Byte | Field | Values |
|------|-------|--------|
| 0 | Type | 0x01=Player, 0x03=Enemy |
| 1 | Direction | 0=none, 1=up, 2=down, 3=left, 4=right, 9=START |
| 2 | Action | 0=none, 1=shoot |
| 3–7 | Reserved | 0x00 |

***
Check out detailed documentation [here](https://languid-suit-427.notion.site/4-Top-module-33728a1af16d80bf829ce6f4d39f5920?pvs=74).