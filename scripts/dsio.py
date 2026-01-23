# dsio.py

import pygame
import serial
import time

pygame.init()
pygame.joystick.init()

# ---- UART ----
ser = serial.Serial('COM4', 115200, timeout=1)
print("✓ Connected to FPGA on COM4")

# ---- Controller ----
pad = pygame.joystick.Joystick(0)
pad.init()
print(f"✓ Controller: {pad.get_name()}")

# ---- Packet Structure (matching test_game.py) ----
PACKET_TYPE_PLAYER = 0x01

# Direction values
DIR_NONE  = 0x00
DIR_UP    = 0x01
DIR_DOWN  = 0x02
DIR_LEFT  = 0x03
DIR_RIGHT = 0x04
DIR_START = 0x09  # START button

# Action values
ACTION_NONE = 0x00
ACTION_FIRE = 0x01

DEBOUNCE = 0.15
last_press = {}

def send_packet(direction=DIR_NONE, action=ACTION_NONE):
    """
    Send 8-byte packet matching test_game.py format:
    Byte 0: packet_type (0x01 = player)
    Byte 1: direction
    Byte 2: action
    Bytes 3-7: padding (0x00)
    """
    packet = bytes([
        PACKET_TYPE_PLAYER,  # Byte 0
        direction,            # Byte 1
        action,               # Byte 2
        0x00, 0x00, 0x00, 0x00, 0x00  # Bytes 3-7: padding
    ])
    ser.write(packet)
    ser.flush()
    
    # Pretty print
    dir_names = {
        DIR_NONE: "NONE",
        DIR_UP: "UP",
        DIR_DOWN: "DOWN",
        DIR_LEFT: "LEFT",
        DIR_RIGHT: "RIGHT",
        DIR_START: "START"
    }
    action_names = {
        ACTION_NONE: "---",
        ACTION_FIRE: "FIRE!"
    }
    
    dir_str = dir_names.get(direction, f"0x{direction:02X}")
    action_str = action_names.get(action, f"0x{action:02X}")
    hex_str = ' '.join(f'{b:02X}' for b in packet)
    print(f"📤 Dir:{dir_str:8} Action:{action_str:6} | {hex_str}")

def debounce(btn):
    now = time.time()
    if btn in last_press and now - last_press[btn] < DEBOUNCE:
        return False
    last_press[btn] = now
    return True

print("\n🎮 Controls:")
print("  D-Pad Up/Down/Left/Right → Move Player")
print("  X (Cross)                → Fire Bullet")
print("  SELECT/SHARE             → Start Game")
print("  Press Ctrl+C to exit\n")

# Send START signal on launch (like test_game.py does)
print("🚀 Sending START signal to begin game...")
send_packet(direction=DIR_START, action=ACTION_NONE)
time.sleep(0.2)
send_packet(direction=DIR_NONE, action=ACTION_NONE)  # Release START
time.sleep(0.5)
print("✓ Game should now be in PLAYING state\n")

# Track current direction for continuous movement
current_direction = DIR_NONE

clock = pygame.time.Clock()

try:
    while True:
        for e in pygame.event.get():
            if e.type == pygame.QUIT:
                raise KeyboardInterrupt
                
            elif e.type == pygame.JOYBUTTONDOWN and debounce(e.button):
                
                # Fire button (X / Cross)
                if e.button == 0:
                    print("🔫 FIRE!")
                    send_packet(direction=current_direction, action=ACTION_FIRE)
                
                # SELECT/SHARE button (button 8 on most controllers)
                elif e.button == 8:
                    print("▶️  START/RESTART GAME")
                    send_packet(direction=DIR_START, action=ACTION_NONE)
                    time.sleep(0.1)
                    send_packet(direction=DIR_NONE, action=ACTION_NONE)
                
                # D-Pad buttons
                elif e.button == 11:  # D-Pad Up
                    print("⬆️  MOVE UP")
                    current_direction = DIR_UP
                    send_packet(direction=DIR_UP, action=ACTION_NONE)
                    
                elif e.button == 12:  # D-Pad Down
                    print("⬇️  MOVE DOWN")
                    current_direction = DIR_DOWN
                    send_packet(direction=DIR_DOWN, action=ACTION_NONE)
                    
                elif e.button == 13:  # D-Pad Left
                    print("⬅️  MOVE LEFT")
                    current_direction = DIR_LEFT
                    send_packet(direction=DIR_LEFT, action=ACTION_NONE)
                    
                elif e.button == 14:  # D-Pad Right
                    print("➡️  MOVE RIGHT")
                    current_direction = DIR_RIGHT
                    send_packet(direction=DIR_RIGHT, action=ACTION_NONE)
            
            elif e.type == pygame.JOYBUTTONUP:
                # Send release events
                if e.button == 0:  # Fire released
                    send_packet(direction=current_direction, action=ACTION_NONE)
                    
                elif e.button in [11, 12, 13, 14]:  # D-Pad released
                    current_direction = DIR_NONE
                    send_packet(direction=DIR_NONE, action=ACTION_NONE)

        clock.tick(60)

except KeyboardInterrupt:
    print("\n👋 Exiting...")
finally:
    ser.close()
    pygame.quit()
    print("✓ Cleanup complete")