# dsio.py

import pygame
import serial
import serial.tools.list_ports
import time
import sys

pygame.init()
pygame.joystick.init()

# ---- UART ----
def find_and_connect_serial():
    """Try to connect to COM4, or list available ports if it fails."""
    try:
        ser = serial.Serial('COM4', 115200, timeout=1)
        print("✓ Connected to FPGA on COM4")
        return ser
    except serial.SerialException as e:
        print(f"❌ Failed to connect to COM4: {e}")
        print("\n📋 Available COM ports:")
        ports = list(serial.tools.list_ports.comports())
        if ports:
            for port in ports:
                print(f"   - {port.device}: {port.description}")
            print("\nPlease close any other programs using COM4 and try again.")
        else:
            print("   No COM ports found!")
        sys.exit(1)

ser = find_and_connect_serial()

# ---- Controller ----
pad = pygame.joystick.Joystick(0)
pad.init()
print(f"✓ Controller: {pad.get_name()}")

# ---- Packet Structure ----
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
    print(f"Dir:{dir_str:8} Action:{action_str:6} | {hex_str}")

def debounce(btn):
    now = time.time()
    if btn in last_press and now - last_press[btn] < DEBOUNCE:
        return False
    last_press[btn] = now
    return True

print("\nControls:")
print("  D-Pad Up/Down/Left/Right → Move Player")
print("  X (Cross)                → Fire Bullet")
print("  SELECT/SHARE             → Start Game")
print("  Press Ctrl+C to exit\n")

# Send START signal on launch (like test_game.py does)
print("Sending START signal to begin game...")
send_packet(direction=DIR_START, action=ACTION_NONE)
time.sleep(0.2)
send_packet(direction=DIR_NONE, action=ACTION_NONE)  # Release START
time.sleep(0.5)
print("Game should now be in PLAYING state\n")

# Track button states for continuous input
button_states = {
    'fire': False,
    'up': False,
    'down': False,
    'left': False,
    'right': False
}

current_direction = DIR_NONE
current_action = ACTION_NONE

clock = pygame.time.Clock()

try:
    while True:
        for e in pygame.event.get():
            if e.type == pygame.QUIT:
                raise KeyboardInterrupt
                
            elif e.type == pygame.JOYBUTTONDOWN:
                
                # Fire button (X / Cross)
                if e.button == 0:
                    if not button_states['fire']:
                        print("FIRE!")
                    button_states['fire'] = True
                    current_action = ACTION_FIRE
                
                # SELECT/SHARE button (button 8 on most controllers)
                elif e.button == 8 and debounce(e.button):
                    print("START/RESTART GAME")
                    send_packet(direction=DIR_START, action=ACTION_NONE)
                    time.sleep(0.1)
                    send_packet(direction=DIR_NONE, action=ACTION_NONE)
                
                # D-Pad buttons
                elif e.button == 11:  # D-Pad Up
                    if not button_states['up']:
                        print("MOVE UP")
                    button_states['up'] = True
                    current_direction = DIR_UP
                    
                elif e.button == 12:  # D-Pad Down
                    if not button_states['down']:
                        print("MOVE DOWN")
                    button_states['down'] = True
                    current_direction = DIR_DOWN
                    
                elif e.button == 13:  # D-Pad Left
                    if not button_states['left']:
                        print("MOVE LEFT")
                    button_states['left'] = True
                    current_direction = DIR_LEFT
                    
                elif e.button == 14:  # D-Pad Right
                    if not button_states['right']:
                        print("MOVE RIGHT")
                    button_states['right'] = True
                    current_direction = DIR_RIGHT
            
            elif e.type == pygame.JOYBUTTONUP:
                # Update button states on release
                if e.button == 0:  # Fire released
                    button_states['fire'] = False
                    current_action = ACTION_NONE
                    
                elif e.button == 11:  # D-Pad Up
                    button_states['up'] = False
                    if current_direction == DIR_UP:
                        current_direction = DIR_NONE
                    
                elif e.button == 12:  # D-Pad Down
                    button_states['down'] = False
                    if current_direction == DIR_DOWN:
                        current_direction = DIR_NONE
                    
                elif e.button == 13:  # D-Pad Left
                    button_states['left'] = False
                    if current_direction == DIR_LEFT:
                        current_direction = DIR_NONE
                    
                elif e.button == 14:  # D-Pad Right
                    button_states['right'] = False
                    if current_direction == DIR_RIGHT:
                        current_direction = DIR_NONE
        
        # Send continuous packets only when buttons are held (60 times per second)
        if current_direction != DIR_NONE or current_action != ACTION_NONE:
            send_packet(direction=current_direction, action=current_action)
        
        clock.tick(60)

except KeyboardInterrupt:
    print("\nExiting...")
finally:
    ser.close()
    pygame.quit()
    print("Cleanup complete")