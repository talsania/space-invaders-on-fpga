# ESP32 PS5 Controller Interface

Wireless PS5 DualSense controller support for Space Invaders FPGA game.

## Hardware Setup

**Wiring:**
```
ESP32 GPIO17 (TX) → FPGA Pin C17 (RX)
ESP32 GPIO16 (RX) → FPGA Pin D18 (TX)
GND               → GND
```

## Quick Start

1. **Install Library:**
   - Arduino IDE → Library Manager
   - Install: `ps5Controller` by Rodney Leath

2. **Get PS5 MAC Address:**
   - **Android:** Through anu Serial Bluetooth info app
   - **Windows:** Settings → Bluetooth → Controller Properties
   - **Linux:** `bluetoothctl` → `scan on` → press PS button

3. **Configure & Upload:**
```cpp
   const char* ps5_MAC = ":YOURMACHERE:";
```
   - Upload to ESP32
   - Press PS button to connect

## Controls

- (Auto-starts game on connection)
- **D-Pad / L:** Move ship
- **X:** Shoot
- **OPTIONS:** Restart game

## Packet Format
8 bytes @ 115200 baud, 60Hz:
`[Type|Direction|Action|00|00|00|00|00]`
- Type: 0x01
- Direction: 0=none, 1=up, 2=down, 3=left, 4=right, 9=START
- Action: 0=none, 1=shoot